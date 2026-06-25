import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

class _DailySlideData {
  final String title;
  final String description;
  final String imagePath;
  final double baseAlignmentX;

  const _DailySlideData({
    required this.title,
    required this.description,
    required this.imagePath,
    this.baseAlignmentX = 0.0,
  });
}

class DailyLandingPage extends StatefulWidget {
  final VoidCallback onContinue;

  const DailyLandingPage({super.key, required this.onContinue});

  @override
  State<DailyLandingPage> createState() => _DailyLandingPageState();
}

class _DailyLandingPageState extends State<DailyLandingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _dontShowToday = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (_dontShowToday) {
      final box = await Hive.openBox('app_settings');
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await box.put('daily_splash_dismissed_date', today);
    }
    widget.onContinue();
  }

  void _onNext() {
    if (_currentIndex < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _handleContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;
    final isLast = _currentIndex == 3;

    final slides = [
      const _DailySlideData(
        title: 'Core Engine Isolate',
        description: 'Experience lightning fast local Javascript runtime sandboxed directly on your device.',
        imagePath: 'assets/images/daily_landing.png',
        baseAlignmentX: 0.0,
      ),
      const _DailySlideData(
        title: 'Secure Execution Sandbox',
        description: 'Run background automation scripts protected by strict local network shielding policies.',
        imagePath: 'assets/images/onboarding_sandbox.png',
        baseAlignmentX: 0.0,
      ),
      const _DailySlideData(
        title: 'Dynamic Screen Widgets',
        description: 'Map script variables to highly interactive home screen widgets updated in real-time.',
        imagePath: 'assets/images/onboarding_widgets.png',
        baseAlignmentX: 0.42, // shifted slightly right to show details
      ),
      const _DailySlideData(
        title: 'Generative AI Co-Pilot',
        description: 'Auto-generate scripts using high-fidelity natural language prompts matching your specific workflow.',
        imagePath: 'assets/images/onboarding_ai.png',
        baseAlignmentX: 0.0,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen edge-to-edge sliding PageView with AnimatedBuilder for 120fps Parallax Transitions
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              final double pageOffset = _pageController.hasClients ? _pageController.page ?? 0.0 : 0.0;

              return PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  final double relativePosition = index - pageOffset;

                  // 1. Calculate dynamic parallax image alignment
                  final double dynamicX = (slide.baseAlignmentX + (relativePosition * 0.35)).clamp(-1.0, 1.0);

                  // 2. Calculate text animation factors (fade and slide)
                  final double opacity = (1.0 - relativePosition.abs() * 1.5).clamp(0.0, 1.0);
                  final double textTranslateX = relativePosition * 150.0;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Parallax-aligned full-screen background image
                      Image.asset(
                        slide.imagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment(dynamicX, 0.0),
                      ),

                      // Soft dark gradient overlay for text readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.95),
                            ],
                            stops: const [0.0, 0.45, 0.9],
                          ),
                        ),
                      ),

                      // Parallax Layered Content Overlay (text translates independently of background)
                      Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(textTranslateX, 0.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide.title,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1.0,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  slide.description,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white.withValues(alpha: 0.82),
                                    height: 1.5,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                // Add spacing so text doesn't overlap bottom navigation panel
                                SizedBox(height: 160 + bottomPad),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // Top right Skip Button (Floating glassmorphic style)
          Positioned(
            top: topPad + 12,
            right: 20,
            child: GestureDetector(
              onTap: _handleContinue,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                ),
                child: const Text(
                  'SKIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),

          // Grounded Layout Footer Controls
          Positioned(
            left: 28,
            right: 28,
            bottom: 24 + bottomPad,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dots & Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Stretch indicators
                    Row(
                      children: List.generate(4, (index) {
                        final isSelected = _currentIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.only(right: 8),
                          height: 6,
                          width: isSelected ? 24 : 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? LiquidTheme.primary
                                : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),

                    // Transparent with white border Button
                    GestureDetector(
                      onTap: _onNext,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.65),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'GET STARTED' : 'CONTINUE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Don't show today checkbox
                GestureDetector(
                  onTap: () => setState(() => _dontShowToday = !_dontShowToday),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: _dontShowToday ? LiquidTheme.primary : Colors.transparent,
                            border: Border.all(
                              color: _dontShowToday
                                  ? LiquidTheme.primary
                                  : Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: _dontShowToday
                              ? const Icon(Icons.check_rounded, size: 10, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Don't show again today",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
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
    );
  }
}

Future<bool> shouldShowDailySplash() async {
  try {
    final box = await Hive.openBox('app_settings');
    final dismissedDate = box.get('daily_splash_dismissed_date') as String?;
    if (dismissedDate == null) return true;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return dismissedDate != today;
  } catch (_) {
    return true;
  }
}
