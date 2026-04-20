import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();
  String? _answer;
  List<Map<String, dynamic>> _sources = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_q.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _answer = null;
      _sources = [];
    });
    try {
      final dio = ref.read(apiServiceProvider).client;
      final res = await dio.post<Map<String, dynamic>>(
        ApiConstants.searchAnswer,
        data: {'question': _q.text.trim()},
      );
      final raw = res.data;
      if (raw is Map<String, dynamic> && raw['success'] == true) {
        final inner = raw['data'];
        if (inner is Map<String, dynamic>) {
          final ans = inner['answer']?.toString();
          final src = inner['sources'];
          final list = <Map<String, dynamic>>[];
          if (src is List) {
            for (final e in src) {
              if (e is Map) {
                list.add(Map<String, dynamic>.from(e));
              }
            }
          }
          setState(() {
            _answer = ans;
            _sources = list;
            _loading = false;
          });
          return;
        }
      }
      setState(() {
        if (raw is Map<String, dynamic>) {
          _error = raw['message']?.toString() ?? 'Erreur';
        } else {
          _error = 'Erreur';
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.darkBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recherche web + IA',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Appels réels (Serper / Tavily / DDG) puis synthèse par le modèle.',
              style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _q,
              style: const TextStyle(color: AppColors.darkTextPrimary),
              decoration: const InputDecoration(
                labelText: 'Votre question',
                hintText: 'Ex. dernières nouvelles sur…',
              ),
              onSubmitted: (_) => _run(),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _run,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.travel_explore_rounded),
              label: Text(_loading ? 'Recherche…' : 'Rechercher'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            if (_sources.isNotEmpty) ...[
              const Row(
                children: [
                  Icon(Icons.link_rounded, size: 16, color: AppColors.darkTextTertiary),
                  SizedBox(width: 6),
                  Text(
                    'Sources',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sources.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final s = _sources[i];
                    final title = s['title']?.toString() ?? 'Sans titre';
                    final url = s['url']?.toString() ?? '';
                    final snip = s['snippet']?.toString() ?? '';
                    return _SourceCard(title: title, url: url, snippet: snip);
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_answer != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.aiMessageBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.aiMessageBorder),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      _answer!,
                      style: const TextStyle(
                        color: AppColors.darkTextPrimary,
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.title,
    required this.url,
    required this.snippet,
  });

  final String title;
  final String url;
  final String snippet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: url.startsWith('http')
            ? () async {
                final u = Uri.tryParse(url);
                if (u != null && await canLaunchUrl(u)) {
                  await launchUrl(u, mode: LaunchMode.externalApplication);
                }
              }
            : null,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                snippet,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
