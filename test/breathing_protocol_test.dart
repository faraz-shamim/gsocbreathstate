import 'package:breath_state/models/breathing_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BreathingProtocol', () {
    test('cycles directly between inhale and exhale when holds are zero', () {
      final protocol = BreathingProtocol(
        inhaleDuration: const Duration(seconds: 4),
        holdDuration: Duration.zero,
        exhaleDuration: const Duration(seconds: 6),
      );

      expect(protocol.activePhases, [
        BreathingPhase.inhale,
        BreathingPhase.exhale,
      ]);
      expect(protocol.nextPhase(BreathingPhase.inhale), BreathingPhase.exhale);
      expect(protocol.nextPhase(BreathingPhase.exhale), BreathingPhase.inhale);
    });

    test('includes only the configured post-inspiratory hold', () {
      final protocol = BreathingProtocol(
        inhaleDuration: const Duration(seconds: 4),
        holdDuration: const Duration(seconds: 2),
        exhaleDuration: const Duration(seconds: 6),
      );

      expect(protocol.activePhases, [
        BreathingPhase.inhale,
        BreathingPhase.hold,
        BreathingPhase.exhale,
      ]);
      expect(protocol.nextPhase(BreathingPhase.hold), BreathingPhase.exhale);
      expect(protocol.cycleDuration, const Duration(seconds: 12));
    });

    test('includes only the configured post-expiratory hold', () {
      final protocol = BreathingProtocol(
        inhaleDuration: const Duration(seconds: 4),
        holdDuration: Duration.zero,
        exhaleDuration: const Duration(seconds: 6),
        emptyHoldDuration: const Duration(seconds: 2),
      );

      expect(protocol.activePhases, [
        BreathingPhase.inhale,
        BreathingPhase.exhale,
        BreathingPhase.emptyHold,
      ]);
      expect(
        protocol.nextPhase(BreathingPhase.exhale),
        BreathingPhase.emptyHold,
      );
      expect(
        protocol.nextPhase(BreathingPhase.emptyHold),
        BreathingPhase.inhale,
      );
    });

    test('skips any disabled leading or trailing phases', () {
      final protocol = BreathingProtocol(
        inhaleDuration: Duration.zero,
        holdDuration: const Duration(seconds: 2),
        exhaleDuration: const Duration(seconds: 3),
      );

      expect(protocol.firstPhase, BreathingPhase.hold);
      expect(protocol.activePhases, [
        BreathingPhase.hold,
        BreathingPhase.exhale,
      ]);
      expect(protocol.nextPhase(BreathingPhase.exhale), BreathingPhase.hold);
    });

    test('converts ratios into an exact requested cycle duration', () {
      final protocol = BreathingProtocol.fromRatios(
        inhale: 1,
        hold: 0,
        exhale: 2,
        emptyHold: 0,
        cycleDuration: const Duration(seconds: 12),
      );

      expect(protocol.inhaleDuration, const Duration(seconds: 4));
      expect(protocol.holdDuration, Duration.zero);
      expect(protocol.exhaleDuration, const Duration(seconds: 8));
      expect(protocol.emptyHoldDuration, Duration.zero);
      expect(protocol.cycleDuration, const Duration(seconds: 12));
    });

    test('rejects negative and fully disabled protocols', () {
      expect(
        () => BreathingProtocol(
          inhaleDuration: const Duration(seconds: -1),
          holdDuration: Duration.zero,
          exhaleDuration: const Duration(seconds: 4),
        ),
        throwsArgumentError,
      );
      expect(
        () => BreathingProtocol(
          inhaleDuration: Duration.zero,
          holdDuration: Duration.zero,
          exhaleDuration: Duration.zero,
        ),
        throwsArgumentError,
      );
    });
  });
}
