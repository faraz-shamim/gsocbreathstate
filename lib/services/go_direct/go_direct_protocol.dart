// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'go_direct_constants.dart';

const int goDirectBleChunkSize = 20;
const int goDirectMaximumRxBufferSize = 4096;

enum GoDirectWriteMode { withoutResponse, withResponse }

GoDirectWriteMode selectGoDirectWriteMode({
  required bool supportsWrite,
  required bool supportsWriteWithoutResponse,
}) {
  if (supportsWriteWithoutResponse) {
    return GoDirectWriteMode.withoutResponse;
  }
  if (supportsWrite) return GoDirectWriteMode.withResponse;
  throw StateError(
    'Go Direct command characteristic supports neither '
    'writeWithoutResponse nor write',
  );
}

List<Uint8List> splitGoDirectBlePacket(Uint8List packet) {
  return <Uint8List>[
    for (var offset = 0; offset < packet.length; offset += goDirectBleChunkSize)
      Uint8List.fromList(
        packet.sublist(
          offset,
          (offset + goDirectBleChunkSize).clamp(0, packet.length).toInt(),
        ),
      ),
  ];
}

typedef GoDirectChunkWriter =
    Future<void> Function(
      Uint8List chunk,
      int chunkIndex,
      int chunkCount,
      bool withoutResponse,
    );

Future<void> writeGoDirectBlePacket({
  required Uint8List packet,
  required GoDirectWriteMode mode,
  required GoDirectChunkWriter writeChunk,
}) async {
  final chunks = splitGoDirectBlePacket(packet);
  for (var index = 0; index < chunks.length; index++) {
    await writeChunk(
      chunks[index],
      index,
      chunks.length,
      mode == GoDirectWriteMode.withoutResponse,
    );
  }
}

Future<T> runGoDirectAfterNotificationSetup<T>({
  required Future<bool> Function() enableNotifications,
  required bool Function() notificationsAreEnabled,
  required Future<T> Function() runWhenReady,
}) async {
  final setupSucceeded = await enableNotifications();
  if (!setupSucceeded || !notificationsAreEnabled()) {
    throw StateError(
      'Go Direct response notification setup completed without enabling notifications',
    );
  }
  return runWhenReady();
}

class GoDirectPacketBuilder {
  static const List<int> _initParameters = [
    0xA5,
    0x4A,
    0x06,
    0x49,
    0x07,
    0x48,
    0x08,
    0x47,
    0x09,
    0x46,
    0x0A,
    0x45,
    0x0B,
    0x44,
    0x0C,
    0x43,
    0x0D,
    0x42,
    0x0E,
    0x41,
  ];

  int _rollingCounter = 0xFF;

  Uint8List buildCommand(int commandId, [List<int>? params]) {
    final packet = <int>[
      GoDirectProtocol.commandHeader,
      0,
      0,
      0,
      commandId,
      ...(params ?? const <int>[]),
    ];

    packet[1] = packet.length;
    packet[2] = _nextRollingCounter();
    final bytes = Uint8List.fromList(packet);
    bytes[3] = calculateGoDirectChecksum(bytes);
    return bytes;
  }

  Uint8List buildInit() => buildCommand(GoDirectCommands.init, _initParameters);

  Uint8List buildGetAvailableSensors() =>
      buildCommand(GoDirectCommands.getAvailableSensors);

  Uint8List buildGetSensorInfo(int sensorNumber) =>
      buildCommand(GoDirectCommands.getSensorInfo, [sensorNumber]);

  Uint8List buildGetDeviceInfo() =>
      buildCommand(GoDirectCommands.getDeviceInfo);

  Uint8List buildGetBatteryStatus() =>
      buildCommand(GoDirectCommands.getBatteryStatus);

  Uint8List buildGetDefaultSensorsMask() =>
      buildCommand(GoDirectCommands.getDefaultSensorsMask);

  Uint8List buildSetMeasurementPeriod(int periodUs) {
    final period = ByteData(4)
      ..setUint32(0, periodUs.clamp(0, 0xFFFFFFFF).toInt(), Endian.little);
    return buildCommand(GoDirectCommands.setMeasurementPeriod, [
      0xFF,
      0x00,
      ...period.buffer.asUint8List(),
      0x00,
      0x00,
      0x00,
      0x00,
    ]);
  }

  Uint8List buildStartMeasurements(int sensorMask) {
    final mask = ByteData(4)
      ..setUint32(0, sensorMask & 0xFFFFFFFF, Endian.little);
    return buildCommand(GoDirectCommands.startMeasurements, [
      0xFF,
      0x01,
      ...mask.buffer.asUint8List(),
      ...List<int>.filled(8, 0),
    ]);
  }

  Uint8List buildStopMeasurements() => buildCommand(
    GoDirectCommands.stopMeasurements,
    [0xFF, 0x00, ...List<int>.filled(4, 0xFF)],
  );

  Uint8List buildDisconnect() => buildCommand(GoDirectCommands.disconnect);

  void reset() => _rollingCounter = 0xFF;

