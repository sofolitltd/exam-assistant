import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/responsive_wrapper.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isRegistering = false;
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateChangesProvider, (_, next) {
      next.whenOrNull(data: (user) {
        if (user != null && !_redirecting) {
          _redirecting = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/');
          });
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAlreadySignedIn();
    });
  }

  void _checkAlreadySignedIn() {
    if (_redirecting) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      _redirecting = true;
      context.go('/');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isRegistering) {
        await ref
            .read(authControllerProvider.notifier)
            .createUserWithEmailAndPassword(email: email, password: password);
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .signInWithEmailAndPassword(email: email, password: password);
      }
      if (mounted && !_redirecting) {
        _redirecting = true;
        context.go('/');
      }
    } catch (_) {}
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
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && mounted && !_redirecting) {
          _redirecting = true;
          context.go('/');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isLoading = authState.isLoading;
    final credState = ref.watch(authControllerProvider);
    final error = credState.hasError ? credState.error.toString() : null;

    return Scaffold(
      body: ResponsiveWrapper(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      const Icon(
                        Icons.school_rounded,
                        size: 80,
                        color: Color(0xFF005C53),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Exam Assistant',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF005C53),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Prepare for BCS and competitive exams with ease.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      const Text('Email',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('Password',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter your password';
                          if (_isRegistering && v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: credState.isLoading ? null : _submit,
                        child: credState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isRegistering ? 'Create Account' : 'Sign In'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            setState(() => _isRegistering = !_isRegistering),
                        child: Text(
                          _isRegistering
                              ? 'Already have an account? Sign In'
                              : "Don't have an account? Register",
                        ),
                      ),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: isLoading || _isGoogleLoading
                            ? null
                            : () async {
                                setState(() => _isGoogleLoading = true);
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithGoogle();
                                if (mounted) setState(() => _isGoogleLoading = false);
                              },
                        icon: _isGoogleLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                        label: Text(_isGoogleLoading
                            ? 'Redirecting...'
                            : 'Sign in with Google'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
