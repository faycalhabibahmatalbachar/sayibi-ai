import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/sim_sms_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/widgets/animated_error_message.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../voice/screens/voice_screen.dart';
import '../../agent/providers/agent_flow_provider.dart';
import '../../agent/widgets/agent_response_panel.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/model_selector_sheet.dart';
import '../widgets/plus_menu_sheet.dart';
import 'sessions_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.sessionId});

  /// Réservé pour reprise de session (routing futur).
  final String? sessionId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  bool _webSearchEnabled = false;
  bool _documentMode = false;
  bool _createMode = false;
  String? _uploadedDocumentId;
  String? _uploadedDocumentName;
  String _createType = 'cv';

  /// Barre « Confirmer l’envoi SMS » : une fois traitée (envoi ou « Plus tard »), on masque.
  final Set<String> _deviceSmsHandledKeys = <String>{};

  List<Map<String, dynamic>> _sessionRows = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendSimSmsDirect(MessageModel msg) async {
    final raw = msg.metadata?['device_action'];
    if (raw is! Map) return;
    if (raw['type']?.toString() != 'send_sms') return;
    final to = raw['to']?.toString() ?? '';
    var body = raw['body']?.toString() ?? '';
    if (body.isEmpty) {
      body = SimSmsService.plainBodyFromAssistantText(msg.content);
    } else {
      body = SimSmsService.plainBodyFromAssistantText(body);
    }
    if (to.isEmpty || body.isEmpty) return;
    if (!mounted) return;
    final r = await SimSmsService.send(toE164: to, body: body);
    if (!mounted) return;
    if (r.ok && ref.read(authProvider).authenticated) {
      final masked = to.length > 6
          ? '${to.substring(0, to.length > 4 ? 4 : 2)} ••• •• ${to.substring(to.length - 2)}'
          : '•••';
      await ref.read(agentApiServiceProvider).logAction(
            actionType: 'send_sms',
            phoneMasked: masked,
            messagePreview: body.length > 120 ? '${body.substring(0, 120)}…' : body,
            status: 'success',
          );
      if (!mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          r.ok
              ? (r.usedSimDirect
                  ? 'SMS envoyé depuis la carte SIM.'
                  : 'Messages ouvert — validez l’envoi.')
              : (r.message ?? 'Échec'),
        ),
      ),
    );
  }

  String _deviceSmsKey(MessageModel msg, int index) {
    final da = msg.metadata?['device_action'];
    if (da is! Map || da['type']?.toString() != 'send_sms') return '';
    final to = da['to']?.toString() ?? '';
    if (to.isEmpty) return '';
    return '$index|$to|${msg.content.hashCode}';
  }

  Future<void> _refreshSessionList() async {
    if (!ref.read(authProvider).authenticated) return;
    try {
      final dio = ref.read(apiServiceProvider).client;
      final res = await dio.get<dynamic>(ApiConstants.chatSessions);
      final body = res.data;
      if (body is Map && body['success'] == true && body['data'] is List) {
        final list = body['data'] as List;
        if (mounted) {
          setState(() {
            _sessionRows = list
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _openSession(String sessionId) async {
    Navigator.pop(context);
    ref.read(agentFlowProvider.notifier).resetSession();
    await ref.read(chatProvider.notifier).loadSession(sessionId);
  }

  void _showPlusMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) => PlusMenuSheet(
        webSearchEnabled: _webSearchEnabled,
        documentMode: _documentMode,
        createMode: _createMode,
        uploadedDocName: _uploadedDocumentName,
        createType: _createType,
        agentModeEnabled: ref.watch(agentFlowProvider).modeEnabled,
        onWebSearchToggled: (v) => setState(() => _webSearchEnabled = v),
        onDocumentUploaded: (docId, docName) {
          setState(() {
            _documentMode = true;
            _uploadedDocumentId = docId;
            _uploadedDocumentName = docName;
          });
        },
        onDocumentRemoved: () {
          setState(() {
            _documentMode = false;
            _uploadedDocumentId = null;
            _uploadedDocumentName = null;
          });
        },
        onCreateToggled: (v, type) {
          setState(() {
            _createMode = v;
            _createType = type;
          });
        },
        onAgentModeToggled: (v) {
          ref.read(agentFlowProvider.notifier).setMode(v);
          setState(() {});
        },
      ),
      ),
    );
  }

  void _showModelSelector() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ModelSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final agentFlow = ref.watch(agentFlowProvider);
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;
    final selectedModel = chatState.selectedModel;
    final agentModeOn = agentFlow.modeEnabled;

    if (messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      onDrawerChanged: (opened) {
        if (opened) {
          _refreshSessionList();
        }
      },
      backgroundColor: AppColors.darkBackground,
      drawer: Drawer(
        backgroundColor: AppColors.darkCard,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'SAYIBI',
                  style: TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                title: Text(AppStrings.chatDrawerNew, style: const TextStyle(color: AppColors.darkTextPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(agentFlowProvider.notifier).resetSession();
                  ref.read(chatProvider.notifier).newSession();
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.chatDrawerHistory,
                    style: TextStyle(
                      color: AppColors.darkTextTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _sessionRows.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            AppStrings.chatDrawerHistoryEmpty,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: _sessionRows.length,
                        itemBuilder: (context, i) {
                          final row = _sessionRows[i];
                          final id = row['id']?.toString() ?? '';
                          final title = row['title']?.toString().trim();
                          final label = (title != null && title.isNotEmpty)
                              ? title
                              : AppStrings.chatDrawerUntitled;
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.forum_outlined, size: 20, color: AppColors.darkTextSecondary),
                            title: Text(
                              label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14),
                            ),
                            onTap: id.isEmpty ? null : () => _openSession(id),
                          );
                        },
                      ),
              ),
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded, color: AppColors.darkTextSecondary),
                title: Text(AppStrings.chatDrawerSessionsAll, style: const TextStyle(color: AppColors.darkTextPrimary)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SessionsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      appBar: _buildAppBar(selectedModel),
      body: Stack(
        children: [
          Column(
            children: [
              if (_webSearchEnabled ||
                  _documentMode ||
                  _createMode ||
                  agentModeOn)
                _buildActiveFeaturesBanner(agentModeOn),
              if (agentModeOn) const AgentResponsePanel(),
              Expanded(
                child: messages.isEmpty ? _buildEmptyState() : _buildMessagesList(messages, isLoading),
              ),
              if (chatState.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: AnimatedErrorMessage(
                    message: chatState.error!,
                    onRetry: () => ref.read(chatProvider.notifier).clearError(),
                  ),
                ),
              ChatInputBar(
                controller: _textController,
                isLoading: isLoading || (agentModeOn && agentFlow.loading),
                webSearchEnabled: _webSearchEnabled,
                documentMode: _documentMode,
                createMode: _createMode,
                createType: _createType,
                agentModeEnabled: agentModeOn,
                onPlusPressed: _showPlusMenu,
                onSend: _sendMessage,
                onVoiceRecord: _startVoiceRecording,
              ),
            ],
          ),
          if (chatState.isGeneratingFile) _buildFileGenerationOverlay(chatState.generatingFileType),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String selectedModel) {
    return AppBar(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
          color: AppColors.darkTextSecondary,
        ),
      ),
      title: GestureDetector(
        onTap: _showModelSelector,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getModelEmoji(selectedModel),
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                _getModelDisplayName(selectedModel),
                style: const TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.darkTextTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.darkTextSecondary,
              size: 20,
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(agentFlowProvider.notifier).resetSession();
            ref.read(chatProvider.notifier).newSession();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActiveFeaturesBanner(bool agentModeOn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          if (agentModeOn)
            _buildFeatureChip(
              icon: Icons.flash_on_rounded,
              label: AppStrings.chatAgentMode,
              color: AppColors.primary,
              onRemove: () {
                ref.read(agentFlowProvider.notifier).setMode(false);
                setState(() {});
              },
            ),
          if (_webSearchEnabled) ...[
            if (agentModeOn) const SizedBox(width: 8),
            _buildFeatureChip(
              icon: Icons.search_rounded,
              label: AppStrings.chatWeb,
              color: AppColors.info,
              onRemove: () => setState(() => _webSearchEnabled = false),
            ),
          ],
          if (_documentMode && _uploadedDocumentName != null) ...[
            if (agentModeOn || _webSearchEnabled) const SizedBox(width: 8),
            _buildFeatureChip(
              icon: Icons.description_rounded,
              label: _uploadedDocumentName!.length > 15
                  ? '${_uploadedDocumentName!.substring(0, 15)}...'
                  : _uploadedDocumentName!,
              color: AppColors.warning,
              onRemove: () => setState(() {
                _documentMode = false;
                _uploadedDocumentId = null;
                _uploadedDocumentName = null;
              }),
            ),
          ],
          if (_createMode) ...[
            if (agentModeOn ||
                _webSearchEnabled ||
                (_documentMode && _uploadedDocumentName != null))
              const SizedBox(width: 8),
            _buildFeatureChip(
              icon: Icons.auto_awesome_rounded,
              label: _getCreateTypeLabel(_createType),
              color: AppColors.accent,
              onRemove: () => setState(() => _createMode = false),
            ),
          ],
          const Spacer(),
          Text(
            AppStrings.chatActive,
            style: const TextStyle(
              color: AppColors.darkTextTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.5, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              color: color.withValues(alpha: 0.7),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/lottie/ai_thinking.json',
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.psychology_rounded, size: 120, color: AppColors.primary),
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 600.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 24),
          AnimatedTextKit(
            animatedTexts: [
              TypewriterAnimatedText(
                AppStrings.chatHello,
                textStyle: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkTextPrimary,
                ),
                speed: const Duration(milliseconds: 80),
              ),
            ],
            isRepeatingAnimation: false,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.chatHelloSub,
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 18,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
          const SizedBox(height: 40),
          _buildSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    final suggestions = [
      SuggestionItem(
        icon: '📝',
        title: 'Créer un CV',
        subtitle: 'Génère un CV professionnel',
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        onTap: () {
          setState(() {
            _createMode = true;
            _createType = 'cv';
          });
          _textController.text = 'Crée-moi un CV professionnel';
        },
      ),
      SuggestionItem(
        icon: '🔍',
        title: 'Recherche Web',
        subtitle: 'Cherche sur internet',
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        onTap: () {
          setState(() => _webSearchEnabled = true);
          _textController.text = 'Recherche les dernières actualités sur ';
        },
      ),
      SuggestionItem(
        icon: '📄',
        title: 'Analyser Document',
        subtitle: 'Upload et analyse un fichier',
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        onTap: _showPlusMenu,
      ),
      SuggestionItem(
        icon: '🎨',
        title: 'Générer Image',
        subtitle: 'Crée une image depuis texte',
        gradient: const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
        ),
        onTap: () {
          ref.read(chatProvider.notifier).selectModel('sayibi-images');
          _textController.text = 'Génère une image de ';
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        // Plus « haut » qu’avant (1.4) pour éviter overflow sur petits écrans / web étroit.
        childAspectRatio: 0.98,
      ),
      itemCount: suggestions.length,
      itemBuilder: (context, i) => _buildSuggestionCard(suggestions[i], i),
    );
  }

  Widget _buildSuggestionCard(SuggestionItem s, int index) {
    return GestureDetector(
      onTap: s.onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (s.gradient.colors.first).withValues(alpha: 0.15),
              (s.gradient.colors.last).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: s.gradient.colors.first.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                s.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: s.gradient.colors.first,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.darkTextTertiary,
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (index * 100).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildMessagesList(List<MessageModel> messages, bool isLoading) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        final last = index == messages.length - 1;
        final smsKey = _deviceSmsKey(msg, index);
        return MessageBubble(
          message: msg,
          onCopy: msg.isStreaming ? null : () => _copyMessage(msg.content),
          onRegenerate: last && !isLoading && !msg.isStreaming
              ? _regenerateLastMessage
              : null,
          deviceSmsConsumed: smsKey.isEmpty || _deviceSmsHandledKeys.contains(smsKey),
          onDeviceSmsConfirm: smsKey.isEmpty
              ? null
              : () async {
                  await _sendSimSmsDirect(msg);
                  if (mounted) {
                    setState(() => _deviceSmsHandledKeys.add(smsKey));
                  }
                },
          onDeviceSmsDismiss: smsKey.isEmpty
              ? null
              : () => setState(() => _deviceSmsHandledKeys.add(smsKey)),
        );
      },
    );
  }

  Widget _buildFileGenerationOverlay(String fileType) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: GlassCard(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/lottie/file_generating.json',
                width: 120,
                height: 120,
                errorBuilder: (_, __, ___) => const CircularProgressIndicator(color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.chatGenerating,
                style: const TextStyle(
                  color: AppColors.darkTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getGeneratingLabel(fileType),
                style: const TextStyle(
                  color: AppColors.darkTextTertiary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModelEmoji(String model) {
    const map = {
      'auto': '⚡',
      'sayibi-reflexion': '🧠',
      'sayibi-images': '🎨',
      'sayibi-nadirx': '📊',
      'sayibi-voix': '🎙️',
      'sayibi-code': '💻',
      'sayibi-creation': '✨',
    };
    return map[model] ?? '⚡';
  }

  String _getModelDisplayName(String model) {
    const map = {
      'auto': 'Auto',
      'sayibi-reflexion': 'Réflexion',
      'sayibi-images': 'Images',
      'sayibi-nadirx': 'NadirX',
      'sayibi-voix': 'Voix',
      'sayibi-code': 'Code',
      'sayibi-creation': 'Création',
      'groq': 'Groq',
      'gemini': 'Gemini',
      'mistral': 'Mistral',
    };
    return map[model] ?? 'Auto';
  }

  String _getCreateTypeLabel(String type) {
    const map = {
      'cv': 'CV',
      'letter': 'Lettre',
      'report': 'Rapport',
      'excel': 'Excel',
    };
    return map[type] ?? 'Créer';
  }

  String _getGeneratingLabel(String type) {
    const map = {
      'cv': 'Création de votre CV professionnel\navec design et mise en page…',
      'letter': 'Rédaction de votre lettre\nde motivation…',
      'report': 'Génération du rapport PDF\nstructuré…',
      'excel': 'Construction du tableau Excel\navec formules…',
    };
    return map[type] ?? 'Traitement en cours…';
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    _textController.clear();
    if (ref.read(agentFlowProvider).modeEnabled) {
      ref.read(agentFlowProvider.notifier).submitUserMessage(text);
      return;
    }
    ref.read(chatProvider.notifier).sendMessage(
          text: text,
          webSearch: _webSearchEnabled,
          documentId: _uploadedDocumentId,
          createMode: _createMode,
          createType: _createMode ? _createType : null,
        );
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(AppStrings.chatCopied),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _regenerateLastMessage() {
    HapticFeedback.mediumImpact();
    ref.read(chatProvider.notifier).regenerateLastMessage(
          webSearch: _webSearchEnabled,
          documentId: _uploadedDocumentId,
          createMode: _createMode,
          createType: _createMode ? _createType : null,
        );
  }

  void _startVoiceRecording() {
    HapticFeedback.heavyImpact();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const SizedBox(
        height: 420,
        child: VoiceScreen(),
      ),
    );
  }
}

class SuggestionItem {
  const SuggestionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;
}
