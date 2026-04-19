/// Détection simple de direction (RTL pour l'arabe).
bool isRtlLocale(String? code) {
  if (code == null) return false;
  return code.toLowerCase().startsWith('ar');
}
