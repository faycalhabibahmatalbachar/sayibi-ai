import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/message_model.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.error,
    this.sessionId,
    this.modelPreference = 'auto',
  });

  final List<MessageModel> messages;
  final bool loading;
  final String? error;
  final String? sessionId;
  final String modelPreference;

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? loading,
    String? error,
    String? sessionId,
    String? modelPreference,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      error: error,
      sessionId: sessionId ?? this.sessionId,
      modelPreference: modelPreference ?? this.modelPreference,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref) : super(const ChatState());

  final Ref _ref;

  void setModel(String m) {
    state = state.copyWith(modelPreference: m);
  }

  Future<void> send(String text, {String language = 'auto'}) async {
    if (text.trim().isEmpty) return;
    final userMsg = MessageModel(role: 'user', content: text.trim());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      loading: true,
      error: null,
    );
    try {
      final dio = _ref.read(apiServiceProvider).client;
      final res = await dio.post(
        ApiConstants.chatMessage,
        data: {
          'message': text,
          'session_id': state.sessionId,
          'language': language,
          'model_preference': state.modelPreference,
        },
      );
      final data = res.data as Map<String, dynamic>;
      if (data['success'] == true && data['data'] != null) {
        final d = data['data'] as Map<String, dynamic>;
        final reply = d['response'] as String? ?? '';
        final sid = d['session_id'] as String?;
        state = state.copyWith(
          messages: [
            ...state.messages,
            MessageModel(role: 'assistant', content: reply),
          ],
          loading: false,
          sessionId: sid ?? state.sessionId,
        );
        return;
      }
      state = state.copyWith(loading: false, error: data['message']?.toString());
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void clear() {
    state = const ChatState();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
