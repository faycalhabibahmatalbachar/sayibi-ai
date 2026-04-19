class DocumentModel {
  DocumentModel({
    required this.id,
    required this.filename,
    this.preview,
  });

  final String id;
  final String filename;
  final String? preview;
}
