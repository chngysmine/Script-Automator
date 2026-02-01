import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart'; // MethodChannel
import 'package:path_provider/path_provider.dart';
import 'package:app_group_directory/app_group_directory.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/widget_node.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/widget_type.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/sasup_modifiers.dart';

class HeadlessWidgetRenderingService {
  static const String _appGroupId = 'group.com.scriptautomator';

  /// Renders a WidgetNode to a PNG image and saves it to the Shared App Group storage.
  /// Returns the file URI 'file://...' accessible by the Widget Extension.
  Future<String> renderAndSave(WidgetNode node, String filename) async {
    try {
      // 1. Convert Node to Flutter Widget
      final widget = _buildWidgetTree(node);

      // 2. Rasterize (Capture Image)
      // Since we might be in background, standard generic capture is risky.
      // We rely on an "Owner" based build if possible, or View synchronization.
      // For this MVP, we assume the app is active enough to pump a frame or we use a virtual pipeline.
      final image = await _captureWidgetOffScreen(widget);

      // 3. Encode to PNG
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception("Failed to encode image");
      final buffer = byteData.buffer.asUint8List();

      // 4. Save to Shared Storage
      final directory = await _getSharedDirectory();
      await _cleanupOldCache(directory); // Prevent Bloat

      final file = File('${directory.path}/$filename');
      await file.writeAsBytes(buffer, flush: true);

      return 'file://${file.path}';
    } catch (e) {
      throw Exception("Headless Render Failed: $e");
    }
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
    if (Platform.isIOS) {
      return await AppGroupDirectory.getAppGroupDirectory(_appGroupId) ??
          await getApplicationDocumentsDirectory();
    } else {
      // Android Robust Fix: Use MethodChannel to ask Native side for the exact path.
      try {
        final platform = MethodChannel('com.antigravity/paths');
        final String? path = await platform.invokeMethod('getNativeFilesDir');
        if (path != null) {
          return Directory(path);
        }
      } catch (e) {
        debugPrint(
          "MethodChannel failed: $e, falling back to standard provider",
        );
      }

      // Fallback
      final appDocDir = await getApplicationDocumentsDirectory();
      if (appDocDir.path.endsWith('app_flutter')) {
        return appDocDir.parent;
      }
      return appDocDir;
    }
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

  Widget _buildWidgetTree(WidgetNode node) {
    Widget widget;

    switch (node.type) {
      case WidgetType.column:
        widget = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _parseCrossAxis(node.modifiers?.alignment),
          mainAxisAlignment: _parseMainAxis(node.modifiers?.alignment),
          children: node.children?.map(_buildWidgetTree).toList() ?? [],
        );
        break;
      case WidgetType.row:
        widget = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _parseCrossAxis(node.modifiers?.alignment),
          mainAxisAlignment: _parseMainAxis(node.modifiers?.alignment),
          children: node.children?.map(_buildWidgetTree).toList() ?? [],
        );
        break;
      case WidgetType.stack:
        widget = Stack(
          alignment: Alignment.center, // Default
          children: node.children?.map(_buildWidgetTree).toList() ?? [],
        );
        break;
      case WidgetType.text:
        widget = Text(
          node.content?.toString() ?? '',
          style: _parseTextStyle(node.modifiers),
        );
        break;
      case WidgetType.image:
        widget = _buildImage(node);
        break;
      case WidgetType.spacer:
        widget = const Spacer();
        break;
      default:
        widget = const SizedBox();
    }

    return _applyModifiers(widget, node.modifiers);
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

  Widget _applyModifiers(Widget child, SASUPModifiers? mods) {
    if (mods == null) return child;

    Widget w = child;

    // Padding
    if (mods.padding != null) {
      final insets = mods.padding!.when(
        all: (val) => EdgeInsets.all(val),
        symmetric: (v, h) =>
            EdgeInsets.symmetric(vertical: v ?? 0, horizontal: h ?? 0),
        only: (l, t, r, b) => EdgeInsets.only(
          left: l ?? 0,
          top: t ?? 0,
          right: r ?? 0,
          bottom: b ?? 0,
        ),
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
    if (mods.flex != null && mods.flex! > 0) {
      w = Expanded(flex: mods.flex!, child: w);
    }

    return w;
  }

  // Helpers

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return Colors.transparent;
    if (colorStr.startsWith("#")) {
      try {
        return Color(int.parse("0xFF${colorStr.substring(1)}"));
      } catch (_) {
        return Colors.transparent;
      }
    }
    return Colors.transparent;
  }

  TextStyle _parseTextStyle(SASUPModifiers? mods) {
    return TextStyle(
      color: _parseColor(mods?.color ?? "#000000"),
      fontWeight: mods?.font == "bold" ? FontWeight.bold : FontWeight.normal,
    );
  }

  CrossAxisAlignment _parseCrossAxis(String? align) {
    switch (align) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
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
      default:
        return MainAxisAlignment.start;
    }
  }

  List<Color> _extractColors(String input) {
    final RegExp regex = RegExp(r'#(?:[0-9a-fA-F]{3}){1,2}');
    final matches = regex.allMatches(input);
    return matches.map((m) => _parseColor(m.group(0))).toList();
  }
}
