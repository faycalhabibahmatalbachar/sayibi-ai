import 'package:flutter/material.dart';

class GenerationProgress extends StatelessWidget {
  const GenerationProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: LinearProgressIndicator(),
    );
  }
}
