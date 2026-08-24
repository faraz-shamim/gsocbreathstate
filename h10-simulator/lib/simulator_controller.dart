// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'ble_peripheral_backend.dart';
import 'peripheral_backend.dart';
import 'physiology_model.dart';
import 'polar_protocol.dart';
import 'simulator_preset.dart';

enum SimulatorStatus {
  idle,
  checkingPermissions,
  permissionsMissing,
  ready,
  advertising,
  connected,
  streaming,
  unsupported,
  error,
}

class SimulatorController extends ChangeNotifier {
  static const String localName = 'Polar H10 SIM';
  static const String heartRateServiceUuid = PolarSimUuids.heartRateService;
  static const String pmdServiceUuid = PolarSimUuids.pmdService;

  final PeripheralBackend _backend;
  final Future<bool> Function() _permissionRequester;
  final Future<void> Function(bool enabled) _wakeLockSetter;
  final PhysiologyModel _model = PhysiologyModel();
  StreamSubscription<PeripheralEvent>? _backendSub;
  Timer? _hrTimer;
  Timer? _ecgTimer;
  Timer? _accTimer;

  SimulatorStatus _status = SimulatorStatus.idle;
  SimulatorPresetId _presetId = SimulatorPresetId.calmCoherent;
  final List<String> _logs = <String>[];
  bool _ecgStreaming = false;
  bool _accStreaming = false;
  String? _statusDetail;

  double heartRateBpm = SimulatorPreset.byId(
    SimulatorPresetId.calmCoherent,
  ).heartRateBpm;
  double breathRateBpm = SimulatorPreset.byId(
    SimulatorPresetId.calmCoherent,
  ).breathRateBpm;
  double rsaAmplitudeMs = SimulatorPreset.byId(
    SimulatorPresetId.calmCoherent,
  ).rsaAmplitudeMs;
  double ecgNoiseUv = SimulatorPreset.byId(
    SimulatorPresetId.calmCoherent,
  ).ecgNoiseUv;
  double packetDropPercent = SimulatorPreset.byId(
    SimulatorPresetId.calmCoherent,
  ).packetDropPercent;
  double motionLevel = SimulatorPreset.byId(
    SimulatorPresetId.calmCoherent,
  ).motionLevel;
  bool ectopyEnabled = SimulatorPreset.byId(
    SimulatorPresetId.calmCoherent,
  ).ectopyEnabled;

  SimulatorStatus get status => _status;
  SimulatorPresetId get presetId => _presetId;
  SimulatorPreset get preset => SimulatorPreset.byId(_presetId);
  List<String> get logs => List.unmodifiable(_logs);
  bool get isAdvertising =>
      _status == SimulatorStatus.advertising ||
      _status == SimulatorStatus.connected ||
      _status == SimulatorStatus.streaming;
  bool get canStop => isAdvertising;
  bool get isEcgStreaming => _ecgStreaming;
  bool get isAccStreaming => _accStreaming;
  String? get statusDetail => _statusDetail;
  bool get canStart =>
      _status == SimulatorStatus.idle ||
      _status == SimulatorStatus.ready ||
      _status == SimulatorStatus.permissionsMissing ||
      _status == SimulatorStatus.error;

  SimulatorController({
    PeripheralBackend? backend,
    Future<bool> Function()? permissionRequester,
    Future<void> Function(bool enabled)? wakeLockSetter,
  }) : _backend = backend ?? BlePeripheralBackend(),
       _permissionRequester =
           permissionRequester ?? _requestRequiredBlePermissions,
       _wakeLockSetter = wakeLockSetter ?? _setWakeLock;

  String get statusLabel {
    switch (_status) {
      case SimulatorStatus.idle:
        return 'Idle';
      case SimulatorStatus.checkingPermissions:
        return 'Checking permissions';
      case SimulatorStatus.permissionsMissing:
        return 'Permissions missing';
      case SimulatorStatus.ready:
        return 'Ready';
      case SimulatorStatus.advertising:
        return 'Advertising';
      case SimulatorStatus.connected:
        return 'Connected';
      case SimulatorStatus.streaming:
        return 'Streaming';
      case SimulatorStatus.unsupported:
        return 'Unsupported device';
      case SimulatorStatus.error:
        return 'Error';
    }
  }

  Future<void> initialize() async {
    _backendSub ??= _backend.events.listen(_handleBackendEvent);
    final prefs = await SharedPreferences.getInstance();
    final savedPreset = prefs.getString('presetId');
    final parsed = SimulatorPresetId.values.where(
      (id) => id.name == savedPreset,
    );
    if (parsed.isNotEmpty) {
      applyPreset(parsed.first, persist: false);
    }
    _log('Simulator ready for ${SimulatorController.localName}.');
    _status = SimulatorStatus.ready;
    notifyListeners();
  }

