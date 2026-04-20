import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/utils/http_error_message.dart';
import '../../auth/providers/auth_provider.dart';

enum VoiceUiState { idle, listening, processing, speaking }

const Map<String, String> sayibiVoiceOptions = {
  'ahmat': 'Ahmat',
  'brahim': 'Brahim',
  'mariam': 'Mariam',
  'hassane': 'Hassane',
};

const String _voicePrefKey = 'sayibi_voice_selected';

class VoiceState {
  const VoiceState({
    this.isRecording = false,
    this.isSpeaking = false,
    this.error,
    this.ui = VoiceUiState.idle,
    this.transcript = '',
    this.assistantReply = '',
    this.callActive = false,
    this.selectedVoice = 'ahmat',
  });

  final bool isRecording;
  final bool isSpeaking;
  final String? error;
  final VoiceUiState ui;
  final String transcript;
  final String assistantReply;
  final bool callActive;
  final String selectedVoice;

  static const Object _unset = Object();

  VoiceState copyWith({
    bool? isRecording,
    bool? isSpeaking,
    Object? error = _unset,
    VoiceUiState? ui,
    String? transcript,
    String? assistantReply,
    bool? callActive,
    String? selectedVoice,
  }) {
    return VoiceState(
      isRecording: isRecording ?? this.isRecording,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      error: identical(error, _unset) ? this.error : error as String?,
      ui: ui ?? this.ui,
      transcript: transcript ?? this.transcript,
      assistantReply: assistantReply ?? this.assistantReply,
      callActive: callActive ?? this.callActive,
      selectedVoice: selectedVoice ?? this.selectedVoice,
    );
  }
}

class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier(this._ref) : super(const VoiceState()) {
    _loadSelectedVoice();
  }

  final Ref _ref;
  String? _sessionId;

  Future<void> _loadSelectedVoice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = (prefs.getString(_voicePrefKey) ?? '').trim().toLowerCase();
      if (sayibiVoiceOptions.containsKey(v)) {
        state = state.copyWith(selectedVoice: v);
      }
    } catch (_) {}
  }

  Future<void> setSelectedVoice(String voiceKey) async {
    final v = voiceKey.trim().toLowerCase();
    if (!sayibiVoiceOptions.containsKey(v)) return;
    state = state.copyWith(selectedVoice: v);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_voicePrefKey, v);
    } catch (_) {}
  }

  Future<T> _withRetry<T>(
    Future<T> Function() run, {
    int attempts = 2,
    Duration delay = const Duration(milliseconds: 350),
  }) async {
    Object? lastError;
    for (var i = 0; i < attempts; i++) {
      try {
        return await run();
      } catch (e) {
        lastError = e;
        if (i < attempts - 1) {
          await Future<void>.delayed(delay);
        }
      }
    }
    throw lastError ?? Exception('Echec apres retry');
  }

  Future<String> transcribeAudio(String audioPath) async {
    try {
      state = state.copyWith(ui: VoiceUiState.processing, error: null);
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception('Fichier audio introuvable');
      }

      final formData = FormData.fromMap({
        // Backend attend "file" (et supporte aussi "audio" en compat).
        'file': await MultipartFile.fromFile(
          audioPath,
          filename: p.basename(audioPath),
        ),
      });

      final response = await _withRetry(
        () => _ref.read(apiServiceProvider).client.post<Map<String, dynamic>>(
              ApiConstants.voiceTranscribe,
              data: formData,
            ),
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
      var msg = httpErrorMessage(e);
      if (e is DioException &&
          e.response?.statusCode == 422 &&
          (e.response?.data?.toString().contains('file') ?? false)) {
        msg = 'Format audio invalide ou champ fichier manquant.';
      }
      state = state.copyWith(
        error: 'Erreur transcription: $msg',
        ui: VoiceUiState.idle,
      );
      rethrow;
    }
  }

  Future<String> generateVoiceResponse(String userMessage) async {
    try {
      state = state.copyWith(ui: VoiceUiState.processing, error: null);
      final response = await _withRetry(
        () => _ref.read(apiServiceProvider).client.post<Map<String, dynamic>>(
              ApiConstants.chatMessage,
              data: {
                'message': userMessage,
                'voice_mode': true,
                if (_sessionId != null) 'session_id': _sessionId,
              },
            ),
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
      state = state.copyWith(
        error: 'Erreur generation reponse: ${httpErrorMessage(e)}',
        ui: VoiceUiState.idle,
      );
      rethrow;
    }
  }

  Future<String> synthesizeSpeech(String text) async {
    try {
      state = state.copyWith(isSpeaking: true, ui: VoiceUiState.speaking, error: null);
      final dio = _ref.read(apiServiceProvider).client;
      final currentVoice = state.selectedVoice;

      Future<String?> fetchRawAudio(String voiceKey) async {
        try {
          final raw = await dio.post<List<int>>(
            ApiConstants.voiceSynthesize,
            queryParameters: const {'raw': true},
            data: {'text': text, 'language': 'fr', 'voice': voiceKey},
            options: Options(responseType: ResponseType.bytes),
          );
          final bytes = raw.data;
          if (bytes == null || bytes.isEmpty) return null;
          final dir = await getTemporaryDirectory();
          final file = File(
            p.join(dir.path, 'sayibi_tts_${DateTime.now().millisecondsSinceEpoch}.mp3'),
          );
          await file.writeAsBytes(bytes, flush: true);
          return file.path;
        } on DioException catch (_) {
          return null;
        } catch (_) {
          return null;
        }
      }

      // Priorité: récupérer directement les bytes audio puis stocker localement.
      final fromRawCurrent = await fetchRawAudio(currentVoice);
      if (fromRawCurrent != null) return fromRawCurrent;

      // Fallback voix: si la voix choisie échoue (404/format), tenter Ahmat.
      if (currentVoice != 'ahmat') {
        final fromRawFallback = await fetchRawAudio('ahmat');
        if (fromRawFallback != null) {
          return fromRawFallback;
        }
      }

      final response = await dio.post<Map<String, dynamic>>(
        ApiConstants.voiceSynthesize,
        data: {'text': text, 'language': 'fr', 'voice': currentVoice},
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
      final fallback = body['audio_path'] as String?;
      if (fallback != null && fallback.isNotEmpty) return fallback;
      throw Exception('Chemin audio manquant');
    } catch (e) {
      var pretty = httpErrorMessage(e);
      final raw = e.toString();
      if (raw.contains('ELEVENLABS_API_KEY invalide') ||
          raw.contains('401 Unauthorized') ||
          raw.contains('clé ElevenLabs invalide')) {
        pretty =
            'Serveur TTS: clé ElevenLabs invalide/expirée. '
            'Le backend doit mettre à jour ELEVENLABS_API_KEY '
            'ou activer KOKORO_TTS_URL.';
      } else if (raw.contains('Aucun service TTS opérationnel')) {
        pretty =
            'Serveur TTS indisponible. Vérifiez ELEVENLABS_API_KEY '
            'ou configurez KOKORO_TTS_URL.';
      }
      state = state.copyWith(
        isSpeaking: false,
        ui: VoiceUiState.idle,
        error: 'Erreur synthese vocale: $pretty',
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
