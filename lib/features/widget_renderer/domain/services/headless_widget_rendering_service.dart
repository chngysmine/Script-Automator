import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

import 'package:script_automator/features/widget_renderer/domain/entities/widget_node.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/widget_type.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/sasup_modifiers.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/sasup_padding.dart';

class HeadlessWidgetRenderingService {
  /// Saves the raw SASUP JSON directly to shared storage for native rendering.
  ///
  /// This is the **preferred** mode: iOS SwiftUI and Android Glance render the
  /// JSON tree natively (text, gradients, icons) instead of a static bitmap.
  /// Falls back to [renderAndSave] for complex UIs that can't be expressed natively.
  Future<String> renderNativeJson(String jsonString, String scriptId) async {
    try {
      debugPrint("HeadlessService: Native JSON Passthrough for $scriptId");
      final directory = await _getSharedDirectory();
      await _cleanupOldCache(directory);

      // Parse and re-serialize to validate JSON structure
      final jsonMap = jsonDecode(jsonString);
      final rootMap = {'root': jsonMap};
      final sanitizedMap = _sanitizeForJson(rootMap);
      final jsonPayload = jsonEncode(sanitizedMap);

      // Save per-script JSON
      final jsonFile = File('${directory.path}/sasup_ui_$scriptId.json');
      await jsonFile.writeAsString(jsonPayload, flush: true);

      // Also write to default filename for compatibility
      final defaultFile = File('${directory.path}/sasup_ui.json');
      await defaultFile.writeAsString(jsonPayload, flush: true);

      await _triggerWidgetReload();

      debugPrint("HeadlessService: Native JSON saved to ${jsonFile.path}");
      return 'file://${jsonFile.path}';
    } catch (e, stack) {
      debugPrint("Native JSON Render Error: $e\n$stack");
      throw Exception("Native JSON Render Failed: $e");
    }
  }

  /// Renders a WidgetNode to a PNG image and saves it to Shared App Group storage.
  /// Returns the file URI 'file://...' accessible by the Widget Extension.
  ///
  /// This is the **fallback** mode for complex UIs that can't be expressed
  /// as native SwiftUI/Glance components. Use [renderNativeJson] when possible.
  Future<String> renderAndSave(WidgetNode node, String scriptId) async {
    try {
      debugPrint(
        "HeadlessService: Starting renderAndSave (Texture Capture)...",
      );

      // Force ignore flex on the absolute root node when rendering internally
      final flutterWidget = _buildWidgetTree(node, isRoot: true);
      final image = await _captureWidgetOffScreen(flutterWidget);

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Failed to encode image");
      final buffer = byteData.buffer.asUint8List();

      final directory = await _getSharedDirectory();
      await _cleanupOldCache(directory);

      final pngFile = File('${directory.path}/sasup_ui_$scriptId.png');
      await pngFile.writeAsBytes(buffer, flush: true);

      // Wrap as image node JSON for widget to render
      final imageNode = WidgetNode(
        type: WidgetType.image,
        content: 'file://${pngFile.path}',
        modifiers: const SASUPModifiers(),
      );

      final jsonFile = File('${directory.path}/sasup_ui_$scriptId.json');
      final rootMap = {'root': imageNode.toJson()};
      final sanitizedMap = _sanitizeForJson(rootMap);
      final jsonPayload = jsonEncode(sanitizedMap);

      await jsonFile.writeAsString(jsonPayload, flush: true);

      final defaultFile = File('${directory.path}/sasup_ui.json');
      await defaultFile.writeAsString(jsonPayload, flush: true);

      await _triggerWidgetReload();

      return 'file://${jsonFile.path}';
    } catch (e, stack) {
      debugPrint("Headless Render Error: $e\n$stack");
      throw Exception("Headless Render Failed: $e");
    }
  }

  /// Deletes the cached JSON and PNG UI files for a given script.
  /// Called when a script is deleted or emptied, preventing stale UI from showing on native widgets.
  Future<void> deleteWidgetUI(String scriptId) async {
    try {
      final directory = await _getSharedDirectory();

      final jsonFile = File('${directory.path}/sasup_ui_$scriptId.json');
      if (await jsonFile.exists()) await jsonFile.delete();

      final pngFile = File('${directory.path}/sasup_ui_$scriptId.png');
      if (await pngFile.exists()) await pngFile.delete();

      // Aggressively delete the fallback sasup_ui.json as well to prevent
      // unconfigured widgets from showing stale data.
      final fallbackJson = File('${directory.path}/sasup_ui.json');
      if (await fallbackJson.exists()) await fallbackJson.delete();

      await _triggerWidgetReload();

      debugPrint(
        "HeadlessService: Deleted cached UI & Triggered Reload for $scriptId",
      );
    } catch (e) {
      debugPrint("Failed to delete widget UI cache for $scriptId: $e");
    }
  }

