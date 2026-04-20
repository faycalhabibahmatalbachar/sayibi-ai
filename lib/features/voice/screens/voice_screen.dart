import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/voice_provider.dart';
import '../widgets/waveform_widget.dart';

class VoiceScreen extends ConsumerWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(voiceProvider);
    final busy = v.ui == VoiceUiState.processing;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Dictée vocale',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.darkTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mode conversation continue: parle, l’IA répond en audio, puis écoute reprend automatiquement. Bouton Arrêter pour quitter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          WaveformWidget(active: v.ui == VoiceUiState.listening || busy),
          const Spacer(),
          if (v.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                v.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
          if (v.transcript.isNotEmpty)
            Text(
              'Vous: ${v.transcript}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 15, height: 1.4),
            ),
          if (v.assistantReply.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'IA: ${v.assistantReply}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 14, height: 1.35),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: busy
                ? null
                : () {
                    ref.read(voiceProvider.notifier).toggleRecording();
                  },
            icon: Icon(
              v.callActive ? Icons.call_end_rounded : Icons.phone_in_talk_rounded,
            ),
            label: Text(
              busy
                  ? (v.ui == VoiceUiState.speaking ? 'L’IA parle…' : 'Traitement…')
                  : (v.callActive ? 'Arrêter' : 'Démarrer la conversation'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            v.callActive
                ? (v.ui == VoiceUiState.listening
                    ? 'J’écoute...'
                    : v.ui == VoiceUiState.speaking
                        ? 'Je réponds...'
                        : 'Traitement...')
                : 'Appuie pour lancer.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
