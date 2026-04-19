import 'package:flutter/material.dart';

import '../widgets/upload_widget.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UploadWidget(onPick: () {}),
          const SizedBox(height: 16),
          const Text('Vos documents apparaîtront ici après upload.'),
        ],
      ),
    );
  }
}