  Future<void> applyPreset(SimulatorPresetId id, {bool persist = true}) async {
    final selected = SimulatorPreset.byId(id);
    _presetId = id;
    heartRateBpm = selected.heartRateBpm;
    breathRateBpm = selected.breathRateBpm;
    rsaAmplitudeMs = selected.rsaAmplitudeMs;
    ecgNoiseUv = selected.ecgNoiseUv;
    packetDropPercent = selected.packetDropPercent;
    motionLevel = selected.motionLevel;
    ectopyEnabled = selected.ectopyEnabled;
    _log('Preset: ${selected.label}.');
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('presetId', id.name);
    }
    notifyListeners();
  }

  Future<void> startAdvertising() async {
    if (!canStart) return;
    _status = SimulatorStatus.checkingPermissions;
    _statusDetail = null;
    notifyListeners();

    try {
      final permissionsOk = await _permissionRequester();
      if (!permissionsOk) {
        _status = SimulatorStatus.permissionsMissing;
        _log('Nearby devices permission is required to advertise.');
        notifyListeners();
        return;
      }

      _model.reset();
      await _backend.initialize();
      await _backend.setServices(_polarServices());
      await _backend.startAdvertising(
        localName: localName,
        serviceUuids: const [PolarSimUuids.heartRateService],
      );

      await _wakeLockSetter(true);
      _status = SimulatorStatus.advertising;
      _startHeartRateLoop();
      _log('Advertising as $localName.');
      _log('Services active: HR $heartRateServiceUuid, PMD $pmdServiceUuid.');
    } on BlePeripheralUnsupportedException catch (e) {
      _status = SimulatorStatus.unsupported;
      _statusDetail = e.message;
      _log('Cannot start: ${e.message}');
      await _wakeLockSetter(false);
    } on BlePeripheralNotReadyException catch (e) {
      _status = SimulatorStatus.error;
      _statusDetail = e.message;
      _log('Cannot start: ${e.message}');
      await _wakeLockSetter(false);
    } on BleAdvertisingException catch (e) {
      _status = SimulatorStatus.error;
      _statusDetail = e.message;
      _log('Cannot start advertising: ${e.message}');
      await _wakeLockSetter(false);
    } catch (e) {
      _status = SimulatorStatus.error;
      _statusDetail = 'BLE startup failed. Check the event log and try again.';
      _log('Start failed: ${_compactError(e)}');
      await _wakeLockSetter(false);
    } finally {
      notifyListeners();
    }
  }

  Future<void> stopAdvertising() async {
    if (_status == SimulatorStatus.idle || _status == SimulatorStatus.ready) {
      return;
    }
    _stopAllLoops();
    await _backend.stopAdvertising().catchError((_) {});
    await _wakeLockSetter(false);
    _status = SimulatorStatus.ready;
    _statusDetail = null;
    _log('Advertising stopped.');
    notifyListeners();
  }

  Future<void> simulateDisconnect() async {
    _resetPmdStreams();
    _status = SimulatorStatus.advertising;
    _log('Simulated connection reset; PMD streams stopped.');
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void setHeartRate(double value) {
    heartRateBpm = value;
    _presetId = SimulatorPresetId.manual;
    notifyListeners();
  }

  void setBreathRate(double value) {
    breathRateBpm = value;
    _presetId = SimulatorPresetId.manual;
    notifyListeners();
  }

  void setRsaAmplitude(double value) {
    rsaAmplitudeMs = value;
    _presetId = SimulatorPresetId.manual;
    notifyListeners();
  }

  void setEcgNoise(double value) {
    ecgNoiseUv = value;
    _presetId = SimulatorPresetId.manual;
    notifyListeners();
  }

  void setPacketDrop(double value) {
    packetDropPercent = value;
    _presetId = SimulatorPresetId.manual;
    notifyListeners();
  }

  void setMotionLevel(double value) {
    motionLevel = value;
    _presetId = SimulatorPresetId.manual;
    notifyListeners();
  }

  void setEctopyEnabled(bool value) {
    ectopyEnabled = value;
    _presetId = SimulatorPresetId.manual;
    notifyListeners();
  }

  static Future<bool> _requestRequiredBlePermissions() async {
                                                                       
                                                                            
    final statuses = await <Permission>[
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();
    return statuses.values.every((status) => status.isGranted);
  }

  static Future<void> _setWakeLock(bool enabled) {
    return enabled ? WakelockPlus.enable() : WakelockPlus.disable();
  }

  List<GattServiceSpec> _polarServices() {
    return const <GattServiceSpec>[
      GattServiceSpec(
        uuid: PolarSimUuids.heartRateService,
        characteristics: <GattCharacteristicSpec>[
          GattCharacteristicSpec(
            uuid: PolarSimUuids.heartRateMeasurement,
            notifiable: true,
          ),
        ],
      ),
      GattServiceSpec(
        uuid: PolarSimUuids.pmdService,
        characteristics: <GattCharacteristicSpec>[
          GattCharacteristicSpec(
            uuid: PolarSimUuids.pmdControlPoint,
            readable: true,
            writable: true,
            notifiable: true,
            initialValue: <int>[0x0F, 0x05],
          ),
          GattCharacteristicSpec(uuid: PolarSimUuids.pmdData, notifiable: true),
        ],
      ),
    ];
  }

  void _handleBackendEvent(PeripheralEvent event) {
    switch (event.type) {
      case PeripheralEventType.advertisingStarted:
        _status = SimulatorStatus.advertising;
      case PeripheralEventType.advertisingStopped:
        if (_status != SimulatorStatus.ready) _status = SimulatorStatus.ready;
      case PeripheralEventType.centralSubscribed:
        if (event.isConnected == true &&
            _status == SimulatorStatus.advertising) {
          _status = SimulatorStatus.connected;
        }
      case PeripheralEventType.centralUnsubscribed:
        if (event.isConnected == false && _status != SimulatorStatus.ready) {
          _resetPmdStreams();
          _status = SimulatorStatus.advertising;
        }
      case PeripheralEventType.characteristicWrite:
        _handleCharacteristicWrite(event);
      case PeripheralEventType.error:
        _status = SimulatorStatus.error;
      case PeripheralEventType.initialized:
      case PeripheralEventType.characteristicRead:
      case PeripheralEventType.notificationSent:
        break;
    }

    if (event.type != PeripheralEventType.notificationSent) {
      _log(event.message);
    }
    notifyListeners();
  }

  void _handleCharacteristicWrite(PeripheralEvent event) {
    if (!_sameUuid(event.characteristicId, PolarSimUuids.pmdControlPoint)) {
      return;
    }
    final value = event.value ?? const <int>[];
    unawaited(_handlePmdCommand(value));
  }

  Future<void> _handlePmdCommand(List<int> command) async {
    if (command.length < 2) {
      await _notifyPmdControl(
        PolarProtocol.pmdResponse(
          opCode: command.isEmpty ? 0 : command[0],
          measurementType: 0,
          errorCode: PolarProtocol.invalidParameter,
        ),
      );
      return;
    }

    final opCode = command[0];
    final measurementType = command[1];
    final type = PmdMeasurementType.fromByte(measurementType);
    if (type == null) {
      await _notifyPmdControl(
        PolarProtocol.pmdResponse(
          opCode: opCode,
          measurementType: measurementType,
          errorCode: PolarProtocol.invalidMeasurementType,
        ),
      );
      return;
    }

    switch (opCode) {
      case 0x01:
        await _notifyPmdControl(PolarProtocol.pmdSettingsResponse(type));
      case 0x02:
        if (_isPmdStreaming(type)) {
          await _notifyPmdControl(
            PolarProtocol.pmdResponse(
              opCode: opCode,
              measurementType: measurementType,
              errorCode: PolarProtocol.alreadyInState,
            ),
          );
          return;
        }
        await _notifyPmdControl(
          PolarProtocol.pmdResponse(
            opCode: opCode,
            measurementType: measurementType,
            errorCode: PolarProtocol.success,
          ),
        );
        _startPmdStream(type);
      case 0x03:
        if (!_isPmdStreaming(type)) {
          await _notifyPmdControl(
            PolarProtocol.pmdResponse(
              opCode: opCode,
              measurementType: measurementType,
              errorCode: PolarProtocol.alreadyInState,
            ),
          );
          return;
        }
        await _notifyPmdControl(
          PolarProtocol.pmdResponse(
            opCode: opCode,
            measurementType: measurementType,
            errorCode: PolarProtocol.success,
          ),
        );
        _stopPmdStream(type);
      default:
        await _notifyPmdControl(
          PolarProtocol.pmdResponse(
            opCode: opCode,
            measurementType: measurementType,
            errorCode: PolarProtocol.invalidOpCode,
          ),
        );
    }
  }

  Future<void> _notifyPmdControl(List<int> response) async {
    await _backend.notify(
      characteristicUuid: PolarSimUuids.pmdControlPoint,
      value: response,
    );
  }

  void _startHeartRateLoop() {
    _hrTimer?.cancel();
    _hrTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_sendHeartRatePacket());
    });
    unawaited(_sendHeartRatePacket());
  }

  Future<void> _sendHeartRatePacket() async {
    if (_status != SimulatorStatus.advertising &&
        _status != SimulatorStatus.connected &&
        _status != SimulatorStatus.streaming) {
      return;
    }
    if (_model.shouldDropPacket(packetDropPercent)) return;
    final rrIntervals = _model.drainRrIntervals(
      const Duration(seconds: 1),
      _settings,
    );
    final packet = PolarProtocol.heartRateMeasurement(
      heartRateBpm: heartRateBpm.round(),
      rrIntervalsMs: rrIntervals,
    );
    await _backend.notify(
      characteristicUuid: PolarSimUuids.heartRateMeasurement,
      value: packet,
    );
  }

  void _startPmdStream(PmdMeasurementType type) {
    switch (type) {
      case PmdMeasurementType.ecg:
        _ecgStreaming = true;
        _ecgTimer?.cancel();
        _ecgTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
          unawaited(_sendEcgFrame());
        });
        unawaited(_sendEcgFrame());
        _log('PMD ECG streaming started.');
      case PmdMeasurementType.acc:
        _accStreaming = true;
        _accTimer?.cancel();
        _accTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          unawaited(_sendAccFrame());
        });
        unawaited(_sendAccFrame());
        _log('PMD ACC streaming started.');
    }
    _status = SimulatorStatus.streaming;
    notifyListeners();
  }

  void _stopPmdStream(PmdMeasurementType type) {
    switch (type) {
      case PmdMeasurementType.ecg:
        _ecgStreaming = false;
        _ecgTimer?.cancel();
        _ecgTimer = null;
        _log('PMD ECG streaming stopped.');
      case PmdMeasurementType.acc:
        _accStreaming = false;
        _accTimer?.cancel();
        _accTimer = null;
        _log('PMD ACC streaming stopped.');
    }
    if (!_ecgStreaming &&
        !_accStreaming &&
        _status == SimulatorStatus.streaming) {
      _status = SimulatorStatus.connected;
    }
    notifyListeners();
  }

  bool _isPmdStreaming(PmdMeasurementType type) {
    return switch (type) {
      PmdMeasurementType.ecg => _ecgStreaming,
      PmdMeasurementType.acc => _accStreaming,
    };
  }

  void _resetPmdStreams() {
    _ecgTimer?.cancel();
    _ecgTimer = null;
    _accTimer?.cancel();
    _accTimer = null;
    _ecgStreaming = false;
    _accStreaming = false;
  }

  Future<void> _sendEcgFrame() async {
    if (!_ecgStreaming || _model.shouldDropPacket(packetDropPercent)) return;
    final samples = _model.nextEcgSamples(26, _settings);
    await _backend.notify(
      characteristicUuid: PolarSimUuids.pmdData,
      value: PolarProtocol.ecgFrame(
        timestampNs: DateTime.now().microsecondsSinceEpoch * 1000,
        samplesUv: samples,
      ),
    );
  }

  Future<void> _sendAccFrame() async {
    if (!_accStreaming || _model.shouldDropPacket(packetDropPercent)) return;
    final samples = _model.nextAccSamples(20, _settings);
    await _backend.notify(
      characteristicUuid: PolarSimUuids.pmdData,
      value: PolarProtocol.accFrame(
        timestampNs: DateTime.now().microsecondsSinceEpoch * 1000,
        samples: samples,
      ),
    );
  }

  PhysiologySettings get _settings {
    return PhysiologySettings(
      heartRateBpm: heartRateBpm,
      breathRateBpm: breathRateBpm,
      rsaAmplitudeMs: rsaAmplitudeMs,
      ecgNoiseUv: ecgNoiseUv,
      packetDropPercent: packetDropPercent,
      motionLevel: motionLevel,
      ectopyEnabled: ectopyEnabled,
    );
  }

  void _stopAllLoops() {
    _hrTimer?.cancel();
    _hrTimer = null;
    _ecgTimer?.cancel();
    _ecgTimer = null;
    _accTimer?.cancel();
    _accTimer = null;
    _ecgStreaming = false;
    _accStreaming = false;
  }

  bool _sameUuid(String? left, String right) {
    return left != null && left.toLowerCase() == right.toLowerCase();
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _logs.insert(0, '$timestamp  $message');
    if (_logs.length > 80) {
      _logs.removeRange(80, _logs.length);
    }
  }

  String _compactError(Object error) {
    final compact = error.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 240) return compact;
    return '${compact.substring(0, 237)}...';
  }

  @override
  void dispose() {
    _stopAllLoops();
    unawaited(_backendSub?.cancel());
    unawaited(_backend.dispose());
    unawaited(_wakeLockSetter(false));
    super.dispose();
  }
}
