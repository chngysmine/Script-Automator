import 'package:flutter/material.dart';

class NewScriptDialog extends StatefulWidget {
  const NewScriptDialog({super.key});

  @override
  State<NewScriptDialog> createState() => _NewScriptDialogState();
}

class _NewScriptDialogState extends State<NewScriptDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("New Script"),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: "Script Name (e.g., my_automation)",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.of(context).pop(_controller.text);
            }
          },
          child: const Text("Create"),
        ),
      ],
    );
  }
}
