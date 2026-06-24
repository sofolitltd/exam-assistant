import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/user_model.dart';
import '../data/services/firebase_auth_service.dart';

part 'auth_controller.g.dart';

final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userDocStreamProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();
  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
});

final profileCompleteProvider = Provider<bool>((ref) {
  final userDoc = ref.watch(userDocStreamProvider).value;
  return userDoc?.isProfileComplete ?? false;
});

@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signInWithGoogle(),
    );
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(authServiceProvider).signOut());
  }
}
