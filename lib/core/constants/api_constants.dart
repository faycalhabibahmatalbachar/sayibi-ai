/// URLs API — Dio utilisera `resolvedApiRoot` comme base.
class ApiConstants {
  ApiConstants._();

  /// Backend déployé par défaut ; en local : `--dart-define=API_HOST=http://127.0.0.1:8000`
  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'https://sayibi-backend.onrender.com',
  );

  static const String apiPrefix = '/api/v1';

  /// Base complète pour Dio : http://host/api/v1
  static String get resolvedApiRoot {
    final h = host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    return '$h$apiPrefix';
  }

  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authRefresh = '/auth/refresh';

  static const String chatMessage = '/chat/message';
  static const String chatStream = '/chat/stream';
  static String chatHistory(String id) => '/chat/history/$id';
  static const String chatSessions = '/chat/sessions';
  static String chatSessionDelete(String id) => '/chat/session/$id';

  static const String voiceTranscribe = '/voice/transcribe';
  static const String voiceSynthesize = '/voice/synthesize';

  static const String documentsUpload = '/documents/upload';
  static const String documentsAsk = '/documents/ask';
  static const String documentsSummarize = '/documents/summarize';

  static const String searchWeb = '/search/web';
  static const String searchAnswer = '/search/answer';

  static const String userProfile = '/user/profile';
  static const String userSettings = '/user/settings';
  static const String userUsage = '/user/usage';
  static const String userFiles = '/user/files';
}
