import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/http_error_message.dart';
import '../../../core/utils/sse_stream.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/message_model.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.error,
    this.sessionId,
    this.modelPreference = 'auto',
    this.isGeneratingFile = false,
    this.generatingFileType = 'cv',
  });

  final List<MessageModel> messages;
  final bool loading;
  final String? error;
  final String? sessionId;

  /// Identifiant modèle ChadGpt (sayibi-*) ou legacy (groq, gemini, mistral, auto).
  final String modelPreference;

  final bool isGeneratingFile;
  final String generatingFileType;

  bool get isLoading => loading;

  String get selectedModel => modelPreference;

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? loading,
    Object? error = _sentinel,
    String? sessionId,
    String? modelPreference,
    bool? isGeneratingFile,
    String? generatingFileType,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      sessionId: sessionId ?? this.sessionId,
      modelPreference: modelPreference ?? this.modelPreference,
      isGeneratingFile: isGeneratingFile ?? this.isGeneratingFile,
      generatingFileType: generatingFileType ?? this.generatingFileType,
    );
  }

  static const Object _sentinel = Object();
}

String _userFacingChatError(Object e) {
  return httpErrorMessage(e, fallback: e.toString());
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref) : super(const ChatState());

  final Ref _ref;

  void selectModel(String m) {
    state = state.copyWith(modelPreference: m);
  }

  /// @deprecated Utiliser [selectModel].
  void setModel(String m) => selectModel(m);

  void newSession() {
    state = ChatState(modelPreference: state.modelPreference);
  }

  String _displayModelLabel() {
    final m = state.modelPreference;
    const map = {
      'auto': 'Auto',
      'sayibi-reflexion': 'ChadGpt · Réflexion',
      'sayibi-images': 'ChadGpt · Images',
      'sayibi-nadirx': 'ChadGpt · NadirX',
      'sayibi-voix': 'ChadGpt · Voix',
      'sayibi-code': 'ChadGpt · Code',
      'sayibi-creation': 'ChadGpt · Création',
      'groq': 'Groq',
      'gemini': 'Gemini',
      'mistral': 'Mistral',
    };
    return map[m] ?? m;
  }

  void _applyStreamMetadata(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) return;
    final msgs = [...state.messages];
    if (msgs.isEmpty) return;
    final last = msgs.last;
    if (last.role != 'assistant') return;
    List<String>? imageUrls = last.imageUrls;
    final iu = raw['image_urls'];
    if (iu is List && iu.isNotEmpty) {
      imageUrls = iu.map((e) => e.toString()).toList();
    }
    final meta = <String, dynamic>{...?last.metadata};
    if (raw['sources'] != null) {
      meta['sources'] = raw['sources'];
    }
    if (raw['generated_file'] != null) {
      meta['generated_file'] = raw['generated_file'];
    }
    if (raw['device_action'] != null) {
      meta['device_action'] = raw['device_action'];
    }
    if (raw['search_images'] != null) {
      meta['search_images'] = raw['search_images'];
    }
    msgs[msgs.length - 1] = MessageModel(
      role: last.role,
      content: last.content,
      createdAt: last.createdAt,
      modelUsed: last.modelUsed,
      imageUrls: imageUrls,
      metadata: meta.isEmpty ? last.metadata : meta,
      isStreaming: last.isStreaming,
    );
    state = state.copyWith(messages: msgs);
  }

  void _setLastAssistantContent(String content, {required bool streaming}) {
    final msgs = [...state.messages];
    if (msgs.isEmpty) return;
    final last = msgs.last;
    if (last.role != 'assistant') return;
    msgs[msgs.length - 1] = MessageModel(
      role: last.role,
      content: content,
      createdAt: last.createdAt,
      modelUsed: streaming ? null : _displayModelLabel(),
      imageUrls: last.imageUrls,
      metadata: last.metadata,
      isStreaming: streaming,
    );
    state = state.copyWith(messages: msgs);
  }

  void _dropEmptyAssistantIfAny() {
    final msgs = state.messages;
    if (msgs.isEmpty) return;
    final last = msgs.last;
    if (last.role == 'assistant' && last.content.isEmpty) {
      state = state.copyWith(messages: msgs.sublist(0, msgs.length - 1));
    }
  }

  Future<void> sendMessage({
    required String text,
    bool webSearch = false,
    String? documentId,
    bool createMode = false,
    String? createType,
  }) async {
    if (text.trim().isEmpty) return;
    final userMsg = MessageModel(role: 'user', content: text.trim());
    final genFile = createMode;
    final gType = createType ?? 'cv';
    final assistantPlaceholder = MessageModel(
      role: 'assistant',
      content: '',
      isStreaming: true,
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantPlaceholder],
      loading: true,
      error: null,
      isGeneratingFile: genFile,
      generatingFileType: gType,
    );

    try {
      final dio = _ref.read(apiServiceProvider).client;
      final res = await dio.post<dynamic>(
        ApiConstants.chatStream,
        data: {
          'message': text,
          'session_id': state.sessionId,
          'language': 'auto',
          'model_preference': state.modelPreference,
          'web_search': webSearch,
          'document_id': documentId,
          'create_mode': createMode,
          'create_type': createType,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final data = res.data;
      if (data is! ResponseBody) {
        throw StateError('Flux SSE indisponible');
      }

      var accumulated = '';
      String? sessionOut;
      Map<String, dynamic>? doneMeta;

      await for (final map in parseSseJsonStream(data)) {
        if (map.containsKey('chunk')) {
          final c = map['chunk'] as String? ?? '';
          accumulated += c;
          _setLastAssistantContent(accumulated, streaming: true);
        } else if (map.containsKey('metadata') && map['done'] != true) {
          final m = map['metadata'];
          if (m is Map<String, dynamic>) {
            _applyStreamMetadata(m);
          } else if (m is Map) {
            _applyStreamMetadata(Map<String, dynamic>.from(m));
          }
        } else if (map['done'] == true) {
          sessionOut = map['session_id'] as String?;
          final m = map['metadata'];
          if (m is Map<String, dynamic>) {
            doneMeta = m;
          } else if (m is Map) {
            doneMeta = Map<String, dynamic>.from(m);
          }
        } else if (map.containsKey('error')) {
          throw map['error'] ?? 'Erreur serveur';
        }
      }

      _setLastAssistantContent(accumulated, streaming: false);
      _applyStreamMetadata(doneMeta);
      state = state.copyWith(
        loading: false,
        sessionId: sessionOut ?? state.sessionId,
        isGeneratingFile: false,
      );
    } catch (e) {
      _dropEmptyAssistantIfAny();
      state = state.copyWith(
        loading: false,
        error: _userFacingChatError(e),
        isGeneratingFile: false,
      );
    }
  }

  /// Compatibilité avec l'ancien appel [send].
  Future<void> send(String text, {String language = 'auto'}) =>
      sendMessage(text: text);

  Future<void> regenerateLastMessage({
    bool webSearch = false,
    String? documentId,
    bool createMode = false,
    String? createType,
  }) async {
    final msgs = state.messages;
    if (msgs.length < 2) return;
    if (msgs.last.role != 'assistant') return;
    final userContent = msgs[msgs.length - 2].content;
    if (msgs[msgs.length - 2].role != 'user') return;
    state = state.copyWith(messages: msgs.sublist(0, msgs.length - 1));
    await sendMessage(
      text: userContent,
      webSearch: webSearch,
      documentId: documentId,
      createMode: createMode,
      createType: createType,
    );
  }

  void clear() {
    state = ChatState(modelPreference: state.modelPreference);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Messages locaux pour le mode agent (hors flux SSE).
  void appendAgentUserMessage(String text) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        MessageModel(role: 'user', content: text.trim()),
      ],
    );
  }

  void appendAgentAssistantMessage(
    String text, {
    Map<String, dynamic>? metadata,
  }) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        MessageModel(
          role: 'assistant',
          content: text,
          metadata: metadata,
          modelUsed: 'ChadGpt · Actions',
        ),
      ],
    );
  }

  /// Charge une session existante (tiroir historique).
  Future<void> loadSession(String sessionId) async {
    if (sessionId.isEmpty) return;
    state = state.copyWith(loading: true, error: null);
    try {
      final dio = _ref.read(apiServiceProvider).client;
      final res = await dio.get<dynamic>(
        ApiConstants.chatHistory(sessionId),
        queryParameters: {'page': 1, 'page_size': 100},
      );
      final body = res.data;
      if (body is! Map || body['success'] != true) {
        throw StateError('Historique indisponible');
      }
      final data = body['data'];
      if (data is! Map) {
        throw StateError('Réponse invalide');
      }
      final raw = data['messages'];
      final out = <MessageModel>[];
      if (raw is List) {
        for (final row in raw) {
          if (row is! Map) continue;
          final role = row['role']?.toString() ?? 'user';
          final content = row['content']?.toString() ?? '';
          out.add(MessageModel(role: role, content: content));
        }
      }
      state = state.copyWith(
        sessionId: sessionId,
        messages: out,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: _userFacingChatError(e),
      );
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
