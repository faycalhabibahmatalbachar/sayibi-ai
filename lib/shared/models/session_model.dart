class SessionModel {
  SessionModel({
    required this.id,
    required this.title,
    this.createdAt,
  });

  final String id;
  final String title;
  final DateTime? createdAt;
}
