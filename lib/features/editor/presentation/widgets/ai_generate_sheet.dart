import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';

/// Self-contained bottom sheet for AI code generation.
///
/// Owns its own [TextEditingController] and disposes it properly
/// through the widget lifecycle, preventing "used after disposed" errors.
class AiGenerateSheetContent extends StatefulWidget {
  final bool isDark;
  final LiquidColors colors;
  final Future<String?> Function(String prompt) onGenerate;

  const AiGenerateSheetContent({
    super.key,
    required this.isDark,
    required this.colors,
    required this.onGenerate,
  });

  @override
  State<AiGenerateSheetContent> createState() => _AiGenerateSheetContentState();
}

class _AiGenerateSheetContentState extends State<AiGenerateSheetContent> {
  final TextEditingController _promptCtrl = TextEditingController();
  bool _isGenerating = false;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final isDark = widget.isDark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        LiquidTheme.primaryGradient.createShader(bounds),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI Code Generator',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.textTitle,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Generate new code, fix bugs, or modify your script',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textCaption,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.inputBorder),
                ),
                child: TextField(
                  controller: _promptCtrl,
                  maxLines: 4,
                  minLines: 2,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textTitle,
                  ),
                  cursorColor: LiquidTheme.primary,
                  decoration: InputDecoration(
                    hintText:
                        'e.g. "Fix the fetch error" or "Create a weather widget script"',
                    hintStyle: TextStyle(
                      color: colors.searchBarHint,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Generate Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: GestureDetector(
                onTap: _isGenerating
                    ? null
                    : () async {
                        final prompt = _promptCtrl.text.trim();
                        if (prompt.isEmpty) return;
                        setState(() => _isGenerating = true);

                        final navigator = Navigator.of(context);
                        final code = await widget.onGenerate(prompt);

                        if (!mounted) return;

                        if (code == null) {
                          // API not ready → signal onboarding needed
                          navigator.pop('__NEED_ONBOARDING__');
                          return;
                        }

                        setState(() => _isGenerating = false);

                        // Return generated code to caller
                        navigator.pop(code);
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LiquidTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: LiquidTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isGenerating
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Generate Code',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
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
    );
  }
}
