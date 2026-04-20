import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onRegenerate,
    this.deviceSmsConsumed = false,
    this.onDeviceSmsConfirm,
    this.onDeviceSmsDismiss,
  });

  final MessageModel message;
  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;

  /// Si false et [onDeviceSmsConfirm] non null, affiche la barre de confirmation SMS.
  final bool deviceSmsConsumed;
  final Future<void> Function()? onDeviceSmsConfirm;
  final VoidCallback? onDeviceSmsDismiss;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: isUser ? _buildUserMessage() : _buildAiMessage(),
    );

    // Pas d’animation pendant le streaming : rendu fluide token par token (évite flash / blocage).
    if (isUser || !message.isStreaming) {
      return child
          .animate()
          .fadeIn(duration: 280.ms)
          .slideY(
            begin: 0.12,
            duration: 280.ms,
            curve: Curves.easeOut,
          );
    }
    return child;
  }

  Widget _buildUserMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.darkCard,
          child: Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildAiMessage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.aiMessageBg,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: AppColors.aiMessageBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.modelUsed != null && message.modelUsed!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _emojiForModelLabel(message.modelUsed!),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                message.modelUsed!,
                                style: const TextStyle(
                                  color: AppColors.darkTextTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (message.content.isEmpty && message.isStreaming)
                      const _StreamingCursor()
                    else if (message.content.isNotEmpty && message.isStreaming)
                      SelectableText(
                        message.content,
                        style: const TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      )
                    else if (message.content.isNotEmpty)
                      MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                        strong: const TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        code: TextStyle(
                          backgroundColor: AppColors.darkBackground,
                          color: AppColors.accent,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.darkBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        h1: const TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        h2: const TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        h3: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        listBullet: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: AppColors.primary,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (message.content.isNotEmpty && message.isStreaming)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: _StreamingCursor(),
                      ),
                    if (message.imageUrls != null && message.imageUrls!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildImagesGrid(message.imageUrls!),
                    ],
                    if (message.metadata?['search_images'] != null) ...[
                      const SizedBox(height: 12),
                      _buildWebSearchImages(message.metadata!['search_images']),
                    ],
                    if (message.metadata?['sources'] != null) ...[
                      const SizedBox(height: 12),
                      _buildWebSources(message.metadata!['sources']),
                    ],
                    if (message.metadata?['generated_file'] != null) ...[
                      const SizedBox(height: 12),
                      _buildGeneratedFileCard(
                        message.metadata!['generated_file'] as Map<dynamic, dynamic>,
                      ),
                    ],
                    if (message.metadata?['local_media_results'] != null) ...[
                      const SizedBox(height: 12),
                      _buildLocalMediaResults(message.metadata!['local_media_results']),
                    ],
                    if (_deviceSmsBarVisible()) ...[
                      const SizedBox(height: 12),
                      _buildDeviceSmsBar(),
                    ],
                  ],
                ),
              ),
              if (!message.isStreaming)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onCopy != null)
                        _buildActionBtn(
                          icon: Icons.copy_rounded,
                          tooltip: 'Copier',
                          onTap: onCopy,
                        ),
                      if (onRegenerate != null)
                        _buildActionBtn(
                          icon: Icons.refresh_rounded,
                          tooltip: 'Régénérer',
                          onTap: onRegenerate,
                        ),
                      _buildActionBtn(
                        icon: Icons.thumb_up_rounded,
                        tooltip: 'J\'aime',
                        onTap: () {},
                      ),
                      _buildActionBtn(
                        icon: Icons.thumb_down_rounded,
                        tooltip: 'Je n\'aime pas',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _deviceSmsBarVisible() {
    if (message.isStreaming || deviceSmsConsumed) return false;
    if (onDeviceSmsConfirm == null) return false;
    final da = message.metadata?['device_action'];
    return da is Map && da['type']?.toString() == 'send_sms';
  }

  Widget _buildDeviceSmsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Envoi SMS depuis votre téléphone — confirmez pour lancer l’action.',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final fn = onDeviceSmsConfirm;
                    if (fn != null) await fn();
                  },
                  child: const Text('Confirmer l’envoi'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onDeviceSmsDismiss,
                child: const Text('Plus tard'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _emojiForModelLabel(String label) {
    final s = label.toLowerCase();
    if (s.contains('réflexion') || s.contains('reflexion')) return '🧠';
    if (s.contains('image')) return '🎨';
    if (s.contains('nadir')) return '📊';
    if (s.contains('voix')) return '🎙️';
    if (s.contains('code')) return '💻';
    if (s.contains('création') || s.contains('creation')) return '✨';
    if (s.contains('auto')) return '⚡';
    return '✨';
  }

  Widget _buildImagesGrid(List<String> urls) {
    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildNetworkImage(
          url: urls.first,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 200,
          placeholder: Container(
            height: 200,
            color: AppColors.darkBackground,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: Container(
            height: 200,
            color: AppColors.darkBackground,
            child: const Icon(Icons.broken_image, color: AppColors.darkTextTertiary),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: urls.length,
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _buildNetworkImage(
          url: urls[i],
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildWebSearchImages(dynamic raw) {
    final list = raw is List ? raw : <dynamic>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.image_outlined, size: 14, color: AppColors.darkTextTertiary),
            SizedBox(width: 4),
            Text(
              'Images web',
              style: TextStyle(
                color: AppColors.darkTextTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: list.length.clamp(0, 9),
          itemBuilder: (_, i) {
            final Map<String, dynamic> m = Map<String, dynamic>.from(list[i] as Map);
            final u = m['url']?.toString() ?? '';
            if (u.isEmpty) return const SizedBox.shrink();
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Material(
                color: AppColors.darkBackground,
                child: InkWell(
                  onTap: () async {
                    final page = m['source_url']?.toString();
                    if (page != null && page.isNotEmpty) {
                      final uri = Uri.tryParse(page);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: _buildNetworkImage(
                    url: u,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    ),
                    error: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.darkTextTertiary,
                      size: 28,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNetworkImage({
    required String url,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? error,
  }) {
    if (kIsWeb) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? const SizedBox.shrink();
        },
        errorBuilder: (context, _, __) => error ?? const SizedBox.shrink(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => placeholder ?? const SizedBox.shrink(),
      errorWidget: (_, __, ___) => error ?? const SizedBox.shrink(),
    );
  }

  Widget _buildWebSources(dynamic sourcesRaw) {
    final sources = sourcesRaw is List ? sourcesRaw : <dynamic>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.link_rounded, size: 14, color: AppColors.darkTextTertiary),
            SizedBox(width: 4),
            Text(
              'Sources',
              style: TextStyle(
                color: AppColors.darkTextTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...sources.take(3).map((s) {
          final Map<String, dynamic> source = Map<String, dynamic>.from(
            s as Map,
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    source['title']?.toString() ?? 'Source',
                    style: const TextStyle(
                      color: AppColors.info,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGeneratedFileCard(Map<dynamic, dynamic> file) {
    final type = file['type'] as String? ?? 'doc';
    final icons = {
      'cv': ('👤', AppColors.success),
      'letter': ('✉️', AppColors.info),
      'report': ('📊', AppColors.primary),
      'excel': ('📈', AppColors.accent),
    };
    final pair = icons[type] ?? ('📄', AppColors.darkTextSecondary);
    final emoji = pair.$1;
    final color = pair.$2;
    final rawDownloadSigned = file['download_url_signed']?.toString();
    final rawDownloadUrl = file['download_url']?.toString();
    final rawUrl = file['url']?.toString();
    final url =
        _resolveGeneratedFileUrl(rawDownloadSigned) ??
        _resolveGeneratedFileUrl(rawDownloadUrl) ??
        _resolveGeneratedFileUrl(rawUrl);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: url != null
            ? () async {
                final u = Uri.tryParse(url);
                if (u != null && await canLaunchUrl(u)) {
                  await launchUrl(u, mode: LaunchMode.externalApplication);
                }
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file['filename']?.toString() ?? 'Document généré',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'Ouvrir / télécharger',
                      style: TextStyle(
                        color: AppColors.darkTextTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.download_rounded, color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalMediaResults(dynamic raw) {
    final list = raw is List ? raw : const [];
    if (list.isEmpty) return const SizedBox.shrink();
    final entries = list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.folder_copy_outlined, size: 14, color: AppColors.darkTextTertiary),
            SizedBox(width: 6),
            Text(
              'Fichiers locaux trouvés',
              style: TextStyle(
                color: AppColors.darkTextTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: entries.length.clamp(0, 12),
          itemBuilder: (_, i) {
            final item = entries[i];
            final path = (item['path'] ?? '').toString();
            final type = (item['type'] ?? 'image').toString();
            final title = (item['title'] ?? '').toString();
            final score = (item['score'] is num) ? (item['score'] as num).toDouble() : null;
            final duration = (item['duration_sec'] is num) ? (item['duration_sec'] as num).toInt() : 0;
            final canLoad = !kIsWeb && path.isNotEmpty && File(path).existsSync();
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Material(
                color: AppColors.darkBackground,
                child: InkWell(
                  onTap: canLoad
                      ? () async {
                          await OpenFile.open(path);
                        }
                      : null,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: canLoad && type == 'image'
                            ? Image.file(
                                File(path),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _localMediaFallback(type, title),
                              )
                            : _localMediaFallback(type, title),
                      ),
                      if (type == 'video')
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDuration(duration),
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      if (score != null)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'S ${score.toStringAsFixed(1)}',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDuration(int sec) {
    if (sec <= 0) return '00:00';
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _localMediaFallback(String type, String title) {
    final icon = type == 'video' ? Icons.videocam_outlined : Icons.image_outlined;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.darkTextSecondary, size: 22),
          const SizedBox(height: 4),
          Text(
            title.isEmpty ? type : title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.darkTextTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveGeneratedFileUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = raw.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    if (v.startsWith('/')) {
      final host = ApiConstants.host.endsWith('/')
          ? ApiConstants.host.substring(0, ApiConstants.host.length - 1)
          : ApiConstants.host;
      return '$host$v';
    }
    return null;
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 15,
            color: AppColors.darkTextTertiary,
          ),
        ),
      ),
    );
  }
}

/// Curseur clignotant type ChatGPT pendant le flux SSE.
class _StreamingCursor extends StatefulWidget {
  const _StreamingCursor();

  @override
  State<_StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<_StreamingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
