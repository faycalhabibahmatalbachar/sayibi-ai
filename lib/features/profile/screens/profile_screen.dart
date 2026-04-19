import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.person_outline),
          title: Text('Profil SAYIBI'),
          subtitle: Text('Thème, langue, usage — branchement /user/*'),
        ),
        SwitchListTile(
          value: Theme.of(context).brightness == Brightness.dark,
          onChanged: (_) {},
          title: const Text('Thème sombre'),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Déconnexion'),
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (!context.mounted) return;
            context.go('/login');
          },
        ),
        const SizedBox(height: 12),
        const Text(AppStrings.tagline, textAlign: TextAlign.center),
      ],
    );
  }
}
