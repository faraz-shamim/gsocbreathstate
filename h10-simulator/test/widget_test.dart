// SPDX-License-Identifier: AGPL-3.0-only
import 'package:breath_state_ble_simulator/main.dart';
import 'package:breath_state_ble_simulator/simulator_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('simulator cockpit renders core controls', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SimulatorController(),
        child: const BreathStateBleSimulatorApp(),
      ),
    );

    expect(find.text('BreathState BLE Sim'), findsWidgets);
    expect(find.text('Polar H10 SIM'), findsOneWidget);
    expect(find.text('Preset'), findsOneWidget);
    expect(find.text('Signals'), findsOneWidget);
    expect(find.text('Faults'), findsOneWidget);
    expect(find.byIcon(Icons.sensors), findsOneWidget);
  });
}
