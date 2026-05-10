import 'package:flutter/material.dart';

/// Semantic color tokens that adapt automatically between Light and Dark mode.
///
/// Usage:
/// ```dart
/// final colors = Theme.of(context).extension<LiquidColors>()!;
/// Container(color: colors.cardBackground);
/// Text('Hello', style: TextStyle(color: colors.textTitle));
/// ```
///
/// Registered in `LiquidTheme.lightTheme` and `LiquidTheme.darkTheme`
/// via the `extensions` parameter.
class LiquidColors extends ThemeExtension<LiquidColors> {
  // Card / Surface
  final Color cardBackground;
  final Color cardBorder;

  // Text
  final Color textTitle;
  final Color textBody;
  final Color textCaption;

  // Search Bar
  final Color searchBarBackground;
  final Color searchBarBorder;
  final Color searchBarHint;

  // Header Actions
  final Color headerActionBackground;
  final Color headerActionBorder;

  // Sheets / Dialogs
  final Color sheetBackground;
  final Color dialogBackground;

  // Glass
  final Color glassOverlay;
  final Color glassBorder;

  // Divider
  final Color divider;

  // Chips / Tags
  final Color chipBackground;
  final Color chipSelectedBackground;
  final Color chipText;

  // Button
  final Color secondaryButtonBackground;
  final Color secondaryButtonText;

  // Input
  final Color inputBackground;
  final Color inputBorder;

  // Dock / Navigation
  final Color dockBackground;
  final Color dockBorder;
  final Color dockItemActive;
  final Color dockItemInactive;

  const LiquidColors({
    required this.cardBackground,
    required this.cardBorder,
    required this.textTitle,
    required this.textBody,
    required this.textCaption,
    required this.searchBarBackground,
    required this.searchBarBorder,
    required this.searchBarHint,
    required this.headerActionBackground,
    required this.headerActionBorder,
    required this.sheetBackground,
    required this.dialogBackground,
    required this.glassOverlay,
    required this.glassBorder,
    required this.divider,
    required this.chipBackground,
    required this.chipSelectedBackground,
    required this.chipText,
    required this.secondaryButtonBackground,
    required this.secondaryButtonText,
    required this.inputBackground,
    required this.inputBorder,
    required this.dockBackground,
    required this.dockBorder,
    required this.dockItemActive,
    required this.dockItemInactive,
  });

  /// Light mode palette — Aurora / Glass aesthetic.
  factory LiquidColors.light() => const LiquidColors(
        // Card
        cardBackground: Color(0xCCFFFFFF), // white 80%
        cardBorder: Color(0x80FFFFFF), // white 50%
        // Text
        textTitle: Color(0xFF0F172A), // Slate 900
        textBody: Color(0xFF334155), // Slate 700
        textCaption: Color(0xFF64748B), // Slate 500
        // Search
        searchBarBackground: Color(0x99FFFFFF), // white 60%
        searchBarBorder: Color(0xCCFFFFFF), // white 80%
        searchBarHint: Color(0x8064748B), // Slate 500 50%
        // Header Actions
        headerActionBackground: Color(0xCCFFFFFF), // white 80%
        headerActionBorder: Color(0x80FFFFFF), // white 50%
        // Sheets
        sheetBackground: Colors.white,
        dialogBackground: Colors.white,
        // Glass
        glassOverlay: Color(0x33FFFFFF), // white 20%
        glassBorder: Color(0x26FFFFFF), // white 15%
        // Divider
        divider: Color(0x26808080), // grey 15%
        // Chips
        chipBackground: Color(0xFFF1F5F9), // Slate 100
        chipSelectedBackground: Color(0xFF6366F1), // Primary
        chipText: Color(0xFF64748B), // Slate 500
        // Button
        secondaryButtonBackground: Color(0xFFF1F5F9), // Slate 100
        secondaryButtonText: Color(0xFF334155), // Slate 700
        // Input
        inputBackground: Color(0x99FFFFFF), // white 60%
        inputBorder: Color(0xFFE2E8F0), // Slate 200
        // Dock
        dockBackground: Color(0xE6FFFFFF), // white 90%
        dockBorder: Color(0x80FFFFFF), // white 50%
        dockItemActive: Color(0xFF6366F1), // Primary
        dockItemInactive: Color(0xFF94A3B8), // Slate 400
      );

