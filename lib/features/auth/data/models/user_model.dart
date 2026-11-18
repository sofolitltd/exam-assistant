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

  // Matches the website: phone is optional and editable from the profile.
  bool get isProfileComplete => name.isNotEmpty;

  factory UserModel.fromJson(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String? ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      totalExamsAttended: (data['totalExamsAttended'] as num? ?? 0).toInt(),
      highestScore: (data['highestScore'] as num? ?? 0).toDouble(),
      averageScore: (data['averageScore'] as num? ?? 0).toDouble(),
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? ''),
    );
  }
}
