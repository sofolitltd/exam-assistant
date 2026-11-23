import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_ui.dart';

final apiConnectionProvider = FutureProvider.autoDispose<bool>((ref) async {
  final client = http.Client();
  ref.onDispose(client.close);
  final baseUrl = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
  final response = await client
      .get(Uri.parse('$baseUrl/health'))
      .timeout(const Duration(seconds: 3));
  if (response.statusCode < 200 || response.statusCode >= 300) return false;

  try {
    final payload = jsonDecode(response.body);
    return payload is Map && payload['status'] == 'ok';
  } on FormatException {
    return false;
  }
});

/// Sends a signed-in user on to `/`, where [AuthGate] picks home or setup.
/// Shared by the login and sign-up pages.
mixin AuthRedirect<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool redirecting = false;

  void goHome() {
    if (redirecting || !mounted) return;
    redirecting = true;
    context.go('/');
  }

  void listenForSignIn() {
    ref.listenManual(authStateChangesProvider, (_, next) {
      if (next.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => goHome());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(authServiceProvider).currentUser != null) goHome();
    });
  }

  /// While the stored session is being restored, show a spinner instead of
  /// flashing the form.
  bool get restoringSession => ref
      .watch(authStateChangesProvider)
      .when(
        data: (u) => u != null,
        loading: () => true,
        error: (_, _) => false,
      );
}

/// লগ ইন: email + password. New users go to [SignupScreen] via the footer.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with AuthRedirect<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    listenForSignIn();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
      goHome();
    } catch (error) {
      if (mounted) setState(() => _error = authErrorText(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (restoringSession) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final busy = ref.watch(authControllerProvider).isLoading;

    return AuthScaffold(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthFooter(
            prompt: 'অ্যাকাউন্ট নেই?',
            action: 'নতুন অ্যাকাউন্ট খোলো',
            onTap: busy ? null : () => context.push('/signup'),
          ),
          if (kDebugMode) const _ApiConnectionBadge(),
        ],
      ),
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: BrandMark(size: 52),
        ),
        const SizedBox(height: 14),
        Text(
          'আবার স্বাগতম',
          style: dsText(26, weight: FontWeight.w700, height: 1.3),
        ),
        const SizedBox(height: 4),
        Text(
          'লগ ইন করে প্রস্তুতি চালিয়ে যাও',
          style: dsText(15, color: AppColors.ink2),
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  AuthErrorBox(_error!),
                  const SizedBox(height: 16),
                ],
                AuthField(
                  label: 'ইমেইল',
                  controller: _email,
                  hint: 'tomar@email.com',
                  keyboardType: TextInputType.emailAddress,
                  action: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: validateEmail,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                AuthField(
                  label: 'পাসওয়ার্ড',
                  controller: _password,
                  focusNode: _passwordFocus,
                  hint: 'পাসওয়ার্ড লেখো',
                  obscure: _obscure,
                  action: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: validatePassword,
                  onSubmitted: (_) => _submit(),
                  suffix: PasswordToggle(
                    obscured: _obscure,
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: AuthLink(
                    label: 'পাসওয়ার্ড ভুলে গেছো?',
                    // The API has no reset endpoint yet.
                    onTap: () => showComingSoon(context, 'পাসওয়ার্ড রিসেট'),
                  ),
                ),
                const SizedBox(height: 10),
                AuthSubmitButton(
                  label: 'লগ ইন',
                  busy: busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Debug builds only: V1 when `/health` answers, tap to create a Neon test
/// user. Not part of the design.
class _ApiConnectionBadge extends ConsumerStatefulWidget {
  const _ApiConnectionBadge();

  @override
  ConsumerState<_ApiConnectionBadge> createState() =>
      _ApiConnectionBadgeState();
}

class _ApiConnectionBadgeState extends ConsumerState<_ApiConnectionBadge> {
  Timer? _timer;
  bool _testing = false;
  bool _passed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) ref.invalidate(apiConnectionProvider);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _runTest() async {
    setState(() => _testing = true);
    String message;
    try {
      final profile = await ref
          .read(accountApiServiceProvider)
          .createTestUser();
      _passed = true;
      message = 'Neon test passed. Test user: ${profile.email}';
    } catch (error) {
      message = 'Neon test failed: $error';
    }
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final up = ref.watch(apiConnectionProvider).value ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: up && !_testing && !_passed ? _runTest : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: up ? AppColors.brandSoft : AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            up ? 'V1' : 'V0',
            style: dsText(
              11,
              weight: FontWeight.w700,
              color: up ? AppColors.brandStrong : AppColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}
