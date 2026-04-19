import 'package:flutter/material.dart';

class DocChatScreen extends StatelessWidget {
  const DocChatScreen({super.key, required this.docId});

  final String docId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document $docId')),
      body: const Center(child: Text('Posez des questions sur ce document (API /documents/ask).')),
    );
  }
}
