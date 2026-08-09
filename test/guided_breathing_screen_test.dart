import 'package:breath_state/screens/guided_breathing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('custom protocol editor supports optional holds and ratios', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: GuidedBreathingScreen()));
    await tester.scrollUntilVisible(
      find.text('Custom Protocol'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Custom Protocol'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom Protocol'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('custom-inhale-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-hold-input')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-exhale-input')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('custom-emptyHold-input')),
      findsOneWidget,
    );
    expect(find.textContaining('10s cycle'), findsOneWidget);

    var startButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('custom-protocol-start')),
    );
    expect(startButton.onPressed, isNotNull);

    await tester.enterText(
      find.byKey(const ValueKey('custom-hold-input')),
      '2',
    );
    await tester.pump();
    expect(find.textContaining('12s cycle'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('custom-inhale-input')),
      '0',
    );
    await tester.pump();
    expect(
      find.text('Inhale and exhale must both be greater than zero.'),
      findsOneWidget,
    );
    startButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('custom-protocol-start')),
    );
    expect(startButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('custom-inhale-input')),
      '4',
    );
    await tester.tap(find.text('Ratio'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('custom-cycle-input')), findsOneWidget);
    expect(find.text('Inhale : Exhale ='), findsOneWidget);
    expect(
      find.text('Post-inspiratory pause : Post-expiratory pause ='),
      findsOneWidget,
    );
    expect(find.text('Cycle duration'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
