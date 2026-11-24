import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../../bcs/views/bcs_format.dart';

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
  /// Last visit before this one, so notices since then can say "নতুন".
  DateTime? _previousSeen;
  bool _seenLoaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      DateTime? previous;
      try {
        previous = await ref.read(noticesLastSeenProvider.future);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _previousSeen = previous;
        _seenLoaded = true;
      });
      await ref.read(noticesLastSeenProvider.notifier).markSeenNow();
    });
  }

  bool _isNew(Notice n) =>
      _seenLoaded &&
      (_previousSeen == null || n.createdAt.isAfter(_previousSeen!));

  @override
  Widget build(BuildContext context) {
    final noticesAsync = ref.watch(noticesProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'নোটিশ'),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(noticesProvider.future),
        child: noticesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _Message(
            icon: LucideIcons.wifiOff,
            text: 'নোটিশ আনা যায়নি',
            action: DsSmallButton(
              label: 'আবার চেষ্টা করো',
              onPressed: () => ref.invalidate(noticesProvider),
            ),
          ),
          data: (notices) {
            if (notices.isEmpty) {
              return const _Message(
                icon: LucideIcons.bellOff,
                text: 'এখনো কোনো নোটিশ নেই',
              );
            }
            return DsPage(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                for (final n in notices) _NoticeCard(n, isNew: _isNew(n)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final bool isNew;

  const _NoticeCard(this.notice, {required this.isNew});

  @override
  Widget build(BuildContext context) {
    final d = notice.createdAt.toLocal();
    return DsCard(
      borderColor: isNew ? AppColors.brandLine : AppColors.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${bnDayMonth(d)} ${bn(d.year)} · ${bnTime(d)}',
                  style: dsText(12, color: AppColors.muted),
                ),
              ),
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'নতুন',
                    style: dsText(
                      11,
                      weight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            notice.title,
            style: dsText(16, weight: FontWeight.w700, height: 1.35),
          ),
          if (notice.body.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            SelectableText(
              notice.body.trim(),
              style: dsText(14, color: AppColors.ink2, height: 1.55),
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Message({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    // A ListView so pull to refresh still works on an empty page.
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
      children: [
        Icon(icon, size: 40, color: AppColors.subtle),
        const SizedBox(height: 12),
        Text(
          text,
          textAlign: TextAlign.center,
          style: dsText(15, color: AppColors.muted),
        ),
        if (action != null) ...[
          const SizedBox(height: 14),
          Center(child: action!),
        ],
      ],
    );
  }
}
