import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_ui.dart';

/// প্রোফাইল এডিট: name and phone. The email is the sign-in id, so it is
/// shown but not editable.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  bool _loaded = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final rawPhone = _phone.text.trim();
    final phone = rawPhone.isEmpty ? '' : normalizeBdPhone(rawPhone)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .updateProfile(name: _name.text.trim(), phone: phone);
      ref.invalidate(userProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('প্রোফাইল সংরক্ষণ হয়েছে')));
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = authErrorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final user = profile.asData?.value;
    if (!_loaded && user != null) {
      _name.text = user.name;
      _phone.text = user.phone;
      _loaded = true;
    }

    Widget body;
    if (profile.hasError && user == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'প্রোফাইল লোড করা যায়নি। ইন্টারনেট দেখে আবার চেষ্টা করো।',
                textAlign: TextAlign.center,
                style: dsText(15, color: AppColors.ink2),
              ),
              const SizedBox(height: 16),
              DsSmallButton(
                label: 'আবার চেষ্টা',
                onPressed: () => ref.invalidate(userProfileProvider),
              ),
            ],
          ),
        ),
      );
    } else if (user == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: DsCard(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthField(
                      label: 'নাম',
                      controller: _name,
                      prefix: const Icon(LucideIcons.user, size: 20),
                      action: TextInputAction.next,
                      capitalization: TextCapitalization.words,
                      maxLength: 100,
                      autofillHints: const [AutofillHints.name],
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'নাম লেখো' : null,
                    ),
                    const SizedBox(height: 16),
                    AuthField(
                      label: 'মোবাইল নম্বর',
                      controller: _phone,
                      prefix: const Icon(LucideIcons.phone, size: 20),
                      keyboardType: TextInputType.phone,
                      action: TextInputAction.done,
                      hint: '০১XXXXXXXXX',
                      helper: 'না দিলেও চলবে',
                      autofillHints: const [AutofillHints.telephoneNumber],
                      onSubmitted: (_) => _save(),
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return null;
                        return normalizeBdPhone(value) == null
                            ? 'সঠিক মোবাইল নম্বর লেখো (যেমন ০১৭১২৩৪৫৬৭৮)'
                            : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('ইমেইল', style: dsText(14, weight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sunken,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.lineStrong),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.mail,
                            size: 20,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              user.email,
                              style: dsText(16, color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 2),
                      child: Text(
                        'এই ইমেইল দিয়ে লগ ইন করো, তাই বদলানো যায় না',
                        style: dsText(12, color: AppColors.muted),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      AuthErrorBox(_error!),
                    ],
                    const SizedBox(height: 24),
                    AuthSubmitButton(
                      label: 'সংরক্ষণ করো',
                      busy: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'প্রোফাইল এডিট'),
      body: body,
    );
  }
}
