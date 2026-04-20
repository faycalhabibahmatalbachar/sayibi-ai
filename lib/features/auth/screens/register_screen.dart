import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/ai_login_mascot.dart';
import '../widgets/auth_glass_field.dart';
import '../widgets/auth_mesh_background.dart';
import '../widgets/auth_remember_row.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    Future<void>(() async {
      await ref.read(authProvider.notifier).waitUntilSessionReady();
      if (!mounted) return;
      if (ref.read(authProvider).authenticated) {
        context.go('/main');
        return;
      }
      final r = await ref.read(authTokenStoreProvider).getRememberMe();
      if (mounted) setState(() => _rememberMe = r);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _goBackToLogin() {
    HapticFeedback.lightImpact();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthMeshBackground(
        child: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: _goBackToLogin,
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.14),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                              tooltip: 'Retour à la connexion',
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Center(child: AiLoginMascot(size: 96))
                            .animate()
                            .fadeIn(duration: 450.ms)
                            .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                        const SizedBox(height: 16),
                        Text(
                          'Créer votre compte',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Quelques secondes pour rejoindre ${AppStrings.appName}.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.76),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.16),
                                    Colors.white.withValues(alpha: 0.06),
                                  ],
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    AppStrings.registerTitle,
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Utilisez une adresse email valide pour activer votre compte.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.65),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextField(
                                    controller: _name,
                                    focusNode: _nameFocus,
                                    textInputAction: TextInputAction.next,
                                    textCapitalization: TextCapitalization.words,
                                    autofillHints: const [AutofillHints.name],
                                    style: GoogleFonts.outfit(color: Colors.white),
                                    cursorColor: AppColors.accentLight,
                                    decoration: AuthGlassField.decoration(
                                      AppStrings.name,
                                      hintText: 'Ex. Jean Dupont',
                                    ),
                                    onSubmitted: (_) => _emailFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _email,
                                    focusNode: _emailFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    style: GoogleFonts.outfit(color: Colors.white),
                                    cursorColor: AppColors.accentLight,
                                    decoration: AuthGlassField.decoration(
                                      AppStrings.email,
                                      hintText: 'vous@exemple.com',
                                    ),
                                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _password,
                                    focusNode: _passwordFocus,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [AutofillHints.newPassword],
                                    style: GoogleFonts.outfit(color: Colors.white),
                                    cursorColor: AppColors.accentLight,
                                    decoration: AuthGlassField.decoration(
                                      AppStrings.password,
                                      hintText: '8 caractères minimum recommandés',
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Afficher le mot de passe'
                                            : 'Masquer',
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          setState(() => _obscurePassword = !_obscurePassword);
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: Colors.white.withValues(alpha: 0.65),
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    onSubmitted: (_) => _submit(),
                                  ),
                                  const SizedBox(height: 8),
                                  AuthRememberRow(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(() => _rememberMe = v),
                                  ),
                                  if (auth.error != null) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          size: 18,
                                          color: AppColors.errorLight,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            auth.error!,
                                            style: GoogleFonts.outfit(
                                              color: AppColors.errorLight,
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  GradientButton(
                                    isLoading: auth.loading,
                                    text: AppStrings.registerTitle,
                                    icon: Icons.check_circle_outline_rounded,
                                    onPressed: auth.loading ? null : () => _submit(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 100.ms, duration: 420.ms)
                            .slideY(begin: 0.05, curve: Curves.easeOutCubic),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _goBackToLogin,
                          icon: Icon(
                            Icons.login_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 20,
                          ),
                          label: Text(
                            'J’ai déjà un compte',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final auth = ref.read(authProvider);
    if (auth.loading) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty || email.isEmpty || _password.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez remplir tous les champs.',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkCard,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
      return;
    }

    if (_password.text.length < 8) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Choisissez un mot de passe d’au moins 8 caractères.',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkCard,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
      return;
    }

    final ok = await ref.read(authProvider.notifier).register(
          email,
          _password.text,
          name,
          rememberMe: _rememberMe,
        );
    if (!mounted) return;
    if (ok) context.go('/main');
  }
}
