import 'dart:io';

import 'package:flutter/material.dart';
import '../../domain/entities/widget_node.dart';
import '../../domain/entities/widget_type.dart';
import '../../domain/entities/sasup_modifiers.dart';

class SasupRenderer extends StatelessWidget {
  final WidgetNode node;

  const SasupRenderer({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: _parseTextStyle(node.modifiers),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: 400, // Reference "Preview Isolate" size
            height: 400,
            child: _buildWidget(node, isRoot: true),
          ),
        ),
      ),
    );
  }

  Widget _buildWidget(WidgetNode node, {bool isRoot = false}) {
    Widget widget;

    switch (node.type) {
      case WidgetType.container:
      case WidgetType.column:
        final children =
            node.children?.map((c) {
              final w = _buildWidget(c, isRoot: false);
              final flex = c.modifiers?.flex;
              return (flex != null && flex > 0)
                  ? Flexible(flex: flex, fit: FlexFit.loose, child: w)
                  : w;
            }).toList() ??
            [];
        final spacing = node.modifiers?.spacing?.toDouble() ?? 0.0;

        widget = Column(
          mainAxisSize: isRoot ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: _parseCrossAxis(node.modifiers?.alignment),
          mainAxisAlignment: _parseMainAxis(node.modifiers?.alignment),
          children: _applySpacing(children, spacing, Axis.vertical),
        );
        break;
      case WidgetType.row:
        final children =
            node.children?.map((c) {
              final w = _buildWidget(c, isRoot: false);
              final flex = c.modifiers?.flex;
              return (flex != null && flex > 0)
                  ? Flexible(flex: flex, fit: FlexFit.loose, child: w)
                  : w;
            }).toList() ??
            [];
        final spacing = node.modifiers?.spacing?.toDouble() ?? 0.0;

        widget = Row(
          mainAxisSize: isRoot ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: _parseCrossAxis(node.modifiers?.alignment),
          mainAxisAlignment: _parseMainAxis(node.modifiers?.alignment),
          children: _applySpacing(children, spacing, Axis.horizontal),
        );
        break;
      case WidgetType.stack:
        widget = Stack(
          alignment: Alignment.center,
          children:
              node.children
                  ?.map((c) => _buildWidget(c, isRoot: false))
                  .toList() ??
              [],
        );
        break;
      case WidgetType.text:
        widget = Text(
          node.content ?? "",
          textAlign: _parseTextAlign(node.modifiers?.alignment),
          style: _parseTextStyle(node.modifiers),
        );
        break;
      case WidgetType.icon:
        widget = Icon(
          _parseIconData(node.content),
          size: node.modifiers?.fontSize ?? 24.0,
          color: _parseColor(node.modifiers?.color ?? "#FFFFFF"),
        );
        break;
      case WidgetType.image:
        if (node.content != null && node.content!.startsWith("file://")) {
          final path = node.content!.replaceFirst("file://", "");
          widget = Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.withAlpha(50),
              child: const Center(
                child: Icon(Icons.error, color: Colors.white24),
              ),
            ),
          );
        } else {
          widget = Container(color: Colors.grey.withAlpha(50));
        }
        break;
      case WidgetType.spacer:
        final mods = node.modifiers;
        if (mods?.width != null || mods?.height != null) {
          widget = SizedBox(
            width: mods?.width?.toDouble(),
            height: mods?.height?.toDouble(),
          );
        } else {
          widget = const Spacer();
        }
        break;
      default:
        widget = const SizedBox.shrink();
    }

    // Apply basic modifiers (padding, size, background)
    widget = _applyModifiers(widget, node.modifiers ?? const SASUPModifiers());

    return widget;
  }

  Widget _applyModifiers(Widget child, SASUPModifiers? mods) {
    if (mods == null) return child;
    Widget w = child;

    if (mods.padding != null) {
      final p = mods.padding!;
      w = Padding(
        padding: EdgeInsets.only(
          left: p.left,
          top: p.top,
          right: p.right,
          bottom: p.bottom,
        ),
        child: w,
      );
    }

    if (mods.width != null || mods.height != null) {
      w = SizedBox(width: mods.width, height: mods.height, child: w);
    }

    if (mods.background != null || mods.cornerRadius != null) {
      final bg = mods.background;
      BoxDecoration decoration;
      if (bg != null && bg.startsWith("linear-gradient")) {
        final colors = _extractColors(bg);
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: colors.isNotEmpty ? colors : [Colors.purple, Colors.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: mods.cornerRadius != null
              ? BorderRadius.circular(mods.cornerRadius!)
              : null,
        );
      } else {
        decoration = BoxDecoration(
          color: _parseColor(bg),
          borderRadius: mods.cornerRadius != null
              ? BorderRadius.circular(mods.cornerRadius!)
              : null,
        );
      }
      w = Container(decoration: decoration, child: w);
    }

    if (mods.clickAction != null) {
      w = GestureDetector(
        onTap: () {
          debugPrint("Action Triggered in Preview: ${mods.clickAction?.type}");
          // Show a small feedback snackbar or toast in the preview
        },
        child: w,
      );
    }

    return w;
  }

  List<Widget> _applySpacing(List<Widget> children, double spacing, Axis axis) {
    if (spacing <= 0 || children.length <= 1) return children;

    final List<Widget> spaced = [];
    for (int i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i < children.length - 1) {
        spaced.add(
          axis == Axis.horizontal
              ? SizedBox(width: spacing)
              : SizedBox(height: spacing),
        );
      }
    }
    return spaced;
  }

  TextAlign _parseTextAlign(String? align) {
    if (align == 'center') return TextAlign.center;
    if (align == 'end') return TextAlign.end;
    return TextAlign.start;
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return Colors.transparent;
    if (colorStr.startsWith("#")) {
      try {
        String hex = colorStr.substring(1);
        if (hex.length == 8) {
          // AARRGGBB
          return Color(int.parse("0x$hex"));
        }
        if (hex.length == 6) hex = "FF$hex";
        return Color(int.parse("0x$hex"));
      } catch (_) {
        return Colors.transparent;
      }
    }
    return Colors.black;
  }

  TextStyle _parseTextStyle(SASUPModifiers? mods) {
    FontWeight weight = FontWeight.normal;
    if (mods?.font == "bold") weight = FontWeight.bold;
    if (mods?.font == "semibold") weight = FontWeight.w600;
    if (mods?.font == "light") weight = FontWeight.w300;

    return TextStyle(
      color: _parseColor(mods?.color ?? "#FFFFFF"),
      fontWeight: weight,
      fontSize: mods?.fontSize ?? 14.0,
      fontFamily: 'Inter',
      decoration: TextDecoration.none,
    );
  }

  IconData _parseIconData(String? iconName) {
    switch (iconName) {
      case 'moon.stars.fill':
        return Icons.nightlight_round;
      case 'sun.max.fill':
        return Icons.wb_sunny;
      case 'cloud.fill':
        return Icons.cloud;
      case 'cloud.sun.fill':
        return Icons.wb_cloudy;
      case 'location.fill':
        return Icons.location_on;
      case 'drop.fill':
        return Icons.water_drop;
      case 'wind':
        return Icons.air;
      case 'thermometer.medium':
        return Icons.thermostat;
      case 'arrow.clockwise':
        return Icons.refresh;
      case 'arrow.up':
        return Icons.arrow_upward;
      case 'arrow.down':
        return Icons.arrow_downward;
      default:
        return Icons.help_outline;
    }
  }

  CrossAxisAlignment _parseCrossAxis(String? align) {
    if (align == 'center') return CrossAxisAlignment.center;
    if (align == 'end') return CrossAxisAlignment.end;
    if (align == 'stretch') return CrossAxisAlignment.stretch;
    return CrossAxisAlignment.start;
  }

  MainAxisAlignment _parseMainAxis(String? align) {
    if (align == 'center') return MainAxisAlignment.center;
    if (align == 'spaceBetween') return MainAxisAlignment.spaceBetween;
    if (align == 'spaceAround') return MainAxisAlignment.spaceAround;
    return MainAxisAlignment.start;
  }

  List<Color> _extractColors(String input) {
    final RegExp regex = RegExp(r'#(?:[0-9a-fA-F]{3,8})');
    final matches = regex.allMatches(input);
    return matches.map((m) => _parseColor(m.group(0))).toList();
  }
}
