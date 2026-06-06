import 'dart:io';
import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/editor/presentation/pages/editor_page.dart';
import 'package:script_automator/features/editor/presentation/syntax_highlighter.dart';
import 'package:script_automator/features/script_management/domain/repositories/script_repository.dart';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:script_automator/features/widget_renderer/presentation/widgets/sasup_renderer.dart';
import 'package:script_automator/features/widget_renderer/domain/entities/widget_node.dart';
import 'package:script_automator/features/widget_renderer/domain/services/headless_widget_rendering_service.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/publish_script_sheet.dart';

/// A bottom sheet that shows a script's preview (rendered widget image) and
/// source code in two tabs, with action buttons to open the editor or delete.
///
/// Displayed when tapping a BentoCard on the Home page, replacing the
/// previous direct-to-editor navigation.
class ScriptPreviewSheet extends StatefulWidget {
  final Script script;
  final VoidCallback? onDeleted;

  const ScriptPreviewSheet({
    super.key,
    required this.script,
    this.onDeleted,
  });

  /// Shows the preview sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context,
    Script script, {
    VoidCallback? onDeleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScriptPreviewSheet(
        script: script,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  State<ScriptPreviewSheet> createState() => _ScriptPreviewSheetState();
}

class _ScriptPreviewSheetState extends State<ScriptPreviewSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _previewImagePath;
  WidgetNode? _previewNode;
  String? _previewFamily;
  String _fullContent = '';
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPreviewData();
    _loadFullContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Checks if a rendered widget JSON or PNG exists for this script.
  Future<void> _checkPreviewData() async {
    try {
      final appDir = await GetIt.I<HeadlessWidgetRenderingService>().getSharedDirectory();
      
      // Try to load JSON first (Modern native mode)
      final jsonPath = '${appDir.path}/sasup_ui_${widget.script.id}.json';
      final jsonFile = File(jsonPath);
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final nodeMap = jsonDecode(content);
        final nodeJson = nodeMap['root'] ?? nodeMap;
        final node = WidgetNode.fromJson(nodeJson as Map<String, dynamic>);
        final family = nodeMap['family'] as String? ?? 'medium';
        if (mounted) {
          setState(() {
            _previewNode = node;
            _previewFamily = family;
          });
        }
        return;
      }

      // Check in app group container for widget preview PNG (Legacy)
      final previewPath = '${appDir.path}/sasup_ui_${widget.script.id}.png';
      if (await File(previewPath).exists()) {
        if (mounted) setState(() => _previewImagePath = previewPath);
      }
    } catch (e) {
      debugPrint("Preview error: $e");
    }
  }

  /// Loads the full script content from the Dual-Store architecture.
  Future<void> _loadFullContent() async {
    setState(() => _isLoadingContent = true);
    try {
      final result = await GetIt.I<ScriptRepository>().getScriptDetail(
        widget.script.id,
      );
      result.fold(
        (_) => setState(() {
          _fullContent = widget.script.content;
          _isLoadingContent = false;
        }),
        (fullScript) => setState(() {
          _fullContent = fullScript.content.isEmpty
              ? '// Empty script'
              : fullScript.content;
          _isLoadingContent = false;
        }),
      );
    } catch (_) {
      setState(() {
        _fullContent = widget.script.content;
        _isLoadingContent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colors.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Script name + info
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: LiquidTheme.pageHorizontalPadding,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.script.name.hashCode % 2 == 0
                            ? LiquidTheme.primary.withValues(alpha: 0.2)
                            : LiquidTheme.cyan.withValues(alpha: 0.2),
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.code_rounded,
                    color: LiquidTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.script.name,
                        style: TextStyle(
                          fontSize: LiquidTheme.fontSectionTitle,
                          fontWeight: FontWeight.w800,
                          color: colors.textTitle,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "JavaScript • Local Script",
                        style: TextStyle(
                          fontSize: LiquidTheme.fontCaption,
                          color: colors.textCaption,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab bar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: LiquidTheme.pageHorizontalPadding,
            ),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: colors.chipBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.cardBorder,
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorPadding: const EdgeInsets.all(2),
                indicator: BoxDecoration(
                  color: colors.sheetBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.cardBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.06,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: colors.textTitle,
                unselectedLabelColor: colors.textCaption,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: "Preview"),
                  Tab(text: "Code"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPreviewTab(),
                _buildCodeTab(),
              ],
            ),
          ),

          // Action bar
          Container(
            padding: EdgeInsets.fromLTRB(
              LiquidTheme.pageHorizontalPadding,
              12,
              LiquidTheme.pageHorizontalPadding,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: colors.sheetBackground,
              border: Border(
                top: BorderSide(
                  color: colors.divider,
                ),
              ),
            ),
            child: Row(
              children: [
                // Delete button
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Publish button
                GestureDetector(
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final navigatorContext = navigator.context;
                    final success = await PublishScriptSheet.show(
                      context, 
                      widget.script.copyWith(content: _fullContent),
                    );
                    if (success == true && navigatorContext.mounted) {
                      navigator.pop(); // Close preview
                      PublishScriptSheet.showSuccessDialog(navigatorContext);
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: LiquidTheme.cyan.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      color: LiquidTheme.cyan,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Open Editor button
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        LiquidPageRoute(
                          page: EditorPage(script: widget.script),
                        ),
                      );
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: Theme.of(context).brightness == Brightness.dark
                            ? LiquidTheme.primaryGradient
                            : LiquidTheme.brandDarkGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: colors.glassOverlay,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Open Editor",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    final colors = Theme.of(context).extension<LiquidColors>()!;

    if (_previewNode != null) {
      final family = _previewFamily ?? 'medium';
      
      double aspectRatio = 329 / 155; // Default medium
      if (family == 'small') {
        aspectRatio = 155 / 155;
      } else if (family == 'large') {
        aspectRatio = 329 / 345;
      }

      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: LiquidTheme.pageHorizontalPadding,
            vertical: 16,
          ),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Container(
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.cardBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SasupRenderer(
                  node: _previewNode!,
                  family: family,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_previewImagePath != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: 375 / 667,  // iPhone SE ratio
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: LiquidTheme.pageHorizontalPadding,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: colors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: Image.file(
                  File(_previewImagePath!),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // No preview — show placeholder
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 56,
            color: colors.textCaption.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            "No preview available",
            style: TextStyle(
              color: colors.textBody,
              fontSize: LiquidTheme.fontBody,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Run the script to generate a widget preview",
            style: TextStyle(
              color: colors.textCaption.withValues(alpha: 0.7),
              fontSize: LiquidTheme.fontCaption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeTab() {
    if (_isLoadingContent) {
      return const Center(
        child: CircularProgressIndicator(color: LiquidTheme.primary),
      );
    }

    final highlighter = SyntaxHighlighter(
      baseStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 12.5,
        color: Color(0xFFCBD5E1),
        height: 1.5,
      ),
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: LiquidTheme.pageHorizontalPadding,
      ),
      decoration: BoxDecoration(
        color: LiquidTheme.darkBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: RichText(
            text: TextSpan(children: highlighter.parse(_fullContent)),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.sheetBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Delete Script?",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "\"${widget.script.name}\" will be permanently deleted. This action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.textBody,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: colors.chipBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: colors.textTitle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Delete",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await GetIt.I<ScriptRepository>().deleteScript(widget.script.id);
      if (context.mounted) {
        Navigator.pop(context);
        widget.onDeleted?.call();
      }
    }
  }
}
