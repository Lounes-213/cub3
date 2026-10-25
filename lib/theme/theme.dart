import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColor {
  // Premium Emerald Green - Light Pro Store Theme
  static const Color primaryColor = Color(0xFF00B761); // Soft Premium Green
  static const Color secondaryColor = Color(0xFF10D976); // Lighter Emerald
  static const Color backgroundColor =
      Color(0xFF0A1F12); // Much lighter dark green (not pitch black)
  static const Color surfaceColor = Color(0xFF13301E); // Soft deep green card
  static const Color cardLight = Color(0xFF1A3D2A); // Lighter card inner
  static const Color accentColor = Color(0xFF69F0AE);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB7DCC8); // Soft grey-green
  static const Color textMuted = Color(0xFF7A9D8A); // Muted label text

  static const Color correctColor = Color(0xFF00E676);
  static const Color wrongColor = Color(0xFFFF5252);
  static const Color warningColor = Color(0xFFFFC107);

  // Dynamic context-aware color helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getTextPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black87;

  static Color getTextSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? textSecondary
          : Colors.black54;

  static Color getTextMuted(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white38
          : Colors.black38;

  static Color getSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceColor
          : Colors.white;

  static Color getCardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? surfaceColor
          : Colors.white;

  static Color getBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08);

  static Color getScaffoldBg(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  // Team Identity Colors
  static const List<Color> teamColors = [
    Color(0xFFE91E63), // Pink (Wardi)
    Color(0xFF0D47A1), // Dark Blue (Azrek Hamiq)
    Color(0xFF03A9F4), // Light Blue (Azraq Fatih)
    Color(0xFF00E676), // Green (Akhdar)
    Color(0xFFFFD600), // Yellow (Asfar)
  ];
}

class IconHelper {
  static IconData getIconFromCode(
    int? codePoint, {
    IconData fallback = Icons.groups,
  }) {
    if (codePoint == null) return fallback;
    if (codePoint == Icons.bolt.codePoint) return Icons.bolt;
    if (codePoint == Icons.rocket_launch.codePoint) return Icons.rocket_launch;
    if (codePoint == Icons.shield.codePoint) return Icons.shield;
    if (codePoint == Icons.auto_awesome.codePoint) return Icons.auto_awesome;
    if (codePoint == Icons.diamond.codePoint) return Icons.diamond;
    if (codePoint == Icons.fort.codePoint) return Icons.fort;
    if (codePoint == Icons.workspace_premium.codePoint) {
      return Icons.workspace_premium;
    }
    if (codePoint == Icons.local_fire_department.codePoint) {
      return Icons.local_fire_department;
    }
    if (codePoint == Icons.person.codePoint) return Icons.person;
    if (codePoint == Icons.groups.codePoint) return Icons.groups;

    return fallback;
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColor.backgroundColor,
      primaryColor: AppColor.primaryColor,
      cardColor: AppColor.surfaceColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColor.surfaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColor.surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColor.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColor.primaryColor,
        secondary: AppColor.secondaryColor,
        surface: AppColor.surfaceColor,
        error: AppColor.wrongColor,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.tajawalTextTheme().copyWith(
        displayLarge: GoogleFonts.tajawal(
          color: AppColor.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.tajawal(
          color: AppColor.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.tajawal(
          color: AppColor.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.tajawal(
          color: AppColor.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.tajawal(color: AppColor.textPrimary),
        bodyMedium: GoogleFonts.tajawal(color: AppColor.textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColor.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColor.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColor.primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: AppColor.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primaryColor,
          foregroundColor: AppColor.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          elevation: 8,
          shadowColor: AppColor.primaryColor.withValues(alpha: 0.4),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColor.primaryColor),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F9F6),
      primaryColor: AppColor.primaryColor,
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColor.primaryColor,
        secondary: AppColor.secondaryColor,
        surface: Colors.white,
        error: AppColor.wrongColor,
        onSurface: Colors.black87,
      ),
      textTheme: GoogleFonts.tajawalTextTheme().copyWith(
        displayLarge: GoogleFonts.tajawal(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.tajawal(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.tajawal(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.tajawal(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.tajawal(color: Colors.black87),
        bodyMedium: GoogleFonts.tajawal(color: Colors.black54),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColor.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColor.primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          elevation: 4,
          shadowColor: AppColor.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColor.primaryColor),
    );
  }
}
