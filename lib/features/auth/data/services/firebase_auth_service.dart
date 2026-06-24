import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants/app_constants.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> _saveUserToFirestore(User user, {String name = ''}) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();
    if (!doc.exists) {
      await userRef.set({
        'uid': user.uid,
        'name': name,
        'email': user.email ?? '',
        'phone': '',
        'totalExamsAttended': 0,
        'highestScore': 0.0,
        'averageScore': 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> saveUserToFirestore(User user, {String name = ''}) {
    return _saveUserToFirestore(user, name: name);
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveExamResult({
    required double score,
    required String examId,
    required int totalQuestions,
    required int correctCount,
    required int wrongCount,
    required int skippedCount,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final totalExamsAttended = (data['totalExamsAttended'] ?? 0) as int;
      final totalScoreSum = (data['totalScoreSum'] ?? 0.0).toDouble();
      final currentHighest = (data['highestScore'] ?? 0.0).toDouble();

      final newTotalExams = totalExamsAttended + 1;
      final newTotalScoreSum = totalScoreSum + score;
      final newHighest = score > currentHighest ? score : currentHighest;
      final newAverage = newTotalScoreSum / newTotalExams;

      transaction.update(userRef, {
        'totalExamsAttended': newTotalExams,
        'highestScore': newHighest,
        'averageScore': newAverage,
        'totalScoreSum': newTotalScoreSum,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // Also write to exam_results collection
    await _firestore.collection(AppConstants.examResultsCollection).add({
      'examId': examId,
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'User',
      'score': score,
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'skippedCount': skippedCount,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final result = await _auth.signInWithPopup(GoogleAuthProvider());
        if (result.user != null) {
          await _saveUserToFirestore(
            result.user!,
            name: result.user!.displayName ?? '',
          );
        }
        return result;
      } else {
        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final result = await _auth.signInWithCredential(credential);
        if (result.user != null) {
          await _saveUserToFirestore(
            result.user!,
            name: result.user!.displayName ?? '',
          );
        }
        return result;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (result.user != null) {
      await _saveUserToFirestore(result.user!);
    }
    return result;
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (result.user != null) {
      await _saveUserToFirestore(result.user!);
    }
    return result;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}
