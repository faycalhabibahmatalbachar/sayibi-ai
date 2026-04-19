class MessageModel {
  MessageModel({
    required this.role,
    required this.content,
    this.createdAt,
  });

  final String role;
  final String content;
  final DateTime? createdAt;
}
