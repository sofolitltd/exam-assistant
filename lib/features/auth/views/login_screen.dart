import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/api_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_mark.dart';
import '../controllers/auth_controller.dart';

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

/// Sign in / create account. Fields, copy, and validation mirror the
/// website's UserSignInScreen (exam_assistant_admin/src/components/
/// user-sign-in-screen.tsx), which is the source of truth.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isRegistering = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _redirecting = false;
  bool _isTestingApi = false;
  bool _apiTestSucceeded = false;
  String? _error;
  Timer? _apiHealthTimer;

  @override
  void initState() {
    super.initState();
    _apiHealthTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) ref.invalidate(apiConnectionProvider);
    });
    ref.listenManual(authStateChangesProvider, (_, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null && !_redirecting) {
            _redirecting = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/');
            });
          }
        },
      );
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAlreadySignedIn(),
    );
  }

  void _checkAlreadySignedIn() {
    if (_redirecting || _isTestingApi) return;
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null && mounted) {
      _redirecting = true;
      context.go('/');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _apiHealthTimer?.cancel();
    super.dispose();
  }

  void _switchMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _error = null;
      _passwordController.clear();
      _confirmController.clear();
    });
    _formKey.currentState?.reset();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    try {
      if (_isRegistering) {
        await controller.createUserWithEmailAndPassword(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await controller.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (mounted && !_redirecting) {
        _redirecting = true;
        context.go('/');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _runApiAccountTest() async {
    if (_isTestingApi || _apiTestSucceeded) return;
    if (ref.read(apiConnectionProvider).asData?.value != true) return;

    setState(() => _isTestingApi = true);
    String resultMessage;
    try {
      final profile = await ref
          .read(accountApiServiceProvider)
          .createTestUser();
      _apiTestSucceeded = true;
      resultMessage = 'Neon test passed. Test user: ${profile.email}';
    } catch (error) {
      resultMessage = 'Neon test failed: $error';
    }
    if (!mounted) return;
    setState(() => _isTestingApi = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(resultMessage)));
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    final bytes = utf8.encode(value).length;
    if (_isRegistering && bytes < 8) return 'At least 8 characters';
    if (bytes > 72) return 'Password must be no more than 72 bytes';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final showForm = authState.when(
      data: (user) => user == null,
      loading: () => false,
      error: (_, _) => true,
    );

    if (!showForm && !_redirecting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final user = ref.read(authServiceProvider).currentUser;
        if (user != null && mounted && !_redirecting) {
          _redirecting = true;
          context.go('/');
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final busy = ref.watch(authControllerProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            const _AuthHero(),
            Transform.translate(
              offset: const Offset(0, -64),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        border: Border.all(color: AppColors.line),
                        boxShadow: AppShadows.card,
                      ),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isRegistering ? 'GET STARTED' : 'WELCOME BACK',
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.brand,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isRegistering
                                    ? 'Create your account'
                                    : 'Sign in to your account',
                                style: textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isRegistering
                                    ? 'Join Exam Assistant to start preparing for your exams.'
                                    : 'Continue to your exams and learning progress.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 22),
                              if (_error != null) _ErrorAlert(message: _error!),
                              if (_isRegistering) ...[
                                const _FieldLabel('Your name'),
                                TextFormField(
                                  controller: _nameController,
                                  autofillHints: const [AutofillHints.name],
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  maxLength: 200,
                                  buildCounter: _noCounter,
                                  decoration: const InputDecoration(
                                    hintText: 'Your name',
                                  ),
                                  onFieldSubmitted: (_) =>
                                      _emailFocus.requestFocus(),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Please enter your name'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                              ],
                              const _FieldLabel('Email address'),
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                autofillHints: const [AutofillHints.email],
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  hintText: 'name@example.com',
                                ),
                                onFieldSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const _FieldLabel('Password'),
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                autofillHints: [
                                  _isRegistering
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                textInputAction: _isRegistering
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                decoration: InputDecoration(
                                  hintText: _isRegistering
                                      ? 'At least 8 characters'
                                      : 'Enter your password',
                                  suffixIcon: _VisibilityToggle(
                                    obscured: _obscurePassword,
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                onFieldSubmitted: (_) => _isRegistering
                                    ? _confirmFocus.requestFocus()
                                    : _submit(),
                                validator: _validatePassword,
                              ),
                              if (_isRegistering) ...[
                                const SizedBox(height: 16),
                                const _FieldLabel('Confirm password'),
                                TextFormField(
                                  controller: _confirmController,
                                  focusNode: _confirmFocus,
                                  obscureText: _obscureConfirm,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your password again',
                                    suffixIcon: _VisibilityToggle(
                                      obscured: _obscureConfirm,
                                      onPressed: () => setState(
                                        () =>
                                            _obscureConfirm = !_obscureConfirm,
                                      ),
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (v != _passwordController.text) {
                                      return 'Passwords do not match.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: busy ? null : _submit,
                                child: busy
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _isRegistering
                                                ? 'Creating account...'
                                                : 'Signing in...',
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _isRegistering
                                            ? 'Create account'
                                            : 'Sign in',
                                      ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    _isRegistering
                                        ? 'Already have an account?'
                                        : 'New to Exam Assistant?',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: busy ? null : _switchMode,
                                    child: Text(
                                      _isRegistering
                                          ? 'Sign in'
                                          : 'Create an account',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -48),
              child: _ApiConnectionIndicator(
                onTap: _runApiAccountTest,
                isTesting: _isTestingApi,
                testSucceeded: _apiTestSucceeded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget? _noCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;
}

/// Emerald header with progress-ring decoration — the mobile layout of the
/// website's `.signin-brand-panel`.
class _AuthHero extends StatelessWidget {
  const _AuthHero();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroSoft, AppColors.hero],
          stops: [0, 0.6],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _RingsPainter())),
          Padding(
            padding: EdgeInsets.fromLTRB(24, topInset + 24, 24, 96),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandLockup(light: true),
                    const SizedBox(height: 32),
                    Text(
                      'YOUR PREPARATION SPACE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      const TextSpan(
                        text: 'Make every ',
                        children: [
                          TextSpan(
                            text: 'day',
                            style: TextStyle(color: AppColors.accent),
                          ),
                          TextSpan(text: ' count.'),
                        ],
                      ),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontSize: 34,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Exams, practice, and your daily routine in one calm place. '
                      'প্রতিদিন একটু একটু করে এগিয়ে যাও।',
                      style: TextStyle(
                        color: const Color(0xFFECF4F1).withValues(alpha: 0.75),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.26),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.9, size.height * 0.85),
              radius: size.width * 0.55,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);

    final center = Offset(size.width + 40, size.height * 0.42);
    canvas.drawCircle(
      center,
      170,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 122),
      math.pi * 0.75,
      math.pi * 0.62,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accent.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink2,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onPressed;

  const _VisibilityToggle({required this.obscured, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
      ),
      onPressed: onPressed,
    );
  }
}

class _ErrorAlert extends StatelessWidget {
  final String message;

  const _ErrorAlert({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: const Color(0xFFF3D3D0)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.danger, fontSize: 13),
      ),
    );
  }
}

class _ApiConnectionIndicator extends ConsumerWidget {
  const _ApiConnectionIndicator({
    required this.onTap,
    required this.isTesting,
    required this.testSucceeded,
  });

  final VoidCallback onTap;
  final bool isTesting;
  final bool testSucceeded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(apiConnectionProvider).asData?.value ?? false;
    final color = isConnected ? AppColors.brandStrong : AppColors.danger;
    final background = isConnected ? AppColors.brandSoft : AppColors.dangerSoft;

    return Semantics(
      button: isConnected,
      label: isConnected
          ? 'V1: Tap to test Neon user creation'
          : 'V0: API unavailable',
      child: InkWell(
        onTap: isConnected && !isTesting && !testSucceeded ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            isConnected ? 'V1' : 'V0',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
