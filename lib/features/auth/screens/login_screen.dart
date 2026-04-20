import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(AppStrings.loginTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              AuthTextField(controller: _email, label: AppStrings.email, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              AuthTextField(controller: _password, label: AppStrings.password, obscure: true),
              if (auth.error != null) ...[
                const SizedBox(height: 8),
                Text(auth.error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const Spacer(),
              GradientButton(
                isLoading: auth.loading,
                text: AppStrings.loginTitle,
                onPressed: () async {
                  final ok = await ref.read(authProvider.notifier).login(_email.text.trim(), _password.text);
                  if (!context.mounted) return;
                  if (ok) context.go('/main');
                },
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
