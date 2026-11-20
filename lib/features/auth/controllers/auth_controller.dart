import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/user_model.dart';
import '../data/services/account_api_service.dart';

part 'auth_controller.g.dart';

final accountApiServiceProvider = Provider<AccountApiService>((ref) {
  return AccountApiService();
});

final authServiceProvider = accountApiServiceProvider;

final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return null;
  return ref.read(accountApiServiceProvider).getProfile();
});

final profileCompleteProvider = Provider<bool>((ref) {
  final userDoc = ref.watch(userProfileProvider).value;
  return userDoc?.isProfileComplete ?? false;
});

@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmailAndPassword(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(authServiceProvider)
          .createUserWithEmailAndPassword(
            name: name,
            email: email,
            password: password,
            phone: phone,
          );
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authServiceProvider).signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
