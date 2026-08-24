// SPDX-License-Identifier: AGPL-3.0-only
import 'dart:async';

import 'package:breath_state/providers/go_direct_provider.dart';
import 'package:breath_state/services/ble_service/ble_scanning.dart';
import 'package:breath_state/services/go_direct/go_direct_constants.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/premium_states.dart';
import 'package:breath_state/widgets/scale_on_press.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GoDirectScanScreen extends StatefulWidget {
  const GoDirectScanScreen({super.key});

  @override
  State<GoDirectScanScreen> createState() => _GoDirectScanScreenState();
}

class _GoDirectScanScreenState extends State<GoDirectScanScreen> {
  GoDirectProvider? _provider;
  bool _isConnecting = false;
  bool _isPreparingScan = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<GoDirectProvider>();
  }

  @override
  void dispose() {
    final provider = _provider;
    if (provider?.connectionState == GoDirectConnectionState.scanning) {
      unawaited(provider!.stopScan());
    }
    super.dispose();
  }

  Future<void> _onDeviceTap(String deviceId) async {
    if (_isConnecting) return;
    _isConnecting = true;
    setState(() {});
    final provider = _provider;
    if (provider == null) {
      if (mounted) setState(() => _isConnecting = false);
      return;
    }
    final success = await provider.connect(deviceId);
    if (!mounted) return;
    setState(() => _isConnecting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connected to ${provider.connectedDeviceName ?? "device"}',
          ),
          backgroundColor: AppTheme.emerald,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.lastError ?? 'Connection failed. Please try again.',
          ),
          backgroundColor: AppTheme.dustyRose,
        ),
      );
    }
  }

  Future<void> _onReconnect() async {
    if (_isConnecting) return;
    _isConnecting = true;
    setState(() {});
    final provider = _provider;
    if (provider == null) {
      if (mounted) setState(() => _isConnecting = false);
      return;
    }
    final success = await provider.reconnect();
    if (!mounted) return;
    setState(() => _isConnecting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reconnected to ${provider.connectedDeviceName ?? "device"}',
          ),
          backgroundColor: AppTheme.emerald,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.lastError ?? 'Reconnection failed. Please scan again.',
          ),
          backgroundColor: AppTheme.dustyRose,
        ),
      );
    }
  }

  Future<void> _startScan() async {
    if (_isPreparingScan || _isConnecting) return;
    setState(() => _isPreparingScan = true);
    try {
      final preparationError = await BleScanning.prepareForScan();
      if (!mounted) return;
      if (preparationError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(preparationError),
            backgroundColor: AppTheme.dustyRose,
          ),
        );
        return;
      }

      final provider = _provider;
      if (provider == null) return;
      await provider.startScan();
      if (!mounted) return;
      if (provider.connectionState == GoDirectConnectionState.error &&
          provider.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.lastError!),
            backgroundColor: AppTheme.dustyRose,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to scan for the respiration belt: $error'),
          backgroundColor: AppTheme.dustyRose,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPreparingScan = false);
    }
  }

  Widget _signalBars(int rssi) {
    final int bars;
    if (rssi >= -50) {
      bars = 4;
    } else if (rssi >= -65) {
      bars = 3;
    } else if (rssi >= -80) {
      bars = 2;
    } else {
      bars = 1;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < bars;
        return Container(
          width: 4,
          height: 6.0 + (i * 4),
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color:
                active
                    ? AppTheme.emerald
                    : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  String _statusLabel(GoDirectConnectionState state, String? deviceName) {
    switch (state) {
      case GoDirectConnectionState.scanning:
        return 'Scanning...';
      case GoDirectConnectionState.connecting:
        return 'Connecting...';
      case GoDirectConnectionState.initializing:
        return 'Initializing...';
      case GoDirectConnectionState.connected:
        return 'Connected to ${deviceName ?? "device"}';
      case GoDirectConnectionState.streaming:
        return 'Streaming from ${deviceName ?? "device"}';
      case GoDirectConnectionState.disconnecting:
        return 'Disconnecting...';
      case GoDirectConnectionState.error:
        return 'Error';
      case GoDirectConnectionState.disconnected:
        return 'Not Connected';
    }
  }

  Color _statusColor(GoDirectConnectionState state) {
    switch (state) {
      case GoDirectConnectionState.connected:
      case GoDirectConnectionState.streaming:
        return Colors.green;
      case GoDirectConnectionState.scanning:
      case GoDirectConnectionState.connecting:
      case GoDirectConnectionState.initializing:
        return Colors.amber;
      case GoDirectConnectionState.error:
        return AppTheme.dustyRose;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<GoDirectProvider>(
      builder: (context, provider, _) {
        final state = provider.connectionState;
        final connected = provider.isConnected;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient:
                  isDark
                      ? AppTheme.darkBackgroundGradient
                      : AppTheme.lightBackgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Connect Respiration Belt',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _statusColor(state),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusLabel(state, provider.connectedDeviceName),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    child:
                        connected
                            ? _buildConnectedView(provider)
                            : _buildScanView(provider, state),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectedView(GoDirectProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.air_rounded,
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
                            provider.connectedDeviceName ?? 'Go Direct Device',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connected',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (provider.availableSensors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Available Sensors',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ...provider.availableSensors.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '* ${s.description} (${s.units})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await provider.disconnect();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dustyRose,
                    ),
                    child: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanView(
    GoDirectProvider provider,
    GoDirectConnectionState state,
  ) {
    final devices = provider.lastScanResults;
    final isScanning = state == GoDirectConnectionState.scanning;
    final isScanBusy = isScanning || _isPreparingScan;

    return Column(
      children: [
        if (provider.canReconnect) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.signalWarn.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: AppTheme.signalWarn,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Reconnect',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          provider.lastConnectedDeviceName ?? 'Previous belt',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isScanBusy || _isConnecting ? null : _onReconnect,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Reconnect'),
                  ),
                ],
              ),
            ),
          ),
        ],

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isScanBusy || _isConnecting ? null : _startScan,
              icon:
                  isScanBusy
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.search_rounded),
              label: Text(
                isScanning
                    ? 'Scanning...'
                    : _isPreparingScan
                    ? 'Preparing Bluetooth...'
                    : 'Scan for Devices',
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child:
              _isConnecting
                  ? const PremiumLoadingState(
                    title: 'Connecting',
                    message: 'Opening the sensor stream and reading metadata.',
                    icon: Icons.sensors_rounded,
                    rows: 2,
                  )
                  : devices.isEmpty
                  ? PremiumEmptyState(
                    icon:
                        isScanBusy
                            ? Icons.radar_rounded
                            : Icons.sensors_off_rounded,
                    title:
                        isScanning
                            ? 'Searching nearby'
                            : _isPreparingScan
                            ? 'Preparing Bluetooth'
                            : state == GoDirectConnectionState.error
                            ? 'Bluetooth scan failed'
                            : provider.hasCompletedScan
                            ? 'No Go Direct devices found'
                            : 'No respiration belt selected',
                    message:
                        isScanning
                            ? 'Keep the belt awake with its Bluetooth LED '
                                'flashing red and within range.'
                            : _isPreparingScan
                            ? 'Checking permissions and the Bluetooth adapter.'
                            : state == GoDirectConnectionState.error
                            ? (provider.lastError ??
                                'Check Bluetooth permissions and try again.')
                            : provider.hasCompletedScan
                            ? 'Press the belt button once so its Bluetooth LED '
                                'flashes red. Disconnect it from Graphical '
                                'Analysis or any other app, then scan again.'
                            : 'Start a scan to discover available Go Direct devices.',
                  )
                  : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ScaleOnPress(
                        scaleFactor: 0.985,
                        haptic: PressHaptic.light,
                        onTap: () => _onDeviceTap(device.id),
                        child: GlassCard(
                          padding: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.emerald.withValues(
                                      alpha: 0.15,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.sensors_rounded,
                                    color: AppTheme.emerald,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        device.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        device.id,
                                        style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                _signalBars(device.rssi),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
