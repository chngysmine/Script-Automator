import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // StreamSubscription
import 'package:get_it/get_it.dart';
import '../../../../features/script_engine/domain/script_runner_service.dart';
import '../../domain/code_forge_controller.dart';
import '../../../../features/ai_integration/data/services/openai_service.dart';
import '../painters/viewport_aware_painter.dart';
import '../widgets/keyboard_toolbar.dart';
import '../widgets/console_log_widget.dart'; // Enhanced Console
import '../widgets/editor_app_bar.dart';
import '../widgets/ai_generate_sheet.dart';
import '../widgets/ai_onboarding_dialog.dart';
import '../../../../features/dashboard/presentation/widgets/publish_script_sheet.dart';
import '../widgets/editor_constants.dart';
import '../syntax_highlighter.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import '../../../../features/script_management/domain/repositories/script_repository.dart';

import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:script_automator/features/widget_renderer/domain/entities/widget_node.dart';
import 'package:script_automator/features/widget_renderer/presentation/widgets/sasup_renderer.dart';
import 'package:script_automator/features/widget_renderer/domain/services/headless_widget_rendering_service.dart';
import 'package:script_automator/features/editor/domain/editor_history.dart';
import 'package:script_automator/features/dashboard/data/services/user_stats_service.dart';

class EditorPage extends StatefulWidget {
  final Script? script;
  const EditorPage({super.key, this.script});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage>
    with SingleTickerProviderStateMixin {
  late CodeForgeController _controller;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _verticalController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ConsoleLogEntry> _logs = []; // Enhanced log entries

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _showConsole = false;
  bool _isLogExpanded = false;
  
  final EditorHistory _history = EditorHistory();
  bool _isUndoRedoAction = false;
  
  bool _isLoadingContent = false;

  // Phase 4 Integration: Real Engine
  final ScriptRunnerService _runnerService = GetIt.I<ScriptRunnerService>();
  StreamSubscription<String>? _logSubscription;
  StreamSubscription<String>? _renderSubscription;

  @override
  void initState() {
    super.initState();
    _controller = CodeForgeController();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    );
    _animController.forward();

    _initScriptContent();

    // Listen to Real Engine Logs
    _logSubscription = _runnerService.logs.listen((log) {
      if (!mounted) return;
      setState(() {
        _logs.add(ConsoleLogEntry.fromRawLog(log));
        // Auto-detect script completion
        if (log.contains('completed') ||
            log.contains('SUCCESS') ||
            log.contains('✓')) {}
      });
    });

    // Listen for Live Preview Requests
    _renderSubscription = _runnerService.renderRequests.listen((jsonString) {
      if (!mounted) return;
      _showLivePreview(jsonString);
    });
  }

  Future<void> _initScriptContent() async {
    if (widget.script != null) {
      setState(() => _isLoadingContent = true);
      // Fetch full content (Dual-Store architecture passes only Metadata from Dashboard)
      final result = await _repository.getScriptDetail(widget.script!.id);
      result.fold(
        (failure) {
          debugPrint("Failed to load script content: ${failure.message}");
          _initializeEditorWithText("// Error loading content.");
        },
        (fullScript) {
          _initializeEditorWithText(
            fullScript.content.isEmpty
                ? "// Start coding..."
                : fullScript.content,
          );
        },
      );
    } else {
      _initializeEditorWithText("// Start coding...");
    }
  }

  void _initializeEditorWithText(String text) {
    if (!mounted) return;
    _inputController.text = text;
    _controller.setText(_inputController.text);
    _history.record(_inputController.text, 0);

    // Only attach Auto-Save Logic AFTER initial load to prevent overwriting
    _inputController.addListener(_handleTextInput);

    setState(() => _isLoadingContent = false);
  }

  void _handleTextInput() {
    if (_isUndoRedoAction) return;
    
    if (_controller.text != _inputController.text) {
      _controller.setText(_inputController.text);
      _controller.selection = _inputController.selection;
      _history.record(_inputController.text, _inputController.selection.baseOffset);
      _onTextChanged(); // Trigger Debounce Save
      setState(() {}); // Trigger rebuild for syntax highlighting update
    }
  }

