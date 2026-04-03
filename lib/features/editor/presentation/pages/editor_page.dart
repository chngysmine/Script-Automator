import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // StreamSubscription
import 'package:get_it/get_it.dart';
import '../../../../features/script_engine/domain/script_runner_service.dart';
import '../../domain/code_forge_controller.dart';
import '../../../../features/ai_integration/data/services/gemini_service.dart';
import '../../../../features/ai_integration/data/services/ollama_service.dart'; // Import OllamaService
import '../painters/viewport_aware_painter.dart';
import '../widgets/keyboard_toolbar.dart';
import '../widgets/console_log_widget.dart'; // Enhanced Console
import '../widgets/editor_app_bar.dart';
import '../syntax_highlighter.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import '../../../../features/script_management/domain/repositories/script_repository.dart';

import 'package:script_automator/core/theme/liquid_theme.dart';
import 'dart:ui';
import 'dart:math';
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
  final ScrollController _horizontalController = ScrollController();
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
      setState(() {});
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

    final updatedScript = Script(
      id: widget.script!.id,
      name: widget.script!.name,
      content: _controller.text,
      createdAt: widget.script!.createdAt,
      updatedAt: DateTime.now(),
      settings: widget.script!.settings,
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
      final finalScript = Script(
        id: widget.script!.id,
        name: widget.script!.name,
        content: _controller.text,
        createdAt: widget.script!.createdAt,
        updatedAt: DateTime.now(),
        settings: widget.script!.settings,
      );
      _repository.saveScript(finalScript);
    }

    _inputController.removeListener(_handleTextInput);
    _controller.dispose();
    _inputController.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Sleek Dark Background (Dark Aurora + Deep Orbs)
          Container(
            decoration: const BoxDecoration(gradient: LiquidTheme.brandDarkGradient),
          ),
          Positioned(
            top: -100,
            right: -50,
            child: _buildOrb(
              300,
              LiquidTheme.primary.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildOrb(
              250,
              LiquidTheme.cyan.withValues(alpha: 0.1),
            ),
          ),

          // Moderate Blur for professional clean look
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: const Color(0xFF0F172A).withValues(alpha: 0.5), // Slate 900 tint
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
                  onAiTap: () async {
                    if (CodeForgeController.activeAiProvider == null) {
                      if (context.mounted) {
                        await _showAIOnboardingDialog(context);
                      }
                      if (CodeForgeController.activeAiProvider == null) return;
                    }
                    await _controller.triggerGhostText();
                    HapticFeedback.lightImpact();
                  },
                  onAiLongPress: () => _showAIOnboardingDialog(context),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      margin: EdgeInsets.zero, // Full-width edge-to-edge
                      decoration: BoxDecoration(
                        // Dark Deep Glass for Professional Code Editor
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E293B).withValues(alpha: 0.6), // Slate 800
                            const Color(0xFF0F172A).withValues(alpha: 0.8), // Slate 900
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
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
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final contentWidth = max(
                                    constraints.maxWidth,
                                    _calculateMaxWidth(),
                                  );
                                  final contentHeight = max(
                                    constraints.maxHeight,
                                    _calculateHeight(),
                                  );

                                  return Scrollbar(
                                    controller: _verticalController,
                                    child: SingleChildScrollView(
                                      controller: _verticalController,
                                      child: SingleChildScrollView(
                                        controller: _horizontalController,
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: contentWidth,
                                          height: contentHeight,
                                          child: Stack(
                                            children: [
                                              AnimatedBuilder(
                                                animation: Listenable.merge([
                                                  _verticalController,
                                                  _horizontalController,
                                                  _controller,
                                                ]),
                                                builder: (context, _) => CustomPaint(
                                                  size: Size(
                                                    contentWidth,
                                                    contentHeight,
                                                  ),
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
                                                        _kEditorTextStyle,
                                                    gutterWidth: 44.0,
                                                    highlighter:
                                                        SyntaxHighlighter(
                                                          baseStyle:
                                                              _kEditorTextStyle,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 52.0,
                                                  right: 8.0,
                                                ),
                                                child: TextField(
                                                  controller: _inputController,
                                                  focusNode: _focusNode,
                                                  maxLines: null,
                                                  keyboardType:
                                                      TextInputType.multiline,
                                                  showCursor: true,
                                                  style: _kEditorTextStyle
                                                      .copyWith(
                                                        color:
                                                            Colors.transparent,
                                                      ),
                                                  strutStyle: const StrutStyle(
                                                    fontSize: 13.5,
                                                    height: 1.6,
                                                    leading: 0,
                                                    forceStrutHeight: true,
                                                  ), // LOCK LINE HEIGHT
                                                  cursorColor: const Color(
                                                    0xFF0284C7,
                                                  ), // Sky 600
                                                  decoration: const InputDecoration(
                                                    border: InputBorder.none,
                                                    // contentPadding: EdgeInsets.only(top: 2), // Removed manual padding, relying on Strut
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: bottomInset > 0 ? 0 : 70),
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
    
    _onTextChanged();
    setState(() {});
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
    
    _onTextChanged();
    setState(() {});
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

  // REPLACES _showAIProviderDialog with a proper Onboarding experience
  Future<void> _showAIOnboardingDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF8FAFC),
              surfaceTintColor: Colors.white,
              title: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: LiquidTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    "Enable AI Assistant",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Choose your intelligence engine:",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // OPTION A: GEMINI
                    // OPTION A: GEMINI (Instant)
                    _buildProviderCard(
                      title: "Google Gemini (Instant)",
                      subtitle: "Ready to use • Free Tier • Fast",
                      icon: Icons.flash_on_rounded,
                      isSelected:
                          CodeForgeController.activeAiProvider == 'gemini',
                      onTap: () async {
                        setState(
                          () => CodeForgeController.activeAiProvider = 'gemini',
                        );
                        // No key check needed for basic usage
                      },
                    ),
                    const SizedBox(height: 12),

                    // OPTION B: OLLAMA
                    _buildProviderCard(
                      title: "Ollama (Local/Private)",
                      subtitle: "Runs on PC • Secure • No Internet",
                      icon: Icons.computer,
                      isSelected:
                          CodeForgeController.activeAiProvider == 'ollama',
                      onTap: () {
                        setState(
                          () => CodeForgeController.activeAiProvider = 'ollama',
                        );
                      },
                    ),

                    // OLLAMA SETUP GUIDE (Collapsed unless selected)
                    if (CodeForgeController.activeAiProvider == 'ollama')
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Setup Instructions:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "1. On your PC, run Ollama with:",
                              style: TextStyle(fontSize: 11),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(6),
                              color: Colors.grey[100],
                              child: const SelectableText(
                                "OLLAMA_HOST=0.0.0.0 ollama serve",
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const Text(
                              "2. Find your PC's IP (e.g., 192.168.1.5)",
                              style: TextStyle(fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Connect to Host:",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextField(
                              style: const TextStyle(height: 1.0, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: "http://192.168.1.X:11434",
                                isDense: true,
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (val) {
                                GetIt.I<OllamaService>().setConfig(
                                  val,
                                  "deepseek-coder:6.7b",
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                // Option to use custom key (removes Free Tier limits)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _showApiKeyDialog(context);
                  },
                  child: const Text("Use My Own Key"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProviderCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? LiquidTheme.primary.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? LiquidTheme.primary
                : Colors.grey.withValues(alpha: 0.2),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? LiquidTheme.primary : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? LiquidTheme.primary : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: LiquidTheme.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Gemini API Key"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "To use AI features, please provide a valid Google Gemini API Key from aistudio.google.com.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "API Key",
                hintText: "AIzaSy...",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty) {
                await GetIt.I<GeminiService>().setApiKey(
                  textController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("API Key Saved!")),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  double _calculateHeight() {
    // 13.5 * 1.6 = 21.6 exactly
    // Adding extra buffer at bottom for easier typing
    return max(
      MediaQuery.of(context).size.height,
      _controller.lineCount * (13.5 * 1.6) + 300,
    );
  }

  double _calculateMaxWidth() {
    if (_inputController.text.isEmpty) return 1000;
    int maxLen = 0;
    final lines = _inputController.text.split('\n');
    for (final line in lines) {
      if (line.length > maxLen) maxLen = line.length;
    }
    return maxLen * 9.0 + 100;
  }
}

// SHARED STYLE CONSTANT TO PREVENT MISMATCH
const TextStyle _kEditorTextStyle = TextStyle(
  fontFamily: 'monospace',
  fontSize: 13.5,
  color: Color(0xFFE2E8F0), // Slate 200 light text for dark mode
  height: 1.6, // FIXED LINE HEIGHT matches TextField StrutStyle
  fontFeatures: [FontFeature.tabularFigures()],
  fontWeight: FontWeight.w500,
);

class CommonColors {
  static const Color pastelBlue = Color(0xFFE0F2FE);
  static const Color pastelPurple = Color(0xFFF3E8FF);
}
