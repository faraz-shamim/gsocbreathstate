// SPDX-License-Identifier: AGPL-3.0-only
import 'fisher_lehrer_protocol.dart';

enum RfAcquisitionMode { measured, estimated }

enum RfResultStatus { completed, invalid }

enum RfExtremumKind { maximum, minimum }

enum RfQualityFlag {
  protocolIncomplete,
  insufficientRr,
  invalidRr,
  insufficientExtrema,
  analysisWindowUnavailable,
  respirationMissing,
  respirationCoverageLow,
  respirationGap,
  respirationFlat,
  respirationFitFailed,
  respirationOutOfRange,
  nonAdherent,
  rrGap,
}

class RfBeatSample {
  final double elapsedMs;
  final double rrMs;
  final double? notificationElapsedMs;

  const RfBeatSample({
    required this.elapsedMs,
    required this.rrMs,
    this.notificationElapsedMs,
  });

  Map<String, Object?> toJson() => {
    'elapsedMs': elapsedMs,
    'rrMs': rrMs,
    'notificationElapsedMs': notificationElapsedMs,
  };

  factory RfBeatSample.fromJson(Map<String, Object?> json) => RfBeatSample(
    elapsedMs: (json['elapsedMs'] as num).toDouble(),
    rrMs: (json['rrMs'] as num).toDouble(),
    notificationElapsedMs: (json['notificationElapsedMs'] as num?)?.toDouble(),
  );
}

class RfRespirationSample {
  final double elapsedMs;
  final double value;
  final int sensorNumber;

  const RfRespirationSample({
    required this.elapsedMs,
    required this.value,
    this.sensorNumber = 1,
  });

  Map<String, Object> toJson() => {
    'elapsedMs': elapsedMs,
    'value': value,
    'sensorNumber': sensorNumber,
  };

  factory RfRespirationSample.fromJson(Map<String, Object?> json) =>
      RfRespirationSample(
        elapsedMs: (json['elapsedMs'] as num).toDouble(),
        value: (json['value'] as num).toDouble(),
        sensorNumber: (json['sensorNumber'] as num?)?.toInt() ?? 1,
      );
}

class RfAssessmentInput {
  final FisherLehrerProtocolConfig protocol;
  final List<RfBeatSample> rrSamples;
  final List<RfRespirationSample> respirationSamples;
  final RfAcquisitionMode mode;
  final int completedCycles;

  RfAssessmentInput({
    this.protocol = const FisherLehrerProtocolConfig(),
    required this.rrSamples,
    this.respirationSamples = const [],
    required this.mode,
    int? completedCycles,
  }) : completedCycles = completedCycles ?? protocol.cycleCount;

  Map<String, Object> toJson() => {
    'protocol': protocol.toJson(),
    'rrSamples': rrSamples.map((sample) => sample.toJson()).toList(),
    'respirationSamples':
        respirationSamples.map((sample) => sample.toJson()).toList(),
    'mode': mode.name,
    'completedCycles': completedCycles,
  };

  factory RfAssessmentInput.fromJson(Map<String, Object?> json) {
    final protocol = FisherLehrerProtocolConfig.fromJson(
      Map<String, Object?>.from(json['protocol']! as Map),
    );
    return RfAssessmentInput(
      protocol: protocol,
      rrSamples:
          (json['rrSamples']! as List)
              .map(
                (value) => RfBeatSample.fromJson(
                  Map<String, Object?>.from(value as Map),
                ),
              )
              .toList(),
      respirationSamples:
          ((json['respirationSamples'] as List?) ?? const [])
              .map(
                (value) => RfRespirationSample.fromJson(
                  Map<String, Object?>.from(value as Map),
                ),
              )
              .toList(),
      mode: RfAcquisitionMode.values.byName(json['mode']! as String),
      completedCycles:
          (json['completedCycles'] as num?)?.toInt() ?? protocol.cycleCount,
    );
  }
}

class RfTimedValue {
  final double elapsedMs;
  final double value;

  const RfTimedValue(this.elapsedMs, this.value);