  int _nextRollingCounter() {
    _rollingCounter = (_rollingCounter - 1) & 0xFF;
    return _rollingCounter;
  }
}

int calculateGoDirectChecksum(Uint8List packet) {
  final length = packet[1];
  var checksum = -packet[3];

  for (var i = 0; i < length; i++) {
    checksum = (checksum + packet[i]) & 0xFF;
  }

  return checksum;
}

class GoDirectResponse {
  final int responseType;
  final int commandId;
  final int counter;
  final List<int> payload;
  final List<int> packet;

  const GoDirectResponse({
    required this.responseType,
    required this.commandId,
    required this.counter,
    required this.payload,
    required this.packet,
  });

  bool get isMeasurement =>
      responseType == GoDirectProtocol.measurementResponse;

  @override
  String toString() =>
      isMeasurement
          ? 'Measurement packet (${packet.length}B)'
          : 'Response(cmd=0x${commandId.toRadixString(16)}, '
              'counter=$counter, payload=${payload.length}B)';
}

class GoDirectResponseParser {
  final List<int> _buffer = [];

  int get bufferedByteCount => _buffer.length;

  List<GoDirectResponse> feed(List<int> data) {
    _buffer.addAll(data);
    if (_buffer.length > goDirectMaximumRxBufferSize) {
      _buffer.removeRange(0, _buffer.length - goDirectMaximumRxBufferSize);
    }
    final responses = <GoDirectResponse>[];

    while (_buffer.length >= 2) {
      final type = _buffer[0];
      final totalLength = _buffer[1];
      final minimumLength =
          type == GoDirectProtocol.measurementResponse ? 5 : 6;
      if (totalLength < minimumLength ||
          totalLength > goDirectMaximumRxBufferSize) {
        _buffer.removeAt(0);
        continue;
      }
      if (_buffer.length < totalLength) {
        final frontIsKnownHeader =
            type == GoDirectProtocol.commandHeader ||
            type == GoDirectProtocol.responseHeader ||
            type == GoDirectProtocol.measurementResponse ||
            type == 0x5C;
        final resyncOffset =
            frontIsKnownHeader ? -1 : _findCompleteKnownPacketStart(_buffer);
        if (resyncOffset > 0) {
          _buffer.removeRange(0, resyncOffset);
          continue;
        }
        break;
      }

      final packet = List<int>.from(_buffer.sublist(0, totalLength));
      _buffer.removeRange(0, totalLength);

      if (type == GoDirectProtocol.measurementResponse) {
        if (packet.length < 5) continue;
        responses.add(
          GoDirectResponse(
            responseType: type,
            commandId: -1,
            counter: packet[2],
            payload: packet.sublist(4),
            packet: packet,
          ),
        );
        continue;
      }

      if (packet.length < 6) continue;
      responses.add(
        GoDirectResponse(
          responseType: type,
          commandId: packet[4],
          counter: packet[5],
          payload: packet.sublist(6),
          packet: packet,
        ),
      );
    }

    return responses;
  }

  void reset() => _buffer.clear();
}

int _findCompleteKnownPacketStart(List<int> buffer) {
  for (var offset = 1; offset + 1 < buffer.length; offset++) {
    final header = buffer[offset];
    if (header != GoDirectProtocol.commandHeader &&
        header != GoDirectProtocol.responseHeader &&
        header != GoDirectProtocol.measurementResponse &&
        header != 0x5C) {
      continue;
    }
    final length = buffer[offset + 1];
    final minimum = header == GoDirectProtocol.measurementResponse ? 5 : 6;
    if (length >= minimum && offset + length <= buffer.length) return offset;
  }
  return -1;
}

bool goDirectResponseMatches(
  GoDirectResponse response, {
  required int? commandId,
  required int? counter,
}) {
  return !response.isMeasurement &&
      response.commandId == commandId &&
      response.counter == counter;
}

class GoDirectSerialQueue {
  Future<void> _tail = Future<void>.value();

