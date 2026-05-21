import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/styled_dropdown.dart';
import 'package:script_automator/features/dashboard/presentation/widgets/pixel_cheer_animation.dart';
import 'package:script_automator/features/script_management/domain/entities/script.dart';
import 'package:script_automator/features/dashboard/domain/repositories/gallery_repository.dart';
import 'package:script_automator/core/services/app_config_service.dart';

class PublishScriptSheet extends StatefulWidget {
  final Script script;

  const PublishScriptSheet({super.key, required this.script});

  static Future<void> show(BuildContext context, Script script) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PublishScriptSheet(script: script),
    );
  }

  @override
  State<PublishScriptSheet> createState() => _PublishScriptSheetState();
}

class _PublishScriptSheetState extends State<PublishScriptSheet> {
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'System';
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<String> _categories = [
    'System',
    'Productivity',
    'Lifestyle',
    'Entertainment',
    'Other'
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    // Check if gallery submissions are enabled by admin
    if (GetIt.I.isRegistered<AppConfigService>() &&
        !GetIt.I<AppConfigService>().gallerySubmissionsEnabled) {
      setState(() {
        _errorMessage = 'Gallery submissions are temporarily disabled by admin.';
      });
      return;
    }

    final bool isImported = widget.script.settings['gallery_id'] != null;
    final bool isModified = widget.script.settings['is_modified_from_gallery'] == true;
    
    if (isImported && !isModified) {
      setState(() {
        _errorMessage = 'No improvements detected. Please modify the script before publishing.';
      });
      return;
    }

    if (_descController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a description for your script';
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = GetIt.I<GalleryRepository>();
      await repo.submitScript({
        'script_id': widget.script.id,
        'name': widget.script.name,
        'description': _descController.text.trim(),
        'category': _selectedCategory,
        'content': widget.script.content,
        'version': '1.0.0',
        'is_featured': false,
        'created_at': DateTime.now().toIso8601String(),
        if (isImported) 'original_gallery_id': widget.script.settings['gallery_id'],
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to submit: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + keyboardHeight,
          ),
          decoration: BoxDecoration(
            color: isDark 
                ? LiquidTheme.darkBackground.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.8),
            border: Border(top: BorderSide(color: colors.glassBorder)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Publish to Gallery",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: colors.textCaption),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Share '${widget.script.name}' with the community. It will be reviewed by moderators before becoming public.",
            style: TextStyle(color: colors.textCaption, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          Text(
            "Category",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StyledDropdown<String>(
                value: _selectedCategory,
                items: _categories,
                labelBuilder: (item) => item,
                icon: Icons.category_rounded,
                onChanged: (String newValue) {
                  setState(() => _selectedCategory = newValue);
                },
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: PixelCheerAnimation(),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 16),

          // Description Input
          Text(
            "Description",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 3,
            style: TextStyle(color: colors.textTitle, fontSize: 15),
            decoration: InputDecoration(
              hintText: "Describe what your script does...",
              hintStyle: TextStyle(color: colors.textCaption),
              filled: true,
              fillColor: colors.inputBackground,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: LiquidTheme.cyan),
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent, 
                        fontSize: 14, 
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Submit Button
          GestureDetector(
            onTap: _isSubmitting ? null : _submit,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LiquidTheme.cyan, LiquidTheme.primary],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: LiquidTheme.cyan.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              alignment: Alignment.center,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      "Submit for Review",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
        ),
      ),
    );
  }
}
