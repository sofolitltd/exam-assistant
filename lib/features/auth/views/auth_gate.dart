import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/auth_controller.dart';
import '../data/services/firebase_auth_service.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final userDoc = ref.watch(userDocStreamProvider);
        return userDoc.when(
          data: (u) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              if (u == null) {
                FirebaseAuthService().saveUserToFirestore(
                  user,
                  name: user.displayName ?? '',
                );
              }
              if (u?.isProfileComplete ?? false) {
                context.go('/home');
              } else {
                context.go('/profile-setup');
              }
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Scaffold(
            body: Center(child: Text('Profile error: $err')),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Auth Error: $err'))),
    );
  }
}
