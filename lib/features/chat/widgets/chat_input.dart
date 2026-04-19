import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

class ChatInput extends StatelessWidget {
  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onMic,
    this.onAttach,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onMic;
  final VoidCallback? onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: const Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onAttach, icon: const Icon(Icons.attach_file)),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: AppStrings.chatHint,
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(onPressed: onMic, icon: const Icon(Icons.mic_none)),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
