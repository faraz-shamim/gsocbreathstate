import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

class BleScanning {
  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }

  static Future<void> checkAndRequestBluetooth(BuildContext context) async {
    if (kIsWeb) return;

    try {
      final isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          await FlutterBluePlus.turnOn();
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder:
                  (_) => AlertDialog(
                    title: const Text("Bluetooth Required"),
                    content: const Text("Please enable Bluetooth in Settings."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
            );
          }
        }
      } else {
        debugPrint("Bluetooth is ON");
      }
    } catch (e) {
      debugPrint("Bluetooth check error: $e");
    }
  }

  static Future<void> checkAndRequestLocation(BuildContext context) async {
    if (kIsWeb) return;

    try {
      final location = loc.Location();
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled && context.mounted) {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Location Required"),
                  content: const Text(
                    "Please enable Location services to scan BLE devices.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      }
    } catch (e) {
      debugPrint("Location check error: $e");
    }
  }
}
