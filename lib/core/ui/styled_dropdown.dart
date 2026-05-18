import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

/// A production-grade dropdown replacement for Flutter's default [DropdownButton].
///
/// Uses [PopupMenuButton] internally to render a beautifully styled popup
/// with glassmorphism border, rounded corners, and proper shadows — replacing
/// the ugly default overlay that DropdownButton produces.
///
/// Usage:
/// ```dart
/// StyledDropdown<String>(
///   value: _selectedSort,
///   items: ['Latest', 'Popular', 'A-Z'],
///   labelBuilder: (item) => item,
///   onChanged: (val) => setState(() => _selectedSort = val),
/// )
/// ```
class StyledDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;
  final IconData? icon;
  final double? width;

  const StyledDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: colors.sheetBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.cardBorder, width: 1),
          ),
        ),
      ),
      child: PopupMenuButton<T>(
        onSelected: onChanged,
        offset: const Offset(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(minWidth: width ?? 200, maxWidth: width ?? 280),
        itemBuilder: (context) {
          return [
            PopupMenuItem<T>(
              height: 8, // Top padding
              enabled: false,
              child: const SizedBox.shrink(),
            ),
            ...items.map((item) {
              final isSelected = item == value;
              return PopupMenuItem<T>(
                value: item,
                padding: EdgeInsets.zero,
                height: 48,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? LiquidTheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelBuilder(item),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? LiquidTheme.primary : colors.textTitle,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: LiquidTheme.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),
            PopupMenuItem<T>(
              height: 8, // Bottom padding
              enabled: false,
              child: const SizedBox.shrink(),
            ),
          ];
        },
          child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.searchBarBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.searchBarBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: colors.textCaption),
              const SizedBox(width: 10),
            ],
            Text(
              labelBuilder(value),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textTitle,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.unfold_more_rounded,
              size: 18,
              color: colors.textCaption,
            ),
          ],
        ),
      ),
    ),
  );
  }
}
