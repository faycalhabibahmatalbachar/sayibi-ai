import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.webSearchEnabled,
    required this.documentMode,
    required this.createMode,
    required this.createType,
    this.agentModeEnabled = false,
    required this.onPlusPressed,
    required this.onSend,
    required this.onVoiceRecord,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool webSearchEnabled;
  final bool documentMode;
  final bool createMode;
  final String createType;
  final bool agentModeEnabled;
  final VoidCallback onPlusPressed;
  final void Function(String text) onSend;
  final VoidCallback onVoiceRecord;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.9), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildPlusButton(),
            const SizedBox(width: 10),
            Expanded(child: _buildInputField()),
            const SizedBox(width: 10),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlusButton() {
    final hasActiveFeature = widget.webSearchEnabled ||
        widget.documentMode ||
        widget.createMode ||
        widget.agentModeEnabled;
    return GestureDetector(
      onTap: widget.onPlusPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasActiveFeature
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasActiveFeature
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.darkBorder,
            width: hasActiveFeature ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Icon(
            hasActiveFeature ? Icons.tune_rounded : Icons.add_rounded,
            color: hasActiveFeature ? AppColors.primary : AppColors.darkTextSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: TextField(
        controller: widget.controller,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: _getPlaceholder(),
          hintStyle: const TextStyle(
            color: AppColors.darkTextTertiary,
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
        ),
        onSubmitted: (_hasText && !widget.isLoading)
            ? (_) => widget.onSend(widget.controller.text)
            : null,
      ),
    );
  }

  Widget _buildActionButton() {
    if (widget.isLoading) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.error,
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: _hasText
          ? GestureDetector(
              key: const ValueKey('send'),
              onTap: () {
                if (_hasText) {
                  HapticFeedback.lightImpact();
                  widget.onSend(widget.controller.text);
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            )
          : GestureDetector(
              key: const ValueKey('mic'),
              onTap: widget.onVoiceRecord,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: const Center(
                  child: Icon(
                    Icons.mic_rounded,
                    color: AppColors.darkTextSecondary,
                    size: 22,
                  ),
                ),
              ),
            ),
    );
  }

  String _getPlaceholder() {
    if (widget.createMode) {
      const m = {
        'cv': 'Décrivez votre expérience pour le CV…',
        'letter': 'Pour quel poste est cette lettre ?',
        'report': 'Quel sujet pour le rapport ?',
        'excel': 'Décrivez le tableau à créer…',
      };
      return m[widget.createType] ?? 'Décrivez ce que vous voulez créer…';
    }
    if (widget.documentMode) return 'Posez une question sur le document…';
    if (widget.webSearchEnabled) return 'Que voulez-vous rechercher ?';
    return 'Posez une question à SAYIBI…';
  }
}
