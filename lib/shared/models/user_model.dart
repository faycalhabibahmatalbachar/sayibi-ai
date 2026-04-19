class UserModel {
  UserModel({
    required this.id,
    this.email,
    this.name,
    this.language,
  });

  final String id;
  final String? email;
  final String? name;
  final String? language;
}
