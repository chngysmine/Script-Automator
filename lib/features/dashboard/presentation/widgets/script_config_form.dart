import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/core/theme/liquid_colors.dart';
import 'package:script_automator/core/ui/styled_dropdown.dart';

/// Renders a dynamic form based on a script's config schema.
/// Returns the config map once the user successfully completes it,
/// or null if they cancel.
class ScriptConfigForm extends StatefulWidget {
  final Map<String, dynamic> configSchema;
  final String scriptName;

  const ScriptConfigForm({
    super.key,
    required this.configSchema,
    required this.scriptName,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    String scriptName,
    Map<String, dynamic> configSchema,
  ) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScriptConfigForm(
        configSchema: configSchema,
        scriptName: scriptName,
      ),
    );
  }

  @override
  State<ScriptConfigForm> createState() => _ScriptConfigFormState();
}

class _ScriptConfigFormState extends State<ScriptConfigForm> {
  final Map<String, dynamic> _formData = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize defaults
    widget.configSchema.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final def = value['default'];
        final type = value['type'];
        if (def != null) {
          _formData[key] = def;
        } else if (type == 'boolean') {
          _formData[key] = false;
        } else if (type == 'string') {
          _formData[key] = '';
        } else if (type == 'enum') {
          final options = value['options'] as List<dynamic>?;
          if (options != null && options.isNotEmpty) {
            _formData[key] = options.first;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LiquidColors>()!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colors.dialogBackground.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colors.glassBorder,
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Form(
                key: _formKey,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Configure Script",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: colors.textTitle,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Set up required variables for ${widget.scriptName} before installation.",
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textCaption,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: widget.configSchema.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildField(context, e.key, e.value as Map<String, dynamic>, colors),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: Text(
                            "CANCEL",
                            style: TextStyle(
                              color: colors.textCaption,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context, _formData);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LiquidTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "SAVE & INSTALL",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(BuildContext context, String key, Map<String, dynamic> schema, LiquidColors colors) {
    final type = schema['type'] ?? 'string';
    final label = (schema['label'] as String?) ?? key;
    final isRequired = schema['required'] == true;
    final helpUrl = schema['helpUrl'] as String?;

    Widget fieldWidget;

    if (type == 'boolean') {
      fieldWidget = SwitchListTile(
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textTitle)),
        value: _formData[key] == true,
        onChanged: (val) {
          setState(() {
            _formData[key] = val;
          });
        },
        contentPadding: EdgeInsets.zero,
        activeThumbColor: LiquidTheme.primary,
      );
    } else if (type == 'enum' && schema['options'] != null) {
      final options = schema['options'] as List<dynamic>;
      fieldWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textTitle)),
          const SizedBox(height: 8),
          StyledDropdown<String>(
            value: _formData[key]?.toString() ?? options.first.toString(),
            items: options.map((e) => e.toString()).toList(),
            labelBuilder: (item) => item,
            onChanged: (val) {
              setState(() {
                _formData[key] = val;
              });
            },
          ),
        ],
      );
    } else {
      // string
      fieldWidget = TextFormField(
        initialValue: _formData[key]?.toString(),
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          filled: true,
          fillColor: colors.inputBackground,
          labelStyle: TextStyle(color: colors.textCaption),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
        onChanged: (val) {
          _formData[key] = val;
        },
      );
    }

    if (helpUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldWidget,
          const SizedBox(height: 4),
          Text(
            "Get a key: $helpUrl",
            style: const TextStyle(fontSize: 12, color: Colors.blue),
          ),
        ],
      );
    }
    return fieldWidget;
  }
}
