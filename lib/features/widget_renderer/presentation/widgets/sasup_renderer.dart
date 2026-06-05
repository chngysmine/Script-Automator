import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../../domain/entities/widget_node.dart';
import '../../domain/entities/widget_type.dart';
import '../../domain/entities/sasup_modifiers.dart';

class SasupRenderer extends StatelessWidget {
  final WidgetNode node;
  final String family;
  final void Function(String actionId)? onActionTriggered;
  final bool responsive;

  const SasupRenderer({
    super.key,
    required this.node,
    this.family = 'medium',
    this.onActionTriggered,
    this.responsive = false,
  });

  @override
  Widget build(BuildContext context) {
    double width = 155;
    double height = 155;

    if (family == 'medium') {
      width = 329;
      height = 155;
    } else if (family == 'large') {
      width = 329;
      height = 345;
    }

    final rootWidget = _buildWidget(node, path: 'root', isRoot: true);

    return ExcludeSemantics(
      key: const ValueKey('sasup_renderer_exclude_semantics'),
      excluding: true,
      child: Material(
        type: MaterialType.transparency,
        child: DefaultTextStyle(
          style: _parseTextStyle(node.modifiers),
          child: responsive
              ? SizedBox.expand(child: rootWidget)
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: rootWidget,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildWidget(WidgetNode node, {required String path, bool isRoot = false}) {
    Widget widget;

    switch (node.type) {
      case WidgetType.container:
        final children = <Widget>[];
        if (node.children != null) {
          for (int i = 0; i < node.children!.length; i++) {
            final childNode = node.children![i];
            final childPath = '${path}_c$i';
            final w = _buildWidget(childNode, path: childPath, isRoot: false);
            
            int? flex = childNode.modifiers?.flex;
            if (childNode.type == WidgetType.spacer &&
                flex == null &&
                childNode.modifiers?.width == null &&
                childNode.modifiers?.height == null) {
              flex = 1;
            }

            children.add(
              (flex != null && flex > 0)
                  ? Expanded(
                      key: ValueKey('${childPath}_flex'),
                      flex: flex,
                      child: w,
                    )
                  : w,
            );
          }
        }
        final spacing = node.modifiers?.spacing?.toDouble() ?? 0.0;

        widget = SizedBox(
          width: double.infinity,
          child: SafeColumn(
            key: ValueKey(node.id ?? '${path}_container_column'),
            mainAxisSize: isRoot ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: node.modifiers?.alignment != null
                ? _parseCrossAxis(node.modifiers?.alignment)
                : CrossAxisAlignment.stretch,
            mainAxisAlignment: _parseMainAxis(node.modifiers?.alignment),
            children: _applySpacing(children, spacing, Axis.vertical, path),
          ),
        );
        break;

      case WidgetType.column:
        final children = <Widget>[];
        if (node.children != null) {
          for (int i = 0; i < node.children!.length; i++) {
            final childNode = node.children![i];
            final childPath = '${path}_c$i';
            final w = _buildWidget(childNode, path: childPath, isRoot: false);
            
            int? flex = childNode.modifiers?.flex;
            if (childNode.type == WidgetType.spacer &&
                flex == null &&
                childNode.modifiers?.width == null &&
                childNode.modifiers?.height == null) {
              flex = 1;
            }

            children.add(
              (flex != null && flex > 0)
                  ? Expanded(
                      key: ValueKey('${childPath}_flex'),
                      flex: flex,
                      child: w,
                    )
                  : w,
            );
          }
        }
        final spacing = node.modifiers?.spacing?.toDouble() ?? 0.0;

        widget = SizedBox(
          width: double.infinity,
          child: SafeColumn(
            key: ValueKey(node.id ?? '${path}_column'),
            mainAxisSize: isRoot ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: node.modifiers?.alignment != null
                ? _parseCrossAxis(node.modifiers?.alignment)
                : CrossAxisAlignment.stretch,
            mainAxisAlignment: _parseMainAxis(node.modifiers?.alignment),
            children: _applySpacing(children, spacing, Axis.vertical, path),
          ),
        );
        break;
      case WidgetType.row:
        final children = <Widget>[];
        if (node.children != null) {
          for (int i = 0; i < node.children!.length; i++) {
            final childNode = node.children![i];
            final childPath = '${path}_r$i';
            final w = _buildWidget(childNode, path: childPath, isRoot: false);
            
            int? flex = childNode.modifiers?.flex;
            if (childNode.type == WidgetType.spacer &&
                flex == null &&
                childNode.modifiers?.width == null &&
                childNode.modifiers?.height == null) {
              flex = 1;
            }

            children.add(
              (flex != null && flex > 0)
                  ? Expanded(
                      key: ValueKey('${childPath}_flex'),
                      flex: flex,
                      child: w,
                    )
                  : w,
            );
          }
        }
        final spacing = node.modifiers?.spacing?.toDouble() ?? 0.0;

        widget = SizedBox(
          width: double.infinity,
          child: SafeRow(
            key: ValueKey(node.id ?? '${path}_row'),
            mainAxisSize: isRoot ? MainAxisSize.max : MainAxisSize.min,
            crossAxisAlignment: node.modifiers?.alignment != null
                ? _parseCrossAxis(node.modifiers?.alignment)
                : CrossAxisAlignment.center,
            mainAxisAlignment: _parseMainAxis(node.modifiers?.alignment),
            children: _applySpacing(children, spacing, Axis.horizontal, path),
          ),
        );
        break;
      case WidgetType.stack:
        final children = <Widget>[];
        if (node.children != null) {
          for (int i = 0; i < node.children!.length; i++) {
            children.add(_buildWidget(node.children![i], path: '${path}_s$i', isRoot: false));
          }
        }
        widget = Stack(
          key: ValueKey(node.id ?? '${path}_stack'),
          alignment: Alignment.center,
          children: children,
        );
        break;
      case WidgetType.text:
        widget = Text(
          node.content ?? "",
          key: ValueKey(node.id ?? '${path}_text'),
          textAlign: _parseTextAlign(node.modifiers?.alignment),
          style: _parseTextStyle(node.modifiers),
        );
        break;
      case WidgetType.icon:
        widget = Icon(
          _parseIconData(node.content),
          key: ValueKey(node.id ?? '${path}_icon'),
          size: node.modifiers?.fontSize ?? 24.0,
          color: _parseColor(node.modifiers?.color ?? "#FFFFFF"),
        );
        break;
      case WidgetType.image:
        final imageKey = ValueKey(node.id ?? '${path}_image');
        if (node.content != null && node.content!.startsWith("file://")) {
          final pathStr = node.content!.replaceFirst("file://", "");
          widget = Image.file(
            File(pathStr),
            key: imageKey,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              key: ValueKey(node.id ?? '${path}_image_err'),
              color: Colors.grey.withAlpha(50),
              child: const Center(
                child: Icon(Icons.error, color: Colors.white24),
              ),
            ),
          );
        } else {
          widget = Container(
            key: imageKey,
            color: Colors.grey.withAlpha(50),
          );
        }
        break;
      case WidgetType.spacer:
        final mods = node.modifiers;
        final spacerKey = ValueKey(node.id ?? '${path}_spacer');
        if (mods?.width != null || mods?.height != null) {
          widget = SizedBox(
            key: spacerKey,
            width: mods?.width?.toDouble(),
            height: mods?.height?.toDouble(),
          );
        } else {
          // Use SizedBox.shrink() instead of Spacer() here to avoid ParentDataWidget errors
          // when wrapped in modifiers. The Column/Row handles flex-wrapping.
          widget = SizedBox.shrink(key: spacerKey);
        }
        break;
      case WidgetType.button:
        final children = <Widget>[];
        if (node.children != null) {
          for (int i = 0; i < node.children!.length; i++) {
            children.add(_buildWidget(node.children![i], path: '${path}_b$i', isRoot: false));
          }
        }
        if (children.isEmpty && node.content != null) {
          children.add(
            Text(
              node.content.toString(),
              key: ValueKey(node.id ?? '${path}_button_text'),
              style: TextStyle(
                color: _parseColor(node.modifiers?.color ?? "#FFFFFF"),
                fontWeight: node.modifiers?.font == "bold" ? FontWeight.bold : FontWeight.normal,
                fontSize: node.modifiers?.fontSize ?? 14.0,
              ),
            ),
          );
        }
        widget = GestureDetector(
          key: ValueKey(node.id ?? '${path}_button_gesture'),
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: () {
            final actionId = node.action?.payload?['actionId']?.toString();
            if (actionId != null) {
              onActionTriggered?.call(actionId);
            }
          },
          child: Stack(
            key: ValueKey(node.id ?? '${path}_button_stack'),
            alignment: Alignment.center,
            children: children,
          ),
        );
        break;
      default:
        widget = SizedBox.shrink(key: ValueKey('${path}_shrink'));
    }

    // Apply basic modifiers (padding, size, background)
    widget = _applyModifiers(widget, node.modifiers ?? const SASUPModifiers(), path);

    return widget;
  }

  Widget _applyModifiers(Widget child, SASUPModifiers? mods, String path) {
    if (mods == null) return child;
    Widget w = child;

    if (mods.padding != null) {
      final p = mods.padding!;
      w = Padding(
        key: ValueKey('${path}_modifier_padding'),
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
      w = SizedBox(
        key: ValueKey('${path}_modifier_size'),
        width: mods.width,
        height: mods.height,
        child: w,
      );
    }

    if (mods.background != null || mods.cornerRadius != null) {
      final bg = mods.background;
      final borderRadius = mods.cornerRadius != null
          ? BorderRadius.circular(mods.cornerRadius!)
          : BorderRadius.zero;

      if (bg == 'glass') {
        w = ClipRRect(
          key: ValueKey('${path}_modifier_glass_clip'),
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              key: ValueKey('${path}_modifier_glass_container'),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: borderRadius,
                border: Border.all(
                  color: Colors.white.withAlpha(38),
                  width: 1.0,
                ),
              ),
              child: w,
            ),
          ),
        );
      } else {
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
        w = Container(
          key: ValueKey('${path}_modifier_bg'),
          decoration: decoration,
          child: w,
        );
      }
    }

    if (mods.clickAction != null) {
      w = GestureDetector(
        key: ValueKey('${path}_modifier_click'),
        excludeFromSemantics: true,
        onTap: () {
          debugPrint("Action Triggered in Preview: ${mods.clickAction?.type}");
        },
        child: w,
      );
    }

    return w;
  }

  List<Widget> _applySpacing(List<Widget> children, double spacing, Axis axis, String path) {
    if (spacing <= 0 || children.length <= 1) return children;

    final List<Widget> spaced = [];
    for (int i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i < children.length - 1) {
        spaced.add(
          axis == Axis.horizontal
              ? SizedBox(key: ValueKey('${path}_spacing_${i}_h'), width: spacing)
              : SizedBox(key: ValueKey('${path}_spacing_${i}_v'), height: spacing),
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
    final clean = colorStr.trim().toLowerCase();
    if (clean == 'transparent') return Colors.transparent;
    
    if (clean.startsWith('rgba')) {
      try {
        final match = RegExp(r'rgba\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*([\d\.]+)\s*\)').firstMatch(clean);
        if (match != null) {
          final r = int.parse(match.group(1)!);
          final g = int.parse(match.group(2)!);
          final b = int.parse(match.group(3)!);
          final a = double.parse(match.group(4)!);
          return Color.fromARGB((a * 255).round(), r, g, b);
        }
      } catch (_) {}
    }
    
    if (clean.startsWith('rgb')) {
      try {
        final match = RegExp(r'rgb\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)').firstMatch(clean);
        if (match != null) {
          final r = int.parse(match.group(1)!);
          final g = int.parse(match.group(2)!);
          final b = int.parse(match.group(3)!);
          return Color.fromARGB(255, r, g, b);
        }
      } catch (_) {}
    }

    String hex = clean;
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    
    if (hex.length == 3) {
      hex = hex.split('').map((c) => c + c).join();
    }
    
    if (hex.length == 6) {
      hex = 'ff$hex';
    }
    
    if (hex.length == 8) {
      try {
        return Color(int.parse('0x$hex'));
      } catch (_) {}
    }

    try {
      if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
        if (hex.length == 6) hex = 'ff$hex';
        return Color(int.parse('0x$hex'));
      }
    } catch (_) {}

    if (clean == 'white') return Colors.white;
    if (clean == 'black') return Colors.black;
    if (clean == 'red') return Colors.red;
    if (clean == 'green') return Colors.green;
    if (clean == 'blue') return Colors.blue;
    if (clean == 'grey' || clean == 'gray') return Colors.grey;

    return Colors.transparent;
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

Widget _stripFlex(Widget c) {
  if (c is Expanded) {
    return c.child;
  }
  if (c is Flexible) {
    return c.child;
  }
  return c;
}

class SafeColumn extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final List<Widget> children;

  const SafeColumn({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isBounded = constraints.maxHeight != double.infinity;
        final processed = children.map((c) => isBounded ? c : _stripFlex(c)).toList();
        return Column(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: isBounded ? mainAxisSize : MainAxisSize.min,
          children: processed,
        );
      },
    );
  }
}

class SafeRow extends StatelessWidget {
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final List<Widget> children;

  const SafeRow({
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isBounded = constraints.maxWidth != double.infinity;
        final processed = children.map((c) => isBounded ? c : _stripFlex(c)).toList();
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: isBounded ? mainAxisSize : MainAxisSize.min,
          children: processed,
        );
      },
    );
  }
}