  /// Triggers a refresh of all Native Widgets (iOS via MethodChannel).
  Future<void> _triggerWidgetReload() async {
    if (Platform.isIOS) {
      try {
        const channel = MethodChannel(
          'com.antigravity.script_automator/widget',
        );
        await channel.invokeMethod('reloadTimelines');
      } catch (e) {
        debugPrint("Failed to reload timelines: $e");
      }
    }
  }

  /// Recursively removes invalid JSON values (Infinity, NaN)
  dynamic _sanitizeForJson(dynamic value) {
    if (value is double) {
      if (value.isInfinite || value.isNaN) return null; // Convert to auto/null
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k, _sanitizeForJson(v)));
    }
    if (value is List) {
      return value.map((e) => _sanitizeForJson(e)).toList();
    }
    return value;
  }

  Future<void> _cleanupOldCache(Directory dir) async {
    try {
      final List<FileSystemEntity> entities = await dir.list().toList();
      final now = DateTime.now();
      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.png')) {
          final stat = await entity.stat();
          // Delete if older than 24h
          if (now.difference(stat.modified).inHours > 24) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint("Cache cleanup warning: $e");
    }
  }

  // ... (existing _getSharedDirectory)

  Future<Directory> _getSharedDirectory() async {
    debugPrint(
      "HeadlessService: _getSharedDirectory called. Platform:IOS=${Platform.isIOS}",
    );
    if (Platform.isIOS) {
      try {
        debugPrint(
          "HeadlessService: Requesting AppGroupDirectory via MethodChannel...",
        );
        const channel = MethodChannel(
          'com.antigravity.script_automator/widget',
        );
        final String? path = await channel.invokeMethod<String>(
          'getAppGroupPath',
          'group.com.antigravity.script_automator',
        );
        debugPrint("HeadlessService: AppGroupPath returned: $path");
        if (path != null) return Directory(path);
      } catch (e) {
        debugPrint(
          "HeadlessService: App Group error: $e. Falling back to local documents.",
        );
        // Fallback for Simulator or devices without App Group configuration
        // This ensures the app doesn't crash, though Widget Sync won't work.
        return await getApplicationDocumentsDirectory();
      }
    }
    // Fallback or Android standard
    if (Platform.isAndroid) {
      // Android Widget reads from context.filesDir which corresponds to getApplicationSupportDirectory
      return await getApplicationSupportDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  // --- Internal Rendering Logic ---

  Future<ui.Image> _captureWidgetOffScreen(Widget widget) async {
    // Advanced Technique: Create a RenderView and Pipeline manually
    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();

    // Safety Check: Background Isolates often lack a View.
    if (ui.PlatformDispatcher.instance.views.isEmpty) {
      throw Exception(
        "Cannot render widget off-screen: No active Flutter View available in this Isolate.",
      );
    }

    // Double check if we are in a headless context without surface
    // If so, we might need to skip or use a virtual view if Flutter allows (Impeller)
    // For now, fail gracefully.

    final RenderView renderView = RenderView(
      configuration: ViewConfiguration(
        devicePixelRatio: 2.0,
        logicalConstraints: BoxConstraints.tight(const Size(800, 800)),
        physicalConstraints: BoxConstraints.tight(const Size(1600, 1600)),
      ),
      view: ui.PlatformDispatcher.instance.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
          container: repaintBoundary,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Theme(data: ThemeData.light(), child: widget),
          ),
        ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final ui.Image image = await repaintBoundary.toImage(pixelRatio: 2.0);
    return image;
  }

  // --- Core Parser: Mirroring SASUP Logic ---

  Widget _buildWidgetTree(WidgetNode node, {bool isRoot = false}) {
    Widget widget;

    switch (node.type) {
      case WidgetType.container:
      case WidgetType.column:
        final children =
            node.children?.map((c) => _buildWidgetTree(c, isRoot: false)).toList() ?? [];
        final spacing = node.modifiers?.spacing?.toDouble() ?? 0.0;

        // Auto-Polish: If no padding is specified for a Container, default to 16.0
        // to prevent content from touching edges.
        var effectiveModifiers = node.modifiers;
        if (node.type == WidgetType.container &&
            (effectiveModifiers?.padding == null)) {
          effectiveModifiers = (effectiveModifiers ?? const SASUPModifiers())
              .copyWith(
                padding: const SASUPPadding(
                  left: 16,
                  top: 16,
                  right: 16,
                  bottom: 16,
                ),
              );
        }

        widget = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _parseCrossAxis(node.modifiers?.alignment),
          mainAxisAlignment: _parseMainAxis(node.modifiers?.alignment),
          children: _applySpacingInService(children, spacing, Axis.vertical),
        );
        // Apply the modified modifiers (with default padding)
        return _applyModifiers(
          widget,
          effectiveModifiers,
          ignoreFlex: isRoot,
        );
      case WidgetType.row:
        final children =
            node.children?.map((c) => _buildWidgetTree(c, isRoot: false)).toList() ?? [];
        final spacing = node.modifiers?.spacing?.toDouble() ?? 0.0;

        widget = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _parseCrossAxis(node.modifiers?.alignment),
          mainAxisAlignment: _parseMainAxis(node.modifiers?.alignment),
          children: _applySpacingInService(children, spacing, Axis.horizontal),
        );
        return _applyModifiers(widget, node.modifiers, ignoreFlex: isRoot);
      case WidgetType.stack:
        final children =
            node.children?.map((c) => _buildWidgetTree(c, isRoot: false)).toList() ?? [];
        widget = Stack(
          alignment: Alignment.center,
          children: children,
        );
        return _applyModifiers(widget, node.modifiers, ignoreFlex: isRoot);
      case WidgetType.text:
        widget = Text(
          node.content?.toString() ?? '',
          style: _parseTextStyle(node.modifiers),
        );
        return _applyModifiers(widget, node.modifiers, ignoreFlex: isRoot);
      case WidgetType.image:
        widget = _buildImage(node);
        return _applyModifiers(widget, node.modifiers, ignoreFlex: isRoot);
      case WidgetType.icon:
        widget = Icon(
          _parseIconData(node.content?.toString()),
          size: node.modifiers?.fontSize ?? 24,
          color: _parseColor(node.modifiers?.color ?? "#FFFFFF"),
        );
        return _applyModifiers(widget, node.modifiers, ignoreFlex: isRoot);
      case WidgetType.spacer:
        // When flex is 0 or null with explicit size, render as fixed gap
        final flex = node.modifiers?.flex;
        if (flex == null || flex == 0) {
          return SizedBox(
            width: node.modifiers?.width,
            height: node.modifiers?.height,
          );
        }
        // Flex spacer: must be inside Row/Column
        final content = _applyModifiers(
          const SizedBox.shrink(),
          node.modifiers,
          ignoreFlex: true,
        );
        return Expanded(flex: flex, child: content);
      default:
        widget = const SizedBox();
        return _applyModifiers(widget, node.modifiers, ignoreFlex: isRoot);
    }
  }

  Widget _buildImage(WidgetNode node) {
    final path = node.content?.toString();
    if (path == null) return const SizedBox();

    if (path.startsWith('file://')) {
      return Image.file(File(path.replaceFirst('file://', '')));
    } else {
      // Fallback or Network support if policies allow
      return const SizedBox(
        width: 50,
        height: 50,
        child: Placeholder(color: Colors.grey),
      );
    }
  }

  Widget _applyModifiers(
    Widget child,
    SASUPModifiers? mods, {
    bool ignoreFlex = false,
  }) {
    if (mods == null) return child;

    Widget w = child;

    // Padding
    if (mods.padding != null) {
      final p = mods.padding!;
      final insets = EdgeInsets.only(
        left: p.left,
        top: p.top,
        right: p.right,
        bottom: p.bottom,
      );
      w = Padding(padding: insets, child: w);
    }

    // Sizing
    if (mods.width != null || mods.height != null) {
      w = SizedBox(width: mods.width, height: mods.height, child: w);
    }

    // Background & Decor
    if (mods.background != null || mods.cornerRadius != null) {
      BoxDecoration decoration;

      final bg = mods.background;
      if (bg != null && bg.startsWith("linear-gradient")) {
        // Parse Gradient: linear-gradient(deg, #Col1, #Col2)
        // Simplistic parser for MVP: ignores degree, takes first 2 colors
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
          color: _parseColor(mods.background),
          borderRadius: mods.cornerRadius != null
              ? BorderRadius.circular(mods.cornerRadius!)
              : null,
        );
      }

      w = Container(decoration: decoration, child: w);
    }

    // Expand/Flex in Column/Row
    if (!ignoreFlex && mods.flex != null && mods.flex! > 0) {
      w = Expanded(flex: mods.flex!, child: w);
    }

    return w;
  }

  // Helpers

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return Colors.transparent;
    // Hex Support: #RRGGBB or #AARRGGBB
    if (colorStr.startsWith("#")) {
      try {
        String hex = colorStr.substring(1);
        if (hex.length == 6) hex = "FF$hex";
        return Color(int.parse("0x$hex"));
      } catch (_) {
        return Colors.transparent;
      }
    }
    // Simple Names
    switch (colorStr.toLowerCase()) {
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'transparent':
        return Colors.transparent;
    }
    return Colors.black;
  }

  TextStyle _parseTextStyle(SASUPModifiers? mods) {
    return TextStyle(
      color: _parseColor(mods?.color ?? "#000000"),
      fontWeight: mods?.font == "bold" ? FontWeight.bold : FontWeight.normal,
      fontSize: mods?.fontSize ?? 14.0,
      fontFamily: 'Inter', // Premium default
    );
  }

  // Simple Icon Parser (Material Icons)
  // In a real app, use a comprehensive map or font glyphs.
  // Expanded Icon Parser (SF Symbols -> Material Icons)
  IconData _parseIconData(String? iconName) {
    if (iconName == null) return Icons.help_outline;

    // Normalize logic if needed
    final name = iconName.toLowerCase();

    // Map: SF Symbol Name -> Material Icon
    const Map<String, IconData> iconMap = {
      // Weather
      'sun.max.fill': Icons.wb_sunny,
      'sun.max': Icons.wb_sunny_outlined,
      'moon.stars.fill': Icons.nightlight_round,
      'moon.fill': Icons.nightlight,
      'cloud.fill': Icons.cloud,
      'cloud.sun.fill': Icons.wb_cloudy,
      'cloud.rain.fill': Icons.grain,
      'cloud.snow.fill': Icons.ac_unit,
      'wind': Icons.air,
      'drop.fill': Icons.water_drop,
      'thermometer.medium': Icons.thermostat,

      // System
      'battery.100': Icons.battery_full,
      'battery.25': Icons.battery_2_bar,
      'wifi': Icons.wifi,
      'airplane': Icons.flight,
      'gear': Icons.settings,
      'trash': Icons.delete,
      'folder': Icons.folder,
      'doc.on.doc': Icons.copy,
      'square.and.arrow.up': Icons.ios_share,
      'xmark': Icons.close,
      'checkmark': Icons.check,
      'checkmark.circle.fill': Icons.check_circle,
      'exclamationmark.triangle.fill': Icons.warning,

      // Media
      'play.fill': Icons.play_arrow,
      'pause.fill': Icons.pause,
      'stop.fill': Icons.stop,
      'speaker.wave.2.fill': Icons.volume_up,

      // Communication
      'envelope.fill': Icons.email,
      'phone.fill': Icons.phone,
      'message.fill': Icons.message,
      'person.fill': Icons.person,
      'person.2.fill': Icons.people,

      // Time/Location
      'clock.fill': Icons.access_time_filled,
      'alarm.fill': Icons.alarm,
      'location.fill': Icons.location_on,
      'map.fill': Icons.map,
      'calendar': Icons.calendar_today,

      // Objects
      'creditcard.fill': Icons.credit_card,
      'cart.fill': Icons.shopping_cart,
      'gift.fill': Icons.card_giftcard,
      'tag.fill': Icons.local_offer,
      'camera.fill': Icons.camera_alt,
      'photo.fill': Icons.photo,
      'book.closed.fill': Icons.book,

      // Arrows
      'arrow.right': Icons.arrow_forward,
      'arrow.left': Icons.arrow_back,
      'arrow.up': Icons.arrow_upward,
      'arrow.down': Icons.arrow_downward,
      'arrow.clockwise': Icons.refresh,
    };

    return iconMap[name] ?? Icons.help_outline;
  }

  CrossAxisAlignment _parseCrossAxis(String? align) {
    switch (align) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.start;
    }
  }

  MainAxisAlignment _parseMainAxis(String? align) {
    switch (align) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  List<Widget> _applySpacingInService(
    List<Widget> children,
    double spacing,
    Axis axis,
  ) {
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

  List<Color> _extractColors(String input) {
    final RegExp regex = RegExp(
      r'#(?:[0-9a-fA-F]{3,8})',
    ); // Modified to support 3-8 chars
    final matches = regex.allMatches(input);
    return matches.map((m) => _parseColor(m.group(0))).toList();
  }
}
