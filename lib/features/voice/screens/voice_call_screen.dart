// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/voice_provider.dart';
import '../widgets/ai_voice_bubble.dart';
import '../widgets/transcription_display.dart';
import '../widgets/voice_controls.dart';
import '../widgets/waveform_visualizer.dart';

enum VoiceCallState {
  idle,
  listening,
  processing,
  speaking,
  paused,
  error,
}

class VoiceCallScreen extends ConsumerStatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen>
    with TickerProviderStateMixin {
  VoiceCallState _currentState = VoiceCallState.idle;

  DateTime? _callStartedAt;
  Duration _callDuration = Duration.zero;
  Timer? _callTimer;

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _vadTimer;
  DateTime? _lastVoiceAt;
  bool _speechDetected = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;
  StreamSubscription<void>? _playerCompleteSub;

  bool _hasMicPermission = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _retryCount = 0;

  String _userTranscription = '';
  String _aiResponse = '';

  late final AnimationController _bubbleAnimController;
  late final AnimationController _waveformAnimController;
  late final AnimationController _glowAnimController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    unawaited(_bootstrapCall());
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _vadTimer?.cancel();
    _amplitudeSub?.cancel();
    _playerCompleteSub?.cancel();
    unawaited(_audioRecorder.dispose());
    unawaited(_audioPlayer.dispose());
    _bubbleAnimController.dispose();
    _waveformAnimController.dispose();
    _glowAnimController.dispose();
    super.dispose();
  }

  void _initAnimations() {
    _bubbleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _waveformAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _glowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  Future<void> _bootstrapCall() async {
    await _checkPermissions();
    if (!mounted || !_hasMicPermission) return;
    _startCall();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    setState(() => _hasMicPermission = status.isGranted);

    if (!status.isGranted) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Permission microphone',
          style: TextStyle(color: AppColors.darkTextPrimary),
        ),
        content: const Text(
          'SAYIBI a besoin d\'acceder au microphone pour les conversations vocales.',
          style: TextStyle(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Parametres'),
          ),
        ],
      ),
    );
  }

  void _startCall() {
    if (!_hasMicPermission) return;
    HapticFeedback.mediumImpact();
    _callStartedAt = DateTime.now();
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _callStartedAt == null) return;
      setState(() => _callDuration = DateTime.now().difference(_callStartedAt!));
    });
    SemanticsService.announce('Appel vocal demarre', TextDirection.ltr);
    Future<void>.delayed(const Duration(milliseconds: 450), _startListening);
  }

  Future<void> _endCall() async {
    HapticFeedback.heavyImpact();
    _callTimer?.cancel();
    await _stopRecording(silentTransition: true);
    await _audioPlayer.stop();
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _startListening() async {
    if (_isSpeaking) {
      // Barge-in: l'utilisateur reprend la main immédiatement.
      await _audioPlayer.stop();
      _playerCompleteSub?.cancel();
      _bubbleAnimController.stop();
      _glowAnimController.stop();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _currentState = VoiceCallState.idle;
        });
      }
    }

    if (!_hasMicPermission ||
        _currentState == VoiceCallState.listening ||
        _currentState == VoiceCallState.processing ||
        _isMuted) {
      return;
    }

    setState(() {
      _currentState = VoiceCallState.listening;
      _userTranscription = '';
    });
    SemanticsService.announce('Mode ecoute actif', TextDirection.ltr);
    HapticFeedback.lightImpact();
    _bubbleAnimController.forward(from: 0);

    try {
      if (!await _audioRecorder.hasPermission()) {
        _handleError('Permission microphone indisponible.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'sayibi_voice_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 128000,
        ),
        path: path,
      );

      if (!mounted) return;
      setState(() => _isRecording = true);
      _speechDetected = false;
      _lastVoiceAt = DateTime.now();
      _amplitudeSub?.cancel();
      _amplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen((amp) {
        final current = amp.current;
        if (current > -34) {
          _speechDetected = true;
          _lastVoiceAt = DateTime.now();
        }
      });
      _vadTimer?.cancel();
      _vadTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
        if (!_isRecording || !_speechDetected || _lastVoiceAt == null) return;
        final silenceMs = DateTime.now().difference(_lastVoiceAt!).inMilliseconds;
        if (silenceMs >= 900) {
          unawaited(_stopRecording());
        }
      });
      Future<void>.delayed(const Duration(seconds: 25), () {
        if (_isRecording) {
          unawaited(_stopRecording());
        }
      });
    } catch (e) {
      _handleError('Erreur enregistrement: $e');
    }
  }

  Future<void> _stopRecording({bool silentTransition = false}) async {
    if (!_isRecording) return;
    _vadTimer?.cancel();
    _amplitudeSub?.cancel();

    if (!silentTransition) {
      setState(() {
        _isRecording = false;
        _currentState = VoiceCallState.processing;
      });
      SemanticsService.announce('Analyse en cours', TextDirection.ltr);
    } else {
      setState(() => _isRecording = false);
    }

    _bubbleAnimController.reverse();

    try {
      final path = await _audioRecorder.stop();
      if (path == null || path.isEmpty) {
        if (!silentTransition) _handleError('Aucun audio capture.');
        return;
      }
      if (!silentTransition) {
        await _processAudio(path);
      }
    } catch (e) {
      _handleError('Erreur traitement: $e');
    }
  }

  Future<void> _processAudio(String audioPath) async {
    final notifier = ref.read(voiceProvider.notifier);
    try {
      final transcription = await notifier.transcribeAudio(audioPath);
      if (!mounted) return;
      setState(() => _userTranscription = transcription);

      final aiResponse = await notifier.generateVoiceResponse(transcription);
      if (!mounted) return;
      setState(() => _aiResponse = aiResponse);

      final ttsAudioPath = await notifier.synthesizeSpeech(aiResponse);
      await _playAiResponse(ttsAudioPath);
      _retryCount = 0;
    } catch (e) {
      final stateError = ref.read(voiceProvider).error;
      _handleError(stateError != null && stateError.isNotEmpty
          ? stateError
          : 'Erreur traitement IA: $e');
    }
  }

  Future<void> _playAiResponse(String audioPath) async {
    setState(() {
      _currentState = VoiceCallState.speaking;
      _isSpeaking = true;
    });
    SemanticsService.announce('SAYIBI repond', TextDirection.ltr);

    _bubbleAnimController.repeat();
    if (!_glowAnimController.isAnimating) {
      _glowAnimController.repeat(reverse: true);
    }

    _playerCompleteSub?.cancel();
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        _currentState = VoiceCallState.idle;
      });
      _bubbleAnimController.stop();
      _glowAnimController.stop();
      Future<void>.delayed(const Duration(milliseconds: 450), _startListening);
    });

    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
        await _audioPlayer.play(UrlSource(audioPath));
      } else {
        await _audioPlayer.play(DeviceFileSource(audioPath));
      }
    } catch (e) {
      _handleError('Erreur lecture audio: $e');
    }
  }

  void _handleError(String error) {
    setState(() {
      _isRecording = false;
      _isSpeaking = false;
      _currentState = VoiceCallState.error;
    });
    SemanticsService.announce('Erreur vocale', TextDirection.ltr);
    _retryCount++;
    final canRetry = _retryCount < 3;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(error, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: canRetry
            ? SnackBarAction(
                label: 'Reessayer',
                textColor: Colors.white,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _currentState = VoiceCallState.idle);
                  _startListening();
                },
              )
            : null,
      ),
    );
  }

  void _toggleMute() {
    HapticFeedback.lightImpact();
    setState(() => _isMuted = !_isMuted);
    if (_isMuted && _isRecording) {
      unawaited(_stopRecording());
    }
    SemanticsService.announce(_isMuted ? 'Micro coupe' : 'Micro active', TextDirection.ltr);
  }

  void _toggleSpeaker() {
    HapticFeedback.lightImpact();
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    final mode = _isSpeakerOn ? PlayerMode.mediaPlayer : PlayerMode.lowLatency;
    _audioPlayer.setPlayerMode(mode);
    SemanticsService.announce(
      _isSpeakerOn ? 'Haut parleur active' : 'Ecouteur active',
      TextDirection.ltr,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(gradient: _getBackgroundGradient()),
        child: SafeArea(
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _glowAnimController,
                builder: (context, _) => _buildBackgroundParticles(),
              ),
              Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const Spacer(),
                  AIVoiceBubble(
                    state: _currentState,
                    isSpeaking: _isSpeaking,
                    animController: _bubbleAnimController,
                    glowController: _glowAnimController,
                  ),
                  const SizedBox(height: 40),
                  if (_currentState == VoiceCallState.listening ||
                      _currentState == VoiceCallState.speaking)
                    WaveformVisualizer(
                      isActive: _isRecording || _isSpeaking,
                      color: _getStateColor(),
                      animController: _waveformAnimController,
                    ),
                  const SizedBox(height: 20),
                  TranscriptionDisplay(
                    userText: _userTranscription,
                    aiText: _aiResponse,
                    currentState: _currentState,
                  ),
                  const Spacer(),
                  VoiceControls(
                    currentState: _currentState,
                    isMuted: _isMuted,
                    isSpeakerOn: _isSpeakerOn,
                    isRecording: _isRecording,
                    onMuteToggle: _toggleMute,
                    onSpeakerToggle: _toggleSpeaker,
                    onMicPressed: _startListening,
                    onMicReleased: _stopRecording,
                    onEndCall: _endCall,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
              _buildStatusIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            label: 'Duree de l appel ${_formatDuration(_callDuration.inSeconds)}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.error : AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .fadeIn(duration: 800.ms)
                      .then()
                      .fadeOut(duration: 800.ms),
                  const SizedBox(width: 10),
                  Text(
                    _formatDuration(_callDuration.inSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Semantics(
            label: 'Terminer l appel',
            button: true,
            child: GestureDetector(
              onTap: _endCall,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 24),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.05, 1.05),
                  duration: 1500.ms,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Positioned(
      top: 16,
      left: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _getStateColor().withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _getStateColor().withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getStateIcon(), color: _getStateColor(), size: 16),
            const SizedBox(width: 8),
            Text(
              _getStateLabel(),
              style: TextStyle(
                color: _getStateColor(),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2, duration: 300.ms),
    );
  }

  Widget _buildBackgroundParticles() {
    return Positioned.fill(
      child: CustomPaint(
        painter: ParticlesPainter(
          animationValue: _glowAnimController.value,
          color: _getStateColor(),
        ),
      ),
    );
  }

  LinearGradient _getBackgroundGradient() {
    switch (_currentState) {
      case VoiceCallState.listening:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF0A0E27)],
        );
      case VoiceCallState.processing:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF0A0E27)],
        );
      case VoiceCallState.speaking:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF0A0E27)],
        );
      case VoiceCallState.error:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF991B1B), Color(0xFF0A0E27)],
        );
      default:
        return AppColors.backgroundGradient;
    }
  }

  Color _getStateColor() {
    switch (_currentState) {
      case VoiceCallState.listening:
        return AppColors.info;
      case VoiceCallState.processing:
        return AppColors.primary;
      case VoiceCallState.speaking:
        return AppColors.success;
      case VoiceCallState.error:
        return AppColors.error;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  IconData _getStateIcon() {
    switch (_currentState) {
      case VoiceCallState.listening:
        return Icons.mic_rounded;
      case VoiceCallState.processing:
        return Icons.psychology_rounded;
      case VoiceCallState.speaking:
        return Icons.volume_up_rounded;
      case VoiceCallState.error:
        return Icons.error_outline_rounded;
      default:
        return Icons.phone_in_talk_rounded;
    }
  }

  String _getStateLabel() {
    switch (_currentState) {
      case VoiceCallState.listening:
        return 'ECOUTE';
      case VoiceCallState.processing:
        return 'ANALYSE';
      case VoiceCallState.speaking:
        return 'SAYIBI PARLE';
      case VoiceCallState.error:
        return 'ERREUR';
      default:
        return 'EN LIGNE';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class ParticlesPainter extends CustomPainter {
  ParticlesPainter({required this.animationValue, required this.color});

  final double animationValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.09)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + (animationValue * math.pi * 2);
      final radius = 26 + (animationValue * 18);
      final x = size.width / 2 + math.cos(angle) * (100 + i * 20);
      final y = size.height / 2 + math.sin(angle) * (100 + i * 20);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.color != color;
  }
}