  Map<String, Object> toJson() => {'elapsedMs': elapsedMs, 'value': value};

  factory RfTimedValue.fromJson(Map<String, Object?> json) => RfTimedValue(
    (json['elapsedMs'] as num).toDouble(),
    (json['value'] as num).toDouble(),
  );
}

class RfExtremum {
  final double elapsedMs;
  final double value;
  final RfExtremumKind kind;

  const RfExtremum({
    required this.elapsedMs,
    required this.value,
    required this.kind,
  });

  Map<String, Object> toJson() => {
    'elapsedMs': elapsedMs,
    'value': value,
    'kind': kind.name,
  };

  factory RfExtremum.fromJson(Map<String, Object?> json) => RfExtremum(
    elapsedMs: (json['elapsedMs'] as num).toDouble(),
    value: (json['value'] as num).toDouble(),
    kind: RfExtremumKind.values.byName(json['kind']! as String),
  );
}

class RfEctopicCorrection {
  final int firstIntervalIndex;
  final int secondIntervalIndex;
  final double originalFirstMs;
  final double originalSecondMs;
  final double correctedFirstMs;
  final double correctedSecondMs;

  const RfEctopicCorrection({
    required this.firstIntervalIndex,
    required this.secondIntervalIndex,
    required this.originalFirstMs,
    required this.originalSecondMs,
    required this.correctedFirstMs,
    required this.correctedSecondMs,
  });

  Map<String, Object> toJson() => {
    'firstIntervalIndex': firstIntervalIndex,
    'secondIntervalIndex': secondIntervalIndex,
    'originalFirstMs': originalFirstMs,
    'originalSecondMs': originalSecondMs,
    'correctedFirstMs': correctedFirstMs,
    'correctedSecondMs': correctedSecondMs,
  };

  factory RfEctopicCorrection.fromJson(Map<String, Object?> json) =>
      RfEctopicCorrection(
        firstIntervalIndex: (json['firstIntervalIndex'] as num).toInt(),
        secondIntervalIndex: (json['secondIntervalIndex'] as num).toInt(),
        originalFirstMs: (json['originalFirstMs'] as num).toDouble(),
        originalSecondMs: (json['originalSecondMs'] as num).toDouble(),
        correctedFirstMs: (json['correctedFirstMs'] as num).toDouble(),
        correctedSecondMs: (json['correctedSecondMs'] as num).toDouble(),
      );
}

class RfSineFit {
  final double bpm;
  final double phase;
  final double omegaRadiansPerSample;
  final double amplitude;
  final double offset;
  final double meanAbsoluteError;
  final bool converged;
  final List<RfTimedValue> fittedWave;

  const RfSineFit({
    required this.bpm,
    required this.phase,
    required this.omegaRadiansPerSample,
    required this.amplitude,
    required this.offset,
    required this.meanAbsoluteError,
    required this.converged,
    required this.fittedWave,
  });

  Map<String, Object> toJson() => {
    'bpm': bpm,
    'phase': phase,
    'omegaRadiansPerSample': omegaRadiansPerSample,
    'amplitude': amplitude,
    'offset': offset,
    'meanAbsoluteError': meanAbsoluteError,
    'converged': converged,
    'fittedWave': fittedWave.map((point) => point.toJson()).toList(),
  };
}

class RfQualityReport {
  final bool protocolCompleted;
  final bool fullAnalysisWindowAvailable;
  final bool rrContinuityPassed;
  final bool beltCoveragePassed;
  final bool respirationFitConverged;
  final bool breathingAdherencePassed;
  final double beltCoverage;
  final double maximumObservedBeltGapMs;
  final double maximumObservedRrGapMs;
  final int ectopicCorrections;
  final List<RfQualityFlag> flags;

  const RfQualityReport({
    required this.protocolCompleted,
    required this.fullAnalysisWindowAvailable,
    required this.rrContinuityPassed,
    required this.beltCoveragePassed,
    required this.respirationFitConverged,
    required this.breathingAdherencePassed,
    required this.beltCoverage,
    required this.maximumObservedBeltGapMs,
    required this.maximumObservedRrGapMs,
    required this.ectopicCorrections,
    required this.flags,
  });

