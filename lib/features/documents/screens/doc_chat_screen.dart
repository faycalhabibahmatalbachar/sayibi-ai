import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/http_error_message.dart';
import '../../auth/providers/auth_provider.dart';

class DocChatScreen extends ConsumerStatefulWidget {
  const DocChatScreen({super.key, required this.docId});

  final String docId;

  @override
  ConsumerState<DocChatScreen> createState() => _DocChatScreenState();
}

class _DocChatScreenState extends ConsumerState<DocChatScreen> {
  final TextEditingController _questionController = TextEditingController();
  String? _answer;
  String? _summary;
  bool _loading = false;
  bool _summarizing = false;
  String? _error;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final q = _questionController.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(apiServiceProvider).client;
      final res = await dio.post<dynamic>(
        ApiConstants.documentsAsk,
        data: {
          'doc_id': widget.docId,
          'question': q,
        },
      );
      final body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final data = body['data'] as Map;
        setState(() {
          _answer = data['answer']?.toString();
          _loading = false;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = body is Map ? body['message']?.toString() : 'Erreur';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = httpErrorMessage(e);
      });
    }
  }

  Future<void> _summarize([String format = 'bullets']) async {
    setState(() {
      _summarizing = true;
      _error = null;
    });
    try {
      final dio = ref.read(apiServiceProvider).client;
      final res = await dio.post<dynamic>(
        ApiConstants.documentsSummarize,
        data: {
          'doc_id': widget.docId,
          'format': format,
        },
      );
      final body = res.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        final data = body['data'] as Map;
        setState(() {
          _summary = data['summary']?.toString();
          _summarizing = false;
        });
        return;
      }
      setState(() {
        _summarizing = false;
        _error = body is Map ? body['message']?.toString() : 'Erreur';
      });
    } catch (e) {
      setState(() {
        _summarizing = false;
        _error = httpErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Document ${widget.docId.substring(0, 8)}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Question sur le document',
                hintText: 'Ex: résume le contrat en 5 points',
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _ask,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.question_answer_rounded),
                    label: const Text('Poser la question'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _summarizing ? null : _summarize,
                  icon: _summarizing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.summarize_rounded),
                  label: const Text('Résumé'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 12),
            if (_answer != null)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.aiMessageBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.aiMessageBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Text(_answer!, style: const TextStyle(color: AppColors.darkTextPrimary, height: 1.4)),
                  ),
                ),
              ),
            if (_summary != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Text(_summary!, style: const TextStyle(color: AppColors.darkTextSecondary, height: 1.35)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
