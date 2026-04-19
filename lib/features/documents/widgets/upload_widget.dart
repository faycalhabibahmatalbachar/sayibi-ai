import 'package:flutter/material.dart';

class UploadWidget extends StatelessWidget {
  const UploadWidget({super.key, required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      child: Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: const Text('Glissez-déposez ou touchez pour importer (PDF, DOCX, image…)'),
      ),
    );
  }
}
