import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';

enum VoiceUiState { idle, listening, processing, speaking }

class VoiceState {
  const VoiceState({
    this.isRecording = false,
    this.isSpeaking = false,
    this.error,
    this.ui = VoiceUiState.idle,
    this.transcript = '',
    this.assistantReply = '',
    this.callActive = false,
  });

  final bool isRecording;
  final bool isSpeaking;
  final String? error;
  final VoiceUiState ui;
  final String transcript;
  final String assistantReply;
  final bool callActive;

  static const Object _unset = Object();

  VoiceState copyWith({
    bool? isRecording,
    bool? isSpeaking,
    Object? error = _unset,
    VoiceUiState? ui,
    String? transcript,
    String? assistantReply,
    bool? callActive,
  }) {
    return VoiceState(
      isRecording: isRecording ?? this.isRecording,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      error: identical(error, _unset) ? this.error : error as String?,
      ui: ui ?? this.ui,
      transcript: transcript ?? this.transcript,
      assistantReply: assistantReply ?? this.assistantReply,
      callActive: callActive ?? this.callActive,
    );
  }
}

class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier(this._ref) : super(const VoiceState());

  final Ref _ref;
  String? _sessionId;

  Future<String> transcribeAudio(String audioPath) async {
    try {
      state = state.copyWith(ui: VoiceUiState.processing, error: null);
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Fichier audio introuvable');
      }

      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioPath,
          filename: p.basename(audioPath),
        ),
      });

      final response = await _ref.read(apiServiceProvider).client.post<Map<String, dynamic>>(
            ApiConstants.voiceTranscribe,
            data: formData,
          );
      final body = response.data;
      if (body == null) {
        throw Exception('Reponse vide du serveur de transcription');
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception(body['message']?.toString() ?? 'Transcription invalide');
      }
      final text = data['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw Exception('Transcription vide');
      }
      state = state.copyWith(transcript: text.trim(), ui: VoiceUiState.idle);
      return text.trim();
    } catch (e) {
      state = state.copyWith(error: 'Erreur transcription: $e', ui: VoiceUiState.idle);
      rethrow;
    }
  }

  Future<String> generateVoiceResponse(String userMessage) async {
    try {
      state = state.copyWith(ui: VoiceUiState.processing, error: null);
      final response = await _ref.read(apiServiceProvider).client.post<Map<String, dynamic>>(
            ApiConstants.chatMessage,
            data: {
              'message': userMessage,
              'voice_mode': true,
              if (_sessionId != null) 'session_id': _sessionId,
            },
          );
      final body = response.data;
      if (body == null) {
        throw Exception('Reponse vide du modele');
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception(body['message']?.toString() ?? 'Reponse invalide');
      }
      final session = data['session_id'] as String?;
      if (session != null && session.isNotEmpty) {
        _sessionId = session;
      }
      final aiText = data['response'] as String?;
      if (aiText == null || aiText.trim().isEmpty) {
        throw Exception('Reponse IA vide');
      }
      state = state.copyWith(assistantReply: aiText.trim(), ui: VoiceUiState.idle);
      return aiText.trim();
    } catch (e) {
      state = state.copyWith(error: 'Erreur generation reponse: $e', ui: VoiceUiState.idle);
      rethrow;
    }
  }

  Future<String> synthesizeSpeech(String text) async {
    try {
      state = state.copyWith(isSpeaking: true, ui: VoiceUiState.speaking, error: null);
      final response = await _ref.read(apiServiceProvider).client.post<Map<String, dynamic>>(
            ApiConstants.voiceSynthesize,
            data: {
              'text': text,
              'language': 'fr',
              'voice': 'default',
            },
          );
      final body = response.data;
      if (body == null) {
        throw Exception('Reponse TTS vide');
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception(body['message']?.toString() ?? 'Synthese invalide');
      }
      final fromApi = data['audio_path'] as String?;
      if (fromApi != null && fromApi.isNotEmpty) {
        return fromApi;
      }

      // Fallback: certains backends renvoient directement un URL.
      final fallback = body['audio_path'] as String?;
      if (fallback != null && fallback.isNotEmpty) {
        return fallback;
      }
      throw Exception('Chemin audio manquant');
    } catch (e) {
      state = state.copyWith(
        isSpeaking: false,
        ui: VoiceUiState.idle,
        error: 'Erreur synthese vocale: $e',
      );
      rethrow;
    }
  }

  Future<void> toggleRecording() async {
    if (state.callActive) {
      await stopConversation();
    } else {
      await startConversation();
    }
  }

  Future<void> startConversation() async {
    if (!_ref.read(authProvider).authenticated) {
      state = state.copyWith(error: 'Connectez-vous pour utiliser la voix.');
      return;
    }
    state = state.copyWith(
      callActive: true,
      ui: VoiceUiState.listening,
      transcript: '',
      assistantReply: '',
      error: null,
    );
  }

  Future<void> stopConversation() async {
    state = state.copyWith(
      callActive: false,
      ui: VoiceUiState.idle,
      isRecording: false,
      isSpeaking: false,
    );
  }

  Future<bool> ensurePermission() async => true;

  Future<String> createTempAudioPath() async {
    final dir = await getTemporaryDirectory();
    return p.join(dir.path, 'sayibi_voice_${DateTime.now().millisecondsSinceEpoch}.wav');
  }

  void stopSpeaking() {
    state = state.copyWith(isSpeaking: false, ui: VoiceUiState.idle);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  return VoiceNotifier(ref);
});
