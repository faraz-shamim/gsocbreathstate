import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/screens/rf_assessment_screen.dart';
import 'package:breath_state/services/heart_rate/polar_connect.dart';
import 'package:breath_state/services/resonance_service/res_freq.dart';
import 'package:flutter/material.dart';

                                                                            
@Deprecated('Use RfAssessmentScreen with UnifiedPolarConnect.')
class ResonanceFrequencyTrainer extends StatelessWidget {
  final ResonanceFrequency rf;
  final PolarConnect polar;
  final int patientId;
  final Future<void>? preStartFuture;

  const ResonanceFrequencyTrainer({
    super.key,
    required this.rf,
    required this.polar,
    required this.patientId,
    this.preStartFuture,
  });

  @override
  Widget build(BuildContext context) {
    return RfAssessmentScreen(
      polar: UnifiedPolarConnect.mobileDevice(polar),
      patientId: patientId,
      preStartFuture: preStartFuture,
    );
  }
}
