import 'dart:io';

import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

/// Modal sheet that guides users on how to add widgets to their home screen.
class WidgetGuideSheet extends StatelessWidget {
  const WidgetGuideSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LiquidTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.widgets_rounded,
              size: 48,
              color: LiquidTheme.primary,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            "Add Widget to Home Screen",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Display your script output as a widget",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Steps
          _buildStep(
            1,
            isIOS
                ? "Long press on your Home Screen"
                : "Long press on empty space",
            Icons.touch_app_rounded,
          ),
          _buildStep(
            2,
            isIOS
                ? "Tap the + button (top left)"
                : "Select 'Widgets' from menu",
            isIOS ? Icons.add_circle_outline : Icons.widgets_outlined,
          ),
          _buildStep(3, "Search for 'Script Automator'", Icons.search_rounded),
          _buildStep(
            4,
            "Drag the widget to your Home Screen",
            Icons.drag_indicator_rounded,
          ),

          const SizedBox(height: 24),

          // Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: LiquidTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Got it!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: LiquidTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                "$number",
                style: const TextStyle(
                  color: LiquidTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );
  }
}
