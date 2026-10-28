import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:script_automator/core/theme/liquid_theme.dart';
import 'package:script_automator/features/ai_integration/data/services/ollama_service.dart';
import 'package:script_automator/features/ai_integration/data/services/openai_service.dart';
import 'package:script_automator/features/ai_integration/domain/ai_backend.dart';
import 'package:script_automator/features/ai_integration/domain/ai_service.dart';

/// AI provider picker (Gemini default, OpenAI / Ollama as advanced options).
///
/// The choice is persisted by [AiService]; if the chosen provider is not
/// configured, requests transparently fall back to Gemini.
Future<void> showAiOnboardingDialog(BuildContext context) async {
  final ai = GetIt.I<AiService>();
  final ollama = GetIt.I<OllamaService>();
  final openAi = GetIt.I<OpenAIService>();
  final ollamaUrlController =
      TextEditingController(text: await ollama.getConfiguredUrl() ?? '');
  if (!context.mounted) return;

  var openKeyDialog = false;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          final selected = ai.selectedProvider;
          String readiness(AiProvider p) =>
              ai.isProviderReady(p) ? '' : ' • Not configured';
          return AlertDialog(
            backgroundColor: const Color(0xFFF8FAFC),
            surfaceTintColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: LiquidTheme.primary),
                SizedBox(width: 8),
                Text("AI Assistant", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Choose your intelligence engine:",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _ProviderCard(
                      title: "Google Gemini",
                      subtitle: "Default • Free • No setup${readiness(AiProvider.gemini)}",
                      icon: Icons.flash_on_rounded,
                      isSelected: selected == AiProvider.gemini,
                      onTap: () async {
                        await ai.selectProvider(AiProvider.gemini);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _ProviderCard(
                      title: "OpenAI (Advanced)",
                      subtitle: "Uses your own API key${readiness(AiProvider.openai)}",
                      icon: Icons.chat_bubble_outline_rounded,
                      isSelected: selected == AiProvider.openai,
                      onTap: () async {
                        await ai.selectProvider(AiProvider.openai);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _ProviderCard(
                      title: "Ollama (Advanced, Local)",
                      subtitle: "Runs on your PC • Private${readiness(AiProvider.ollama)}",
                      icon: Icons.computer,
                      isSelected: selected == AiProvider.ollama,
                      onTap: () async {
                        await ai.selectProvider(AiProvider.ollama);
                        setState(() {});
                      },
                    ),
                    if (selected != AiProvider.gemini &&
                        !ai.isProviderReady(selected))
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          "Until this provider is configured, Gemini will be used.",
                          style: TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ),
                    if (selected == AiProvider.ollama)
                      _OllamaSetup(
                        controller: ollamaUrlController,
                        onChanged: (val) async {
                          await ollama.setConfig(val, ollama.model);
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              if (selected == AiProvider.openai)
                TextButton(
                  onPressed: () {
                    openKeyDialog = true;
                    Navigator.pop(dialogContext);
                  },
                  child: Text(openAi.isUsingCustomKey
                      ? "Change OpenAI Key"
                      : "Add OpenAI API Key"),
                ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Done"),
              ),
            ],
          );
        },
      );
    },
  );
  ollamaUrlController.dispose();
  // Opened from the outer context because the picker's context is gone.
  if (openKeyDialog && context.mounted) {
    await showOpenAiApiKeyDialog(context);
  }
}

/// Dialog for entering a custom OpenAI API key.
Future<void> showOpenAiApiKeyDialog(BuildContext context) async {
  final textController = TextEditingController();
  final openAi = GetIt.I<OpenAIService>();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("OpenAI API Key"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Optional. Your key is stored securely on this device and used only "
            "when OpenAI is selected. Gemini works without any key.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: textController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "API Key",
              hintText: "sk-...",
            ),
          ),
        ],
      ),
      actions: [
        if (openAi.isUsingCustomKey)
          TextButton(
            onPressed: () async {
              await openAi.clearApiKey();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text("Remove Key", style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            if (textController.text.trim().isEmpty) return;
            await openAi.setApiKey(textController.text);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
  textController.dispose();
}

class _OllamaSetup extends StatelessWidget {
  const _OllamaSetup({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Setup Instructions:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text("1. On your PC, run Ollama with:", style: TextStyle(fontSize: 11)),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(6),
            color: Colors.grey[100],
            child: const SelectableText(
              "OLLAMA_HOST=0.0.0.0 ollama serve",
              style: TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          const Text(
            "2. Find your PC's IP (e.g., 192.168.1.5)",
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 8),
          const Text(
            "Connect to Host:",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            style: const TextStyle(height: 1.0, fontSize: 13),
            decoration: const InputDecoration(
              hintText: "http://192.168.1.X:11434",
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Reusable provider selection card used in the picker dialog.
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
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$title. $subtitle',
      child: GestureDetector(
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
                const Icon(Icons.check_circle, color: LiquidTheme.primary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
