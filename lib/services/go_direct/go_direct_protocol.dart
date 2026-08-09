library;
import 'dart:typed_data';
import 'go_direct_constants.dart';

class GoDirectPacketBuilder {
  int _rollingCounter = 0;

  Uint8List buildCommand(int commandId, [List<int>? params]) {
    params ??= const [];
    _rollingCounter = (_rollingCounter + 1) & 0xFF;

    final body = <int>[_rollingCounter, commandId, ...params];
    final int length = body.length + 1;

    int sum = 0;
    for (final b in body) {
      sum += b;
    }
    final int checksum = (-sum) & 0xFF;

    return Uint8List.fromList([
      GoDirectProtocol.commandHeader,
      length,
      ...body,
      checksum,
    ]);
  }

  Uint8List buildInit() => buildCommand(GoDirectCommands.init);

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
    final bd = ByteData(4)..setUint32(0, periodUs, Endian.little);
    return buildCommand(
      GoDirectCommands.setMeasurementPeriod,
      bd.buffer.asUint8List().toList(),
    );
  }

  Uint8List buildStartMeasurements(int sensorMask) {
    final bd = ByteData(4)..setUint32(0, sensorMask, Endian.little);
    return buildCommand(
      GoDirectCommands.startMeasurements,
      bd.buffer.asUint8List().toList(),
    );
  }

  Uint8List buildStopMeasurements() =>
      buildCommand(GoDirectCommands.stopMeasurements);

  void reset() => _rollingCounter = 0;
}

class GoDirectResponse {
  final int commandId;
  final int counter;
  final List<int> payload;

  const GoDirectResponse({
    required this.commandId,
    required this.counter,
    required this.payload,
  });

  @override
  String toString() =>
      'Response(cmd=0x${commandId.toRadixString(16)}, '
      'counter=$counter, payload=${payload.length}B)';
}

class GoDirectResponseParser {
  final List<int> _buffer = [];

  List<GoDirectResponse> feed(List<int> data) {
    _buffer.addAll(data);
    final responses = <GoDirectResponse>[];

    while (_buffer.length >= 4) {
      if (_buffer[0] != GoDirectProtocol.responseHeader) {
        _buffer.removeAt(0);
        continue;
      }

      final int payloadLen = _buffer[1];
      final int totalLen = 2 + payloadLen;

      if (_buffer.length < totalLen) break;

      final packet = _buffer.sublist(0, totalLen);
      _buffer.removeRange(0, totalLen);

      if (totalLen < 5) continue;

      final int counter = packet[2];
      final int cmdId = packet[3];
      final List<int> payload =
          totalLen > 5 ? packet.sublist(4, totalLen - 1) : const [];

      int sum = 0;
      for (int i = 2; i < totalLen; i++) {
        sum += packet[i];
      }
      if ((sum & 0xFF) != 0) {
        continue;
      }

      responses.add(GoDirectResponse(
        commandId: cmdId,
        counter: counter,
        payload: payload,
      ));
    }

    return responses;
  }

  void reset() => _buffer.clear();
}

List<int> parseSensorIds(List<int> payload) {
  if (payload.isEmpty) return const [];

  if (payload.length > 1 && payload[0] == payload.length - 1) {
    return payload.sublist(1);
  }
  return List<int>.from(payload);
}

GoDirectSensorInfo? parseSensorInfo(List<int> payload) {
  if (payload.length < 3) return null;

  final int sensorNumber = payload[0];

  int descEnd = _indexOf(payload, 0x00, 1);
  if (descEnd < 0) {
    return GoDirectSensorInfo(
      sensorNumber: sensorNumber,
      description: String.fromCharCodes(payload.sublist(1)),
      units: '',
    );
  }
  final String description =
      String.fromCharCodes(payload.sublist(1, descEnd));

  String units = '';
  final int unitsStart = descEnd + 1;
  if (unitsStart < payload.length) {
    int unitsEnd = _indexOf(payload, 0x00, unitsStart);
    if (unitsEnd < 0) unitsEnd = payload.length;
    units = String.fromCharCodes(payload.sublist(unitsStart, unitsEnd));
  }

  int exclusionMask = 0;
  final int maskStart = descEnd + 1 + units.length + 1;
  if (maskStart + 4 <= payload.length) {
    exclusionMask = ByteData.view(
      Uint8List.fromList(payload.sublist(maskStart, maskStart + 4)).buffer,
    ).getUint32(0, Endian.little);
  }

  return GoDirectSensorInfo(
    sensorNumber: sensorNumber,
    description: description,
    units: units,
    mutualExclusionMask: exclusionMask,
  );
}

int parseDefaultSensorsMask(List<int> payload) {
  if (payload.length >= 4) {
    return ByteData.view(
      Uint8List.fromList(payload.sublist(0, 4)).buffer,
    ).getUint32(0, Endian.little);
  }
  if (payload.isNotEmpty) return payload[0];
  return 0;
}

Map<int, List<double>> parseMeasurementData(
  List<int> data,
  List<int> enabledSensorNumbers,
) {
  final result = <int, List<double>>{
    for (final sn in enabledSensorNumbers) sn: <double>[],
  };

  if (enabledSensorNumbers.isEmpty || data.length < 4) return result;

  final int bytesPerSample = enabledSensorNumbers.length * 4;
  final int nSamples = data.length ~/ bytesPerSample;
  if (nSamples == 0) return result;

  final bd = ByteData.view(Uint8List.fromList(data).buffer);

  for (int s = 0; s < nSamples; s++) {
    for (int si = 0; si < enabledSensorNumbers.length; si++) {
      final int offset = s * bytesPerSample + si * 4;
      if (offset + 4 <= data.length) {
        result[enabledSensorNumbers[si]]!
            .add(bd.getFloat32(offset, Endian.little));
      }
    }
  }
  return result;
}

int _indexOf(List<int> list, int value, int start) {
  for (int i = start; i < list.length; i++) {
    if (list[i] == value) return i;
  }
  return -1;
}