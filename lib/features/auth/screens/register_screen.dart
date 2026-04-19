import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.registerTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(controller: _name, label: AppStrings.name),
              const SizedBox(height: 12),
              AuthTextField(controller: _email, label: AppStrings.email, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              AuthTextField(controller: _password, label: AppStrings.password, obscure: true),
              if (auth.error != null) ...[
                const SizedBox(height: 8),
                Text(auth.error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const Spacer(),
              GradientButton(
                loading: auth.loading,
                label: AppStrings.registerTitle,
                onPressed: () async {
                  final ok = await ref.read(authProvider.notifier).register(
                        _email.text.trim(),
                        _password.text,
                        _name.text.trim(),
                      );
                  if (!context.mounted) return;
                  if (ok) context.go('/main');
                },
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('J’ai déjà un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
