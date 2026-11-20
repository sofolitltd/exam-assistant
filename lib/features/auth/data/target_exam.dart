import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The exam the student is preparing for, chosen at sign up.
///
/// The API has no field for this yet, so it is kept on the device only.
/// Move it to `/v1/users/me` once the server stores it.
typedef TargetExam = ({String id, String label});

const targetExamOptions = <TargetExam>[
  (id: 'bcs', label: '৫২তম বিসিএস'),
  (id: 'bank', label: 'ব্যাংক নিয়োগ'),
  (id: 'ntrca', label: 'শিক্ষক নিবন্ধন'),
  (id: 'primary', label: 'প্রাথমিক শিক্ষক'),
];

TargetExam targetExamById(String? id) => targetExamOptions.firstWhere(
  (o) => o.id == id,
  orElse: () => targetExamOptions.first,
);

class TargetExamNotifier extends AsyncNotifier<String?> {
  static const _key = 'exam_assistant_target_exam';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> build() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null;
    }
  }

  Future<void> set(String id) async {
    // Let the first read finish, or it would overwrite this choice.
    try {
      await future;
    } catch (_) {}
    state = AsyncData(id);
    try {
      await _storage.write(key: _key, value: id);
    } catch (_) {
      // Keep the in-memory choice even if the device store fails.
    }
  }
}

final targetExamProvider = AsyncNotifierProvider<TargetExamNotifier, String?>(
  TargetExamNotifier.new,
);
