import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/ai_integration/data/services/openai_service.dart';
import 'package:script_automator/features/ai_integration/data/services/ollama_service.dart';
import 'package:script_automator/features/editor/domain/code_forge_controller.dart';

/// Shows the AI provider selection dialog (OpenAI / Gemini / Ollama).
///
/// Returns after the user dismisses the dialog. Provider choice is stored
/// in [CodeForgeController.activeAiProvider].
Future<void> showAiOnboardingDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF8FAFC),
            surfaceTintColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: LiquidTheme.primary),
                SizedBox(width: 8),
                Text(
                  "Enable AI Assistant",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Choose your intelligence engine:",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  // OPTION A: OPENAI (Default)
                  _ProviderCard(
                    title: "OpenAI ChatGPT",
                    subtitle: "Requires API Key • Smartest • Fast",
                    icon: Icons.chat_bubble_outline_rounded,
                    isSelected:
                        CodeForgeController.activeAiProvider == 'openai',
                    onTap: () {
                      setState(
                        () => CodeForgeController.activeAiProvider = 'openai',
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // OPTION B: GEMINI
                  _ProviderCard(
                    title: "Google Gemini",
                    subtitle: "Fast • Standard Model",
                    icon: Icons.flash_on_rounded,
                    isSelected:
                        CodeForgeController.activeAiProvider == 'gemini',
                    onTap: () {
                      setState(
                        () => CodeForgeController.activeAiProvider = 'gemini',
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // OPTION C: OLLAMA
                  _ProviderCard(
                    title: "Ollama (Local/Private)",
                    subtitle: "Runs on PC • Secure • No Internet",
                    icon: Icons.computer,
                    isSelected:
                        CodeForgeController.activeAiProvider == 'ollama',
                    onTap: () {
                      setState(
                        () => CodeForgeController.activeAiProvider = 'ollama',
                      );
                    },
                  ),

                  // OLLAMA SETUP GUIDE (Collapsed unless selected)
                  if (CodeForgeController.activeAiProvider == 'ollama')
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Setup Instructions:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "1. On your PC, run Ollama with:",
                            style: TextStyle(fontSize: 11),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(6),
                            color: Colors.grey[100],
                            child: const SelectableText(
                              "OLLAMA_HOST=0.0.0.0 ollama serve",
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const Text(
                            "2. Find your PC's IP (e.g., 192.168.1.5)",
                            style: TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Connect to Host:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextField(
                            style:
                                const TextStyle(height: 1.0, fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: "http://192.168.1.X:11434",
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (val) {
                              GetIt.I<OllamaService>().setConfig(
                                val,
                                "deepseek-coder:6.7b",
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              // Option to set a custom OpenAI API key
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await showOpenAiApiKeyDialog(context);
                },
                child: const Text("Add OpenAI API Key"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Done"),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Dialog for entering a custom OpenAI API key.
Future<void> showOpenAiApiKeyDialog(BuildContext context) async {
  final textController = TextEditingController();
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("OpenAI API Key"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Your API key is stored securely on this device. "
            "Paste your key from platform.openai.com. Gemini key can be set in Settings.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: textController,
            obscureText: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "API Key",
              hintText: "sk-...",
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (textController.text.isNotEmpty) {
              await GetIt.I<OpenAIService>().setApiKey(
                textController.text.trim(),
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}

/// Reusable provider selection card used in the onboarding dialog.
class _ProviderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? LiquidTheme.primary.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? LiquidTheme.primary
                : Colors.grey.withValues(alpha: 0.2),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? LiquidTheme.primary : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? LiquidTheme.primary : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: LiquidTheme.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
