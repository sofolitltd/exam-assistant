import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final int totalExamsAttended;
  final double highestScore;
  final double averageScore;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.totalExamsAttended = 0,
    this.highestScore = 0.0,
    this.averageScore = 0.0,
    this.updatedAt,
  });

  bool get isProfileComplete => name.isNotEmpty && phone.isNotEmpty;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      totalExamsAttended: data['totalExamsAttended'] ?? 0,
      highestScore: (data['highestScore'] ?? 0.0).toDouble(),
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'totalExamsAttended': totalExamsAttended,
      'highestScore': highestScore,
      'averageScore': averageScore,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
    };
  }
}
