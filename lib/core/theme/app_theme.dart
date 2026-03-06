import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme system supporting Light and AMOLED modes
/// with high-contrast, premium color palettes
class AppTheme {
  AppTheme._();

  // ══════════════════════════════════════════════════
  // COLOR PALETTES
  // ══════════════════════════════════════════════════

  // Brand colors
  static const Color _primaryColor = Color(0xFFFFC107); // Amber/Yellow
  static const Color _primaryDark = Color(0xFFE5A800);  // Deeper amber for light theme
  static const Color _accentColor = Color(0xFF5C6BC0);

  // ── Light theme: off-white color palette ───────────
  static const Color _lightBackground = Color(0xFFFAF9F6);   // Off-white / ivory
  static const Color _lightSurface = Color(0xFFFFFEFB);      // Warm white surface
  static const Color _lightCard = Color(0xFFFFFFFF);          // Pure white cards
  static const Color _lightText = Color(0xFF1C1C1E);          // iOS-style near-black
  static const Color _lightTextSecondary = Color(0xFF636366); // Medium gray
  static const Color _lightDivider = Color(0xFFE8E6E1);      // Soft warm divider
  static const Color _lightNavBar = Color(0xFFFAF9F6);       // Matches background

  // ── AMOLED theme: pure black with high contrast ───
  static const Color _amoledBackground = Color(0xFF000000);   // Pure black
  static const Color _amoledSurface = Color(0xFF0D0D0D);     // Near-black surface
  static const Color _amoledCard = Color(0xFF141414);         // Slightly lifted cards
  static const Color _amoledText = Color(0xFFF5F5F5);        // Soft white (less harsh)
  static const Color _amoledTextSecondary = Color(0xFF8C8C8C); // Mid-gray for contrast
  static const Color _amoledDivider = Color(0xFF262626);      // Visible dark divider
  static const Color _amoledNavBar = Color(0xFF080808);       // Near-black nav bar

  // Note tag/highlight colors
  static const List<Color> noteColors = [
    Color(0xFFFFF3E0), // Orange
    Color(0xFFFCE4EC), // Pink
    Color(0xFFE8F5E9), // Green
    Color(0xFFE3F2FD), // Blue
    Color(0xFFF3E5F5), // Purple
    Color(0xFFFFFDE7), // Yellow
    Color(0xFFE0F7FA), // Teal
    Color(0xFFFBE9E7), // Deep Orange
  ];

  // ══════════════════════════════════════════════════
  // TEXT THEME
  // ══════════════════════════════════════════════════

  static TextTheme _buildTextTheme(Color textColor, Color secondaryTextColor) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
        letterSpacing: 0.5,
      ),
    );
  }

  // ══════════════════════════════════════════════════
  // THEME DATA
  // ══════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: _primaryDark,
        onPrimary: _lightText,
        secondary: _accentColor,
        onSecondary: Colors.white,
        surface: _lightSurface,
        onSurface: _lightText,
        error: const Color(0xFFD32F2F),
      ),
      scaffoldBackgroundColor: _lightBackground,
      textTheme: _buildTextTheme(_lightText, _lightTextSecondary),
      cardTheme: CardThemeData(
        color: _lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _lightDivider.withValues(alpha: 0.6)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _lightBackground,
        foregroundColor: _lightText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _lightText,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _lightNavBar,
        selectedItemColor: _primaryDark,
        unselectedItemColor: _lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerColor: _lightDivider,
      dividerTheme: DividerThemeData(color: _lightDivider, thickness: 0.5),
      chipTheme: ChipThemeData(
        backgroundColor: _lightSurface,
        selectedColor: _primaryDark.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2D2D2D),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconTheme: const IconThemeData(
        color: _lightText,
        size: 24,
      ),
    );
  }

  static ThemeData get amoledTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        onPrimary: Colors.black,
        secondary: _accentColor,
        onSecondary: Colors.white,
        surface: _amoledSurface,
        onSurface: _amoledText,
        error: const Color(0xFFFF6B6B),
      ),
      scaffoldBackgroundColor: _amoledBackground,
      textTheme: _buildTextTheme(_amoledText, _amoledTextSecondary),
      cardTheme: CardThemeData(
        color: _amoledCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _amoledDivider.withValues(alpha: 0.5)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _amoledBackground,
        foregroundColor: _amoledText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _amoledText,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _amoledNavBar,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _amoledTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _amoledSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _amoledDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _amoledDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerColor: _amoledDivider,
      dividerTheme: DividerThemeData(color: _amoledDivider, thickness: 0.5),
      chipTheme: ChipThemeData(
        backgroundColor: _amoledSurface,
        selectedColor: _primaryColor.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        contentTextStyle: GoogleFonts.inter(
          color: _amoledText,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      iconTheme: const IconThemeData(
        color: _amoledText,
        size: 24,
      ),
    );
  }
}
