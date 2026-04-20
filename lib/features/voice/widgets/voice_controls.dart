// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../screens/voice_call_screen.dart';

class VoiceControls extends StatelessWidget {
  const VoiceControls({
    super.key,
    required this.currentState,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.isRecording,
    required this.onMuteToggle,
    required this.onSpeakerToggle,
    required this.onMicPressed,
    required this.onMicReleased,
    required this.onEndCall,
  });

  final VoiceCallState currentState;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isRecording;
  final VoidCallback onMuteToggle;
  final VoidCallback onSpeakerToggle;
  final VoidCallback onMicPressed;
  final VoidCallback onMicReleased;
  final VoidCallback onEndCall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: isMuted ? 'Muet' : 'Micro',
            isActive: isMuted,
            activeColor: AppColors.warning,
            onTap: onMuteToggle,
          ),
          _buildMainMicButton(),
          _buildControlButton(
            icon: isSpeakerOn ? Icons.volume_up_rounded : Icons.phone_in_talk_rounded,
            label: isSpeakerOn ? 'Haut-parleur' : 'Ecouteur',
            isActive: isSpeakerOn,
            activeColor: AppColors.info,
            onTap: onSpeakerToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildMainMicButton() {
    final canRecord =
        currentState == VoiceCallState.idle || currentState == VoiceCallState.listening;

    return Semantics(
      label: isRecording ? 'Arreter enregistrement' : 'Demarrer enregistrement',
      button: true,
      child: GestureDetector(
        onTapDown: canRecord
            ? (_) {
                HapticFeedback.lightImpact();
                onMicPressed();
              }
            : null,
        onTapUp: canRecord
            ? (_) {
                HapticFeedback.selectionClick();
                onMicReleased();
              }
            : null,
        onTapCancel: canRecord ? onMicReleased : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isRecording ? 90 : 80,
          height: isRecording ? 90 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isRecording
                ? const LinearGradient(colors: [AppColors.error, Color(0xFFDC2626)])
                : AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: (isRecording ? AppColors.error : AppColors.primary).withOpacity(0.5),
                blurRadius: isRecording ? 30 : 20,
                spreadRadius: isRecording ? 8 : 4,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isRecording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: isRecording ? 40 : 36,
            ),
          ),
        ),
      )
          .animate(target: isRecording ? 1 : 0)
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.1, 1.1),
            duration: 200.ms,
          ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:
                    isActive ? activeColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? activeColor.withOpacity(0.6)
                      : Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isActive ? activeColor : Colors.white.withOpacity(0.7),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
