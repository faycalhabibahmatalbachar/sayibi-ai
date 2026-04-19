String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email requis';
  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
  return ok ? null : 'Email invalide';
}

String? validatePassword(String? v) {
  if (v == null || v.length < 8) return '8 caractères minimum';
  return null;
}
