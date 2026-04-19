import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VoiceUiState { idle, listening, processing, speaking }

class VoiceState {
  const VoiceState({
    this.ui = VoiceUiState.idle,
    this.transcript = '',
    this.error,
  });

  final VoiceUiState ui;
  final String transcript;
  final String? error;

  VoiceState copyWith({VoiceUiState? ui, String? transcript, String? error}) {
    return VoiceState(
      ui: ui ?? this.ui,
      transcript: transcript ?? this.transcript,
      error: error,
    );
  }
}

class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier() : super(const VoiceState());

  void setUi(VoiceUiState u) => state = state.copyWith(ui: u);

  void setTranscript(String t) => state = state.copyWith(transcript: t);
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  return VoiceNotifier();
});
