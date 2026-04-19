import 'package:flutter/material.dart';

class SuggestionChips extends StatelessWidget {
  const SuggestionChips({super.key, required this.items, required this.onSelect});

  final List<String> items;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (t) => ActionChip(
              label: Text(t),
              onPressed: () => onSelect(t),
            ),
          )
          .toList(),
    );
  }
}