  bool get passed => flags.isEmpty;

  Map<String, Object> toJson() => {
    'protocolCompleted': protocolCompleted,
    'fullAnalysisWindowAvailable': fullAnalysisWindowAvailable,
    'rrContinuityPassed': rrContinuityPassed,
    'beltCoveragePassed': beltCoveragePassed,
    'respirationFitConverged': respirationFitConverged,
    'breathingAdherencePassed': breathingAdherencePassed,
    'beltCoverage': beltCoverage,
    'maximumObservedBeltGapMs': maximumObservedBeltGapMs,
    'maximumObservedRrGapMs': maximumObservedRrGapMs,
    'ectopicCorrections': ectopicCorrections,
    'flags': flags.map((flag) => flag.name).toList(),
  };

  factory RfQualityReport.fromJson(
    Map<String, Object?> json,
  ) => RfQualityReport(
    protocolCompleted: json['protocolCompleted']! as bool,
    fullAnalysisWindowAvailable: json['fullAnalysisWindowAvailable']! as bool,
    rrContinuityPassed: json['rrContinuityPassed']! as bool,
    beltCoveragePassed: json['beltCoveragePassed']! as bool,
    respirationFitConverged: json['respirationFitConverged']! as bool,
    breathingAdherencePassed: json['breathingAdherencePassed']! as bool,
    beltCoverage: (json['beltCoverage'] as num).toDouble(),
    maximumObservedBeltGapMs:
        (json['maximumObservedBeltGapMs'] as num).toDouble(),
    maximumObservedRrGapMs: (json['maximumObservedRrGapMs'] as num).toDouble(),
    ectopicCorrections: (json['ectopicCorrections'] as num).toInt(),
    flags:
        (json['flags']! as List)
            .cast<String>()
            .map(RfQualityFlag.values.byName)
            .toList(),
  );
}

class RfAnalysisTrace {
  final List<RfTimedValue> originalRr;
  final List<RfTimedValue> correctedRr;
  final List<RfTimedValue> ibiBaseline;
  final List<RfTimedValue> detrendedIbi;
  final List<RfExtremum> extrema;
  final List<RfTimedValue> peakToTrough;
  final List<RfTimedValue> smoothedPeakToTrough;
  final List<RfTimedValue> respirationWindow;
  final List<RfTimedValue> fittedRespiration;
  final List<RfEctopicCorrection> ectopicCorrections;

  const RfAnalysisTrace({
    this.originalRr = const [],
    this.correctedRr = const [],
    this.ibiBaseline = const [],
    this.detrendedIbi = const [],
    this.extrema = const [],
    this.peakToTrough = const [],
    this.smoothedPeakToTrough = const [],
    this.respirationWindow = const [],
    this.fittedRespiration = const [],
    this.ectopicCorrections = const [],
  });

  Map<String, Object> toJson() => {
    'originalRr': originalRr.map((point) => point.toJson()).toList(),
    'correctedRr': correctedRr.map((point) => point.toJson()).toList(),
    'ibiBaseline': ibiBaseline.map((point) => point.toJson()).toList(),
    'detrendedIbi': detrendedIbi.map((point) => point.toJson()).toList(),
    'extrema': extrema.map((point) => point.toJson()).toList(),
    'peakToTrough': peakToTrough.map((point) => point.toJson()).toList(),
    'smoothedPeakToTrough':
        smoothedPeakToTrough.map((point) => point.toJson()).toList(),
    'respirationWindow':
        respirationWindow.map((point) => point.toJson()).toList(),
    'fittedRespiration':
        fittedRespiration.map((point) => point.toJson()).toList(),
    'ectopicCorrections':
        ectopicCorrections.map((correction) => correction.toJson()).toList(),
  };

