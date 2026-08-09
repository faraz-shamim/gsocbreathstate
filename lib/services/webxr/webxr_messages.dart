library;

class WebXRMessageType {
  static const String sessionState = 'session_state';
  static const String biofeedbackSnapshot = 'biofeedback_snapshot';
  static const String breathPhase = 'breath_phase';
  static const String treeProgress = 'tree_progress';
  static const String sessionResult = 'session_result';
  static const String error = 'error';
  static const String command = 'command';
}

class WebXRCommandName {
  static const String start = 'start';
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String stop = 'stop';
  static const String setProtocol = 'set_protocol';
  static const String setDuration = 'set_duration';
  static const String recenter = 'recenter';
  static const String setComfortOptions = 'set_comfort_options';
}

class WebXRMessage {
  static const int version = 1;
  static const String flutterSource = 'flutter';
  static const String webXRSource = 'webxr';

  static Map<String, Object?> build(
    String type, {
    Map<String, Object?>? session,
    Map<String, Object?>? metrics,
    Map<String, Object?>? breath,
    Map<String, Object?>? tree,
    Map<String, Object?>? result,
    Map<String, Object?>? error,
  }) {
    return <String, Object?>{
      'version': version,
      'source': flutterSource,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      if (session != null) 'session': session,
      if (metrics != null) 'metrics': metrics,
      if (breath != null) 'breath': breath,
      if (tree != null) 'tree': tree,
      if (result != null) 'result': result,
      if (error != null) 'error': error,
    };
  }
}

class WebXRCommand {
  final String name;
  final Map<String, Object?> payload;

  const WebXRCommand({required this.name, this.payload = const {}});

  static WebXRCommand? tryParse(Object? raw) {
    if (raw is! Map) return null;

    final type = raw['type'];
    final source = raw['source'];
    if (type != WebXRMessageType.command ||
        (source != null && source != WebXRMessage.webXRSource)) {
      return null;
    }

    final commandValue = raw['command'];
    if (commandValue is! String || commandValue.isEmpty) return null;

    final payloadRaw = raw['payload'];
    return WebXRCommand(
      name: commandValue,
      payload:
          payloadRaw is Map
              ? payloadRaw.map(
                (key, value) => MapEntry(key.toString(), value as Object?),
              )
              : const {},
    );
  }
}
