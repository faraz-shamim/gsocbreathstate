                                                  
  
                                                          
                                                                
                                        

import 'dart:typed_data';

                                                                     

class PolarPmdUuids {
  PolarPmdUuids._();

  static const String service = 'fb005c80-02e7-f387-1cad-8acd2d8df0c8';
  static const String controlPoint = 'fb005c81-02e7-f387-1cad-8acd2d8df0c8';
  static const String data = 'fb005c82-02e7-f387-1cad-8acd2d8df0c8';
}

                                                                     

enum PmdMeasurementType {
  ecg(0x00),
  ppg(0x01),
  acc(0x02),
  ppi(0x03),
  gyro(0x05),
  mag(0x06);

  final int value;
  const PmdMeasurementType(this.value);

  static PmdMeasurementType? fromByte(int byte) {
    for (final t in values) {
      if (t.value == byte) return t;
    }
    return null;
  }
}

class PmdAvailableMeasurements {
  PmdAvailableMeasurements._();

  static List<PmdMeasurementType> parse(List<int> data) {
    if (data.length < 2 || data[0] != 0x0F) {
      throw StateError('Invalid PMD measurement availability response');
    }

    final flags = data[1];
    final measurements = <PmdMeasurementType>[];
    for (final type in PmdMeasurementType.values) {
      if ((flags & (1 << type.value)) != 0) {
        measurements.add(type);
      }
    }
    return measurements;
  }
}

                                                                     

class PmdResponseCode {
  static const int success = 0x00;
  static const int invalidOpCode = 0x01;
  static const int invalidMeasurementType = 0x02;
  static const int notSupported = 0x03;
  static const int invalidLength = 0x04;
  static const int invalidParameter = 0x05;
  static const int alreadyInState = 0x06;
  static const int invalidResolution = 0x07;
  static const int invalidSampleRate = 0x08;
  static const int invalidRange = 0x09;
  static const int invalidMtu = 0x0A;
  static const int invalidNumberOfChannels = 0x0B;
  static const int invalidState = 0x0C;
  static const int deviceInCharger = 0x0D;
}

class PmdCommandBuilder {
  PmdCommandBuilder._();

                                            
  static Uint8List getSettings(PmdMeasurementType type) {
    return Uint8List.fromList([0x01, type.value]);
  }

                                     
                                                                   
     
                                            
                          
                         
                    
  static Uint8List startMeasurement(
    PmdMeasurementType type, {
    int sampleRate = 130,
    int resolution = 14,
    int? range,
    int? channels,
  }) {
    final srBytes = ByteData(2)..setUint16(0, sampleRate, Endian.little);
    final resBytes = ByteData(2)..setUint16(0, resolution, Endian.little);

    final command = <int>[
      0x02,             
      type.value,
                          
      0x00,                              
      0x01,                    
      srBytes.getUint8(0),
      srBytes.getUint8(1),
                         
      0x01,                                                 
      0x01,                    
      resBytes.getUint8(0),
      resBytes.getUint8(1),
    ];

    if (range != null) {
      final rangeBytes = ByteData(2)..setUint16(0, range, Endian.little);
      command.addAll([
        0x02,
        0x01,
        rangeBytes.getUint8(0),
        rangeBytes.getUint8(1),
      ]);
    }

    if (channels != null) {
      command.addAll([0x04, 0x01, channels & 0xFF]);
    }

    return Uint8List.fromList(command);
  }

                                                                        
                                                        
  static Uint8List startAccMeasurement({
    int sampleRate = 200,
    int resolution = 16,
    int range = 2,
  }) {
    return startMeasurement(
      PmdMeasurementType.acc,
      sampleRate: sampleRate,
      resolution: resolution,
      range: range,
    );
  }

                                    
  static Uint8List stopMeasurement(PmdMeasurementType type) {
    return Uint8List.fromList([0x03, type.value]);
  }
}

                                                                     

class PmdControlPointResponse {
  final int opCode;
  final PmdMeasurementType? measurementType;
  final int errorCode;
  final String errorMessage;
  final List<int> parameters;

  PmdControlPointResponse({
    required this.opCode,
    this.measurementType,
    required this.errorCode,
    required this.errorMessage,
    required this.parameters,
  });

  bool get isSuccess => errorCode == PmdResponseCode.success;

  static PmdControlPointResponse parse(List<int> data) {
    if (data.length < 4 || data[0] != 0xF0) {
      return PmdControlPointResponse(
        opCode: 0,
        errorCode: -1,
        errorMessage: 'Invalid response format',
        parameters: data,
      );
    }

    final opCode = data[1];
    final measType = PmdMeasurementType.fromByte(data[2]);
    final errCode = data[3];
    final params = data.length > 4 ? data.sublist(4) : <int>[];

    return PmdControlPointResponse(
      opCode: opCode,
      measurementType: measType,
      errorCode: errCode,
      errorMessage: _errorMessage(errCode),
      parameters: params,
    );
  }

