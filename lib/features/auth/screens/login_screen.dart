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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = true;
  bool _prefsLoaded = false;
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
      final store = ref.read(authTokenStoreProvider);
      final remember = await store.getRememberMe();
      final lastEmail = await store.getLastEmail();
      if (!mounted) return;
      setState(() {
        _rememberMe = remember;
        if (lastEmail != null && lastEmail.isNotEmpty) {
          _email.text = lastEmail;
        }
        _prefsLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
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
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: AiLoginMascot(size: 128))
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.08, curve: Curves.easeOutCubic),
                        const SizedBox(height: 20),
                        Text(
                          AppStrings.appName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Votre assistant, toujours présent.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.78),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 28),
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
                              child: AutofillGroup(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      AppStrings.loginTitle,
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Entrez vos identifiants pour continuer.',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.65),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    TextField(
                                      controller: _email,
                                      focusNode: _emailFocus,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.email],
                                      style: GoogleFonts.outfit(color: Colors.white),
                                      cursorColor: AppColors.accentLight,
                                      decoration: AuthGlassField.decoration(AppStrings.email),
                                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _password,
                                      focusNode: _passwordFocus,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [AutofillHints.password],
                                      style: GoogleFonts.outfit(color: Colors.white),
                                      cursorColor: AppColors.accentLight,
                                      decoration: AuthGlassField.decoration(
                                        AppStrings.password,
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
                                      enabled: _prefsLoaded,
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
                                      text: AppStrings.loginTitle,
                                      icon: Icons.login_rounded,
                                      onPressed: auth.loading ? null : () => _submit(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 120.ms, duration: 450.ms)
                            .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push('/register');
                          },
                          icon: Icon(
                            Icons.person_add_alt_1_outlined,
                            color: Colors.white.withValues(alpha: 0.92),
                            size: 20,
                          ),
                          label: Text(
                            'Créer un compte',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.92),
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

    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez remplir l’email et le mot de passe.',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkCard,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        ),
      );
      return;
    }

    final ok = await ref.read(authProvider.notifier).login(
          email,
          _password.text,
          rememberMe: _rememberMe,
        );
    if (!mounted) return;
    if (ok) context.go('/main');
  }
}
