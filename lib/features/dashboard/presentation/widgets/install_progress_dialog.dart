import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InstallProgressDialog extends StatefulWidget {
  final String scriptName;
  final Future<void> Function(
    void Function(String progressMessage) updateProgress,
  ) installTask;

  const InstallProgressDialog({
    super.key,
    required this.scriptName,
    required this.installTask,
  });

  @override
  State<InstallProgressDialog> createState() => _InstallProgressDialogState();
}

class _InstallProgressDialogState extends State<InstallProgressDialog> {
  String _message = 'Preparing installation...';
  bool _isLoading = true;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runInstall();
  }

  Future<void> _runInstall() async {
    try {
      await widget.installTask((msg) {
        if (mounted) {
          setState(() {
            _message = msg;
          });
        }
      });
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _message = '"${widget.scriptName}" installed successfully and is ready to run!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _message = 'Failed to install "${widget.scriptName}".';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    
    IconData icon;
    Color accentColor;
    Color bgIconColor;

    if (_isLoading) {
      icon = Icons.refresh_rounded;
      accentColor = LiquidTheme.primary;
      bgIconColor = LiquidTheme.primary.withValues(alpha: 0.1);
    } else if (_isSuccess) {
      icon = Icons.check_circle_outline_rounded;
      accentColor = Colors.green;
      bgIconColor = Colors.green.withValues(alpha: 0.1);
    } else {
      icon = Icons.error_outline_rounded;
      accentColor = Colors.red;
      bgIconColor = Colors.red.withValues(alpha: 0.1);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: colors.dialogBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colors.glassBorder,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon / Loader
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bgIconColor,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: LiquidTheme.primary,
                          ),
                        )
                      : Icon(
                          icon,
                          color: accentColor,
                          size: 32,
                        ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  _isLoading
                      ? 'Installing Widget'
                      : (_isSuccess ? 'Installation Complete' : 'Installation Failed'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colors.textTitle,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Message description
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textBody,
                    height: 1.4,
                  ),
                ),

                // Error detail if present
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],

                // Action button (Only when finished)
                if (!_isLoading) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .scale(duration: 300.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 200.ms);
  }
}
