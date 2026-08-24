// SPDX-License-Identifier: AGPL-3.0-only
                                                              
                                             
   
             
                                                              
                                                                  
                                           
                                                                
                                                                    
   
               
                                                                  
                                                         
                                                                 
                                                               
                       
                                                                   
                                                                    
                
library;

import 'dart:math' as math;

                                                                      
                
                                                                      

                                                         
enum IndexLevel {
  low,
  moderate,
  high,
  veryHigh,
  unknown,
}

                                                                  
                          
class PsychophysiologicalIndex {
                                                
  final String name;

                     
  final double? value;

                                                         
  final String unit;

                                                       
  final IndexLevel level;

                                                              
                                 
  final String interpretation;

                                                    
  final String description;

  const PsychophysiologicalIndex({
    required this.name,
    required this.value,
    required this.unit,
    required this.level,
    required this.interpretation,
    required this.description,
  });
}

                                                               
class PsychophysiologicalResult {
                                                                

                                     
     
                                 
     
                                                                     
                                                       
                                                                
     
                                 
                                               
                                   
                                
                            
                               
  final PsychophysiologicalIndex stressIndex;

                                         
     
                                      
                                       
                         
                                     
                                            
  final PsychophysiologicalIndex autonomicBalance;

                                          
     
                                                             
                                                          
     
                                           
                       
                                          
  final PsychophysiologicalIndex parasympatheticTone;

                                  
     
                                                                    
                            
     
              
                                      
                                       
                                               
                                         
  final PsychophysiologicalIndex relaxationScore;

                                                                
                                                             
  final double? mo;

                                                                
                
  final double? amo;

                                                               
  final double? mxdmn;

                                                                
                                                              
  final double? meanHeartRateBpm;

                                               
  final double? rmssd;

                                                            
  final double? hfPower;

                                             
  final double? lfHfRatio;

                                        
  final String? warning;

  const PsychophysiologicalResult({
    required this.stressIndex,
    required this.autonomicBalance,
    required this.parasympatheticTone,
    required this.relaxationScore,
    this.mo,
    this.amo,
    this.mxdmn,
    this.meanHeartRateBpm,
    this.rmssd,
    this.hfPower,
    this.lfHfRatio,
    this.warning,
  });

                                                                

                                                   
  Map<String, String> essentials() {
    return {
      'Stress Index': stressIndex.value != null
          ? stressIndex.value!.toStringAsFixed(0)
          : 'N/A',
      'Autonomic Balance': autonomicBalance.value != null
          ? autonomicBalance.value!.toStringAsFixed(2)
          : 'N/A',
      'Parasympathetic': parasympatheticTone.value != null
          ? '${parasympatheticTone.value!.toStringAsFixed(0)}/100'
          : 'N/A',
      'Relaxation': relaxationScore.value != null
          ? '${relaxationScore.value!.toStringAsFixed(0)}/100'
          : 'N/A',
    };
  }

                                                
  Map<String, List<({String label, double? value, String unit})>>
      allMetrics() {
    return {
      'Stress Assessment': [
        (
          label: 'Baevsky SI',
          value: stressIndex.value,
          unit: '',
        ),
        (label: 'Mode (Mo)', value: mo, unit: 'ms'),
        (label: 'AMo', value: amo, unit: '%'),
        (label: 'MxDMn', value: mxdmn, unit: 'ms'),
      ],
      'Autonomic Balance': [
        (
          label: 'LF/HF Ratio',
          value: autonomicBalance.value,
          unit: '',
        ),
      ],
      'Parasympathetic Activity': [
        (
          label: 'Para. Tone Score',
          value: parasympatheticTone.value,
          unit: '/100',
        ),
        (label: 'RMSSD', value: rmssd, unit: 'ms'),
        (label: 'HF Power', value: hfPower, unit: 'ms²'),
      ],
      'Relaxation': [
        (
          label: 'Relaxation Score',
          value: relaxationScore.value,
          unit: '/100',
        ),
        (
          label: 'Mean HR',
          value: meanHeartRateBpm,
          unit: 'BPM',
        ),
      ],
    };
  }

                              
  Map<String, double?> toExportMap() {
    return {
      'PSY_Baevsky_SI': stressIndex.value,
      'PSY_Baevsky_Mo': mo,
      'PSY_Baevsky_AMo': amo,
      'PSY_Baevsky_MxDMn': mxdmn,
      'PSY_Autonomic_Balance_LFHF': autonomicBalance.value,
      'PSY_Parasympathetic_Tone': parasympatheticTone.value,
      'PSY_Relaxation_Score': relaxationScore.value,
      'PSY_RMSSD': rmssd,
      'PSY_HF_Power': hfPower,
      'PSY_Mean_HR_BPM': meanHeartRateBpm,
    };
  }

                                                                  
  List<PsychophysiologicalIndex> get allIndices => [
        stressIndex,
        autonomicBalance,
        parasympatheticTone,
        relaxationScore,
      ];
}

                                                                      
            
                                                                      

                                                   
   
                                         
           
                                                       
                                 
                                    
                                      
      
       
   
                                             
           
                                                       
                                 
                                    
                                      
                                           
                                      
      
       
class PsychophysiologicalAnalyzer {
  PsychophysiologicalAnalyzer._();

                                                                
                                                          
