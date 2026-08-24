// SPDX-License-Identifier: AGPL-3.0-only
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

                                                
   
                                                                           
                                                                               
                                                                           
                                   
class AppTheme {
  static const double radiusXs = 10;
  static const double radiusSm = 14;
  static const double radiusMd = 18;
  static const double radiusLg = 24;
  static const double radiusXl = 28;
  static const double radiusFull = 999;

  static const Color graphite = Color(0xFF0B1116);
  static const Color graphite2 = Color(0xFF111A22);
  static const Color graphite3 = Color(0xFF17222B);
  static const Color porcelain = Color(0xFFF6F8F8);
  static const Color porcelain2 = Color(0xFFEAF0F0);
  static const Color pureWhite = Color(0xFFFFFFFF);

  static const Color clinicalTeal = Color(0xFF5AD7C8);
  static const Color clinicalTealDark = Color(0xFF0F8D82);
  static const Color clinicalCyan = Color(0xFF7FB7F0);
  static const Color cardiacRose = Color(0xFFE48A7D);
  static const Color signalGood = Color(0xFF54D38A);
  static const Color signalWarn = Color(0xFFE4C45F);
  static const Color signalBad = Color(0xFFE56F61);

  static const Color textLight = Color(0xFFF2F7F7);
  static const Color textDark = Color(0xFF11181D);
  static const Color textDimLight = Color(0xFF94A6AC);
  static const Color textDimDark = Color(0xFF617178);

