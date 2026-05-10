import 'package:flutter/material.dart';
import 'liquid_typography.dart';
import 'liquid_colors.dart';

/// The Liquid Design System Theme (2026 Edition).
/// Defines the semantic color palette and visual properties for the "Liquid Motion" aesthetic.
/// Uses HSL for fluid color adjustments.
class LiquidTheme {
  // --- 2026 Liquid Palette ---
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFFA855F7); // Purple
  static const Color accent = Color(0xFFEC4899); // Pink
  static const Color cyan = Color(0xFF06B6D4);

  // --- 2026 Liquid Colors (Standardized) ---
  static const Color textDeep = Color(0xFF0F172A); // Slate 900
  static const Color textMedium = Color(0xFF334155); // Slate 700
  static const Color textLight = Color(0xFF64748B); // Slate 500

  // Backgrounds
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50

  // Glass
  static const Color glassLow = Color(0x1AFFFFFF); // 10% White
  static const Color glassHigh = Color(0x33FFFFFF); // 20% White
  static const Color glassBorder = Color(0x4DFFFFFF); // 30% White

  // Primary Gradient (for buttons, overlays)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  // --- Gradients ---
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC4B5FD), // Violet 300
      Color(0xFFA5F3FC), // Cyan 200
      Color(0xFFFBCFE8), // Pink 200
      Color(0xFFFFFFFF), // White
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  static const LinearGradient darkAuroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF312E81), // Indigo 900
      Color(0xFF4C1D95), // Violet 900
      Color(0xFF831843), // Pink 900
    ],
  );

  static const LinearGradient brandDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A), // Slate 900
      Color(0xFF334155), // Slate 700
    ],
  );

  static const LinearGradient roseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF7ED), // Orange 50
      Color(0xFFFFE4E6), // Rose 100
      Color(0xFFFCE7F3), // Pink 100
      Colors.white, // Pure White
    ],
    stops: [0.0, 0.4, 0.7, 1.0],
  );

  // --- Legacy Compatibility (Mapped to 2026 Design) ---
  static const Color textPrimary = Color(0xFFF8FAFC); // White/Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color surface = glassLow;
  static const Color surfaceHighlight = glassHigh;
  static const Color background = darkBackground;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // --- Standardized Page Layout Tokens ---
  static const double pageHorizontalPadding = 20.0;
  static const double sectionGap = 24.0;
  static const double searchBarHeight = 52.0;

  // --- Standardized Typography Sizes ---
  static const double fontPageTitle = 28.0;
  static const double fontSectionTitle = 18.0;
  static const double fontBody = 15.0;
  static const double fontCaption = 12.0;
  static const double fontSmall = 11.0;

  // Radii
  static const Radius radiusS = Radius.circular(8);
  static const Radius radiusM = Radius.circular(16);
  static const Radius radiusL = Radius.circular(24);
  static const Radius radiusXL = Radius.circular(32);

  // --- Glassmorphism Helpers ---
  static final BoxDecoration glassDecoration = BoxDecoration(
    color: glassLow,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: glassBorder, width: 1.5),
    boxShadow: [
      BoxShadow(
        color: const Color(0x1A000000), // 10% Black
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Returns the main ThemeData for the app.
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBackground,
      cardColor: const Color(
        0xFF1E293B,
      ).withValues(alpha: 0.6), // Slate 800 + Opacity
      fontFamily: 'Inter',
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: Colors.transparent, // Important for glass
        error: Color(0xFFFF754C),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: LiquidTypography.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      extensions: [LiquidColors.dark()],
    );
  }

  /// Returns the "Liquid Glass" Light Theme (Aurora).
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: Colors.white, // Handled by Container Gradient
      cardColor: Colors.white.withValues(alpha: 0.6),
      fontFamily: 'Inter',
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: Colors.transparent, // Important for glass
        onSurface: Color(0xFF1E293B), // Slate 800
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      extensions: [LiquidColors.light()],
    );
  }
}
