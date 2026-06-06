import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';

/// Log level for console messages
enum LogLevel { info, success, warning, error, debug }

/// A structured log entry with timestamp and level
class ConsoleLogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;

  ConsoleLogEntry({
    required this.message,
    this.level = LogLevel.info,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Parse a raw log string into a ConsoleLogEntry
  factory ConsoleLogEntry.fromRawLog(String log) {
    LogLevel detectLevel() {
      final lowerLog = log.toLowerCase();
      if (log.contains('[SEVERE]') || log.contains('[JS stderr]') || log.contains('[ERROR]') || lowerLog.contains('error') || log.contains('Exception:')) {
        return LogLevel.error;
      }
      if (log.contains('[WARNING]') || log.contains('[JS warn]') || lowerLog.contains('warning')) {
        return LogLevel.warning;
      }
      if (log.contains('[JS debug]') || lowerLog.contains('debug')) {
        return LogLevel.debug;
      }
      if (log.contains('[SUCCESS]') || log.contains('✓') || lowerLog.contains('success')) {
        return LogLevel.success;
      }
      return LogLevel.info; 
    }

    // Clean up the prefix for display
    String displayMessage = log;
    final prefixes = [
      '[JS stdout] ',
      '[JS stderr] ',
      '[JS warn] ',
      '[JS debug] ',
      '[INFO] ',
      '[ERROR] ',
      '[SUCCESS] ',
      '[WARNING] '
    ];
    for (final prefix in prefixes) {
      if (displayMessage.startsWith(prefix)) {
        displayMessage = displayMessage.substring(prefix.length);
        break;
      }
    }

    return ConsoleLogEntry(
      timestamp: DateTime.now(),
      message: displayMessage,
      level: detectLevel(),
    );
  }
}

/// Enhanced console log widget with colors, timestamps, and animations
class ConsoleLogItem extends StatelessWidget {
  final ConsoleLogEntry entry;
  final bool showTimestamp;

  const ConsoleLogItem({
    super.key,
    required this.entry,
    this.showTimestamp = true,
  });

  Color _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return const Color(0xFFEF4444); // Red
      case LogLevel.warning:
        return const Color(0xFFF59E0B); // Amber
      case LogLevel.success:
        return const Color(0xFF10B981); // Emerald
      case LogLevel.debug:
        return const Color(0xFF8B5CF6); // Violet
      case LogLevel.info:
        return const Color(0xFF60A5FA); // Blue
    }
  }

  IconData _getIconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Icons.error_outline_rounded;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.success:
        return Icons.check_circle_outline_rounded;
      case LogLevel.debug:
        return Icons.bug_report_outlined;
      case LogLevel.info:
        return Icons.info_outline_rounded;
    }
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForLevel(entry.level);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIconForLevel(entry.level), color: color, size: 16),
          const SizedBox(width: 8),
          if (showTimestamp) ...[
            Text(
              _formatTimestamp(entry.timestamp),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              entry.message,
              style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated success overlay shown when script completes
class ScriptSuccessOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const ScriptSuccessOverlay({super.key, required this.onComplete});

  @override
  State<ScriptSuccessOverlay> createState() => _ScriptSuccessOverlayState();
}

class _ScriptSuccessOverlayState extends State<ScriptSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LiquidTheme.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: LiquidTheme.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.check_rounded, color: Colors.white, size: 60),
              ),
            ),
          ),
        );
      },
    );
  }
}
