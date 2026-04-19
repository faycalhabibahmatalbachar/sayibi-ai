import 'package:flutter/material.dart';

import '../../../shared/models/document_model.dart';

class DocCard extends StatelessWidget {
  const DocCard({super.key, required this.doc, required this.onTap});

  final DocumentModel doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file_outlined),
        title: Text(doc.filename),
        subtitle: Text(doc.preview ?? ''),
        onTap: onTap,
      ),
    );
  }
}
