import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_ui.dart';
import 'login_screen.dart';

/// নতুন অ্যাকাউন্ট: name, mobile (contact only), then the login details
/// (email + password), then the target exam so home's "আজ" card is ready.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with AuthRedirect<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  bool _agree = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    listenForSignIn();
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password]) {
      c.dispose();
    }
    for (final f in [_phoneFocus, _emailFocus, _passwordFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  void _toLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    TextInput.finishAutofillContext();
    try {
      await ref
          .read(authControllerProvider.notifier)
          .createUserWithEmailAndPassword(
            name: _name.text.trim(),
            phone: normalizeBdPhone(_phone.text),
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      header: SizedBox(
        height: 60,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: IconButton(
              tooltip: 'ফিরে যাও',
              onPressed: busy ? null : _toLogin,
              icon: const Icon(LucideIcons.chevronLeft, size: 22),
              color: AppColors.ink,
            ),
          ),
        ),
      ),
      footer: AuthFooter(
        prompt: 'আগে থেকেই অ্যাকাউন্ট আছে?',
        action: 'লগ ইন',
        onTap: busy ? null : _toLogin,
      ),
      children: [
        Text(
          'নতুন অ্যাকাউন্ট',
          style: dsText(26, weight: FontWeight.w700, height: 1.3),
        ),
        const SizedBox(height: 4),
        Text('১ মিনিটেই শুরু করো', style: dsText(15, color: AppColors.ink2)),
        const SizedBox(height: 22),
        DsCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    AuthErrorBox(_error!),
                    const SizedBox(height: 14),
                  ],
                  AuthField(
                    label: 'তোমার নাম',
                    controller: _name,
                    hint: 'পুরো নাম',
                    action: TextInputAction.next,
                    capitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    maxLength: 200,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'নাম লেখো' : null,
                    onSubmitted: (_) => _phoneFocus.requestFocus(),
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    label: 'মোবাইল নম্বর',
                    controller: _phone,
                    focusNode: _phoneFocus,
                    hint: '০১XXXXXXXXX',
                    helper: 'যোগাযোগ ও নোটিশের জন্য, লগ ইনে লাগবে না',
                    keyboardType: TextInputType.phone,
                    action: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.telephoneNumberNational,
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'মোবাইল নম্বর লেখো';
                      }
                      if (normalizeBdPhone(v) == null) {
                        return '০১ দিয়ে শুরু ১১ সংখ্যার নম্বর লেখো';
                      }
                      return null;
                    },
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                  ),
                  const SizedBox(height: 10),
                  const _Divider(label: 'লগ ইনের তথ্য'),
                  const SizedBox(height: 10),
                  AuthField(
                    label: 'ইমেইল',
                    controller: _email,
                    focusNode: _emailFocus,
                    hint: 'tomar@email.com',
                    keyboardType: TextInputType.emailAddress,
                    action: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: validateEmail,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    label: 'পাসওয়ার্ড',
                    controller: _password,
                    focusNode: _passwordFocus,
                    hint: 'কমপক্ষে ৮ অক্ষর',
                    obscure: _obscure,
                    action: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => validatePassword(v, isNew: true),
                    suffix: PasswordToggle(
                      obscured: _obscure,
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.lineStrong),
                  const SizedBox(height: 14),
                  _AgreeRow(
                    value: _agree,
                    onChanged: (v) => setState(() => _agree = v),
                  ),
                  const SizedBox(height: 10),
                  AuthSubmitButton(
                    label: 'অ্যাকাউন্ট খোলো',
                    busy: busy,
                    enabled: _agree,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;

  const _Divider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.lineStrong)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: dsText(13, weight: FontWeight.w600, color: AppColors.ink2),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.lineStrong)),
      ],
    );
  }
}

class _AgreeRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AgreeRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final link = dsText(14, weight: FontWeight.w600, color: AppColors.brand);
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.brand,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text.rich(
                  TextSpan(
                    style: dsText(14, color: AppColors.ink2),
                    children: [
                      const TextSpan(text: 'আমি '),
                      TextSpan(text: 'শর্তাবলি', style: link),
                      const TextSpan(text: ' ও '),
                      TextSpan(text: 'গোপনীয়তা নীতি', style: link),
                      const TextSpan(text: ' মেনে নিচ্ছি'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
