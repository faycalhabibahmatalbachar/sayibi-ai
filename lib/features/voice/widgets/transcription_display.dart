// ignore_for_file: deprecated_member_use

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../screens/voice_call_screen.dart';

class TranscriptionDisplay extends StatelessWidget {
  const TranscriptionDisplay({
    super.key,
    required this.userText,
    required this.aiText,
    required this.currentState,
  });

  final String userText;
  final String aiText;
  final VoiceCallState currentState;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Zone de transcription vocale',
      child: Container(
        constraints: const BoxConstraints(maxHeight: 180),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userText.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.info, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        userText,
                        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, duration: 300.ms),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                const SizedBox(height: 16),
              ],
              if (aiText.isNotEmpty)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'S',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: currentState == VoiceCallState.speaking
                          ? AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  aiText,
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  speed: const Duration(milliseconds: 40),
                                ),
                              ],
                              isRepeatingAnimation: false,
                              displayFullTextOnTap: true,
                            )
                          : Text(
                              aiText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, duration: 300.ms),
              if (userText.isEmpty && aiText.isEmpty)
                Center(
                  child: Text(
                    'Les transcriptions apparaitront ici...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