  static const double _histogramBinWidthMs = 50.0;

                                                             
                                                              
                                        
  static const double _rmssdNormLow = 15.0;
  static const double _rmssdNormHigh = 80.0;

                                                      
  static const double _hfLogNormLow = 2.0;              
  static const double _hfLogNormHigh = 8.0;                 

                                              
     
                                                                   
                                
                                                     
                                                                     
                                                               
                                                              
                                                              
                                                         
  static PsychophysiologicalResult compute({
    required List<double> rrIntervalsMs,
    required double rmssd,
    required double meanNN,
    double? hfPower,
    double? lfHfRatio,
  }) {
    final warnings = <String>[];

    if (rrIntervalsMs.length < 10) {
      return PsychophysiologicalResult(
        stressIndex: _unavailable('Baevsky SI',
            'Reflects overall cardiac stress from RR distribution'),
        autonomicBalance: _unavailable('Autonomic Balance',
            'Sympatho-vagal balance from LF/HF ratio'),
        parasympatheticTone: _unavailable('Parasympathetic Tone',
            'Vagal activity from RMSSD and HF power'),
        relaxationScore: _unavailable('Relaxation Score',
            'Composite wellness score (0–100)'),
        warning: 'Too few RR intervals (${rrIntervalsMs.length}, '
            'need ≥ 10).',
      );
    }

                                                                
                               
                                                                
    final baevsky = _computeBaevskySI(rrIntervalsMs);

    final PsychophysiologicalIndex stressIdx;
    if (baevsky.si != null && baevsky.si!.isFinite) {
      final double si = baevsky.si!;
      final IndexLevel level;
      final String interp;
      if (si < 50) {
        level = IndexLevel.low;
        interp = 'Very low stress / high vagal tone';
      } else if (si < 150) {
        level = IndexLevel.low;
        interp = 'Normal — low stress';
      } else if (si < 500) {
        level = IndexLevel.moderate;
        interp = 'Moderate stress';
      } else if (si < 900) {
        level = IndexLevel.high;
        interp = 'High stress';
      } else {
        level = IndexLevel.veryHigh;
        interp = 'Very high stress';
      }
      stressIdx = PsychophysiologicalIndex(
        name: 'Baevsky Stress Index',
        value: si,
        unit: '',
        level: level,
        interpretation: interp,
        description:
            'SI = AMo / (2 × Mo × MxDMn). '
            'Reflects tension in cardiovascular regulation.',
      );
    } else {
      stressIdx = _unavailable('Baevsky SI',
          'Reflects overall cardiac stress from RR distribution');
      warnings.add('Baevsky SI could not be computed '
          '(MxDMn or Mo is zero).');
    }

                                                                
                                    
                                                                
    final PsychophysiologicalIndex autonomicIdx;
    if (lfHfRatio != null && lfHfRatio.isFinite) {
      final IndexLevel level;
      final String interp;
      if (lfHfRatio < 0.5) {
        level = IndexLevel.low;
        interp = 'Parasympathetic dominant';
      } else if (lfHfRatio < 2.0) {
        level = IndexLevel.moderate;
        interp = 'Balanced autonomic activity';
      } else if (lfHfRatio < 5.0) {
        level = IndexLevel.high;
        interp = 'Sympathetic dominant';
      } else {
        level = IndexLevel.veryHigh;
        interp = 'Strong sympathetic activation';
      }
      autonomicIdx = PsychophysiologicalIndex(
        name: 'Autonomic Balance',
        value: lfHfRatio,
        unit: '',
        level: level,
        interpretation: interp,
        description:
            'LF/HF ratio. Lower = more parasympathetic; '
            'higher = more sympathetic.',
      );
    } else {
      autonomicIdx = PsychophysiologicalIndex(
        name: 'Autonomic Balance',
        value: null,
        unit: '',
        level: IndexLevel.unknown,
        interpretation: 'Unavailable — frequency-domain '
            'analysis required',
        description:
            'LF/HF ratio from frequency-domain HRV.',
      );
      if (lfHfRatio == null) {
        warnings.add('LF/HF ratio not provided — '
            'autonomic balance unavailable.');
      }
    }

                                                                
                                                      
                                                                
    final double rmssdScore = _normalise(
      rmssd,
      _rmssdNormLow,
      _rmssdNormHigh,
    );

    double paraScore;
    if (hfPower != null && hfPower > 0 && hfPower.isFinite) {
      final double hfLog = math.log(hfPower);
      final double hfScore = _normalise(
        hfLog,
        _hfLogNormLow,
        _hfLogNormHigh,
      );
                                                 
                                                           
                                                 
      paraScore = (0.6 * rmssdScore + 0.4 * hfScore) * 100;
    } else {
                                          
      paraScore = rmssdScore * 100;
      if (hfPower == null) {
        warnings.add('HF power not provided — parasympathetic '
            'tone uses RMSSD only.');
      }
    }
    paraScore = paraScore.clamp(0, 100);

    final IndexLevel paraLevel;
    final String paraInterp;
    if (paraScore > 70) {
      paraLevel = IndexLevel.high;
      paraInterp = 'High parasympathetic activity';
    } else if (paraScore > 40) {
      paraLevel = IndexLevel.moderate;
      paraInterp = 'Moderate parasympathetic activity';
    } else {
      paraLevel = IndexLevel.low;
      paraInterp = 'Low parasympathetic activity';
    }

    final parasympatheticIdx = PsychophysiologicalIndex(
      name: 'Parasympathetic Tone',
      value: paraScore,
      unit: '/100',
      level: paraLevel,
      interpretation: paraInterp,
      description:
          'Composite score from RMSSD and HF power. '
          'Higher = stronger vagal influence.',
    );

                                                                
                                             
                                                                
    final double meanHR = meanNN > 0 ? 60000.0 / meanNN : 75.0;

                                                            
                                                 
    double stressComponent = 100;
    if (baevsky.si != null && baevsky.si!.isFinite) {
      stressComponent =
          (100.0 - (baevsky.si! / 10.0)).clamp(0, 100);
    }

                                                   
    double balanceComponent = 50;
    if (lfHfRatio != null && lfHfRatio.isFinite && lfHfRatio > 0) {
                                                            
                                                     
      final double logDeviation = math.log(lfHfRatio).abs();
      balanceComponent =
          (100.0 * math.exp(-logDeviation)).clamp(0, 100);
    }

                                            
    final double paraComponent = paraScore;

                                                            
                                        
    final double hrComponent =
        ((100 - meanHR) / 60.0 * 100.0).clamp(0, 100);

                         
    final double relaxation = (0.35 * stressComponent +
            0.25 * balanceComponent +
            0.25 * paraComponent +
            0.15 * hrComponent)
        .clamp(0, 100);

    final IndexLevel relaxLevel;
    final String relaxInterp;
    if (relaxation > 75) {
      relaxLevel = IndexLevel.high;
      relaxInterp = 'Deeply relaxed';
    } else if (relaxation > 55) {
      relaxLevel = IndexLevel.moderate;
      relaxInterp = 'Moderately relaxed';
    } else if (relaxation > 35) {
      relaxLevel = IndexLevel.moderate;
      relaxInterp = 'Mild tension';
    } else {
      relaxLevel = IndexLevel.low;
      relaxInterp = 'Elevated stress / tension';
    }

    final relaxationIdx = PsychophysiologicalIndex(
      name: 'Relaxation Score',
      value: relaxation,
      unit: '/100',
      level: relaxLevel,
      interpretation: relaxInterp,
      description:
          'Composite score integrating stress index, autonomic '
          'balance, parasympathetic tone, and heart rate. '
          'Higher = more relaxed.',
    );

    return PsychophysiologicalResult(
      stressIndex: stressIdx,
      autonomicBalance: autonomicIdx,
      parasympatheticTone: parasympatheticIdx,
      relaxationScore: relaxationIdx,
      mo: baevsky.mo,
      amo: baevsky.amo,
      mxdmn: baevsky.mxdmn,
      meanHeartRateBpm: meanHR,
      rmssd: rmssd,
      hfPower: hfPower,
      lfHfRatio: lfHfRatio,
      warning: warnings.isEmpty ? null : warnings.join('\n'),
    );
  }
}

                                                                      
                          
                                                                      

