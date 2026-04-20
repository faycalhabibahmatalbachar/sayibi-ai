import 'package:dio/dio.dart';

String httpErrorMessage(Object error, {String fallback = 'Erreur réseau'}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final m = data['message']?.toString().trim();
      if (m != null && m.isNotEmpty) return m;
    }
    final code = error.response?.statusCode;
    if (code == 400) return 'Requête invalide.';
    if (code == 401 || code == 403) {
      return 'Session expirée ou accès refusé. Reconnectez-vous.';
    }
    if (code == 404) return 'Ressource introuvable.';
    if (code == 413) return 'Fichier trop volumineux.';
    if (code == 429) return 'Trop de requêtes. Réessayez dans un instant.';
    if (code != null && code >= 500) {
      return 'Serveur temporairement indisponible. Réessayez plus tard.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Délai dépassé. Vérifiez votre connexion.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Connexion impossible. Vérifiez internet.';
    }

    return error.message ?? fallback;
  }
  return fallback;
}
