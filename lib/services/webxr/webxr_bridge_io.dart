                                                                          
                                                          
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart'
    show FlutterError, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';

import 'package:breath_state/services/biofeedback/realtime_hrv_engine.dart';
import 'package:breath_state/services/hrv_analysis/hrv_psychophysiological_indices.dart';
import 'package:breath_state/services/webxr/webxr_messages.dart';

class WebXRBridge {
  static const MethodChannel _platform = MethodChannel('breath_state/webxr');
  static const String _assetPrefix = 'web/vr/';
  static const int _maxMessageTypes = 16;

  final StreamController<WebXRCommand> _commandController =
      StreamController<WebXRCommand>.broadcast();
  final Set<WebSocket> _clients = <WebSocket>{};
  final Map<String, String> _latestMessages = <String, String>{};
  final String _token = _createToken();

  HttpServer? _server;
  Future<HttpServer>? _serverFuture;
  bool _disposed = false;
  int _messagesSent = 0;

  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;
  int get messagesSent => _messagesSent;
  Stream<WebXRCommand> get commands => _commandController.stream;

  void open() {
    if (!isSupported || _disposed) return;
    unawaited(
      _ensureServer().then<void>(
        (_) {},
        onError: (Object _, StackTrace _) {},
      ),
    );
  }

  Future<HttpServer> _ensureServer() {
    final running = _server;
    if (running != null) return Future<HttpServer>.value(running);
    return _serverFuture ??= _startServer();
  }

  Future<HttpServer> _startServer() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (_disposed) {
      await server.close(force: true);
      throw StateError('The VR bridge was disposed before startup completed.');
    }
    _server = server;
    unawaited(
      server.forEach(_handleRequest).catchError((Object _) {
                                                                             
      }),
    );
    return server;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    _setCommonHeaders(request.response);
    if (request.uri.path == '/bridge') {
      await _handleSocketUpgrade(request);
      return;
    }

    if (request.method != 'GET' && request.method != 'HEAD') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      await request.response.close();
      return;
    }

    final assetKey = assetKeyForPath(request.uri.path);
    if (assetKey == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      final data = await rootBundle.load(assetKey);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = contentTypeForPath(assetKey)
        ..headers.contentLength = bytes.length
        ..headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      if (request.method == 'GET') request.response.add(bytes);
    } on FlutterError {
      request.response.statusCode = HttpStatus.notFound;
    } catch (_) {
      request.response.statusCode = HttpStatus.internalServerError;
    }
    await request.response.close();
  }

  Future<void> _handleSocketUpgrade(HttpRequest request) async {
    if (request.uri.queryParameters['token'] != _token ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    if (_disposed) {
      await socket.close(WebSocketStatus.goingAway);
      return;
    }
    _clients.add(socket);
    for (final message in _latestMessages.values) {
      socket.add(message);
    }
    socket.listen(
      (Object? raw) => _handleSocketMessage(raw),
      onDone: () => _clients.remove(socket),
      onError: (Object _) => _clients.remove(socket),
      cancelOnError: true,
    );
  }

  void _handleSocketMessage(Object? raw) {
    if (raw is! String || _commandController.isClosed) return;
    try {
      final command = WebXRCommand.tryParse(jsonDecode(raw));
      if (command != null) _commandController.add(command);
    } on FormatException {
                                                         
    }
  }

  void sendMessage(Map<String, Object?> message) {
    if (!isSupported || _disposed) return;
    open();
    final encoded = jsonEncode(message);
    final type = message['type']?.toString() ?? 'message_${_messagesSent + 1}';
    _latestMessages.remove(type);
    _latestMessages[type] = encoded;
    while (_latestMessages.length > _maxMessageTypes) {
      _latestMessages.remove(_latestMessages.keys.first);
    }
    for (final client in List<WebSocket>.of(_clients)) {
      if (client.readyState == WebSocket.open) {
        client.add(encoded);
      } else {
        _clients.remove(client);
      }
    }
    _messagesSent++;
  }

  void sendData(Map<String, double> data) {
    sendMessage(
      WebXRMessage.build(
        WebXRMessageType.biofeedbackSnapshot,
        metrics: data.map((key, value) => MapEntry(key, value)),
      ),
    );
  }

  void sendSnapshot(RealtimeHrvSnapshot snapshot) {
    sendSnapshotWithBreathRate(snapshot, 6.0);
  }

  void sendSnapshotWithBreathRate(
    RealtimeHrvSnapshot snapshot,
    double breathingRateBpm,
  ) {
    if (snapshot.windowRRs.length < 10) return;
    double stressIndex = 150;
    try {
      final result = PsychophysiologicalAnalyzer.compute(
        rrIntervalsMs: snapshot.windowRRs,
        rmssd: snapshot.timeDomain?.rmssd ?? 40,
        meanNN: snapshot.timeDomain?.meanNN ?? 800,
      );
      stressIndex = result.stressIndex.value ?? 150;
    } catch (_) {}

    sendMessage(
      WebXRMessage.build(
        WebXRMessageType.biofeedbackSnapshot,
        metrics: {
          'rmssd': snapshot.timeDomain?.rmssd ?? 40,
          'stressIndex': stressIndex,
          'coherence': snapshot.coherence.clamp(0.0, 100.0).toDouble(),
          'heartRate': snapshot.instantHR,
          'sdnn': snapshot.timeDomain?.sdnn ?? 30,
          'breathingRate': breathingRateBpm,
        },
      ),
    );
  }

  Future<void> launchVrWindow() async {
    if (!isSupported) {
      throw UnsupportedError(
        'Native WebXR launch is only available on Android.',
      );
    }
    final server = await _ensureServer();
    final uri = Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: server.port,
      path: '/vr/webxr_scene.html',
      queryParameters: {'bridgeToken': _token},
    );
    await _platform.invokeMethod<void>('launchBrowser', {'url': '$uri'});
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final client in List<WebSocket>.of(_clients)) {
      unawaited(client.close(WebSocketStatus.goingAway));
    }
    _clients.clear();
    final server = _server;
    if (server != null) unawaited(server.close(force: true));
    if (!_commandController.isClosed) unawaited(_commandController.close());
  }

  static String? assetKeyForPath(String path) {
    late final String decoded;
    try {
      decoded = Uri.decodeComponent(path);
    } on ArgumentError {
      return null;
    }
    if (!decoded.startsWith('/vr/') ||
        decoded.contains('\\') ||
        decoded.split('/').contains('..')) {
      return null;
    }
    final relative = decoded.substring('/vr/'.length);
    if (relative.isEmpty) return null;
    return '$_assetPrefix$relative';
  }

  static ContentType contentTypeForPath(String path) {
    final extension = path.toLowerCase().split('.').last;
    return switch (extension) {
      'html' => ContentType.html,
      'js' => ContentType('text', 'javascript', charset: 'utf-8'),
      'json' => ContentType.json,
      'wasm' => ContentType('application', 'wasm'),
      'glb' => ContentType('model', 'gltf-binary'),
      'gltf' => ContentType('model', 'gltf+json'),
      'webp' => ContentType('image', 'webp'),
      'png' => ContentType('image', 'png'),
      'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
      'ktx2' => ContentType('image', 'ktx2'),
      _ => ContentType.binary,
    };
  }

  static void _setCommonHeaders(HttpResponse response) {
    response.headers
      ..set('Permissions-Policy', 'xr-spatial-tracking=(self)')
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Referrer-Policy', 'no-referrer');
  }

  static String _createToken() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(24, (_) => random.nextInt(256)),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
