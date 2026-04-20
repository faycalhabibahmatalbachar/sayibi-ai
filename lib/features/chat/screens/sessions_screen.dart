import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/http_error_message.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

/// Liste complète des conversations (titres générés côté serveur).
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!ref.read(authProvider).authenticated) {
      setState(() {
        _loading = false;
        _error = 'Connectez-vous pour voir l’historique.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(apiServiceProvider).client;
      final res = await dio.get<dynamic>(ApiConstants.chatSessions);
      final body = res.data;
      if (body is Map && body['success'] == true && body['data'] is List) {
        setState(() {
          _rows = (body['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Réponse invalide';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = httpErrorMessage(e);
      });
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    try {
      final dio = ref.read(apiServiceProvider).client;
      await dio.delete<dynamic>(ApiConstants.chatSessionDelete(sessionId));
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation supprimée.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(httpErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, style: const TextStyle(color: AppColors.error)),
                      ),
                    ],
                  )
                : _rows.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Aucune conversation.',
                              style: TextStyle(color: AppColors.darkTextTertiary),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        itemCount: _rows.length,
                        itemBuilder: (context, i) {
                          final row = _rows[i];
                          final id = row['id']?.toString() ?? '';
                          final title = row['title']?.toString().trim();
                          final label = (title != null && title.isNotEmpty)
                              ? title
                              : 'Sans titre';
                          return Dismissible(
                            key: ValueKey(id.isEmpty ? '$i-$label' : id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              color: AppColors.error.withValues(alpha: 0.2),
                              child: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                            ),
                            confirmDismiss: (_) async => id.isNotEmpty,
                            onDismissed: (_) {
                              if (id.isNotEmpty) {
                                _deleteSession(id);
                              }
                            },
                            child: ListTile(
                              leading: const Icon(Icons.forum_outlined, color: AppColors.primary),
                              title: Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.darkTextPrimary),
                              ),
                              subtitle: row['created_at'] != null
                                  ? Text(
                                      row['created_at'].toString(),
                                      style: const TextStyle(fontSize: 11, color: AppColors.darkTextTertiary),
                                    )
                                  : null,
                              onTap: id.isEmpty
                                  ? null
                                  : () async {
                                      await ref.read(chatProvider.notifier).loadSession(id);
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
