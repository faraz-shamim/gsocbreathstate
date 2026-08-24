import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:breath_state/providers/app_mode_provider.dart';
import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/providers/go_direct_provider.dart';
import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/providers/theme_provider.dart';
import 'package:breath_state/screens/go_direct_scan_screen.dart';
import 'package:breath_state/screens/patient_list_screen.dart';
import 'package:breath_state/services/ble_service/ble_scanning.dart';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/services/file_service/file_write.dart';
import 'package:breath_state/services/go_direct/go_direct_constants.dart';
import 'package:breath_state/theme/app_theme.dart';
import 'package:breath_state/utils/responsive.dart';
import 'package:breath_state/widgets/ble_device_select.dart';
import 'package:breath_state/widgets/glass_card.dart';
import 'package:breath_state/widgets/result_card_primitives.dart';
import 'package:breath_state/widgets/animated_entrance.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SelectedBleDevice? _selectedPolarDevice;
  bool _isConnectingPolar = false;
  bool _isExporting = false;
  final fileSharer = FileWriterService();
  int _settingsTitleTapCount = 0;
  DateTime? _lastTapTime;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = Responsive.horizontalPadding(context);
    final appModeProvider = context.watch<AppModeProvider>();
    final appMode = appModeProvider.mode;
    final isPatientWithoutPolar = appMode == AppMode.patientWithoutPolar;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDark
                  ? AppTheme.darkBackgroundGradient
                  : AppTheme.lightBackgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.all(hPad),
                child: ContentContainer(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: GestureDetector(
                            onTap: _handleSettingsTitleTap,
                            behavior: HitTestBehavior.translucent,
                            child: Text(
                              "Settings",
                              style: Theme.of(context).textTheme.displayMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        _buildSectionHeader('APPEARANCE'),
                        AnimatedEntrance(
                          delay: Duration.zero,
                          child: GlassCard(
                            sheen: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            child: Consumer<ThemeProvider>(
                              builder: (context, themeProvider, child) {
                                return _SettingsRow(
                                  icon: Icons.palette_rounded,
                                  iconColor: AppTheme.emerald,
                                  isDark: isDark,
                                  title: "Dark Mode",
                                  trailing: Switch(
                                    value: themeProvider.isDarkMode,
                                    activeThumbColor: AppTheme.pureWhite,
                                    activeTrackColor: AppTheme.emerald,
                                    onChanged: themeProvider.toggleTheme,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        if (!isPatientWithoutPolar) ...[
                          _buildSectionHeader('CONFIGURATION & DEVICES'),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 60),
                            child: GlassCard(
                              sheen: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              child: Column(
                                children: [
                                  _buildAppModeRow(context, appMode, isDark),
                                  ResultDivider(isDark: isDark),
                                  _buildPatientsRow(context, isDark),
                                  ResultDivider(isDark: isDark),
                                  Consumer<PolarConnectProvider>(
                                    builder:
                                        (context, polarProvider, _) =>
                                            _buildPolarRow(
                                              context,
                                              polarProvider,
                                              isDark,
                                            ),
                                  ),
                                  ResultDivider(isDark: isDark),
                                  AnimatedEntrance(
                                    delay: const Duration(milliseconds: 240),
                                    child: Consumer<GoDirectProvider>(
                                      builder:
                                          (context, gdProvider, _) =>
                                              _buildBeltRow(
                                                context,
                                                gdProvider,
                                                isDark,
                                              ),
                                    ),
                                  ),
                                  if (kIsWeb) ...[
                                    ResultDivider(isDark: isDark),
                                    _buildWebBluetoothRow(context, isDark),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          _buildSectionHeader('DATA'),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 360),
                            child: GlassCard(
                              sheen: true,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              child: _SettingsRow(
                                icon: Icons.download_rounded,
                                iconColor: AppTheme.emerald,
                                isDark: isDark,
                                title: "Export Data",
                                trailing: _CompactButton(
                                  label:
                                      _isExporting
                                          ? "Exporting..."
                                          : "Export Data",
                                  color: AppTheme.emerald,
                                  textColor: AppTheme.obsidian,
                                  onPressed:
                                      _isExporting ? null : _exportPatientCsv,
                                ),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: Responsive.bottomListPadding(context)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 12),
      child: Text(
        title,
        style: AppTheme.luxuryItalic(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.35),
        ).copyWith(letterSpacing: 1.4),
      ),
    );
  }

  void _handleSettingsTitleTap() {
    final now = DateTime.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(milliseconds: 1500)) {
      _settingsTitleTapCount = 1;
    } else {
      _settingsTitleTapCount++;
    }
    _lastTapTime = now;

    if (_settingsTitleTapCount >= 3) {
      _settingsTitleTapCount = 0;
      _showModeSwitchDialog();
    }
  }

  void _showModeSwitchDialog() {
    final appModeProvider = context.read<AppModeProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          title: const Text("Switch App Mode"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                AppMode.values.map((mode) {
                  String label = "";
                  switch (mode) {
                    case AppMode.clinician:
                      label = "Clinician Mode";
                      break;
                    case AppMode.patientWithPolar:
                      label = "Patient (with Polar)";
                      break;
                    case AppMode.patientWithoutPolar:
                      label = "Patient (No Polar)";
                      break;
                  }
                  return ListTile(
                    title: Text(label),
                    selected: appModeProvider.mode == mode,
                    selectedColor: AppTheme.emerald,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                    onTap: () {
                      appModeProvider.setMode(mode);
                      context.read<NavBarProvider>().changeIndex(0);
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched to $label'),
                          backgroundColor: AppTheme.emerald,
                        ),
                      );
                    },
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppModeRow(
    BuildContext context,
    AppMode currentMode,
    bool isDark,
  ) {
    return _SettingsRow(
      icon: Icons.admin_panel_settings_rounded,
      iconColor: AppTheme.emerald,
      isDark: isDark,
      title: "App Mode",
      subtitle:
          currentMode == AppMode.clinician
              ? "Clinician Mode"
              : currentMode == AppMode.patientWithPolar
              ? "Patient (with Polar)"
              : "Patient (No Polar)",
      subtitleColor: AppTheme.emerald,
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<AppMode>(
          value: currentMode,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppTheme.emerald,
          ),
          dropdownColor: isDark ? AppTheme.charcoal : AppTheme.pureWhite,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          items: const [
            DropdownMenuItem(
              value: AppMode.clinician,
              child: Text("Clinician"),
            ),
            DropdownMenuItem(
              value: AppMode.patientWithPolar,
              child: Text("Patient (Polar)"),
            ),
            DropdownMenuItem(
              value: AppMode.patientWithoutPolar,
              child: Text("Patient (No Polar)"),
            ),
          ],
          onChanged: (newMode) {
            if (newMode != null) {
              context.read<AppModeProvider>().setMode(newMode);
              context.read<NavBarProvider>().changeIndex(0);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPatientsRow(BuildContext context, bool isDark) {
    return _SettingsRow(
      icon: Icons.people_rounded,
      iconColor: AppTheme.softSage,
      isDark: isDark,
      title: "Patients",
      subtitleBuilder:
          (_) => Consumer<PatientProvider>(
            builder:
                (_, pp, __) => Text(
                  '${pp.patients.length} profile(s)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.emerald),
                ),
          ),
      trailing: _CompactButton(
        label: 'Manage',
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PatientListScreen()),
            ),
      ),
    );
  }

  Widget _buildPolarRow(
    BuildContext context,
    PolarConnectProvider polarProvider,
    bool isDark,
  ) {
    final connected = polarProvider.isConnected;
    final statusText =
        connected ? (polarProvider.deviceName ?? 'Connected') : 'Disconnected';
    final statusColor =
        connected ? const Color(0xFF16A34A) : AppTheme.dustyRose;

    return _SettingsRow(
      icon: Icons.bluetooth,
      iconColor: Colors.blueAccent,
      isDark: isDark,
      title: "Polar Sensor",
      subtitle: statusText,
      subtitleColor: statusColor,
      trailing: _CompactButton(
        label:
            _isConnectingPolar
                ? "Connecting..."
                : connected
                ? "Reconnect"
                : "Connect",
        onPressed: () => _connectPolar(context, polarProvider),
      ),
    );
  }

  Future<void> _connectPolar(
    BuildContext context,
    PolarConnectProvider polarProvider,
  ) async {
    if (_isConnectingPolar) return;
    setState(() => _isConnectingPolar = true);
    if (kIsWeb) {
      try {
        final ok = await polarProvider.connectViaBrowser();
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Polar connection failed or cancelled. '
                'Make sure your browser supports Web Bluetooth.',
              ),
              backgroundColor: AppTheme.dustyRose,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isConnectingPolar = false);
      }
    } else {
      try {
        await BleScanning.requestPermissions();
        if (context.mounted) {
          await BleScanning.checkAndRequestBluetooth(context);
        }
        if (context.mounted) {
          await BleScanning.checkAndRequestLocation(context);
        }
        if (context.mounted) {
          _selectedPolarDevice = await Navigator.push<SelectedBleDevice>(
            context,
            MaterialPageRoute(builder: (_) => const BleDeviceSelect()),
          );
        }
        developer.log(
          "Selected Polar device: "
          "polarId=${_selectedPolarDevice?.polarIdentifier}",
        );
        if (_selectedPolarDevice != null) {
          final ok = await polarProvider.connectToPolarSensor(
            _selectedPolarDevice!.polarIdentifier,
            displayName: _selectedPolarDevice!.displayName,
          );
          if (!ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Polar connection failed. '
                  'Keep the sensor awake and try again.',
                ),
                backgroundColor: AppTheme.dustyRose,
              ),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isConnectingPolar = false);
      }
    }
  }

  Widget _buildBeltRow(
    BuildContext context,
    GoDirectProvider gdProvider,
    bool isDark,
  ) {
    final state = gdProvider.connectionState;
    final isGdConnected = gdProvider.isConnected;
    final statusText =
        isGdConnected
            ? (gdProvider.connectedDeviceName ?? 'Connected')
            : state == GoDirectConnectionState.scanning
            ? 'Scanning…'
            : state == GoDirectConnectionState.error
            ? (gdProvider.lastError ?? 'Connection error')
            : 'Disconnected';
    final statusColor =
        isGdConnected
            ? const Color(0xFF16A34A)
            : state == GoDirectConnectionState.scanning
            ? Colors.amber
            : AppTheme.dustyRose;

    return _SettingsRow(
      icon: Icons.air_rounded,
      iconColor: AppTheme.emerald,
      isDark: isDark,
      title: 'Respiration Belt',
      subtitle: statusText,
      subtitleColor: statusColor,
      trailing: _CompactButton(
        label: isGdConnected ? 'Disconnect' : 'Connect',
        onPressed: () => _connectBelt(context, gdProvider, isGdConnected),
      ),
    );
  }

  Future<void> _connectBelt(
    BuildContext context,
    GoDirectProvider gdProvider,
    bool isGdConnected,
  ) async {
    if (kIsWeb) {
      if (isGdConnected) {
        await gdProvider.disconnect();
      } else {
        final ok = await gdProvider.connectViaBrowser();
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                gdProvider.lastError ??
                    'Go Direct connection failed or cancelled.',
              ),
              backgroundColor: AppTheme.dustyRose,
            ),
          );
        }
      }
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const GoDirectScanScreen()));
    }
  }

  Widget _buildWebBluetoothRow(BuildContext context, bool isDark) {
    return _SettingsRow(
      icon: Icons.bluetooth_searching_rounded,
      iconColor: AppTheme.softSage,
      isDark: isDark,
      title:
          "Web Bluetooth is used for sensor connections. "
          "Ensure your browser supports it (Chrome/Edge). "
          "Microphone-based breathing is not available on web.",
    );
  }

  Future<void> _exportPatientCsv() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final db = context.read<AppDatabase>();
      final patient = context.read<PatientProvider>().activePatient;
      if (patient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select a patient before exporting.'),
            backgroundColor: AppTheme.dustyRose,
          ),
        );
        return;
      }

      final csv = await db.generatePatientCsv(patient.id);
      final safeName =
          patient.name.replaceAll(RegExp(r'[^\w]'), '_').toLowerCase();
      final result = await fileSharer.exportCsv(csv, safeName);
      if (!mounted) return;
      final message = switch (result) {
        CsvExportStatus.shared => 'Export sent to the share sheet.',
        CsvExportStatus.dismissed => 'Export cancelled.',
        CsvExportStatus.unavailable =>
          'Export prepared, but the share result was unavailable.',
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      developer.log('CSV export error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export failed. Please try again.'),
          backgroundColor: AppTheme.dustyRose,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final WidgetBuilder? subtitleBuilder;
  final Widget? trailing;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.subtitleBuilder,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.14 : 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                if (subtitleBuilder != null)
                  subtitleBuilder!(context)
                else if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            subtitleColor ??
                            Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;

  const _CompactButton({
    required this.label,
    required this.onPressed,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = color ?? (isDark ? AppTheme.emerald : AppTheme.deepJade);
    final foreground =
        textColor ?? (isDark ? AppTheme.obsidian : AppTheme.pureWhite);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        minimumSize: const Size(88, 38),
        elevation: 0,
        shadowColor: background.withValues(alpha: 0.22),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      child: Text(label),
    );
  }
}
