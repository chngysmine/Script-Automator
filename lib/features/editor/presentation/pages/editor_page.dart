import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/code_forge_controller.dart';
import '../painters/viewport_aware_painter.dart';
import '../widgets/keyboard_toolbar.dart';
import '../syntax_highlighter.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'dart:ui';
import 'dart:math';

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
  final List<String> _logs = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _showConsole = false;
  bool _isLogExpanded = false;

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

    final initialText = widget.script?.content ?? "// Start coding...";
    _inputController.text = initialText;
    _controller.setText(_inputController.text);

    _inputController.addListener(() {
      if (_controller.text != _inputController.text) {
        _controller.setText(_inputController.text);
        _controller.selection = _inputController.selection;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputController.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
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

  void _runScript() {
    HapticFeedback.mediumImpact();
    setState(() {
      _showConsole = true;
      _isLogExpanded = true;
      _logs.clear();
      _logs.add("[Info] Build started...");
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _logs.add("[Info] Compiled successfully in 45ms");
      });
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final isWeather =
          _controller.text.contains("Weather") ||
          widget.script?.name.contains("Weather") == true;

      setState(() {
        if (isWeather) {
          _logs.add("[Service] LocationManager: Requesting updates...");
          _logs.add("[Service] LocationManager: Hanoi, VN (Accuracy: High)");
          _logs.add("[Network] GET api.weather.com/v1/current 200 OK");
        } else {
          _logs.add("[Output] Hello World!");
        }
      });

      if (isWeather) {
        _showWidgetPreview(isWeather: true);
      } else if (_controller.text.contains("render")) {
        _showWidgetPreview(isWeather: false);
      }
    });
  }

  void _showWidgetPreview({required bool isWeather}) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            contentPadding: EdgeInsets.zero,
            content: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: isWeather ? _buildLiveWeatherCard() : _buildGenericCard(),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildLiveWeatherCard() {
    final hour = DateTime.now().hour;
    final isNight = hour < 6 || hour > 18;
    final temp = 29;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 340,
            constraints: const BoxConstraints(minHeight: 420),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isNight
                    ? [const Color(0xFF0F172A), const Color(0xFF312E81)]
                    : [const Color(0xFF2563EB), const Color(0xFF60A5FA)],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: (isNight ? Colors.black : Colors.blueAccent)
                      .withValues(alpha: 0.4),
                  blurRadius: 60,
                  offset: const Offset(0, 30),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.topRight,
                        radius: 1.2,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.near_me,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "HANOI, VN",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Icon(
                        isNight
                            ? Icons.nights_stay_rounded
                            : Icons.wb_sunny_rounded,
                        size: 110,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "$temp°",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 92,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        isNight ? "Clear Night" : "Mostly Sunny",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _WeatherStat(
                              icon: Icons.water_drop_rounded,
                              label: "Humidity",
                              value: "88%",
                            ),
                            _WeatherStat(
                              icon: Icons.air_rounded,
                              label: "Wind",
                              value: "9 km/h",
                            ),
                            _WeatherStat(
                              icon: Icons.compress,
                              label: "Pressure",
                              value: "1009",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGenericCard() {
    return Container(
      height: 250,
      width: 300,
      decoration: BoxDecoration(
        gradient: LiquidTheme.auroraGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: LiquidTheme.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.widgets_rounded,
                    size: 32,
                    color: LiquidTheme.textDeep,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Widget Preview",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: LiquidTheme.textDeep,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Visual output will appear here.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: LiquidTheme.textMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          // 1. DASHBOARD BACKGROUND (Aurora + Orbs) - MODE: WARM SUNSET
          Container(
            decoration: const BoxDecoration(gradient: LiquidTheme.roseGradient),
          ),
          Positioned(
            top: -100,
            right: -50,
            child: _buildOrb(
              300,
              const Color(0xFFFDA4AF).withValues(alpha: 0.3),
            ), // Rose 300
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildOrb(
              250,
              const Color(0xFFFDBA74).withValues(alpha: 0.3),
            ), // Orange 300
          ),

          // Heavy Blur for uniformity (Optional, but helps text legibility if Editor is semi-transparent)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.transparent),
          ),

          // 2. Editor Surface (PRISM GLASS: Tinted, not White)
          SafeArea(
            child: Column(
              children: [
                _buildLightAppBar(context),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        // Glass Tint for Contrast against Sunset
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(
                              0xFFFFF1F2,
                            ).withValues(alpha: 0.7), // Rose 50
                            const Color(
                              0xFFFDF2F8,
                            ).withValues(alpha: 0.5), // Pink 50
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFE11D48,
                            ).withValues(alpha: 0.05), // Rose Shadow
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
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
                                                  _verticalController.hasClients
                                                  ? _verticalController.offset
                                                  : 0,
                                              viewportHeight:
                                                  constraints.maxHeight,
                                              textStyle: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontSize: 13.5,
                                                color: LiquidTheme.textDeep,
                                                height: 1.6,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              gutterWidth: 44.0,
                                              highlighter: SyntaxHighlighter(
                                                baseStyle: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 13.5,
                                                  color: LiquidTheme.textDeep,
                                                  height: 1.6,
                                                  fontWeight: FontWeight.w500,
                                                ),
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
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 13.5,
                                              color: Colors.transparent,
                                              height: 1.6,
                                            ),
                                            cursorColor: const Color(
                                              0xFF0284C7,
                                            ),
                                            decoration: const InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
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

          // 3. CROSS-PLATFORM CONSOLE (Dark Theme, No Fake Text)
          if (_showConsole)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: _isLogExpanded
                    ? _buildConsoleSheet()
                    : _buildConsolePill(),
              ),
            ),

          Positioned(
            bottom: bottomInset,
            left: 0,
            right: 0,
            child: KeyboardToolbar(
              onInsert: _insertText,
              onTab: () => _insertText("  "),
              onUndo: () {},
              onRedo: () {},
            ),
          ),
        ],
      ),
    );
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

  // Expanded Sheet (Standard App Logs)
  Widget _buildConsoleSheet() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 320,
          margin: const EdgeInsets.only(left: 12, right: 12, bottom: 60),
          decoration: BoxDecoration(
            color: LiquidTheme.darkBackground.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  color: Colors.black.withValues(alpha: 0.2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            _isLogExpanded = false;
                            _showConsole = false;
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
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              // Log Content
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Text(
                      log,
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontFamily: 'monospace',
                        fontSize: 13,
                        height: 1.3,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ); // Close Container, BackdropFilter, ClipRRect
  }

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildLightAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildGlassBtn(
            context,
            Icons.grid_view_rounded,
            () => Navigator.pop(context),
          ),
          Text(
            widget.script?.name ?? "Untitled",
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          _buildGlassBtn(
            context,
            Icons.play_arrow_rounded,
            _runScript,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBtn(
    BuildContext context,
    IconData icon,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF0EA5E9)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : const Color(0xFF334155),
          size: 22,
        ),
      ),
    );
  }

  double _calculateHeight() {
    return _controller.lineCount * 22.4 + 500;
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

class CommonColors {
  static const Color pastelBlue = Color(0xFFE0F2FE);
  static const Color pastelPurple = Color(0xFFF3E8FF);
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _WeatherStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
