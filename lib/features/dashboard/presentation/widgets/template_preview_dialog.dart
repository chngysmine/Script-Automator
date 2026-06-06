import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TemplatePreviewDialog extends StatefulWidget {
  final Map<String, dynamic> scriptData;
  final void Function(Map<String, dynamic> data, String fetchedContent) onImportTriggered;

  const TemplatePreviewDialog({
    super.key,
    required this.scriptData,
    required this.onImportTriggered,
  });

  @override
  State<TemplatePreviewDialog> createState() => _TemplatePreviewDialogState();
}

class _TemplatePreviewDialogState extends State<TemplatePreviewDialog> {
  String _code = "";
  bool _isLoadingCode = false;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    final existingContent = widget.scriptData['content'] as String?;
    if (existingContent != null && existingContent.isNotEmpty) {
      setState(() {
        _code = existingContent;
      });
      return;
    }

    final scriptUrl = widget.scriptData['scriptUrl'] as String?;
    if (scriptUrl == null || scriptUrl.isEmpty) {
      setState(() {
        _code = "// Code content not available offline.";
      });
      return;
    }

    setState(() {
      _isLoadingCode = true;
      _fetchError = null;
    });

    try {
      final response = await http
          .get(Uri.parse(scriptUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _code = utf8.decode(response.bodyBytes);
            _isLoadingCode = false;
          });
        }
      } else {
        throw Exception("Server returned HTTP ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchError = "Failed to fetch code: $e";
          _isLoadingCode = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final name = widget.scriptData['name'] ?? 'Untitled';
    final author = widget.scriptData['author'] ?? 'Unknown';
    final description = widget.scriptData['description'] ?? 'No description provided.';
    final version = widget.scriptData['version'] ?? '1.0.0';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: colors.dialogBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colors.glassBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Details
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: colors.textTitle,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "by $author • v$version",
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textCaption,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: colors.textCaption),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textBody,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),

                // Code Viewport title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Code Preview",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textTitle,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (_code.isNotEmpty && !_isLoadingCode && _fetchError == null)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Code copied to clipboard"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 14, color: LiquidTheme.primary),
                              const SizedBox(width: 4),
                              const Text(
                                "Copy Code",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: LiquidTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Code Viewport (Scrollable container)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A), // Slate 900 for premium dark code bg
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.cardBorder,
                      ),
                    ),
                    child: _buildCodeContent(colors),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LiquidTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              disabledBackgroundColor: LiquidTheme.primary.withValues(alpha: 0.3),
                            ),
                            onPressed: (_isLoadingCode || _fetchError != null || _code.isEmpty)
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                    widget.onImportTriggered(widget.scriptData, _code);
                                  },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "Import Template",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
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
    )
        .animate()
        .scale(duration: 300.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 200.ms);
  }

  Widget _buildCodeContent(LiquidColors colors) {
    if (_isLoadingCode) {
      return const Center(
        child: CircularProgressIndicator(color: LiquidTheme.primary),
      );
    }

    if (_fetchError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(height: 8),
            Text(
              _fetchError!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _loadCode,
              child: const Text(
                "Retry",
                style: TextStyle(color: LiquidTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Text(
        _code,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: Color(0xFFF1F5F9), // Slate 100 for code readable text
          height: 1.4,
        ),
      ),
    );
  }
}
