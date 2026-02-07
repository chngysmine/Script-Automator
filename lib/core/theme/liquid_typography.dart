import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'liquid_theme.dart';

/// Typography System for Liquid Motion Design.
/// Uses 'Inter' for a clean, modern, and highly readable look.
/// Features carefully tuned letter spacing and line heights.
class LiquidTypography {
  static TextTheme get textTheme {
    return TextTheme(
      // Headlines (Hero usage)
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        height: 1.12,
        letterSpacing: -0.25,
        color: LiquidTheme.textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        height: 1.16,
        letterSpacing: 0,
        color: LiquidTheme.textPrimary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.22,
        letterSpacing: 0,
        color: LiquidTheme.textPrimary,
      ),

      // Titles (Section Headers)
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.27,
        letterSpacing: 0,
        color: LiquidTheme.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        letterSpacing: 0.15,
        color: LiquidTheme.textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
        color: LiquidTheme.textSecondary,
      ),

      // Body (Reading text)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.5,
        color: LiquidTheme.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.25,
        color: LiquidTheme.textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.4,
        color: LiquidTheme.textSecondary,
      ),

      // Code (Editor specific - using Monospace fallback)
      labelLarge: GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: LiquidTheme.textPrimary,
      ),
    );
  }
}
