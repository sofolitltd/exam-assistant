import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the routine feature's own local notifications: two daily
/// check-in reminders and one weekly summary nudge. Deliberately kept to
/// three notifications a day at most to avoid alert fatigue — no
/// per-block reminders.
class RoutineNotificationService {
  static const _afternoonCheckInId = 9001;
  static const _nightCheckInId = 9002;
  static const _weeklySummaryId = 9003;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await _localTimeZoneName()));

    // A flat white silhouette, per Android's status-bar icon guidelines —
    // the full-color launcher icon gets masked into an unrecognizable blob.
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_stat_notify',
    );
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  /// Schedules (or re-schedules) the recurring check-in and weekly summary
  /// notifications. Safe to call repeatedly — each call replaces the
  /// previous schedule for that slot.
  Future<void> scheduleRoutineReminders() async {
    await init();
    await _scheduleDaily(
      id: _afternoonCheckInId,
      hour: 14,
      minute: 0,
      title: 'আজকের অগ্রগতি জানাও',
      body: 'সকাল থেকে এখন পর্যন্ত কোন কোন রুটিন ব্লক করতে পারলে?',
    );
    await _scheduleDaily(
      id: _nightCheckInId,
      hour: 22,
      minute: 0,
      title: 'দিনের শেষ check-in',
      body: 'আজকের বাকি ব্লকগুলো মার্ক করে নাও।',
    );
    await _scheduleWeekly(
      id: _weeklySummaryId,
      weekday: DateTime.friday,
      hour: 20,
      minute: 0,
      title: 'এই সপ্তাহের রুটিন সামারি তৈরি',
      body: 'দেখো এই সপ্তাহে কতটুকু মানতে পারলে, আর কোথায় বেশি miss হয়েছে।',
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancel(_afternoonCheckInId);
    await _plugin.cancel(_nightCheckInId);
    await _plugin.cancel(_weeklySummaryId);
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekday(weekday, hour, minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'routine_reminders',
        'Routine reminders',
        channelDescription: 'Daily check-in and weekly summary reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    var scheduled = _nextInstanceOfTime(hour, minute);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<String> _localTimeZoneName() async {
    // Bangladesh-only app for now; avoids pulling in an extra plugin just
    // to read the device's IANA timezone name.
    return 'Asia/Dhaka';
  }
}
