import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ds.dart';
import '../../routine/controllers/routine_controller.dart';

/// নোটিফিকেশন: which of the three routine reminders are on.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    ReminderPrefs next,
  ) async {
    final service = ref.read(routineNotificationServiceProvider);
    if (next.anyOn) {
      final granted = await service.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ফোনের সেটিংস থেকে এই অ্যাপের নোটিফিকেশন চালু করো'),
            ),
          );
        }
        return;
      }
    }
    await ref.read(reminderPrefsProvider.notifier).set(next);
    await service.scheduleRoutineReminders(prefs: next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs =
        ref.watch(reminderPrefsProvider).value ?? const ReminderPrefs();

    Widget row(String title, String subtitle, bool value, ReminderPrefs next) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: dsText(15, weight: FontWeight.w600)),
                  Text(subtitle, style: dsText(12, color: AppColors.muted)),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.brand,
              onChanged: (_) => _change(context, ref, next),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'নোটিফিকেশন'),
      body: DsPage(
        children: [
          Text(
            'রুটিনের রিমাইন্ডার দিনে সর্বোচ্চ দুটি, আর সপ্তাহে একটি সামারি।',
            style: dsText(13, color: AppColors.muted, height: 1.5),
          ),
          DsListCard(
            radius: 16,
            children: [
              row(
                'দুপুরের check-in',
                'রোজ দুপুর ২টা',
                prefs.afternoon,
                prefs.copyWith(afternoon: !prefs.afternoon),
              ),
              row(
                'রাতের check-in',
                'রোজ রাত ১০টা',
                prefs.night,
                prefs.copyWith(night: !prefs.night),
              ),
              row(
                'সাপ্তাহিক সামারি',
                'প্রতি শুক্রবার রাত ৮টা',
                prefs.weekly,
                prefs.copyWith(weekly: !prefs.weekly),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