  Future<T> enqueue<T>(FutureOr<T> Function() operation) {
    final result = _tail.then<T>((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}

List<int> parseSensorIds(List<int> payload) {
  final mask = parseSensorMask(payload);
  return [
    for (var sensorNumber = 0; sensorNumber < 32; sensorNumber++)
      if ((mask & (1 << sensorNumber)) != 0) sensorNumber,
  ];
}

int parseSensorMask(List<int> payload) {
  var mask = 0;
  final length = payload.length < 4 ? payload.length : 4;
  for (var index = 0; index < length; index++) {
    mask |= payload[index] << (index * 8);
  }
  return mask;
}

int parseDefaultSensorsMask(List<int> payload) => parseSensorMask(payload);

GoDirectSensorInfo? parseSensorInfo(List<int> payload) {
  if (payload.length >= 148) {
    return GoDirectSensorInfo(
      sensorNumber: payload[0],
      sensorId: _readUint32(payload, 2),
      description: _decodeCString(payload, 14, 60),
      units: _decodeCString(payload, 74, 32),
      minimumPeriodMs: _readUint32(payload, 124) / 1000.0,
      typicalPeriodMs: _readUint32(payload, 136) / 1000.0,
      mutualExclusionMask: _readUint32(payload, 144),
    );
  }

  if (payload.length < 3) return null;
  final sensorNumber = payload[0];
  final descEnd = _indexOf(payload, 0x00, 1);
  if (descEnd < 0) {
    return GoDirectSensorInfo(
      sensorNumber: sensorNumber,
      description: String.fromCharCodes(payload.sublist(1)),
      units: '',
    );
  }

  final description = String.fromCharCodes(payload.sublist(1, descEnd));
  final unitsStart = descEnd + 1;
  var unitsEnd = _indexOf(payload, 0x00, unitsStart);
  if (unitsEnd < 0) unitsEnd = payload.length;
  final units = String.fromCharCodes(payload.sublist(unitsStart, unitsEnd));

  final maskStart = unitsEnd + 1;
  final exclusionMask =
      maskStart + 4 <= payload.length ? _readUint32(payload, maskStart) : 0;

  return GoDirectSensorInfo(
    sensorNumber: sensorNumber,
    description: description,
    units: units,
    mutualExclusionMask: exclusionMask,
  );
}

Map<int, List<double>> parseMeasurementData(
  List<int> data,
  List<int> sensorNumbers,
) {
  final result = <int, List<double>>{
    for (final sensorNumber in sensorNumbers) sensorNumber: <double>[],
  };

  if (data.length < 8 || data[0] != GoDirectProtocol.measurementResponse) {
    return result;
  }

  final bytes = Uint8List.fromList(data);
  final byteData = ByteData.sublistView(bytes);
  final type = data[4];
  var valueCount = 0;
  var valueOffset = 0;
  var isFloat = true;
  late List<int> channels;

  switch (type) {
    case GoDirectMeasurementType.normalReal32:
      if (data.length < 9) return result;
      channels = _channelsForMask(
        byteData.getUint16(5, Endian.little),
        sensorNumbers,
        bitWidth: 16,
      );
      valueCount = data[7];
      valueOffset = 9;
      break;
    case GoDirectMeasurementType.wideReal32:
      if (data.length < 11) return result;
      channels = _channelsForMask(
        byteData.getUint32(5, Endian.little),
        sensorNumbers,
        bitWidth: 32,
      );
      valueCount = data[9];
      valueOffset = 11;
      break;
    case GoDirectMeasurementType.singleChannelReal32:
    case GoDirectMeasurementType.aperiodicReal32:
      channels = [data[6]];
      valueCount = data[7];
      valueOffset = 8;
      break;
    case GoDirectMeasurementType.singleChannelInt32:
    case GoDirectMeasurementType.aperiodicInt32:
      channels = [data[6]];
      valueCount = data[7];
      valueOffset = 8;
      isFloat = false;
      break;
    case GoDirectMeasurementType.startTime:
    case GoDirectMeasurementType.dropped:
    case GoDirectMeasurementType.period:
      return result;
    default:
      return result;
  }

  for (final channel in channels) {
    result.putIfAbsent(channel, () => <double>[]);
  }

  var offset = valueOffset;
  for (var count = 0; count < valueCount; count++) {
    for (final channel in channels) {
      if (offset + 4 > bytes.length) return result;
      final value =
          isFloat
              ? byteData.getFloat32(offset, Endian.little)
              : byteData.getInt32(offset, Endian.little).toDouble();
      result[channel]!.add(value);
      offset += 4;
    }
  }

  return result;
}

List<int> _channelsForMask(
  int sensorMask,
  List<int> sensorNumbers, {
  required int bitWidth,
}) {
  final channels =
      sensorNumbers
          .where((sensorNumber) => (sensorMask & (1 << sensorNumber)) != 0)
          .toList()
        ..sort();
  if (channels.isNotEmpty) return channels;

  if (sensorNumbers.length == 1 && sensorMask != 0) {
    return [sensorNumbers.first];
  }

  return [
    for (var sensorNumber = 0; sensorNumber < bitWidth; sensorNumber++)
      if ((sensorMask & (1 << sensorNumber)) != 0) sensorNumber,
  ];
}

String _decodeCString(List<int> payload, int start, int length) {
  final end = (start + length).clamp(0, payload.length).toInt();
  final bytes = payload.sublist(start, end);
  final nul = bytes.indexOf(0);
  final value = nul < 0 ? bytes : bytes.sublist(0, nul);
  return utf8.decode(value, allowMalformed: true).trim();
}

int _readUint32(List<int> payload, int offset) {
  if (offset < 0 || offset + 4 > payload.length) return 0;
  final bytes = Uint8List.fromList(payload.sublist(offset, offset + 4));
  return ByteData.sublistView(bytes).getUint32(0, Endian.little);
}

int _indexOf(List<int> list, int value, int start) {
  for (var index = start; index < list.length; index++) {
    if (list[index] == value) return index;
  }
  return -1;
}
