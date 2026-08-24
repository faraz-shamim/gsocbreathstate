import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

class BleScanning {
  static const MethodChannel _platformChannel = MethodChannel(
    'breath_state/platform',
  );

  static Future<String?> prepareForScan() async {
    if (kIsWeb) return null;

    try {
      if (!await FlutterBluePlus.isSupported) {
        return 'Bluetooth Low Energy is not supported on this device.';
      }

      final permissionError = await _requestPlatformPermissions();
      if (permissionError != null) return permissionError;

      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState == BluetoothAdapterState.unauthorized) {
        return 'Bluetooth permission is disabled for Breath State. Enable it '
            'in the app settings.';
      }
      if (adapterState == BluetoothAdapterState.unavailable) {
        return 'Bluetooth is unavailable on this device.';
      }

      if (adapterState != BluetoothAdapterState.on) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          try {
            await FlutterBluePlus.turnOn();
            adapterState = await FlutterBluePlus.adapterState.first;
          } catch (_) {
            return 'Turn Bluetooth on, then try scanning again.';
          }
        } else {
          return 'Turn Bluetooth on in Settings, then try scanning again.';
        }
      }

      if (adapterState != BluetoothAdapterState.on) {
        return 'Bluetooth is still turned off.';
      }
      return null;
    } catch (error) {
      return 'Bluetooth could not be prepared for scanning: $error';
    }
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _requestPlatformPermissions();
  }

  static Future<void> checkAndRequestBluetooth(BuildContext context) async {
    if (kIsWeb) return;

    try {
      final isOn = await _isBluetoothOn();
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
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final sdk = await _androidSdkInt();
    if (sdk != null && sdk >= 31) return;

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

  static Future<String?> _requestPlatformPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final sdk = await _androidSdkInt();
      if (sdk == null) {
        return 'Unable to determine the Android Bluetooth permission model.';
      }

      if (sdk >= 31) {
        final statuses =
            await [
              Permission.bluetoothScan,
              Permission.bluetoothConnect,
            ].request();
        final scan = statuses[Permission.bluetoothScan];
        final connect = statuses[Permission.bluetoothConnect];
        if (scan?.isGranted == true && connect?.isGranted == true) return null;
        if (scan?.isPermanentlyDenied == true ||
            connect?.isPermanentlyDenied == true) {
          return 'Nearby devices permission is disabled. Enable it in the '
              'Breath State app settings.';
        }
        return 'Nearby devices permission is required to find the respiration belt.';
      }

      final locationStatus = await Permission.location.request();
      if (!locationStatus.isGranted) {
        if (locationStatus.isPermanentlyDenied) {
          return 'Location permission is disabled. Enable it in the Breath '
              'State app settings to scan on Android 11 or older.';
        }
        return 'Location permission is required for Bluetooth scanning on '
            'Android 11 or older.';
      }

      final location = loc.Location();
      var serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
      }
      if (!serviceEnabled) {
        return 'Enable Location services to scan for Bluetooth devices on '
            'Android 11 or older.';
      }
      return null;
    }

    return null;
  }

  static Future<int?> _androidSdkInt() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      return await _platformChannel.invokeMethod<int>('androidSdkInt');
    } catch (error) {
      debugPrint('Android SDK lookup failed: $error');
      return null;
    }
  }

  static Future<bool> _isBluetoothOn() async =>
      await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
}
