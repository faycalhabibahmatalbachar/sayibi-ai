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
  /// Échange du JWT Supabase (#access_token) contre les jetons applicatifs après confirmation e-mail.
  static const String authSupabaseSession = '/auth/supabase-session';

  /// Même base que [PUBLIC_APP_URL] côté backend (ex. https://sayibi-web.onrender.com).
  static const String appPublicOrigin = String.fromEnvironment(
    'APP_PUBLIC_URL',
    defaultValue: 'https://sayibi-web.onrender.com',
  );

  static const String chatMessage = '/chat/message';
  static const String chatStream = '/chat/stream';
  static String chatHistory(String id) => '/chat/history/$id';
  static const String chatSessions = '/chat/sessions';
  static String chatSessionDelete(String id) => '/chat/session/$id';

  static const String voiceTranscribe = '/voice/transcribe';
  static const String voiceSynthesize = '/voice/synthesize';
  static const String imageHealth = '/image/health';
  static const String alarms = '/alarms';

  static const String documentsUpload = '/documents/upload';
  static const String documentsAsk = '/documents/ask';
  static const String documentsSummarize = '/documents/summarize';

  static const String searchWeb = '/search/web';
  static const String searchAnswer = '/search/answer';

  static const String userProfile = '/user/profile';
  static const String userSettings = '/user/settings';
  static const String userUsage = '/user/usage';
  static const String userFiles = '/user/files';
  static const String userFcmToken = '/user/fcm-token';
  static const String userNotifyTest = '/user/notify-test';
  static const String userNotifyContextual = '/user/notify-contextual';

  /// Mode agent (JSON structuré : intentions, confirmation, ambiguïtés).
  static const String agentTurn = '/agent/turn';
  static const String agentLog = '/agent/log';
  static const String agentContactResolution = '/agent/contact-resolution';
  static const String agentMemorySummary = '/agent/memory-summary';
  static const String agentSmsDraft = '/agent/actions/sms/draft';
  static const String agentSmsConfirm = '/agent/actions/sms/confirm';
  static const String agentSmsExecute = '/agent/actions/sms/execute';
  static const String agentSmsList = '/agent/actions/sms';
  static const String agentContactsSync = '/agent/actions/contacts/sync';
  static const String agentContactsSearch = '/agent/actions/contacts/search';
}
