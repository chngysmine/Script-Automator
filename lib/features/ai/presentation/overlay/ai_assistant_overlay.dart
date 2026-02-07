import 'package:flutter/material.dart';
import '../../../../../core/theme/liquid_theme.dart';

class AIAssistantOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String) onPromptSubmit;

  const AIAssistantOverlay({
    super.key,
    required this.onClose,
    required this.onPromptSubmit,
  });

  @override
  State<AIAssistantOverlay> createState() => _AIAssistantOverlayState();
}

class _AIAssistantOverlayState extends State<AIAssistantOverlay> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: LiquidTheme.glassDecoration,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "AI Assistant",
                style: LiquidTheme.lightTheme.textTheme.titleMedium,
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: "Ask AI to generate code...",
            ),
            onSubmitted: widget.onPromptSubmit,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => widget.onPromptSubmit(_controller.text),
              child: const Text("Generate"),
            ),
          ),
        ],
      ),
    );
  }
}
