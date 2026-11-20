import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ds.dart';
import '../data/services/account_api_service.dart';

/// Shared pieces of the লগ ইন and নতুন অ্যাকাউন্ট pages.

/// Page frame: scrollable body, a footer pinned to the bottom, no nav.
class AuthScaffold extends StatelessWidget {
  final Widget? header;
  final EdgeInsets padding;
  final List<Widget> children;
  final Widget footer;

  const AuthScaffold({
    required this.children,
    required this.footer,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(20, 56, 20, 20),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?header,
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
                    ),
                  ),
                ),
                footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "অ্যাকাউন্ট নেই? নতুন অ্যাকাউন্ট খোলো"
class AuthFooter extends StatelessWidget {
  final String prompt;
  final String action;
  final VoidCallback? onTap;

  const AuthFooter({
    required this.prompt,
    required this.action,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(prompt, style: dsText(15, color: AppColors.ink2)),
          AuthLink(label: action, onTap: onTap, fontSize: 15),
        ],
      ),
    );
  }
}

class AuthLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double fontSize;

  const AuthLink({
    required this.label,
    required this.onTap,
    this.fontSize = 14,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: dsText(
                fontSize,
                weight: FontWeight.w600,
                color: AppColors.brand,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Label above a white, outlined 50px input.
class AuthField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helper;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? action;
  final Iterable<String>? autofillHints;
  final TextCapitalization capitalization;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;

  const AuthField({
    required this.label,
    required this.controller,
    this.focusNode,
    this.hint,
    this.helper,
    this.prefix,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.action,
    this.autofillHints,
    this.capitalization = TextCapitalization.none,
    this.maxLength,
    this.validator,
    this.onSubmitted,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: dsText(14, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: action,
          autofillHints: autofillHints,
          textCapitalization: capitalization,
          maxLength: maxLength,
          buildCounter: _noCounter,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          style: dsText(16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: dsText(16, color: AppColors.subtle),
            helperText: helper,
            helperMaxLines: 2,
            helperStyle: dsText(12, color: AppColors.muted),
            filled: true,
            fillColor: AppColors.paper,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            prefixIcon: prefix,
            prefixIconConstraints: const BoxConstraints(minHeight: 48),
            suffixIcon: suffix,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            border: border(AppColors.lineStrong),
            enabledBorder: border(AppColors.lineStrong),
            focusedBorder: border(AppColors.brand, 2),
            errorBorder: border(AppColors.danger),
            focusedErrorBorder: border(AppColors.danger, 2),
            errorStyle: dsText(13, color: AppColors.danger),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }

  static Widget? _noCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;
}

/// Eye button at the end of a password field.
class PasswordToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onPressed;

  const PasswordToggle({
    required this.obscured,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'পাসওয়ার্ড দেখাও' : 'পাসওয়ার্ড লুকাও',
      color: AppColors.muted,
      icon: Icon(obscured ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
      onPressed: onPressed,
    );
  }
}

/// Full-width 50px primary button with a spinner while [busy].
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback onPressed;

  const AuthSubmitButton({
    required this.label,
    required this.busy,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: busy ? AppColors.brandStrong : AppColors.brand,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onPressed,
        child: SizedBox(
          height: 50,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    style: dsText(
                      16,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class AuthErrorBox extends StatelessWidget {
  final String message;

  const AuthErrorBox(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(message, style: dsText(14, color: AppColors.danger)),
      ),
    );
  }
}

/// Turns an API or network failure into a short Bangla sentence.
String authErrorText(Object error) {
  if (error is http.ClientException || error is TimeoutException) {
    return 'সার্ভারে পৌঁছানো যাচ্ছে না। ইন্টারনেট সংযোগ দেখে আবার চেষ্টা করো।';
  }
  if (error is ApiException) {
    final m = error.message.toLowerCase();
    if (error.statusCode == 429) {
      return 'অনেকবার চেষ্টা হয়েছে। এক মিনিট পরে আবার চেষ্টা করো।';
    }
    if (m.contains('incorrect')) return 'ইমেইল বা পাসওয়ার্ড মিলছে না।';
    if (m.contains('already exists')) {
      return 'এই ইমেইলে আগেই একটা অ্যাকাউন্ট আছে। লগ ইন করো।';
    }
    if (m.contains('valid email')) return 'সঠিক ইমেইল লেখো।';
    if (m.contains('password')) return 'পাসওয়ার্ড ৮ থেকে ৭২ অক্ষরের হতে হবে।';
    if (error.statusCode >= 500) {
      return 'সার্ভারে সমস্যা হচ্ছে। একটু পরে আবার চেষ্টা করো।';
    }
  }
  return error.toString();
}

String? validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'ইমেইল লেখো';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
    return 'সঠিক ইমেইল লেখো';
  }
  return null;
}

/// Login only checks presence; sign up also enforces the server's 8–72 bytes.
String? validatePassword(String? v, {bool isNew = false}) {
  if (v == null || v.isEmpty) return 'পাসওয়ার্ড লেখো';
  final bytes = utf8.encode(v).length;
  if (isNew && bytes < 8) return 'কমপক্ষে ৮ অক্ষর দাও';
  if (bytes > 72) return 'পাসওয়ার্ড অনেক বড়, ৭২ অক্ষরের মধ্যে রাখো';
  return null;
}

/// "০১৭১২-৩৪৫৬৭৮", "+8801712345678" → "01712345678"; null if not a BD mobile.
String? normalizeBdPhone(String raw) {
  const bnDigits = '০১২৩৪৫৬৭৮৯';
  final ascii = raw.split('').map((c) {
    final i = bnDigits.indexOf(c);
    return i >= 0 ? '$i' : c;
  }).join();
  var digits = ascii.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('880')) digits = digits.substring(2);
  return RegExp(r'^01[3-9][0-9]{8}$').hasMatch(digits) ? digits : null;
}
