import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/agent_flow_provider.dart';

/// Panneau compact sous la barre de fonctionnalités : état du mode actions + boutons.
class AgentResponsePanel extends ConsumerWidget {
  const AgentResponsePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(agentFlowProvider);
    final notifier = ref.read(agentFlowProvider.notifier);

    if (!s.modeEnabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.accent.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.smartphone_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mode actions',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  if (s.loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              if (s.successHint != null) ...[
                const SizedBox(height: 8),
                Text(
                  s.successHint!,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                s.contactsSynced
                    ? 'Ressource contacts: synchronisée'
                    : 'Ressource contacts: non synchronisée',
                style: TextStyle(
                  color: s.contactsSynced ? AppColors.success : AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (s.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  s.error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                ),
              ],
              if (!s.loading && s.lastResponse == null && s.error == null) ...[
                const SizedBox(height: 8),
                Text(
                  'Décrivez une action : SMS, appel, rappel, agenda… '
                  'Exécution automatique active (sans confirmation manuelle).',
                  style: TextStyle(
                    color: AppColors.darkTextSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
              if (s.lastResponse != null && !s.loading) ...[
                const SizedBox(height: 10),
                _ActionBlock(
                  data: s.lastResponse!,
                  onPickContact: notifier.pickContact,
                  onPickNumber: notifier.pickPhoneNumber,
                  onRequestPermissions: notifier.requestPermissions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBlock extends StatelessWidget {
  const _ActionBlock({
    required this.data,
    required this.onPickContact,
    required this.onPickNumber,
    required this.onRequestPermissions,
  });

  final Map<String, dynamic> data;
  final void Function({
    required String contactId,
    required String displayName,
    required String querySnapshot,
  }) onPickContact;
  final void Function({required String number, required String label})
      onPickNumber;
  final VoidCallback onRequestPermissions;

  @override
  Widget build(BuildContext context) {
    final action = data['action']?.toString() ?? '';
    final payload = data['payload'];
    final p = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};

    if (action == 'permission_needed') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            (p['reason'] ?? 'Autorisations requises').toString(),
            style: const TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onRequestPermissions,
            icon: const Icon(Icons.lock_open_rounded, size: 18),
            label: const Text('Demander les autorisations'),
          ),
        ],
      );
    }

    if (action == 'clarify_contact') {
      final matches = p['matches'];
      final list = matches is List ? matches : const [];
      final q = (p['query'] ?? '').toString();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Choisissez un contact :',
            style: TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final raw = list[i];
                final m = raw is Map
                    ? Map<String, dynamic>.from(raw)
                    : <String, dynamic>{};
                final id = m['contact_id']?.toString() ?? '';
                final name = m['display_name']?.toString() ?? '?';
                final company = m['company']?.toString() ?? '';
                return OutlinedButton(
                  onPressed: id.isEmpty
                      ? null
                      : () => onPickContact(
                            contactId: id,
                            displayName: name,
                            querySnapshot: q,
                          ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (company.isNotEmpty)
                          Text(
                            company,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.darkTextTertiary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (action == 'clarify_number') {
      final phones = p['phone_numbers'];
      final list = phones is List ? phones : const [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (p['contact_name'] ?? 'Contact').toString(),
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final raw = list[i];
                final m = raw is Map
                    ? Map<String, dynamic>.from(raw)
                    : <String, dynamic>{};
                final phone = m['number']?.toString() ?? '';
                final label = m['label']?.toString() ?? '';
                return OutlinedButton(
                  onPressed: phone.isEmpty
                      ? null
                      : () => onPickNumber(
                            number: phone,
                            label: label.isEmpty ? 'Mobile' : label,
                          ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('$label · $phone'),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (action == 'search_contacts') {
      return const Text(
        'Recherche des contacts…',
        style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
      );
    }

    return const SizedBox.shrink();
  }
}