  static String _errorMessage(int code) {
    switch (code) {
      case PmdResponseCode.success:
        return 'Success';
      case PmdResponseCode.invalidOpCode:
        return 'Invalid op code';
      case PmdResponseCode.invalidMeasurementType:
        return 'Invalid measurement type';
      case PmdResponseCode.notSupported:
        return 'Not supported';
      case PmdResponseCode.invalidLength:
        return 'Invalid length';
      case PmdResponseCode.invalidParameter:
        return 'Invalid parameter';
      case PmdResponseCode.alreadyInState:
        return 'Already in state';
      case PmdResponseCode.invalidResolution:
        return 'Invalid resolution';
      case PmdResponseCode.invalidSampleRate:
        return 'Invalid sample rate';
      case PmdResponseCode.invalidRange:
        return 'Invalid range';
      default:
        return 'Error code $code';
    }
  }
}

                                                                     

class PmdAvailableSettings {
  final Map<String, List<int>> settings;

  PmdAvailableSettings(this.settings);

  static PmdAvailableSettings parse(List<int> params) {
    final result = <String, List<int>>{};
    int offset = 0;

    while (offset < params.length) {
      if (offset + 2 > params.length) break;

      final settingType = params[offset];
      final arrayLen = params[offset + 1];
      offset += 2;

      final values = <int>[];
      for (int i = 0; i < arrayLen; i++) {
        if (offset + 2 > params.length) break;
        final val = params[offset] | (params[offset + 1] << 8);
        values.add(val);
        offset += 2;
      }

      result[_settingName(settingType)] = values;
    }

    return PmdAvailableSettings(result);
  }

  static String _settingName(int type) {
    switch (type) {
      case 0x00:
        return 'SAMPLE_RATE';
      case 0x01:
        return 'RESOLUTION';
      case 0x02:
        return 'RANGE';
      case 0x03:
        return 'RANGE_MILLIUNIT';
      case 0x04:
        return 'CHANNELS';
      case 0x05:
        return 'FACTOR';
      default:
        return 'UNKNOWN_$type';
    }
  }

  @override
  String toString() => settings.toString();
}

                                                                     

class PolarEcgFrame {
                                                            
  final int timestampNs;

                                     
  final List<double> samplesUv;

  PolarEcgFrame({required this.timestampNs, required this.samplesUv});
}

class PolarAccSample {
  final int xMg;
  final int yMg;
  final int zMg;

  const PolarAccSample({
    required this.xMg,
    required this.yMg,
    required this.zMg,
  });
}

class PolarAccFrame {
                                                            
  final int timestampNs;

                                       
  final List<PolarAccSample> samples;

  const PolarAccFrame({required this.timestampNs, required this.samples});
}

class PmdDataParser {
  PmdDataParser._();

                                                      
                                               
  static PolarEcgFrame? parseEcgNotification(List<int> data) {
                                                                          
    if (data.length < 13) return null;

    final measurementType = PmdMeasurementType.fromByte(data[0]);
    if (measurementType != PmdMeasurementType.ecg) return null;

                                                         
                                                                 
                                                                  
                                                               
    final timestampNs = _parseTimestampNs(data);

                                  
                                                                   
                                                                    

                                 
    final samplesData = data.sublist(10);
    final samples = _parse3ByteSamples(samplesData);

    return PolarEcgFrame(timestampNs: timestampNs, samplesUv: samples);
  }

                                                     
                                                                    
                                               
  static PolarAccFrame? parseAccNotification(List<int> data) {
                                                                     
    if (data.length < 16) return null;

    final measurementType = PmdMeasurementType.fromByte(data[0]);
    if (measurementType != PmdMeasurementType.acc) return null;

                                                                    
                                               
    if (data[9] != 0x01) return null;

    final samplesData = data.sublist(10);
    if (samplesData.length % 6 != 0) return null;

    final samples = <PolarAccSample>[];
    for (int i = 0; i + 5 < samplesData.length; i += 6) {
      samples.add(
        PolarAccSample(
          xMg: _parseInt16Le(samplesData, i),
          yMg: _parseInt16Le(samplesData, i + 2),
          zMg: _parseInt16Le(samplesData, i + 4),
        ),
      );
    }
    if (samples.isEmpty) return null;

    return PolarAccFrame(
      timestampNs: _parseTimestampNs(data),
      samples: samples,
    );
  }

  static int _parseTimestampNs(List<int> data) {
                                                                 
                                                                 
                                                               
    final bd = ByteData.view(Uint8List.fromList(data).buffer);
    final lo = bd.getUint32(1, Endian.little);
    final hi = bd.getUint32(5, Endian.little);
    return hi * 0x100000000 + lo;
  }

  static int _parseInt16Le(List<int> data, int offset) {
    var raw = data[offset] | (data[offset + 1] << 8);
    if (raw >= 0x8000) raw -= 0x10000;
    return raw;
  }

  static List<double> _parse3ByteSamples(List<int> data) {
    final samples = <double>[];
    for (int i = 0; i + 2 < data.length; i += 3) {
      int raw = data[i] | (data[i + 1] << 8) | (data[i + 2] << 16);
                                       
                                                                 
      if (raw >= 0x800000) {
        raw -= 0x1000000;
      }
      samples.add(raw.toDouble());
    }
    return samples;
  }
}
