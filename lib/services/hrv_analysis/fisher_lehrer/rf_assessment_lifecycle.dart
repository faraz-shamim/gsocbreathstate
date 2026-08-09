import 'dart:async';

import 'package:flutter/widgets.dart';

import 'rf_assessment_controller.dart';

                                                                             
class RfAssessmentLifecycleObserver with WidgetsBindingObserver {
  final RfAssessmentController controller;
  bool _attached = false;

  RfAssessmentLifecycleObserver(this.controller);

  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed ||
        controller.snapshot.state != RfAssessmentControllerState.running) {
      return;
    }
    final reason =
        state == AppLifecycleState.hidden
            ? RfAbortReason.webHidden
            : RfAbortReason.appBackgrounded;
    unawaited(controller.abort(reason));
  }

  void dispose() {
    if (!_attached) return;
    _attached = false;
    WidgetsBinding.instance.removeObserver(this);
  }
}
