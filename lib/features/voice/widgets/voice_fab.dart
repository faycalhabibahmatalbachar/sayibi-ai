import 'package:flutter/material.dart';

class VoiceFab extends StatelessWidget {
  const VoiceFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: const Icon(Icons.mic),
    );
  }
}
