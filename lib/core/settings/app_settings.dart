import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-only preferences. They are not tied to the account, so they stay
/// when someone signs out.
const _storage = FlutterSecureStorage();

Future<String?> _read(String key) async {
  try {
    return await _storage.read(key: key);
  } catch (_) {
    return null;
  }
}

Future<void> _write(String key, String value) async {
  try {
    await _storage.write(key: key, value: value);
  } catch (_) {
    // The in-memory choice still applies for this session.
  }
}

enum TextSize {
  small('ছোট', 0.9),
  medium('মাঝারি', 1.0),
  large('বড়', 1.15),
  xlarge('অনেক বড়', 1.3);

  final String label;
  final double factor;
  const TextSize(this.label, this.factor);
}

/// Multiplies the phone's own font size setting, so a learner who already
/// uses large system text keeps it.
class TextSizeNotifier extends AsyncNotifier<TextSize> {
  static const _key = 'exam_assistant_text_size';

  @override
  Future<TextSize> build() async {
    final saved = await _read(_key);
    return TextSize.values.firstWhere(
      (s) => s.name == saved,
      orElse: () => TextSize.medium,
    );
  }

  Future<void> set(TextSize size) async {
    state = AsyncData(size);
    await _write(_key, size.name);
  }
}

final textSizeProvider = AsyncNotifierProvider<TextSizeNotifier, TextSize>(
  TextSizeNotifier.new,
);

/// Which routine reminders are on. All three default to on, as before.
class ReminderPrefs {
  final bool afternoon;
  final bool night;
  final bool weekly;

  const ReminderPrefs({
    this.afternoon = true,
    this.night = true,
    this.weekly = true,
  });

  bool get anyOn => afternoon || night || weekly;

  ReminderPrefs copyWith({bool? afternoon, bool? night, bool? weekly}) =>
      ReminderPrefs(
        afternoon: afternoon ?? this.afternoon,
        night: night ?? this.night,
        weekly: weekly ?? this.weekly,
      );

  static const _key = 'exam_assistant_reminders';

  static Future<ReminderPrefs> load() async {
    final raw = await _read(_key);
    if (raw == null || raw.length != 3) return const ReminderPrefs();
    return ReminderPrefs(
      afternoon: raw[0] == '1',
      night: raw[1] == '1',
      weekly: raw[2] == '1',
    );
  }

  Future<void> save() =>
      _write(_key, '${afternoon ? 1 : 0}${night ? 1 : 0}${weekly ? 1 : 0}');
}

class ReminderPrefsNotifier extends AsyncNotifier<ReminderPrefs> {
  @override
  Future<ReminderPrefs> build() => ReminderPrefs.load();

  Future<void> set(ReminderPrefs prefs) async {
    state = AsyncData(prefs);
    await prefs.save();
  }
}

final reminderPrefsProvider =
    AsyncNotifierProvider<ReminderPrefsNotifier, ReminderPrefs>(
      ReminderPrefsNotifier.new,
    );
