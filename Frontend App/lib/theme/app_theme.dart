import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// HillSafe AI — Clean Light Theme Design System
class AppTheme {
  AppTheme._();

  static bool isDark = false;

  // ===== LIGHT THEME CONSTANTS =====
  static const Color lightBackground = Color(0xFFF5F4F0);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextHint = Color(0xFF9CA3AF);
  static const Color lightBorderColor = Color(0xFFE5E7EB);

  // ===== COLOR PALETTE =====

  /// Warm paper-white background (matches screenshot)
  static Color get background => isDark ? const Color(0xFF0F172A) : lightBackground;

  /// Card / surface white
  static Color get surface => isDark ? const Color(0xFF1E293B) : lightSurface;

  /// Deep navy — authority card, appbar, dark elements
  static const Color primaryDark = Color(0xFF1E293B);

  /// Teal accent — matches mountain logo colors
  static const Color accentTeal = Color(0xFF2A7D6F);

  /// Lighter teal for secondary accents
  static const Color accentTealLight = Color(0xFFE8F5F2);

  /// Text — near black
  static Color get textPrimary => isDark ? const Color(0xFFF8FAFC) : lightTextPrimary;

  /// Text — grey subtitle
  static Color get textSecondary => isDark ? const Color(0xFF94A3B8) : lightTextSecondary;

  /// Text — light hint
  static Color get textHint => isDark ? const Color(0xFF64748B) : lightTextHint;

  /// Text on dark backgrounds
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Divider / border
  static Color get borderColor => isDark ? const Color(0xFF334155) : lightBorderColor;

  /// Success green
  static const Color success = Color(0xFF16A34A);

  /// Warning amber
  static const Color warning = Color(0xFFF59E0B);

  /// Danger red
  static const Color danger = Color(0xFFDC2626);

  // ===== LEGACY ALIASES (keeps old references working) =====
  static const Color primaryColor = primaryDark;
  static Color get surfaceWhite => surface;
  static Color get surfaceGrey => background;
  static const Color accentBlue = accentTeal;

  // ===== SIZING =====
  static const double cardRadius = 20.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // ===== SHADOWS =====

  /// Soft card shadow
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Elevated shadow
  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.10),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Teal glow shadow for buttons
  static List<BoxShadow> get tealShadow => [
        BoxShadow(
          color: accentTeal.withOpacity(0.30),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  // ===== LIGHT THEME =====

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accentTeal,
        secondary: primaryDark,
        surface: lightSurface,
        onPrimary: textOnDark,
        onSecondary: textOnDark,
        onSurface: lightTextPrimary,
        error: danger,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,

      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: lightTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: lightTextPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: lightTextPrimary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: lightTextSecondary,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightTextPrimary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: lightTextSecondary,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF0F172A),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFFF5F4F0),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        color: lightSurface,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: textOnDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingMedium,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: lightBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
        hintStyle: GoogleFonts.inter(color: lightTextHint, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: lightTextSecondary, fontSize: 14),
      ),

      // Icon theme
      iconTheme: IconThemeData(color: lightTextPrimary, size: 24),

      // Divider
      dividerColor: lightBorderColor,
    );
  }

  // ===== DARK THEME (keep for toggle support) =====
  static ThemeData get darkTheme {
    const Color darkBg = Color(0xFF0F172A);
    const Color darkSurface = Color(0xFF1E293B);
    const Color darkCard = Color(0xFF263347);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: accentTeal,
        secondary: Color(0xFF34D399),
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: danger,
      ),
      scaffoldBackgroundColor: darkBg,
      cardColor: darkCard,

      textTheme: TextTheme(
        headlineLarge: GoogleFonts.poppins(
            fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
        headlineMedium: GoogleFonts.poppins(
            fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
        headlineSmall: GoogleFonts.poppins(
            fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        titleLarge: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: GoogleFonts.inter(
            fontSize: 16, color: Colors.white, height: 1.5),
        bodyMedium: GoogleFonts.inter(
            fontSize: 14, color: Colors.white, height: 1.5),
        bodySmall: GoogleFonts.inter(
            fontSize: 12, color: const Color(0xFF94A3B8), height: 1.5),
        labelLarge: GoogleFonts.inter(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF0F172A),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF0F172A),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
              horizontal: spacingLarge, vertical: spacingMedium),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cardRadius)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentTeal, width: 2),
        ),
        hintStyle:
            GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14),
      ),

      iconTheme: const IconThemeData(color: Colors.white, size: 24),
      dividerColor: const Color(0xFF334155),
    );
  }

  // ===== DECORATIONS =====

  static BoxDecoration get bentoCardLight => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: cardShadow,
      );

  static BoxDecoration get bentoCardDark => BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: cardShadow,
      );

  static BoxDecoration get glassmorphism => BoxDecoration(
        color: surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
        boxShadow: cardShadow,
      );

  static BoxDecoration get gradientCard => BoxDecoration(
        gradient: const LinearGradient(
          colors: [accentTeal, Color(0xFF1A5C54)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: tealShadow,
      );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentTeal, Color(0xFF1A5C54)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static InputDecoration inputDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF263347) : surface,
      contentPadding: const EdgeInsets.all(spacingMedium),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accentTeal, width: 2),
      ),
    );
  }
}
