import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';

class FeedbackSheet extends StatefulWidget {
  final String appVersion;

  const FeedbackSheet({
    super.key,
    required this.appVersion,
  });

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  String _category = 'suggestion'; // 'bug' | 'suggestion' | 'other'
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    
    // Pre-fill user email if logged in
    final user = FirebaseAuth.instance.currentUser;
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      await FirebaseFirestore.instance.collection('user_feedback').add({
        'user_id': user?.uid ?? 'anonymous',
        'email': _emailController.text.trim(),
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _category,
        'app_version': widget.appVersion,
        'platform': Platform.operatingSystem,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: colors.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Send Feedback",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.textTitle,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Help us improve Script Automator by sharing bugs or features.",
              style: TextStyle(
                fontSize: 13,
                color: colors.textCaption,
              ),
            ),
            const SizedBox(height: 20),
            
            // Category selector (Segmented style)
            Text(
              "Category",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.textCaption,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildCategoryButton('suggestion', Icons.lightbulb_rounded, 'Feature'),
                const SizedBox(width: 8),
                _buildCategoryButton('bug', Icons.bug_report_rounded, 'Bug'),
                const SizedBox(width: 8),
                _buildCategoryButton('other', Icons.help_outline_rounded, 'Other'),
              ],
            ),
            const SizedBox(height: 20),

            // Email input
            TextFormField(
              controller: _emailController,
              style: TextStyle(color: colors.textTitle),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Contact Email",
                labelStyle: TextStyle(color: colors.textCaption, fontSize: 14),
                prefixIcon: Icon(Icons.email_outlined, color: colors.textCaption, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: LiquidTheme.primary, width: 1.5),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Title input
            TextFormField(
              controller: _titleController,
              style: TextStyle(color: colors.textTitle),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Short Summary",
                labelStyle: TextStyle(color: colors.textCaption, fontSize: 14),
                prefixIcon: Icon(Icons.title_rounded, color: colors.textCaption, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: LiquidTheme.primary, width: 1.5),
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 16),

            // Description input
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              style: TextStyle(color: colors.textTitle),
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: "Description",
                alignLabelWithHint: true,
                labelStyle: TextStyle(color: colors.textCaption, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: LiquidTheme.primary, width: 1.5),
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a description' : null,
            ),
            const SizedBox(height: 24),

            // Submit / Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LiquidTheme.primary,
                  disabledBackgroundColor: LiquidTheme.primary.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        "Submit Feedback",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String cat, IconData icon, String label) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    final isSelected = _category == cat;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _category = cat),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? LiquidTheme.primary.withValues(alpha: 0.1) 
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? LiquidTheme.primary : colors.inputBorder,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                color: isSelected ? LiquidTheme.primary : colors.textCaption,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? LiquidTheme.primary : colors.textCaption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
