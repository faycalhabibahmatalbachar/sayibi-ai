import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/voice_provider.dart';
import '../widgets/waveform_widget.dart';

class VoiceScreen extends ConsumerWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(voiceProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text('État : ${v.ui.name}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          WaveformWidget(active: v.ui != VoiceUiState.idle),
          const Spacer(),
          if (v.transcript.isNotEmpty)
            Text(v.transcript, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              ref.read(voiceProvider.notifier).setUi(VoiceUiState.listening);
            },
            child: const Text('Simuler écoute'),
          ),
        ],
      ),
    );
  }
}
