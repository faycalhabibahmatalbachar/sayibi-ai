class MessageModel {
  MessageModel({
    required this.role,
    required this.content,
    this.createdAt,
    this.modelUsed,
    this.imageUrls,
    this.metadata,
    this.isStreaming = false,
  });

  final String role;
  final String content;
  final DateTime? createdAt;

  /// Libellé modèle (ChadGpt ou backend).
  final String? modelUsed;

  final List<String>? imageUrls;

  /// Ex. sources web, fichier généré (`generated_file`).
  final Map<String, dynamic>? metadata;

  /// Réponse assistant en cours de réception (flux SSE).
  final bool isStreaming;
}
