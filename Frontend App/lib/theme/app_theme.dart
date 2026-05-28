import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HillSafe AI App Theme
/// Modern Disaster Management Design System
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ===== COLOR PALETTE =====
  
  /// Primary: Deep Navy Blue - Authority and Stability
  static const Color primaryColor = Color(0xFF1E293B);
  
  /// Surface: Clean White
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  /// Surface: Light Slate Grey
  static const Color surfaceGrey = Color(0xFFF8FAFC);
  
  /// Accent Gradient: Blue to Cyan
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  /// Accent Blue - Primary accent color
  static const Color accentBlue = Color(0xFF3B82F6);
  
  /// Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnDark = Color(0xFFFFFFFF);
  
  // ===== SIZING =====
  
  /// Border Radius for Cards
  static const double cardRadius = 20.0;
  
  /// Spacing Units
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  // ===== SHADOWS =====
  
  /// Soft Shadow for Cards
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Elevated Shadow (for hover/active states)
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];
  
  // ===== THEME DATA =====
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: const Color(0xFF3B82F6),
        surface: surfaceWhite,
        background: surfaceGrey,
        onPrimary: textOnDark,
        onSecondary: textOnDark,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      
      // Typography
      textTheme: TextTheme(
        // Headers - Poppins
        displayLarge: GoogleFonts.poppins(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        
        // Body - Inter
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          height: 1.5,
        ),
        
        // Labels - Inter
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        color: surfaceWhite,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
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
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: textOnDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textOnDark,
        ),
        iconTheme: const IconThemeData(color: textOnDark),
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: surfaceGrey,
    );
  }
  
  // ===== DARK THEME =====
  
  static ThemeData get darkTheme {
    const Color darkBackground = Color(0xFF121212); // True Black/Dark
    const Color darkSurface = Color(0xFF1E1E1E); // Lighter Black
    const Color darkCard = Color(0xFF2C2C2C); // Card background
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF3B82F6),
        secondary: const Color(0xFF06B6D4),
        surface: darkSurface,
        background: darkBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),
      
      // Typography
      textTheme: TextTheme(
        // Headers - Poppins
        displayLarge: GoogleFonts.poppins(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        
        // Body - Inter
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.white,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF94A3B8),
          height: 1.5,
        ),
        
        // Labels - Inter
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF94A3B8),
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        color: darkCard,
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
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
      
      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      // Scaffold Background
      scaffoldBackgroundColor: darkBackground,
    );
  }
  
  // ===== CUSTOM DECORATIONS =====
  
  /// Bento Grid Card Decoration (Light)
  static BoxDecoration get bentoCardLight => BoxDecoration(
    color: surfaceWhite,
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: cardShadow,
  );
  
  /// Bento Grid Card Decoration (Dark)
  static BoxDecoration get bentoCardDark => BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: cardShadow,
  );
  
  /// Glassmorphism Effect
  static BoxDecoration get glassmorphism => BoxDecoration(
    color: surfaceWhite.withOpacity(0.7),
    borderRadius: BorderRadius.circular(cardRadius),
    border: Border.all(
      color: Colors.white.withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
  
  /// Gradient Container Decoration
  static BoxDecoration get gradientCard => BoxDecoration(
    gradient: accentGradient,
    borderRadius: BorderRadius.circular(cardRadius),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF3B82F6).withOpacity(0.3),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ],
  );

  /// Standard Input Decoration
  static InputDecoration inputDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
      contentPadding: const EdgeInsets.all(spacingMedium),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF3B82F6) : primaryColor,
          width: 2,
        ),
      ),
    );
  }
}

