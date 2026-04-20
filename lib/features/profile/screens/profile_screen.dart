import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/providers/theme_mode_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;

    final name = p.user?['name'] as String? ??
        p.user?['full_name'] as String? ??
        'Utilisateur';
    final email = p.user?['email'] as String? ?? '—';
    final lang = p.user?['language'] as String? ?? 'fr';
    final notif = p.user?['notifications'] as bool? ?? true;

    final fmt = NumberFormat.decimalPattern('fr');

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(profileProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.darkTextPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Compte, usage et préférences',
                      style: TextStyle(
                        color: AppColors.darkTextTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.glowShadow,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: AppColors.darkTextPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: AppColors.darkTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (p.loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Usage IA',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Tokens (jour)',
                          value: fmt.format(p.usage?['tokens_today'] ?? 0),
                          icon: Icons.bolt_rounded,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          label: 'Tokens (mois)',
                          value: fmt.format(p.usage?['tokens_month'] ?? 0),
                          icon: Icons.stacked_line_chart_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          label: 'Requêtes (jour)',
                          value: fmt.format(p.usage?['requests_today'] ?? 0),
                          icon: Icons.chat_bubble_outline_rounded,
                          color: AppColors.info,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          label: 'Requêtes (mois)',
                          value: fmt.format(p.usage?['requests_month'] ?? 0),
                          icon: Icons.forum_outlined,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Ressources',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                          title: const Text('Documents', style: TextStyle(color: AppColors.darkTextPrimary)),
                          subtitle: Text(
                            '${p.documentsCount} fichier(s) — onglet Documents',
                            style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.darkTextTertiary),
                          onTap: () => _showFilesSheet(context, 'Documents', p.files?['documents']),
                        ),
                        const Divider(height: 1, color: AppColors.darkBorder),
                        ListTile(
                          leading: const Icon(Icons.auto_awesome, color: AppColors.accent),
                          title: const Text('Fichiers générés', style: TextStyle(color: AppColors.darkTextPrimary)),
                          subtitle: Text(
                            '${p.generatedCount} fichier(s)',
                            style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.darkTextTertiary),
                          onTap: () => _showFilesSheet(context, 'Fichiers générés', p.files?['generated']),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Préférences',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            themeMode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            color: AppColors.primary,
                          ),
                          title: const Text('Thème', style: TextStyle(color: AppColors.darkTextPrimary)),
                          subtitle: Text(
                            _themeLabel(themeMode),
                            style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
                          ),
                          trailing: DropdownButton<ThemeMode>(
                            value: themeMode,
                            dropdownColor: AppColors.darkCard,
                            underline: const SizedBox.shrink(),
                            style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13),
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text('Automatique'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text('Clair'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Sombre'),
                              ),
                            ],
                            onChanged: (m) async {
                              if (m == null) return;
                              await ref.read(themeModeProvider.notifier).setThemeMode(m);
                              final t = m == ThemeMode.light
                                  ? 'light'
                                  : m == ThemeMode.dark
                                      ? 'dark'
                                      : 'system';
                              await ref.read(profileProvider.notifier).saveSettings(theme: t);
                            },
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.darkBorder),
                        ListTile(
                          leading: const Icon(Icons.language_rounded, color: AppColors.info),
                          title: const Text('Langue', style: TextStyle(color: AppColors.darkTextPrimary)),
                          trailing: DropdownButton<String>(
                            value: ['fr', 'ar', 'en'].contains(lang) ? lang : 'fr',
                            dropdownColor: AppColors.darkCard,
                            style: const TextStyle(color: AppColors.darkTextPrimary),
                            items: const [
                              DropdownMenuItem(value: 'fr', child: Text('Français')),
                              DropdownMenuItem(value: 'ar', child: Text('العربية')),
                              DropdownMenuItem(value: 'en', child: Text('English')),
                            ],
                            onChanged: p.saving
                                ? null
                                : (v) async {
                                    if (v == null) return;
                                    await ref.read(profileProvider.notifier).saveSettings(language: v);
                                  },
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.darkBorder),
                        SwitchListTile(
                          secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.accent),
                          title: const Text('Notifications', style: TextStyle(color: AppColors.darkTextPrimary)),
                          subtitle: const Text(
                            'Alertes et rappels dans l’app',
                            style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
                          ),
                          value: notif,
                          onChanged: p.saving
                              ? null
                              : (v) async {
                                  await ref.read(profileProvider.notifier).saveSettings(notifications: v);
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                    'Notifications push',
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GlassCard(
                    child: ListTile(
                      leading: p.notifySending
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.send_rounded, color: AppColors.primary),
                      title: const Text('Envoyer une notification test', style: TextStyle(color: AppColors.darkTextPrimary)),
                      subtitle: const Text(
                        'Vérifie le token FCM enregistré sur cet appareil',
                        style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
                      ),
                      onTap: p.notifySending
                          ? null
                          : () async {
                              final err = await ref.read(profileProvider.notifier).sendTestNotification();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(err == null ? 'Notification envoyée' : err),
                                  backgroundColor: err == null ? AppColors.success : AppColors.error,
                                ),
                              );
                            },
                    ),
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Text(
                  AppStrings.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Selon le système';
    }
  }

  void _showFilesSheet(BuildContext context, String title, dynamic raw) {
    final list = raw is List ? raw : <dynamic>[];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucun élément',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.darkTextTertiary),
                  ),
                )
              else
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: ListView.builder(
                    itemCount: list.length.clamp(0, 50),
                    itemBuilder: (_, i) {
                      final row = list[i];
                      final map = row is Map ? Map<String, dynamic>.from(row) : <String, dynamic>{};
                      final name = map['title'] as String? ??
                          map['filename'] as String? ??
                          map['name'] as String? ??
                          map['id']?.toString() ??
                          '—';
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary),
                        title: Text(
                          name,
                          style: const TextStyle(color: AppColors.darkTextPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.darkTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.darkTextTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
