import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/dashboard/data/services/user_preferences_service.dart';

class NewUserOnboardingDialog extends StatefulWidget {
  final VoidCallback onDismiss;

  const NewUserOnboardingDialog({super.key, required this.onDismiss});

  @override
  State<NewUserOnboardingDialog> createState() => _NewUserOnboardingDialogState();
}

class _NewUserOnboardingDialogState extends State<NewUserOnboardingDialog> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (_pageController.hasClients) {
      setState(() {
        _pageOffset = _pageController.page ?? 0.0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() async {
    if (_currentIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      final prefs = GetIt.I<UserPreferencesService>();
      await prefs.set('onboarding_completed', 'true');
      widget.onDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Harmonious paper colors synchronized with core app color scheme
    final paperColor = colors.dialogBackground;
    final shadowColor = isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.1);
    final coverColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0);
    final coverBorderColor = colors.cardBorder;

    return Material(
      type: MaterialType.transparency, // Root transparent wrapper to remove yellow double underlines
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 380, // Tightly reduced height to avoid any vertical empty space
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Bottom cover container (Clean card shadow peek)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: coverColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: coverBorderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. The Main Ruled Paper Page (Fills completely)
                Positioned.fill(
                  left: 4,
                  right: 4,
                  top: 4,
                  bottom: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: paperColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CustomPaint(
                        painter: _NotebookLinesPainter(
                          isDark: isDark,
                          lineColor: colors.divider,
                          marginColor: LiquidTheme.primary.withValues(alpha: 0.35),
                        ),
                        child: Column(
                          children: [
                            // Header info (QUICK TOUR & Steps Indicator)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        color: isDark ? const Color(0xFFF58A5B) : LiquidTheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'QUICK TOUR',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? const Color(0xFFF58A5B) : LiquidTheme.primary,
                                          letterSpacing: 2.0,
                                          fontFamily: 'Inter',
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: colors.chipBackground,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_currentIndex + 1} / 04',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textCaption,
                                        fontFamily: 'monospace',
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Smooth Parallax Fade & Slide Content Carousel
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: 4,
                                onPageChanged: (index) {
                                  setState(() => _currentIndex = index);
                                },
                                itemBuilder: (context, index) {
                                  final double delta = index - _pageOffset;

                                  // Do not render pages that are turned completely out of view
                                  if (delta <= -1.0 || delta >= 1.0) {
                                    return const SizedBox.shrink();
                                  }

                                  // Premium Parallax Transition
                                  final double slideX = delta * 24.0;
                                  final double opacity = (1.0 - delta.abs()).clamp(0.0, 1.0);

                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      final double width = constraints.maxWidth;

                                      return Transform.translate(
                                        offset: Offset(-delta * width + slideX, 0),
                                        child: Opacity(
                                          opacity: opacity,
                                          child: _buildSlideContent(index, colors, isDark),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),

                            // Footer controls (Sits on clean slate/white background)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Page dots
                                  Row(
                                    children: List.generate(4, (index) {
                                      final isSelected = _currentIndex == index;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.only(right: 6),
                                        height: 6,
                                        width: isSelected ? 18 : 6,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (isDark ? const Color(0xFFF58A5B) : LiquidTheme.primary)
                                              : colors.textCaption.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      );
                                    }),
                                  ),

                                  // Styled Next/Start button
                                  GestureDetector(
                                    onTap: _onNext,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: colors.cardBorder,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _currentIndex == 3 ? 'START' : 'NEXT',
                                            style: TextStyle(
                                              color: colors.textTitle,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.0,
                                              fontFamily: 'Inter',
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            color: colors.textTitle,
                                            size: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- MAP INDEX TO SLIDE CONTENT ---

  Widget _buildSlideContent(int index, LiquidColors colors, bool isDark) {
    switch (index) {
      case 0:
        return _buildSlide(
          title: 'Bento Dashboard',
          desc: 'Keep track of all automation tasks. Monitor runtime isolates, system clipboards, and local security states.',
          preview: _buildBentoPreview(colors, isDark),
          isDark: isDark,
          rotateAngle: -0.012,
          colors: colors,
        );
      case 1:
        return _buildSlide(
          title: 'CodeForge Editor',
          desc: 'Write robust JS automation scripts on the fly with access to custom native system polyfills.',
          preview: _buildEditorPreview(colors, isDark),
          isDark: isDark,
          rotateAngle: 0.01,
          colors: colors,
        );
      case 2:
        return _buildSlide(
          title: 'Isolate Terminal',
          desc: 'Debug sandbox streams and exception logs via a real-time retro isolate console.',
          preview: _buildTerminalPreview(colors, isDark),
          isDark: isDark,
          rotateAngle: -0.008,
          colors: colors,
        );
      case 3:
        return _buildSlide(
          title: 'Template Gallery',
          desc: 'Explore, rate, and clone community verified scripts directly to your local sandbox workspace.',
          preview: _buildGalleryPreview(colors, isDark),
          isDark: isDark,
          rotateAngle: 0.012,
          colors: colors,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // --- SLIDE WRAPPER ---

  Widget _buildSlide({
    required String title,
    required String desc,
    required Widget preview,
    required bool isDark,
    required double rotateAngle,
    required LiquidColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0), // Shifted top padding from 12 to 24 to move slide content down
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact Polaroid scrapbook preview card with rotation & tape
          Transform.rotate(
            angle: rotateAngle,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: preview,
                ),
                // Washi Tape / Tape strip at the top
                Positioned(
                  top: -8,
                  child: Container(
                    width: 48,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.12) : colors.cardBorder.withValues(alpha: 0.7),
                      border: Border.all(
                        color: colors.cardBorder,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Title mimicking human written notes with app colors
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colors.textTitle,
              fontFamily: 'Inter',
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),

          // Description styled to sit perfectly on ruled paper lines
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              height: 2.2, // Perfect line height multiplier to fit the lines
              color: colors.textBody,
              fontFamily: 'Inter',
              fontStyle: FontStyle.italic, // Slanted handwriting feel
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  // --- PREVIEW MODULES SYNCHRONIZED WITH THEME ---

  Widget _buildBentoPreview(LiquidColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.dashboard_customize_rounded, color: Colors.blue, size: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '12 Active',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: colors.textTitle,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'System Tasks',
                        style: TextStyle(
                          fontSize: 8,
                          color: colors.textCaption,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal_rounded, color: Colors.green, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        'isolate_1',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colors.textTitle,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Clipboard watcher.',
                    style: TextStyle(
                      fontSize: 7.5,
                      height: 1.2,
                      color: colors.textBody,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'RUNNING',
                      style: TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorPreview(LiquidColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.code_rounded, color: Colors.amber, size: 12),
              const SizedBox(width: 6),
              Text(
                'clipboard_trigger.js',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: colors.textTitle,
                  decoration: TextDecoration.none,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 8),
              ),
            ],
          ),
          Divider(height: 8, color: colors.divider),
          const Text(
            '1  const text = await Clipboard.read();\n'
            '2  if (text.includes("http")) {\n'
            '3    await Share.share(text);\n'
            '4  }',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8.5,
              color: Color(0xFF4FA6E0),
              height: 1.3,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalPreview(LiquidColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x4D22C55E), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.videogame_asset_rounded, color: Colors.green, size: 12),
              SizedBox(width: 6),
              Text(
                'ISOLATE LOGS',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const Text(
            '14:02:10 [SYSTEM] Virtual FS ready\n'
            '14:02:11 [SUCCESS] Process finished.',
            style: TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 8,
              fontFamily: 'monospace',
              height: 1.3,
              decoration: TextDecoration.none,
            ),
          ),
          Row(
            children: [
              const Text(
                r'$ ',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 8.5,
                  fontFamily: 'monospace',
                  decoration: TextDecoration.none,
                ),
              ),
              Container(width: 4, height: 8, color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryPreview(LiquidColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.cardBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 12),
              const SizedBox(width: 6),
              Text(
                'Webhook Dispatcher',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: colors.textTitle,
                  decoration: TextDecoration.none,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'API V2',
                  style: TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Instantly dispatch server alerts from local background triggers.',
            style: TextStyle(
              fontSize: 8,
              height: 1.25,
              color: colors.textBody,
              decoration: TextDecoration.none,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Clone',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: colors.textTitle,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Execute',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. NOTEBOOK RULED LINES CUSTOM PAINTER
// ==========================================
class _NotebookLinesPainter extends CustomPainter {
  final bool isDark;
  final Color lineColor;
  final Color marginColor;

  _NotebookLinesPainter({
    required this.isDark,
    required this.lineColor,
    required this.marginColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.15) // Subtle theme-synchronized notebook lines
      ..strokeWidth = 1.0;

    final marginPaint = Paint()
      ..color = marginColor // Theme primary branding color margin line
      ..strokeWidth = 1.5;

    // Draw horizontal ruled lines only in the middle content area
    // Header ends around y = 52. Footer starts around y = size.height - 68.
    const double lineSpacing = 28.0;
    const double startY = 54.0;
    final double endY = size.height - 68.0;

    // Draw a bounding horizontal line exactly at startY
    canvas.drawLine(Offset(0, startY), Offset(size.width, startY), linePaint);

    // Draw intermediate lines
    for (double y = startY + lineSpacing; y < endY; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Draw a bounding horizontal line exactly at endY (caps the blank segment at the bottom)
    canvas.drawLine(Offset(0, endY), Offset(size.width, endY), linePaint);

    // Draw vertical margin line in the content area only (bounded cleanly between startY and endY)
    const double marginX = 16.0;
    canvas.drawLine(const Offset(marginX, startY), Offset(marginX, endY), marginPaint);
  }

  @override
  bool shouldRepaint(covariant _NotebookLinesPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.marginColor != marginColor;
  }
}