  factory RfAnalysisTrace.fromJson(Map<String, Object?> json) {
    List<RfTimedValue> timedValues(String key) =>
        ((json[key] as List?) ?? const [])
            .map(
              (value) => RfTimedValue.fromJson(
                Map<String, Object?>.from(value as Map),
              ),
            )
            .toList();

    return RfAnalysisTrace(
      originalRr: timedValues('originalRr'),
      correctedRr: timedValues('correctedRr'),
      ibiBaseline: timedValues('ibiBaseline'),
      detrendedIbi: timedValues('detrendedIbi'),
      extrema:
          ((json['extrema'] as List?) ?? const [])
              .map(
                (value) => RfExtremum.fromJson(
                  Map<String, Object?>.from(value as Map),
                ),
              )
              .toList(),
      peakToTrough: timedValues('peakToTrough'),
      smoothedPeakToTrough: timedValues('smoothedPeakToTrough'),
      respirationWindow: timedValues('respirationWindow'),
      fittedRespiration: timedValues('fittedRespiration'),
      ectopicCorrections:
          ((json['ectopicCorrections'] as List?) ?? const [])
              .map(
                (value) => RfEctopicCorrection.fromJson(
                  Map<String, Object?>.from(value as Map),
                ),
              )
              .toList(),
    );
  }
}

class RfAssessmentResult {
  final String protocolVersion;
  final RfAcquisitionMode mode;
  final RfResultStatus status;
  final double? rfBpm;
  final double? rfCenterElapsedMs;
  final double? peakToTroughAmplitude;
  final double? scheduledBpmAtCenter;
  final double? fittedRespirationBpm;
  final double? adherenceDeltaBpm;
  final double? respirationFitError;
  final RfQualityReport quality;
  final RfAnalysisTrace trace;

  const RfAssessmentResult({
    required this.protocolVersion,
    required this.mode,
    required this.status,
    required this.rfBpm,
    required this.rfCenterElapsedMs,
    required this.peakToTroughAmplitude,
    required this.scheduledBpmAtCenter,
    required this.fittedRespirationBpm,
    required this.adherenceDeltaBpm,
    required this.respirationFitError,
    required this.quality,
    required this.trace,
  });

  double? get rfHz => rfBpm == null ? null : rfBpm! / 60;
  double? get rfPeriodMs => rfBpm == null ? null : 60000 / rfBpm!;

  Map<String, Object?> toJson() => {
    'protocolVersion': protocolVersion,
    'mode': mode.name,
    'status': status.name,
    'rfBpm': rfBpm,
    'rfHz': rfHz,
    'rfPeriodMs': rfPeriodMs,
    'rfCenterElapsedMs': rfCenterElapsedMs,
    'peakToTroughAmplitude': peakToTroughAmplitude,
    'scheduledBpmAtCenter': scheduledBpmAtCenter,
    'fittedRespirationBpm': fittedRespirationBpm,
    'adherenceDeltaBpm': adherenceDeltaBpm,
    'respirationFitError': respirationFitError,
    'quality': quality.toJson(),
    'trace': trace.toJson(),
  };

  factory RfAssessmentResult.fromJson(
    Map<String, Object?> json,
  ) => RfAssessmentResult(
    protocolVersion: json['protocolVersion']! as String,
    mode: RfAcquisitionMode.values.byName(json['mode']! as String),
    status: RfResultStatus.values.byName(json['status']! as String),
    rfBpm: (json['rfBpm'] as num?)?.toDouble(),
    rfCenterElapsedMs: (json['rfCenterElapsedMs'] as num?)?.toDouble(),
    peakToTroughAmplitude: (json['peakToTroughAmplitude'] as num?)?.toDouble(),
    scheduledBpmAtCenter: (json['scheduledBpmAtCenter'] as num?)?.toDouble(),
    fittedRespirationBpm: (json['fittedRespirationBpm'] as num?)?.toDouble(),
    adherenceDeltaBpm: (json['adherenceDeltaBpm'] as num?)?.toDouble(),
    respirationFitError: (json['respirationFitError'] as num?)?.toDouble(),
    quality: RfQualityReport.fromJson(
      Map<String, Object?>.from(json['quality']! as Map),
    ),
    trace: RfAnalysisTrace.fromJson(
      Map<String, Object?>.from(json['trace']! as Map),
    ),
  );
}
