// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/screens/rf_assessment_screen.dart';
import 'package:flutter/material.dart';

import 'package:breath_state/services/heart_rate/polar_connect_web.dart'
    if (dart.library.io) 'package:breath_state/services/heart_rate/polar_connect_web_stub.dart';

                                                                             
@Deprecated('Use RfAssessmentScreen with UnifiedPolarConnect.')
class WebResonanceFrequencyTrainer extends StatelessWidget {
  final PolarConnectWeb polarWeb;
  final int patientId;
  final Future<void>? preStartFuture;

  const WebResonanceFrequencyTrainer({
    super.key,
    required this.polarWeb,
    required this.patientId,
    this.preStartFuture,
  });

  @override
  Widget build(BuildContext context) {
    return RfAssessmentScreen(
      polar: UnifiedPolarConnect.webDevice(polarWeb),
      patientId: patientId,
      preStartFuture: preStartFuture,
    );
  }
}