class _BaevskyComponents {
  final double? si;
  final double? mo;
  final double? amo;
  final double? mxdmn;
  const _BaevskyComponents(this.si, this.mo, this.amo, this.mxdmn);
}

                                                          
   
                               
   
                                                                 
                                                             
                                   
                                                                   
                           
                                                 
   
                                                                    
                                                                    
                                                    
_BaevskyComponents _computeBaevskySI(List<double> rrIntervalsMs) {
  if (rrIntervalsMs.length < 5) {
    return const _BaevskyComponents(null, null, null, null);
  }

                
  double minRR = rrIntervalsMs[0];
  double maxRR = rrIntervalsMs[0];
  for (final rr in rrIntervalsMs) {
    if (rr < minRR) minRR = rr;
    if (rr > maxRR) maxRR = rr;
  }
  final double mxdmn = maxRR - minRR;

  if (mxdmn <= 0) {
                                                
    return _BaevskyComponents(null, minRR, 100.0, 0.0);
  }

                                   
                                                         
  final double binWidth = PsychophysiologicalAnalyzer
      ._histogramBinWidthMs;
  final double histStart =
      (minRR / binWidth).floorToDouble() * binWidth;
  final int nBins =
      ((maxRR - histStart) / binWidth).ceil() + 1;

  final binCounts = List<int>.filled(nBins, 0);
  for (final rr in rrIntervalsMs) {
    int binIdx = ((rr - histStart) / binWidth).floor();
    if (binIdx < 0) binIdx = 0;
    if (binIdx >= nBins) binIdx = nBins - 1;
    binCounts[binIdx]++;
  }

              
  int maxCount = 0;
  int modalBinIdx = 0;
  for (int i = 0; i < nBins; i++) {
    if (binCounts[i] > maxCount) {
      maxCount = binCounts[i];
      modalBinIdx = i;
    }
  }

                                      
  final double mo = histStart + (modalBinIdx + 0.5) * binWidth;

                                                   
  final double amo =
      (maxCount / rrIntervalsMs.length) * 100.0;

  if (mo <= 0) {
    return _BaevskyComponents(null, mo, amo, mxdmn);
  }

                                      
                                                             
                                                         
  final double moSec = mo / 1000.0;
  final double mxdmnSec = mxdmn / 1000.0;
  final double si = amo / (2.0 * moSec * mxdmnSec);

  return _BaevskyComponents(si, mo, amo, mxdmn);
}

                                                                      
           
                                                                      

                                                    
double _normalise(double value, double low, double high) {
  if (high <= low) return 0.5;
  return ((value - low) / (high - low)).clamp(0.0, 1.0);
}

                                            
PsychophysiologicalIndex _unavailable(
    String name, String description) {
  return PsychophysiologicalIndex(
    name: name,
    value: null,
    unit: '',
    level: IndexLevel.unknown,
    interpretation: 'Unavailable',
    description: description,
  );
}