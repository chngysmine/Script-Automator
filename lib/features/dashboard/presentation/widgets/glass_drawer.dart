import 'package:flutter/material.dart';
import 'dart:ui';

class GlassDrawer extends StatefulWidget {
  const GlassDrawer({super.key});

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
    // Start animation when drawer opens
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
          // 1. Portal Background (Mesh Gradient)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(40),
              ),
              child: Stack(
                children: [
                  // Deep Space Base
                  Container(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                  ),

                  // Aurora Mesh 1
                  Positioned(
                    top: -100,
                    left: -50,
                    child: _buildOrb(300, Colors.purple.withValues(alpha: 0.3)),
                  ),
                  // Aurora Mesh 2
                  Positioned(
                    bottom: 100,
                    right: -50,
                    child: _buildOrb(250, Colors.cyan.withValues(alpha: 0.3)),
                  ),

                  // Holographic Blur
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.1,
                        ), // Ultra-thin glass
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Noise Texture Overlay (Simulated with Grainy Image or Gradient)
                  // For performance, we'll use a subtle gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
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

          // 2. 3D Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                _buildAnimatedItem(
                  index: 0,
                  total: 8,
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
                              color: Colors.white.withValues(alpha: 0.3),
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
                          child: const CircleAvatar(
                            radius: 36,
                            backgroundImage: NetworkImage(
                              "https://i.pravatar.cc/300",
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "CodeForge",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "Pro Workspace",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Navigation Items
                _buildAnimatedItem(
                  index: 1,
                  total: 8,
                  child: _buildGlassTile(
                    Icons.dashboard_rounded,
                    "Dashboard",
                    isActive: true,
                  ),
                ),
                _buildAnimatedItem(
                  index: 2,
                  total: 8,
                  child: _buildGlassTile(Icons.code_rounded, "My Scripts"),
                ),
                _buildAnimatedItem(
                  index: 3,
                  total: 8,
                  child: _buildGlassTile(Icons.extension_rounded, "Extensions"),
                ),
                _buildAnimatedItem(
                  index: 4,
                  total: 8,
                  child: _buildGlassTile(Icons.analytics_rounded, "Analytics"),
                ),
                _buildAnimatedItem(
                  index: 5,
                  total: 8,
                  child: _buildGlassTile(Icons.cloud_sync_rounded, "Sync"),
                ),

                const Spacer(),

                // Bottom Actions
                _buildAnimatedItem(
                  index: 6,
                  total: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: _buildGlassButton("Pro Settings"),
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
    // Staggered delay based on index
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
              ..setEntry(3, 2, 0.001) // Perspective
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

  Widget _buildGlassTile(IconData icon, String label, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: Colors.white.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.6),
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.6),
                fontSize: 16,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.cyan,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGlassButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
