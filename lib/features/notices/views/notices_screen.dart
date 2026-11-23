import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../auth/controllers/auth_controller.dart';

final noticesProvider = FutureProvider<List<Notice>>((ref) async {
  final response = await ref
      .read(accountApiServiceProvider)
      .getApiJson('/v1/notices');
  if (response is! List) {
    throw const FormatException('Expected a notices list response.');
  }
  return response
      .map((item) => Notice.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

/// When the user last opened the notices screen, kept on the device only
/// (the API has no per-user read state for notices).
class NoticesLastSeenNotifier extends AsyncNotifier<DateTime?> {
  static const _key = 'exam_assistant_notices_last_seen';
  static const _storage = FlutterSecureStorage();

  @override
  Future<DateTime?> build() async {
    try {
      final raw = await _storage.read(key: _key);
      return raw == null ? null : DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> markSeenNow() async {
    final now = DateTime.now();
    state = AsyncData(now);
    try {
      await _storage.write(key: _key, value: now.toIso8601String());
    } catch (_) {
      // Keep the in-memory timestamp even if the device store fails.
    }
  }
}

final noticesLastSeenProvider =
    AsyncNotifierProvider<NoticesLastSeenNotifier, DateTime?>(
      NoticesLastSeenNotifier.new,
    );

/// Whether any notice is newer than the last time the user opened the
/// notices screen.
final noticesUnreadProvider = Provider<bool>((ref) {
  final notices = ref.watch(noticesProvider).value;
  if (notices == null || notices.isEmpty) return false;
  final lastSeen = ref.watch(noticesLastSeenProvider).value;
  if (lastSeen == null) return true;
  return notices.any((n) => n.createdAt.isAfter(lastSeen));
});

class Notice {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  Notice({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> data) {
    return Notice(
      id: data['id'] as String? ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt:
          DateTime.tryParse(data['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key});

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(noticesLastSeenProvider.notifier).markSeenNow(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: noticesAsync.when(
        data: (notices) {
          if (notices.isEmpty) {
            return const Center(
              child: Text(
                'No notices yet.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              return Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notice.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(notice.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(notice.body),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