  /// Dark mode palette — Deep Slate + Glass.
  factory LiquidColors.dark() => const LiquidColors(
        // Card
        cardBackground: Color(0x991E293B), // Slate 800 60%
        cardBorder: Color(0x1AFFFFFF), // white 10%
        // Text
        textTitle: Color(0xFFF8FAFC), // Slate 50
        textBody: Color(0xFFCBD5E1), // Slate 300
        textCaption: Color(0xFF94A3B8), // Slate 400
        // Search
        searchBarBackground: Color(0x661E293B), // Slate 800 40%
        searchBarBorder: Color(0x1AFFFFFF), // white 10%
        searchBarHint: Color(0x8094A3B8), // Slate 400 50%
        // Header Actions
        headerActionBackground: Color(0x991E293B), // Slate 800 60%
        headerActionBorder: Color(0x1AFFFFFF), // white 10%
        // Sheets
        sheetBackground: Color(0xFF0F172A), // Slate 900
        dialogBackground: Color(0xFF1E293B), // Slate 800
        // Glass
        glassOverlay: Color(0x660F172A), // Slate 900 40%
        glassBorder: Color(0x1AFFFFFF), // white 10%
        // Divider
        divider: Color(0x14FFFFFF), // white 8%
        // Chips
        chipBackground: Color(0xFF1E293B), // Slate 800
        chipSelectedBackground: Color(0xFF6366F1), // Primary
        chipText: Color(0xFF94A3B8), // Slate 400
        // Button
        secondaryButtonBackground: Color(0xFF1E293B), // Slate 800
        secondaryButtonText: Color(0xFFCBD5E1), // Slate 300
        // Input
        inputBackground: Color(0x661E293B), // Slate 800 40%
        inputBorder: Color(0x1AFFFFFF), // white 10%
        // Dock
        dockBackground: Color(0xE60F172A), // Slate 900 90%
        dockBorder: Color(0x1AFFFFFF), // white 10%
        dockItemActive: Color(0xFF818CF8), // Indigo 400
        dockItemInactive: Color(0xFF64748B), // Slate 500
      );

  @override
  LiquidColors copyWith({
    Color? cardBackground,
    Color? cardBorder,
    Color? textTitle,
    Color? textBody,
    Color? textCaption,
    Color? searchBarBackground,
    Color? searchBarBorder,
    Color? searchBarHint,
    Color? headerActionBackground,
    Color? headerActionBorder,
    Color? sheetBackground,
    Color? dialogBackground,
    Color? glassOverlay,
    Color? glassBorder,
    Color? divider,
    Color? chipBackground,
    Color? chipSelectedBackground,
    Color? chipText,
    Color? secondaryButtonBackground,
    Color? secondaryButtonText,
    Color? inputBackground,
    Color? inputBorder,
    Color? dockBackground,
    Color? dockBorder,
    Color? dockItemActive,
    Color? dockItemInactive,
  }) {
    return LiquidColors(
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      textTitle: textTitle ?? this.textTitle,
      textBody: textBody ?? this.textBody,
      textCaption: textCaption ?? this.textCaption,
      searchBarBackground: searchBarBackground ?? this.searchBarBackground,
      searchBarBorder: searchBarBorder ?? this.searchBarBorder,
      searchBarHint: searchBarHint ?? this.searchBarHint,
      headerActionBackground:
          headerActionBackground ?? this.headerActionBackground,
      headerActionBorder: headerActionBorder ?? this.headerActionBorder,
      sheetBackground: sheetBackground ?? this.sheetBackground,
      dialogBackground: dialogBackground ?? this.dialogBackground,
      glassOverlay: glassOverlay ?? this.glassOverlay,
      glassBorder: glassBorder ?? this.glassBorder,
      divider: divider ?? this.divider,
      chipBackground: chipBackground ?? this.chipBackground,
      chipSelectedBackground:
          chipSelectedBackground ?? this.chipSelectedBackground,
      chipText: chipText ?? this.chipText,
      secondaryButtonBackground:
          secondaryButtonBackground ?? this.secondaryButtonBackground,
      secondaryButtonText: secondaryButtonText ?? this.secondaryButtonText,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      dockBackground: dockBackground ?? this.dockBackground,
      dockBorder: dockBorder ?? this.dockBorder,
      dockItemActive: dockItemActive ?? this.dockItemActive,
      dockItemInactive: dockItemInactive ?? this.dockItemInactive,
    );
  }

  @override
  LiquidColors lerp(covariant LiquidColors? other, double t) {
    if (other == null) return this;
    return LiquidColors(
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textTitle: Color.lerp(textTitle, other.textTitle, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textCaption: Color.lerp(textCaption, other.textCaption, t)!,
      searchBarBackground:
          Color.lerp(searchBarBackground, other.searchBarBackground, t)!,
      searchBarBorder:
          Color.lerp(searchBarBorder, other.searchBarBorder, t)!,
      searchBarHint: Color.lerp(searchBarHint, other.searchBarHint, t)!,
      headerActionBackground: Color.lerp(
          headerActionBackground, other.headerActionBackground, t)!,
      headerActionBorder:
          Color.lerp(headerActionBorder, other.headerActionBorder, t)!,
      sheetBackground:
          Color.lerp(sheetBackground, other.sheetBackground, t)!,
      dialogBackground:
          Color.lerp(dialogBackground, other.dialogBackground, t)!,
      glassOverlay: Color.lerp(glassOverlay, other.glassOverlay, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      chipBackground: Color.lerp(chipBackground, other.chipBackground, t)!,
      chipSelectedBackground: Color.lerp(
          chipSelectedBackground, other.chipSelectedBackground, t)!,
      chipText: Color.lerp(chipText, other.chipText, t)!,
      secondaryButtonBackground: Color.lerp(
          secondaryButtonBackground, other.secondaryButtonBackground, t)!,
      secondaryButtonText:
          Color.lerp(secondaryButtonText, other.secondaryButtonText, t)!,
      inputBackground:
          Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      dockBackground:
          Color.lerp(dockBackground, other.dockBackground, t)!,
      dockBorder: Color.lerp(dockBorder, other.dockBorder, t)!,
      dockItemActive:
          Color.lerp(dockItemActive, other.dockItemActive, t)!,
      dockItemInactive:
          Color.lerp(dockItemInactive, other.dockItemInactive, t)!,
    );
  }
}
