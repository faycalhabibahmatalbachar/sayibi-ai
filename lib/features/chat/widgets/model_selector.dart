import 'package:flutter/material.dart';

class ModelSelector extends StatelessWidget {
  const ModelSelector({super.key, required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Auto'),
            selected: value == 'auto',
            onSelected: (_) => onChanged('auto'),
          ),
          ChoiceChip(
            label: const Text('Groq'),
            selected: value == 'groq',
            onSelected: (_) => onChanged('groq'),
          ),
          ChoiceChip(
            label: const Text('Gemini'),
            selected: value == 'gemini',
            onSelected: (_) => onChanged('gemini'),
          ),
          ChoiceChip(
            label: const Text('Mistral'),
            selected: value == 'mistral',
            onSelected: (_) => onChanged('mistral'),
          ),
        ],
      ),
    );
  }
}
