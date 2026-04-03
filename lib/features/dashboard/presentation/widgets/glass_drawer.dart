import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'dart:ui';
import 'package:script_automator/features/dashboard/presentation/pages/settings_page.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/features/dashboard/domain/services/notification_service.dart';
import 'package:script_automator/core/theme/liquid_page_route.dart';

/// A frosted-glass side drawer providing navigation to all main sections.
///
/// Each tile maps to a nav index consumed by [AppShell.onNavigate]:
/// - 0: Dashboard
/// - 3: Gallery
/// - 5: Notifications
class GlassDrawer extends StatefulWidget {
  final int currentNavIndex;
  final Function(int) onNavigate;

  const GlassDrawer({
    super.key,
    required this.currentNavIndex,
    required this.onNavigate,
  });

  @override
  State<GlassDrawer> createState() => _GlassDrawerState();
}

class _GlassDrawerState extends State<GlassDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: 300,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(40),
              ),
              child: Stack(
                children: [
                  Container(
                    color: LiquidTheme.darkBackground.withValues(alpha: 0.6),
                  ),
                  Positioned(
                    top: -100,
                    left: -50,
                    child: _buildOrb(300, Colors.purple.withValues(alpha: 0.3)),
                  ),
                  Positioned(
                    bottom: 100,
                    right: -50,
                    child: _buildOrb(250, Colors.cyan.withValues(alpha: 0.3)),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          LiquidTheme.textPrimary.withValues(alpha: 0.05),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedItem(
                  index: 0,
                  total: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: LiquidTheme.textPrimary.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [LiquidTheme.primary, LiquidTheme.cyan],
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Script Automator",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: LiquidTheme.textDeep,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "Workspace",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: LiquidTheme.textLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildAnimatedItem(
                  index: 1,
                  total: 7,
                  child: _buildGlassTile(
                    Icons.dashboard_rounded,
                    "Dashboard",
                    isActive: widget.currentNavIndex == 0,
                    onTap: () => widget.onNavigate(0),
                  ),
                ),
                _buildAnimatedItem(
                  index: 2,
                  total: 7,
                  child: _buildGlassTile(
                    Icons.explore_rounded,
                    "Explore",
                    isActive: widget.currentNavIndex == 1,
                    onTap: () => widget.onNavigate(1),
                  ),
                ),
                _buildAnimatedItem(
                  index: 3,
                  total: 7,
                  child: _buildGlassTile(
                    Icons.storefront_rounded,
                    "Script Store",
                    isActive: widget.currentNavIndex == 3,
                    onTap: () => widget.onNavigate(3),
                  ),
                ),
                _buildAnimatedItem(
                  index: 4,
                  total: 7,
                  child: _buildGlassTile(
                    Icons.person_rounded,
                    "Profile",
                    isActive: widget.currentNavIndex == 4,
                    onTap: () => widget.onNavigate(4),
                  ),
                ),
                _buildAnimatedItem(
                  index: 5,
                  total: 7,
                  child: StreamBuilder<int>(
                    stream: GetIt.I<NotificationService>().unreadCount,
                    builder: (context, snapshot) {
                      return _buildGlassTile(
                        Icons.notifications_rounded,
                        "Notifications",
                        isActive: widget.currentNavIndex == 5,
                        badgeCount: snapshot.data ?? 0,
                        onTap: () => widget.onNavigate(5),
                      );
                    },
                  ),
                ),
                const Spacer(),
                _buildAnimatedItem(
                  index: 6,
                  total: 7,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: _buildGlassButton("Settings"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 10)],
      ),
    );
  }

  Widget _buildAnimatedItem({
    required int index,
    required int total,
    required Widget child,
  }) {
    final double start = (index / total) * 0.5;
    final double end = start + 0.5;

    final Animation<double> fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutQuad),
      ),
    );

    final Animation<double> slide = Tween<double>(begin: 100.0, end: 0.0)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );

    final Animation<double> rotate = Tween<double>(begin: -0.2, end: 0.0)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: fade.value,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..setTranslationRaw(slide.value, 0, 0)
              ..rotateY(rotate.value),
            alignment: Alignment.centerLeft,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildGlassTile(
    IconData icon,
    String label, {
    bool isActive = false,
    int badgeCount = 0,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isActive
                ? LiquidTheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isActive
                ? Border.all(color: LiquidTheme.primary.withValues(alpha: 0.3))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive
                    ? LiquidTheme.primary
                    : LiquidTheme.textMedium.withValues(alpha: 0.8),
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? LiquidTheme.primary
                        : LiquidTheme.textDeep,
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ] else if (isActive) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: LiquidTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(String label) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, LiquidPageRoute(page: const SettingsPage()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.8),
              Colors.white.withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: LiquidTheme.textDeep,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