  static const Color darkSurface = Color(0xFF121C24);
  static const Color darkSurfaceElevated = Color(0xFF18252E);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFDFEFE);

                                                    
  static const Color emerald = clinicalTeal;
  static const Color deepJade = clinicalTealDark;
  static const Color obsidian = graphite;
  static const Color charcoal = graphite2;
  static const Color ivory = porcelain;
  static const Color dustyRose = cardiacRose;
  static const Color coralRose = signalBad;
  static const Color softSage = clinicalCyan;
  static const Color violetAccent = clinicalCyan;
  static const Color darkRose = Color(0xFFC65449);

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [graphite, Color(0xFF0E171E), graphite2],
  );

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [porcelain, Color(0xFFF9FBFB), porcelain2],
  );

  static Color panelFill(bool isDark) =>
      isDark ? darkSurface.withValues(alpha: 0.94) : lightSurface;

  static Color panelFillMuted(bool isDark) =>
      isDark ? darkSurfaceElevated.withValues(alpha: 0.72) : porcelain2;

  static Color foreground(bool isDark) => isDark ? textLight : textDark;

  static Color muted(bool isDark) => isDark ? textDimLight : textDimDark;

  static Color hairline(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFDCE4E5);

  static Color gridline(bool isDark) =>
      isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFD8E1E3);

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'good':
      case 'connected':
      case 'active':
      case 'streaming':
        return signalGood;
      case 'fair':
      case 'warning':
      case 'connecting':
      case 'scanning':
      case 'initializing':
        return signalWarn;
      case 'bad':
      case 'error':
      case 'off':
      case 'disconnected':
        return signalBad;
      default:
        return clinicalCyan;
    }
  }

  static List<BoxShadow> softShadow({
    required bool isDark,
    bool bright = false,
  }) {
    return [
      BoxShadow(
        color:
            isDark
                ? Colors.black.withValues(alpha: bright ? 0.30 : 0.22)
                : const Color(
                  0xFF4A5A60,
                ).withValues(alpha: bright ? 0.10 : 0.07),
        blurRadius: bright ? 36 : 28,
        spreadRadius: -18,
        offset: const Offset(0, 20),
      ),
    ];
  }

  static TextStyle luxuryItalic({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w500,
    required Color color,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: FontStyle.italic,
      color: color,
      letterSpacing: 0,
      height: 1.35,
    );
  }

  static TextTheme _buildTextTheme(Color primaryColor, Color dimColor) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: primaryColor,
        letterSpacing: -0.4,
        height: 1.08,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: primaryColor,
        letterSpacing: -0.25,
        height: 1.10,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.1,
        height: 1.15,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: primaryColor,
        letterSpacing: -0.15,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.05,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        height: 1.45,
        color: dimColor,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        height: 1.35,
        color: dimColor,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: primaryColor,
        letterSpacing: 0.05,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: dimColor,
        letterSpacing: 0.15,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: dimColor,
        letterSpacing: 0.25,
      ),
    );
  }

  static TextStyle monoNumeral({
    required Color color,
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.robotoMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: -0.1,
    );
  }

  static TextStyle _buttonText(Color color) {
    return GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: 0.05,
    );
  }

  static ButtonStyle _elevatedButtonStyle({
    required Color background,
    required Color foreground,
    required Color disabledBackground,
    required Color disabledForeground,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      disabledBackgroundColor: disabledBackground,
      disabledForegroundColor: disabledForeground,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      minimumSize: const Size(64, 46),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusSm),
      ),
      textStyle: _buttonText(foreground),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return Colors.transparent;
        if (states.contains(WidgetState.pressed)) {
          return foreground.withValues(alpha: 0.16);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return foreground.withValues(alpha: 0.10);
        }
        return null;
      }),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme({
    required Color foreground,
    required Color overlay,
  }) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: foreground.withValues(alpha: 0.28), width: 1),
        minimumSize: const Size(64, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: _buttonText(foreground),
      ).copyWith(overlayColor: WidgetStatePropertyAll(overlay)),
    );
  }

  static TextButtonThemeData _textButtonTheme({
    required Color foreground,
    required Color overlay,
  }) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        minimumSize: const Size(48, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXs),
        ),
        textStyle: _buttonText(foreground),
      ).copyWith(overlayColor: WidgetStatePropertyAll(overlay)),
    );
  }

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color hairlineColor,
    required Color focus,
    required Color label,
  }) {
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSm),
      borderSide: BorderSide(color: hairlineColor, width: 1),
    );
    final focused = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSm),
      borderSide: BorderSide(color: focus, width: 1.5),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      labelStyle: TextStyle(color: label, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: label.withValues(alpha: 0.72)),
      border: base,
      enabledBorder: base,
      focusedBorder: focused,
      errorBorder: base.copyWith(
        borderSide: const BorderSide(color: signalBad, width: 1.4),
      ),
      focusedErrorBorder: focused.copyWith(
        borderSide: const BorderSide(color: signalBad, width: 1.7),
      ),
    );
  }

  static ThemeData get darkTheme {
    const outline = Color(0xFF263540);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: graphite,
      primaryColor: clinicalTeal,
      canvasColor: graphite,
      dividerColor: Colors.white.withValues(alpha: 0.08),
      colorScheme: const ColorScheme.dark(
        primary: clinicalTeal,
        secondary: cardiacRose,
        tertiary: clinicalCyan,
        surface: darkSurface,
        onSurface: textLight,
        onPrimary: graphite,
        error: signalBad,
        outline: outline,
      ),
      textTheme: _buildTextTheme(textLight, textDimLight),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceElevated,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textLight,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15,
          height: 1.5,
          color: textDimLight,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurfaceElevated,
        modalBackgroundColor: darkSurfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textLight,
        ),
        iconTheme: const IconThemeData(color: textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedButtonStyle(
          background: clinicalTeal,
          foreground: graphite,
          disabledBackground: Colors.white.withValues(alpha: 0.10),
          disabledForeground: Colors.white.withValues(alpha: 0.38),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: clinicalTeal,
          foregroundColor: graphite,
          elevation: 0,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: _buttonText(graphite),
        ),
      ),
      outlinedButtonTheme: _outlinedButtonTheme(
        foreground: textLight,
        overlay: clinicalTeal.withValues(alpha: 0.10),
      ),
      textButtonTheme: _textButtonTheme(
        foreground: clinicalTeal,
        overlay: clinicalTeal.withValues(alpha: 0.10),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textLight,
          hoverColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: clinicalTeal.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXs),
          ),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: darkSurfaceElevated.withValues(alpha: 0.56),
        hairlineColor: Colors.white.withValues(alpha: 0.10),
        focus: clinicalTeal,
        label: textDimLight,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? graphite
              : textDimLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? clinicalTeal
              : Colors.white.withValues(alpha: 0.14);
        }),
        trackOutlineColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        selectedColor: clinicalTeal.withValues(alpha: 0.16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        labelStyle: const TextStyle(color: textLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textDimLight,
        textColor: textLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkSurfaceElevated,
        contentTextStyle: GoogleFonts.inter(
          color: textLight,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: darkSurfaceElevated,
          borderRadius: BorderRadius.circular(radiusXs),
        ),
        textStyle: const TextStyle(color: textLight, fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: clinicalTeal,
      ),
    );
  }

  static ThemeData get lightTheme {
    const outline = Color(0xFFD9E3E4);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: porcelain,
      primaryColor: clinicalTealDark,
      canvasColor: porcelain,
      dividerColor: outline,
      colorScheme: const ColorScheme.light(
        primary: clinicalTealDark,
        secondary: darkRose,
        tertiary: Color(0xFF347BB8),
        surface: lightSurface,
        onSurface: textDark,
        onPrimary: pureWhite,
        error: darkRose,
        outline: outline,
      ),
      textTheme: _buildTextTheme(textDark, textDimDark),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: pureWhite,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 15,
          height: 1.5,
          color: textDimDark,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: pureWhite,
        modalBackgroundColor: pureWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        iconTheme: const IconThemeData(color: textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _elevatedButtonStyle(
          background: clinicalTealDark,
          foreground: pureWhite,
          disabledBackground: const Color(0xFFE1EAEB),
          disabledForeground: const Color(0xFF77878D),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: clinicalTealDark,
          foregroundColor: pureWhite,
          elevation: 0,
          minimumSize: const Size(64, 46),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: _buttonText(pureWhite),
        ),
      ),
      outlinedButtonTheme: _outlinedButtonTheme(
        foreground: clinicalTealDark,
        overlay: clinicalTealDark.withValues(alpha: 0.08),
      ),
      textButtonTheme: _textButtonTheme(
        foreground: clinicalTealDark,
        overlay: clinicalTealDark.withValues(alpha: 0.08),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textDark,
          hoverColor: const Color(0xFFE8F0F1),
          highlightColor: clinicalTealDark.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXs),
          ),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: pureWhite,
        hairlineColor: outline,
        focus: clinicalTealDark,
        label: textDimDark,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? pureWhite
              : const Color(0xFF718187);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? clinicalTealDark
              : const Color(0xFFD7E1E3);
        }),
        trackOutlineColor: const WidgetStatePropertyAll(outline),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFEAF0F0),
        selectedColor: clinicalTealDark.withValues(alpha: 0.13),
        side: const BorderSide(color: outline),
        labelStyle: const TextStyle(color: textDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textDimDark,
        textColor: textDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textDark,
        contentTextStyle: GoogleFonts.inter(
          color: pureWhite,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textDark,
          borderRadius: BorderRadius.circular(radiusXs),
        ),
        textStyle: const TextStyle(color: pureWhite, fontSize: 12),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: clinicalTealDark,
      ),
    );
  }
}
