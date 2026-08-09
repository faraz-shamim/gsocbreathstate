import 'dart:async';

import 'package:breath_state/services/heart_rate/polar_pmd_protocol.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/premium_states.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class SelectedBleDevice {
  final String polarIdentifier;
  final String displayName;

  const SelectedBleDevice({
    required this.polarIdentifier,
    required this.displayName,
  });
}

class BleDeviceSelect extends StatefulWidget {
  const BleDeviceSelect({super.key});

  @override
  State<BleDeviceSelect> createState() => _BleDeviceSelectState();
}

class _PolarScanDevice {
  final String id;
  final String name;
  final int rssi;
  final bool systemConnected;

  const _PolarScanDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.systemConnected,
  });
}

class _BleDeviceSelectState extends State<BleDeviceSelect> {
  static final Guid _heartRateServiceGuid = Guid(
    '0000180d-0000-1000-8000-00805f9b34fb',
  );
  static final Guid _pmdServiceGuid = Guid(PolarPmdUuids.service);

  final Map<String, _PolarScanDevice> _devicesById = {};
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  List<_PolarScanDevice> scannedDevices = [];
  Object? _scanError;

  @override
  void initState() {
    super.initState();
    unawaited(_startPolarScan());
  }

  @override
  void dispose() {
    unawaited(_stopPolarScan());
    super.dispose();
  }

  Future<void> _startPolarScan() async {
    await _stopPolarScan();

    try {
      await _loadKnownPolarDevices();
      _scanSubscription = FlutterBluePlus.onScanResults.listen(
        (results) {
          for (final result in results) {
            if (!_looksLikePolar(result)) continue;
            _upsertDevice(
              _PolarScanDevice(
                id: result.device.remoteId.str,
                name: _displayName(result),
                rssi: result.rssi,
                systemConnected: false,
              ),
            );
          }
          _publishDevices();
        },
        onError: (Object error) {
          if (!mounted) return;
          setState(() => _scanError = error);
        },
      );

      await FlutterBluePlus.startScan(
        withServices: [_heartRateServiceGuid],
        timeout: const Duration(seconds: 12),
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 6),
        androidScanMode: AndroidScanMode.lowLatency,
        androidCheckLocationServices: false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _scanError = error);
    }
  }

  Future<void> _loadKnownPolarDevices() async {
    final known = <BluetoothDevice>[];
    try {
      known.addAll(
        await FlutterBluePlus.systemDevices([
          _heartRateServiceGuid,
        ]).timeout(const Duration(seconds: 2)),
      );
    } catch (_) {}

    try {
      known.addAll(
        await FlutterBluePlus.bondedDevices.timeout(const Duration(seconds: 2)),
      );
    } catch (_) {}

    for (final device in known) {
      final name = _knownPolarName(device);
      if (name == null) continue;
      _upsertDevice(
        _PolarScanDevice(
          id: device.remoteId.str,
          name: name,
          rssi: -999,
          systemConnected: true,
        ),
      );
    }
    _publishDevices();
  }

  Future<void> _stopPolarScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  void _upsertDevice(_PolarScanDevice device) {
    if (device.id.trim().isEmpty) return;
    final existing = _devicesById[device.id];
    if (existing == null ||
        device.rssi > existing.rssi ||
        (!existing.systemConnected && device.systemConnected)) {
      _devicesById[device.id] = device;
    }
  }

  void _publishDevices() {
    final devices = _devicesById.values.toList()..sort(_comparePolarDevices);
    if (!mounted) return;
    setState(() {
      _scanError = null;
      scannedDevices = devices;
    });
  }

  int _comparePolarDevices(_PolarScanDevice a, _PolarScanDevice b) {
    final aH10 = _isH10(a.name);
    final bH10 = _isH10(b.name);
    if (aH10 != bH10) return aH10 ? -1 : 1;
    if (a.systemConnected != b.systemConnected) {
      return a.systemConnected ? -1 : 1;
    }
    final aNamed = a.name.trim().isNotEmpty;
    final bNamed = b.name.trim().isNotEmpty;
    if (aNamed != bNamed) return aNamed ? -1 : 1;
    return b.rssi.compareTo(a.rssi);
  }

  bool _looksLikePolar(ScanResult result) {
    if (_isPolarName(_displayName(result))) return true;
    return result.advertisementData.serviceUuids.any(
      (uuid) => uuid == _heartRateServiceGuid || uuid == _pmdServiceGuid,
    );
  }

  bool _isPolarName(String name) {
    final normalized = name.toUpperCase();
    return normalized.contains('POLAR') || normalized.contains('H10');
  }

  bool _isH10(String name) => name.toUpperCase().contains('H10');

  String _displayName(ScanResult result) {
    final advertised = result.advertisementData.advName.trim();
    if (advertised.isNotEmpty) return advertised;
    final platform = result.device.platformName.trim();
    if (platform.isNotEmpty) return platform;
    return 'Polar ${result.device.remoteId.str}';
  }

  String? _knownPolarName(BluetoothDevice device) {
    final platform = device.platformName.trim();
    if (platform.isNotEmpty && _isPolarName(platform)) return platform;
    final advertised = device.advName.trim();
    if (advertised.isNotEmpty && _isPolarName(advertised)) {
      return advertised;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.obsidian : AppTheme.ivory,
      appBar: AppBar(
        title: const Text("Select Device"),
        elevation: 0,
        centerTitle: true,
      ),
      body:
          scannedDevices.isEmpty
              ? _scanError == null
                  ? const PremiumLoadingState(
                    title: 'Scanning for Polar',
                    message: 'Looking for nearby H10 heart-rate sensors.',
                    icon: Icons.bluetooth_searching_rounded,
                    rows: 3,
                  )
                  : PremiumEmptyState(
                    icon: Icons.bluetooth_disabled_rounded,
                    title: 'Polar scan failed',
                    message: 'Check Bluetooth permissions, then try again.',
                    actionLabel: 'Retry scan',
                    actionIcon: Icons.refresh_rounded,
                    onActionPressed: () => unawaited(_startPolarScan()),
                  )
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: scannedDevices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final device = scannedDevices[index];
                  return ScaleOnPress(
                    scaleFactor: 0.985,
                    haptic: PressHaptic.light,
                    onTap: () async {
                      await _stopPolarScan();
                      if (!context.mounted) return;
                      Navigator.pop(
                        context,
                        SelectedBleDevice(
                          polarIdentifier: device.id,
                          displayName: device.name,
                        ),
                      );
                    },
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.emerald.withValues(
                                alpha: isDark ? 0.18 : 0.12,
                              ),
                              child: const Icon(
                                Icons.bluetooth_rounded,
                                color: AppTheme.emerald,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "ID: ${device.id}",
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    device.systemConnected
                                        ? "Already connected to Android"
                                        : "RSSI: ${device.rssi}",
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.34),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
