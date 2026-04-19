import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/model_selector.dart';
import '../widgets/suggestion_chips.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    return Column(
      children: [
        ModelSelector(
          value: chat.modelPreference,
          onChanged: ref.read(chatProvider.notifier).setModel,
        ),
        Expanded(
          child: chat.messages.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(AppStrings.emptyChatTitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text(AppStrings.suggestions, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    SuggestionChips(
                      items: const [
                        'Résume-moi un texte administratif',
                        'Aide-moi à rédiger un email professionnel',
                        'Explique-moi un concept simplement',
                      ],
                      onSelect: (t) {
                        _controller.text = t;
                      },
                    ),
                  ],
                )
              : ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.only(bottom: 12, top: 12),
                  itemCount: chat.messages.length + (chat.loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (chat.loading && index == 0) {
                      return const TypingIndicator();
                    }
                    final i = chat.loading ? index - 1 : index;
                    final m = chat.messages[chat.messages.length - 1 - i];
                    return MessageBubble(text: m.content, isUser: m.role == 'user')
                        .animate()
                        .fade(duration: const Duration(milliseconds: 180))
                        .slideY(begin: 0.06, curve: Curves.easeOut);
                  },
                ),
        ),
        if (chat.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(chat.error!, style: const TextStyle(color: Colors.redAccent)),
          ),
        ChatInput(
          controller: _controller,
          onSend: () async {
            final t = _controller.text;
            _controller.clear();
            await ref.read(chatProvider.notifier).send(t);
          },
          onMic: () {},
          onAttach: () {},
        ),
      ],
    );
  }
}
