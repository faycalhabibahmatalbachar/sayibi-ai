import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/alarm_provider.dart';
import '../widgets/alarm_editor_sheet.dart';

class AlarmListScreen extends ConsumerStatefulWidget {
  const AlarmListScreen({super.key});

  @override
  ConsumerState<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends ConsumerState<AlarmListScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(alarmProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(alarmProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Alarmes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Ajouter'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(alarmProvider.notifier).load(),
        child: s.loading
            ? const Center(child: CircularProgressIndicator())
            : s.items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 140),
                      Center(
                        child: Text(
                          'Aucune alarme pour le moment.',
                          style: TextStyle(color: AppColors.darkTextSecondary),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    itemCount: s.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final a = s.items[i];
                      return Dismissible(
                        key: ValueKey(a.id),
                        background: Container(
                          color: AppColors.error.withValues(alpha: 0.2),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete_outline_rounded),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            ref.read(alarmProvider.notifier).delete(a.id),
                        child: ListTile(
                          title: Text(a.title),
                          subtitle: Text(
                            '${a.scheduledFor.toLocal()}'
                            '${a.repeatRule != null ? ' · ${a.repeatRule}' : ''}',
                          ),
                          trailing: Switch(
                            value: a.isEnabled,
                            onChanged: (v) {
                              ref.read(alarmProvider.notifier).update(
                                    a.id,
                                    isEnabled: v,
                                  );
                            },
                          ),
                          onTap: () => _edit(a),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _create() async {
    final res = await showModalBottomSheet<AlarmEditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AlarmEditorSheet(),
    );
    if (res == null) return;
    if (!mounted) return;
    final ok = await ref.read(alarmProvider.notifier).create(
          title: res.title,
          message: res.message,
          scheduledForLocal: res.scheduledFor,
          repeatRule: res.repeatRule,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Alarme créée.' : 'Échec création alarme.')),
    );
  }

  Future<void> _edit(AlarmItem item) async {
    final res = await showModalBottomSheet<AlarmEditorResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AlarmEditorSheet(
        initialTitle: item.title,
        initialMessage: item.message,
        initialDateTime: item.scheduledFor.toLocal(),
      ),
    );
    if (res == null) return;
    if (!mounted) return;
    final ok = await ref.read(alarmProvider.notifier).update(
          item.id,
          title: res.title,
          message: res.message,
          scheduledForLocal: res.scheduledFor,
          repeatRule: res.repeatRule,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Alarme mise à jour.' : 'Échec mise à jour.')),
    );
  }
}

