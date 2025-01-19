import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomCardDialog extends StatefulWidget {
  final Function(String text, String icon) onAdd;

  const CustomCardDialog({super.key, required this.onAdd});

  @override
  State<CustomCardDialog> createState() => _CustomCardDialogState();
}

class _CustomCardDialogState extends State<CustomCardDialog> {
  final _textController = TextEditingController();
  final _iconController = TextEditingController();
  bool _isValid = false;

  void _validateInput() {
    setState(() {
      _isValid = _textController.text.isNotEmpty && _iconController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(_validateInput);
    _iconController.addListener(_validateInput);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white.withOpacity(0.9),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Create New Card',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Phrase',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => HapticFeedback.selectionClick(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _iconController,
            decoration: const InputDecoration(
              labelText: 'Emoji',
              border: OutlineInputBorder(),
            ),
            maxLength: 2,
            onChanged: (_) => HapticFeedback.selectionClick(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        AnimatedOpacity(
          opacity: _isValid ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: TextButton(
            onPressed: _isValid
                ? () {
                    HapticFeedback.mediumImpact();
                    widget.onAdd(_textController.text, _iconController.text);
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Add'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _iconController.dispose();
    super.dispose();
  }
}
