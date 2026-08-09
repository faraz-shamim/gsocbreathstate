import 'package:breath_state/providers/app_mode_provider.dart';
import 'package:breath_state/providers/breathing_sound_provider.dart';
import 'package:breath_state/providers/go_direct_provider.dart';
import 'package:breath_state/providers/nav_bar_provider.dart';
import 'package:breath_state/providers/patient_provider.dart';
import 'package:breath_state/providers/polar_connect_provider.dart';
import 'package:breath_state/screens/psychiatric_assessment_screen.dart';
import 'package:breath_state/screens/psychometric_trend_screen.dart';
import 'package:breath_state/providers/theme_provider.dart';
import 'package:breath_state/screens/record_screen.dart';
import 'package:breath_state/screens/settings_screen.dart';
import 'package:breath_state/services/db_service/database.dart';
import 'package:breath_state/widgets/adaptive_scaffold.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/guided_breathing_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: AppTheme.obsidian,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final db = AppDatabase();

  final patientProvider = PatientProvider(db);
  await patientProvider.loadPatients();
  final breathingSoundProvider = BreathingSoundProvider();
  await breathingSoundProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: db),
        ChangeNotifierProvider<PatientProvider>.value(value: patientProvider),
        ChangeNotifierProvider<BreathingSoundProvider>.value(
          value: breathingSoundProvider,
        ),
        ChangeNotifierProvider(create: (_) => NavBarProvider(0)),
        ChangeNotifierProvider(create: (_) => PolarConnectProvider()),
        ChangeNotifierProvider(create: (_) => GoDirectProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppModeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  List<Widget> _getVisibleScreens(AppMode mode) {
    switch (mode) {
      case AppMode.patientWithoutPolar:
        return const [GuidedBreathingScreen(), SettingsScreen()];
      case AppMode.patientWithPolar:
        return const [
          HomeScreen(),
          RecordScreen(),
          GuidedBreathingScreen(),
          SettingsScreen(),
        ];
      case AppMode.clinician:
        return const [
          HomeScreen(),
          RecordScreen(),
          PsychiatricAssessmentScreen(),
          PsychometricTrendScreen(),
          GuidedBreathingScreen(),
          SettingsScreen(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AppModeProvider>(
      builder: (context, themeProvider, appModeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final navColor = isDark ? AppTheme.obsidian : AppTheme.ivory;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: navColor,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: navColor,
          ),
        );

        return MaterialApp(
          title: 'BreathState',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: AdaptiveScaffold(
            screens: _getVisibleScreens(appModeProvider.mode),
          ),
        );
      },
    );
  }
}
