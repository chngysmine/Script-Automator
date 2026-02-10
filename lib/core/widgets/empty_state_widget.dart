import 'package:flutter/material.dart';

/// A reusable empty state widget with icon, title, and subtitle.
/// Used when lists or grids have no content to display.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gradient Icon Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey.shade200, Colors.grey.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 64, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            // Optional Action Button
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
