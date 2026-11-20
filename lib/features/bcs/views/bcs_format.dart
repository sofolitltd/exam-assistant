import '../../../core/utils/bangla_digits.dart';
import '../data/bcs_models.dart';

const _months = [
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];
const _monthsShort = [
  'জানু',
  'ফেব্রু',
  'মার্চ',
  'এপ্রি',
  'মে',
  'জুন',
  'জুলা',
  'আগ',
  'সেপ্টে',
  'অক্টো',
  'নভ',
  'ডিসে',
];
const _weekdays = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];

/// "৫২তম"
String bnOrdinal(int n) => '${bn(n)}তম';

/// "৫২তম বিসিএস"
String editionName(int n) => '${bnOrdinal(n)} বিসিএস';

/// "রাত ৯:০০"
String bnTime(DateTime t) {
  final h = t.hour;
  final part = h < 4
      ? 'রাত'
      : h < 12
      ? 'সকাল'
      : h < 15
      ? 'দুপুর'
      : h < 18
      ? 'বিকাল'
      : h < 20
      ? 'সন্ধ্যা'
      : 'রাত';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$part ${bn(h12)}:${bn(t.minute.toString().padLeft(2, '0'))}';
}

String bnWeekday(DateTime d) => _weekdays[d.weekday - 1];
String bnDay(DateTime d) => bn(d.day);
String bnDayMonth(DateTime d) => '${bn(d.day)} ${_months[d.month - 1]}';
String bnDayMonthShort(DateTime d) =>
    '${bn(d.day)} ${_monthsShort[d.month - 1]}';

bool isToday(DateTime d) {
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

/// "২৫ প্রশ্ন · ১৫ মিনিট · নেগেটিভ ০.৫"
String slotMeta(LiveSlot s) =>
    '${bn(s.questions)} প্রশ্ন · ${bn(s.minutes)} মিনিট · নেগেটিভ ${bnScore(s.negative)}';

/// "৩ ঘ ২০ মি" until [t], or null when it has passed.
String? bnUntil(DateTime t) {
  final diff = t.difference(DateTime.now());
  if (diff.isNegative) return null;
  final h = diff.inHours;
  final m = diff.inMinutes % 60;
  if (h == 0) return '${bn(m)} মি';
  return '${bn(h)} ঘ ${bn(m)} মি';
}

/// "১২,৩৪৫" with Bangla digits and thousands separators.
String bnCount(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return bn(buf.toString());
}

/// "১:৩৪:১২" for a countdown.
String bnClock(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return bn(h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}');
}

/// "১৫ ডিসেম্বর ২০২৬"
String bnDate(DateTime d) => '${bnDayMonth(d)} ${bn(d.year)}';

/// The prelim line under an edition: days left, the date it was held, or
/// that PSC has not announced it.
String prelimText(BcsEdition e) {
  final date = e.prelimDate;
  if (date == null) return 'প্রিলির তারিখ এখনো ঘোষণা হয়নি';
  final days = e.daysToPrelim;
  if (days == null) return 'প্রিলি হয়েছে ${bnDate(date)}';
  if (days == 0) return 'প্রিলি আজ';
  return 'প্রিলি পর্যন্ত ${bn(days)} দিন · ${bnDayMonth(date)}';
}

/// "বিশেষ · স্বাস্থ্য", "বিশেষ", or null for a general BCS.
String? specialText(BcsEdition e) {
  if (!e.special) return null;
  final label = e.specialLabel;
  return label == null || label.isEmpty ? 'বিশেষ' : 'বিশেষ · $label';
}
