import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { clinician, patientWithPolar, patientWithoutPolar }

class NavDestination {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const NavDestination({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

const List<NavDestination> kClinicianNavDestinations = [
  NavDestination(icon: Icons.home_rounded, label: 'Home'),
  NavDestination(
    icon: Icons.monitor_heart_outlined,
    activeIcon: Icons.monitor_heart_rounded,
    label: 'Record',
  ),
  NavDestination(
    icon: Icons.assignment_outlined,
    activeIcon: Icons.assignment_rounded,
    label: 'Assess',
  ),
  NavDestination(
    icon: Icons.timeline_outlined,
    activeIcon: Icons.timeline_rounded,
    label: 'Trends',
  ),
  NavDestination(icon: Icons.spa_rounded, label: 'Breath'),
  NavDestination(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Settings',
  ),
];

const List<NavDestination> kPatientWithPolarNavDestinations = [
  NavDestination(icon: Icons.home_rounded, label: 'Home'),
  NavDestination(
    icon: Icons.monitor_heart_outlined,
    activeIcon: Icons.monitor_heart_rounded,
    label: 'Record',
  ),
  NavDestination(icon: Icons.spa_rounded, label: 'Breath'),
  NavDestination(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Settings',
  ),
];

const List<NavDestination> kPatientWithoutPolarNavDestinations = [
  NavDestination(icon: Icons.spa_rounded, label: 'Breath'),
  NavDestination(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Settings',
  ),
];

class AppModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.clinician;
  static const String _modeKey = 'app_mode_index';

  AppModeProvider() {
    _loadMode();
  }

  AppMode get mode => _mode;

  bool get isClinician => _mode == AppMode.clinician;
  bool get isPatientWithPolar => _mode == AppMode.patientWithPolar;
  bool get isPatientWithoutPolar => _mode == AppMode.patientWithoutPolar;

  List<NavDestination> get destinations {
    if (isPatientWithoutPolar) {
      return kPatientWithoutPolarNavDestinations;
    }
    if (isPatientWithPolar) {
      return kPatientWithPolarNavDestinations;
    }
    return kClinicianNavDestinations;
  }

  int indexForDestination(String label, {int fallback = 0}) {
    final index = destinations.indexWhere((dest) => dest.label == label);
    return index == -1 ? fallback : index;
  }

  Future<void> setMode(AppMode newMode) async {
    _mode = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, newMode.index);
    notifyListeners();
  }

  Future<void> _loadMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_modeKey);
    if (index != null && index >= 0 && index < AppMode.values.length) {
      _mode = AppMode.values[index];
      notifyListeners();
    }
  }
}
