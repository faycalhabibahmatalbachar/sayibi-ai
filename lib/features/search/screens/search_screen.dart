import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();
  String? _answer;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _q,
            decoration: const InputDecoration(
              labelText: 'Question (web + IA)',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              try {
                final dio = ref.read(apiServiceProvider).client;
                final res = await dio.post(
                  ApiConstants.searchAnswer,
                  data: {'question': _q.text},
                );
                final data = res.data as Map<String, dynamic>;
                final d = data['data'] as Map<String, dynamic>?;
                setState(() => _answer = d?['answer']?.toString());
              } catch (e) {
                setState(() => _answer = e.toString());
              }
            },
            child: const Text('Rechercher'),
          ),
          const SizedBox(height: 16),
          if (_answer != null)
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(_answer!),
              ),
            ),
        ],
      ),
    );
  }
}