  // --- Auto Save ---
  Timer? _debounceTimer;
  final ScriptRepository _repository = GetIt.I<ScriptRepository>();
  bool _isSaving = false;

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(
      const Duration(seconds: 1, milliseconds: 500),
      _saveScript,
    );
  }

  Future<void> _saveScript() async {
    if (widget.script == null) {
      return; // Can't save untitled/temp yet contextually (though Dashboard creates one)
    }

    if (mounted) {
      setState(() => _isSaving = true);
    }

    final newSettings = Map<String, dynamic>.from(widget.script!.settings);
    newSettings['is_modified_from_gallery'] = true;

    final updatedScript = Script(
      id: widget.script!.id,
      name: widget.script!.name,
      content: _controller.text,
      createdAt: widget.script!.createdAt,
      updatedAt: DateTime.now(),
      settings: newSettings,
    );

    // Save to Hive + Sync to SQLite (Widget)
    await _repository.saveScript(updatedScript);
    
    // Track lines written for gamification
    if (GetIt.I.isRegistered<UserStatsService>()) {
      final lineCount = '\n'.allMatches(updatedScript.content).length + 1;
      final previousLines = widget.script?.content != null
          ? '\n'.allMatches(widget.script!.content).length + 1
          : 0;
      final delta = lineCount - previousLines;
      if (delta > 0) {
        GetIt.I<UserStatsService>().recordLinesWritten(delta);
      }
    }

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.script != null && _controller.text != widget.script!.content) {
      // Create a fire-and-forget save that doesn't rely on State
      final newSettings = Map<String, dynamic>.from(widget.script!.settings);
      newSettings['is_modified_from_gallery'] = true;

      final finalScript = Script(
        id: widget.script!.id,
        name: widget.script!.name,
        content: _controller.text,
        createdAt: widget.script!.createdAt,
        updatedAt: DateTime.now(),
        settings: newSettings,
      );
      _repository.saveScript(finalScript);
    }

    _inputController.removeListener(_handleTextInput);
    _controller.dispose();
    _inputController.dispose();
    _verticalController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    _logSubscription?.cancel();
    _renderSubscription?.cancel();
    super.dispose();
  }

  void _showLivePreview(String jsonString) {
    try {
      final nodeMap = jsonDecode(jsonString);
      final node = WidgetNode.fromJson(nodeMap as Map<String, dynamic>);

      showDialog(
        context: context,
        builder: (context) => Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  SasupRenderer(node: node),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton.filled(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Preview Error: $e");
    }
  }

  void _insertText(String text) {
    if (text == '{') text = '{}';
    if (text == '(') text = '()';
    if (text == '[') text = '[]';
    final selection = _inputController.selection;
    if (selection.start < 0) return;

    final newText = _inputController.text.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    _inputController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + 1),
    );
  }

  Future<void> _runScript() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _showConsole = true;
      _isLogExpanded = true;
      _logs.clear();
      _logs.add(ConsoleLogEntry.fromRawLog("[INFO] Initializing Engine..."));
    });

    try {
      final scriptId = widget.script?.id ?? 'manual_run';

      // ALWLAYS proactively clear the Widget UI before running to ensure no "ghost" old UI
      // is left behind if the script succeeds but simply doesn't call renderWidget().
      if (GetIt.I.isRegistered<HeadlessWidgetRenderingService>()) {
        await GetIt.I<HeadlessWidgetRenderingService>().deleteWidgetUI(
          scriptId,
        );
      }

      await _runnerService.runScript(_controller.text, scriptId);

      if (mounted) {
        setState(() {
          _logs.add(
            ConsoleLogEntry(
              message: "Script executed successfully!",
              level: LogLevel.success,
            ),
          );
        });
        // Console log entry above already informs the user of success.
      }
    } catch (e) {
      final scriptId = widget.script?.id ?? 'manual_run';
      // Fallback: If script crashes entirely, also clear the widget to avoid stale data
      if (GetIt.I.isRegistered<HeadlessWidgetRenderingService>()) {
        await GetIt.I<HeadlessWidgetRenderingService>().deleteWidgetUI(
          scriptId,
        );
      }

      setState(() {
        _logs.add(
          ConsoleLogEntry(
            message: "Failed to run script: $e",
            level: LogLevel.error,
          ),
        );
      });
    }
  }

  // Helper for Orbs (Copied from DashboardPage)
  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 20)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final editorBg = isDark
        ? LiquidTheme.darkBackground
        : const Color(0xFFF1F5F9); // Slate 100 — matches app gradient
    final editorTextStyle = kEditorTextStyle.copyWith(
      color: isDark
          ? const Color(0xFFCBD5E1) // Slate 300
          : const Color(0xFF334155), // Slate 700
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Background
          Container(
            color: editorBg,
          ),
          Positioned(
            top: -100,
            right: -50,
            child: _buildOrb(
              300,
              LiquidTheme.primary.withValues(alpha: isDark ? 0.1 : 0.06),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildOrb(
              250,
              LiquidTheme.cyan.withValues(alpha: isDark ? 0.08 : 0.05),
            ),
          ),

          // Moderate Blur for professional clean look
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: editorBg.withValues(alpha: 0.6),
            ),
          ),

          // 2. Editor Surface (PRISM GLASS: Tinted, not White)
          SafeArea(
            child: Column(
              children: [
                EditorAppBar(
                  scriptName: widget.script?.name ?? "Untitled",
                  isSaving: _isSaving,
                  onBack: () => Navigator.pop(context),
                  onPlay: _runScript,
                  onPublish: () {
                    if (widget.script != null) {
                      PublishScriptSheet.show(
                        context, 
                        widget.script!.copyWith(
                          content: _controller.text, 
                          settings: widget.script!.settings,
                        ),
                      );
                    }
                  },
                  onAiTap: () async {
                    if (CodeForgeController.activeAiProvider == null) {
                      if (context.mounted) {
                        await showAiOnboardingDialog(context);
                      }
                      if (CodeForgeController.activeAiProvider == null) return;
                    }
                    await _controller.triggerGhostText();
                    HapticFeedback.lightImpact();
                  },
                  onAiLongPress: () => showAiOnboardingDialog(context),
                  onAiGenerate: () => _showAiGenerateSheet(context),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      margin: EdgeInsets.zero, // Full-width edge-to-edge
                      decoration: BoxDecoration(
                        // Adaptive Glass for Code Editor
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF1E293B).withValues(alpha: 0.6),
                                  const Color(0xFF0F172A).withValues(alpha: 0.8),
                                ]
                              : [
                                  const Color(0xFFF1F5F9).withValues(alpha: 0.95),
                                  const Color(0xFFE2E8F0).withValues(alpha: 0.8),
                                ],
                        ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFE2E8F0), // Slate 200
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.06),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: _isLoadingContent
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: LiquidTheme.primary,
                              ),
                            )
                          : LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableWidth = constraints.maxWidth;

                                  return Scrollbar(
                                    controller: _verticalController,
                                    child: SingleChildScrollView(
                                      controller: _verticalController,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight,
                                          maxWidth: availableWidth,
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: AnimatedBuilder(
                                                animation: Listenable.merge([
                                                  _verticalController,
                                                  _controller,
                                                ]),
                                                builder: (context, _) => CustomPaint(
                                                painter: ViewportAwarePainter(
                                                  controller: _controller,
                                                  scrollOffset:
                                                      _verticalController
                                                          .hasClients
                                                      ? _verticalController
                                                            .offset
                                                      : 0,
                                                  viewportHeight:
                                                      constraints.maxHeight,
                                                  textStyle:
                                                      editorTextStyle,
                                                  gutterWidth: 44.0,
                                                  codePaddingLeft: 8.0,
                                                  isDark: isDark,
                                                  maxLineWidth:
                                                      availableWidth - 60.0,
                                                  highlighter:
                                                      SyntaxHighlighter.adaptive(
                                                        baseStyle: editorTextStyle,
                                                        brightness: isDark
                                                            ? Brightness.dark
                                                            : Brightness.light,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 52.0,
                                                right: 8.0,
                                                bottom: 300.0,
                                              ),
                                              child: TextField(
                                                controller: _inputController,
                                                focusNode: _focusNode,
                                                maxLines: null,
                                                keyboardType:
                                                    TextInputType.multiline,
                                                scrollPhysics: const NeverScrollableScrollPhysics(),
                                                showCursor: true,
                                                style: editorTextStyle
                                                    .copyWith(
                                                      color:
                                                          Colors.transparent,
                                                    ),
                                                strutStyle: const StrutStyle(
                                                  fontSize: 13.5,
                                                  height: 1.6,
                                                  leading: 0,
                                                  forceStrutHeight: true,
                                                ),
                                                cursorColor: const Color(
                                                  0xFF0284C7,
                                                ),
                                                cursorHeight: 16,
                                                cursorWidth: 1.5,
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  isCollapsed: true,
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.zero,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ),
                ),
                SizedBox(height: bottomInset > 0 ? 0 : 0),
              ],
            ),
          ),

          // 3. CROSS-PLATFORM CONSOLE (DraggableScrollableSheet)
          if (_showConsole)
            if (!_isLogExpanded)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: _buildConsolePill(),
                ),
              )
            else
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.4,
                    minChildSize: 0.1,
                    maxChildSize: 0.8,
                    builder: (context, scrollController) {
                      return _buildDraggableConsoleSheet(scrollController);
                    },
                  ),
                ),
              ),

          Positioned(
            bottom: bottomInset,
            left: 0,
            right: 0,
            child: KeyboardToolbar(
              onInsert: _insertText,
              onTab: () => _insertText("  "),
              onUndo: _handleUndo,
              onRedo: _handleRedo,
            ),
          ),
        ],
      ),
    );
  }

  void _handleUndo() {
    final snapshot = _history.undo();
    if (snapshot == null) return;
    
    _isUndoRedoAction = true;
    _inputController.text = snapshot.text;
    _inputController.selection = TextSelection.collapsed(
      offset: snapshot.cursorPosition.clamp(0, snapshot.text.length),
    );
    _controller.setText(snapshot.text);
    _isUndoRedoAction = false;
    
    // _controller.setText already triggers CustomPaint rebuild via Listenable
  }

  void _handleRedo() {
    final snapshot = _history.redo();
    if (snapshot == null) return;
    
    _isUndoRedoAction = true;
    _inputController.text = snapshot.text;
    _inputController.selection = TextSelection.collapsed(
      offset: snapshot.cursorPosition.clamp(0, snapshot.text.length),
    );
    _controller.setText(snapshot.text);
    _isUndoRedoAction = false;
    
    // _controller.setText already triggers CustomPaint rebuild via Listenable
  }

  // Minimal Pill (Generic System Status)
  Widget _buildConsolePill() {
    return GestureDetector(
      onTap: () => setState(() => _isLogExpanded = true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937), // Cool Grey 800
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusDot(const Color(0xFFEF4444)),
            const SizedBox(width: 6),
            _buildStatusDot(const Color(0xFFF59E0B)),
            const SizedBox(width: 6),
            _buildStatusDot(const Color(0xFF10B981)),
            const SizedBox(width: 12),
            const Text(
              "Build: Running...",
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableConsoleSheet(ScrollController scrollController) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xE6121212), // 90% opacity solid dark
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Less blurry
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            _isLogExpanded = false;
                          }),
                          child: _buildStatusDot(const Color(0xFFEF4444)),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusDot(const Color(0xFFF59E0B)),
                        const SizedBox(width: 8),
                        _buildStatusDot(const Color(0xFF10B981)),
                      ],
                    ),
                    const Text(
                      "Console Output",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              // Log Content
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return ConsoleLogItem(entry: log);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ────────────────────── AI Code Generation Sheet ──────────────────────

  Future<void> _showAiGenerateSheet(BuildContext ctx) async {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final colors = Theme.of(ctx).extension<LiquidColors>()!;

    final generatedCode = await showModalBottomSheet<String>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return AiGenerateSheetContent(
          isDark: isDark,
          colors: colors,
          onGenerate: (prompt) async {
            final openai = GetIt.I<OpenAIService>();
            if (!openai.isReady) {
              return null; // signal to show onboarding
            }
            return openai.generateCode(
              prompt,
              existingCode: _inputController.text,
            );
          },
        );
      },
    );

    // Handle result after sheet is fully dismissed
    if (generatedCode == null) return;

    // Check if we need to show onboarding (special sentinel)
    if (generatedCode == '__NEED_ONBOARDING__' && mounted) {
      await showAiOnboardingDialog(context);
      return;
    }

    if (!mounted) return;

    // Detect error responses from AI and show snackbar instead of polluting editor
    if (generatedCode.startsWith('// Error')) {
      final errorMsg = generatedCode
          .replaceFirst('// Error generating code: ', '')
          .replaceFirst('// Error: ', '');
      debugPrint('AI Error: $errorMsg');
      return;
    }

    if (generatedCode.isNotEmpty) {
      // AI always returns the complete script (whether new, fixed, or modified)
      _inputController.text = generatedCode;
      _inputController.selection = TextSelection.collapsed(
        offset: generatedCode.length,
      );
      _controller.setText(generatedCode);
      _history.record(generatedCode, generatedCode.length);
      _onTextChanged();
      // _controller.setText already triggers CustomPaint rebuild via Listenable
      HapticFeedback.mediumImpact();

    }
  }

}

