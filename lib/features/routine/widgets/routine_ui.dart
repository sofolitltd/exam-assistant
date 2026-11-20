import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../data/models/routine_block_model.dart';

/// Week as shown in the routine UI: শনি first. Values are
/// [DateTime.weekday] numbers (1 = Monday … 7 = Sunday).
const routineWeekOrder = [6, 7, 1, 2, 3, 4, 5];
const routineWorkWeek = [6, 7, 1, 2, 3, 4];

const _short = {
  1: 'সোম',
  2: 'মঙ্গল',
  3: 'বুধ',
  4: 'বৃহঃ',
  5: 'শুক্র',
  6: 'শনি',
  7: 'রবি',
};
const _full = {
  1: 'সোমবার',
  2: 'মঙ্গলবার',
  3: 'বুধবার',
  4: 'বৃহস্পতিবার',
  5: 'শুক্রবার',
  6: 'শনিবার',
  7: 'রবিবার',
};
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

String weekdayShort(int weekday) => _short[weekday]!;
String weekdayFull(int weekday) => _full[weekday]!;

/// "শুক্রবার, ২০ নভেম্বর"
String bnLongDate(DateTime d) =>
    '${weekdayFull(d.weekday)}, ${bn(d.day)} ${_months[d.month - 1]}';

/// "১৪ – ২০ নভেম্বর"
String bnRange(DateTime a, DateTime b) => a.month == b.month
    ? '${bn(a.day)} – ${bn(b.day)} ${_months[b.month - 1]}'
    : '${bn(a.day)} ${_months[a.month - 1]} – ${bn(b.day)} ${_months[b.month - 1]}';

int minutesOf(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length < 2) return 0;
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}

String dayPart(int hour) {
  if (hour < 4) return 'রাত';
  if (hour < 6) return 'ভোর';
  if (hour < 12) return 'সকাল';
  if (hour < 15) return 'দুপুর';
  if (hour < 18) return 'বিকাল';
  if (hour < 20) return 'সন্ধ্যা';
  return 'রাত';
}

/// "07:00" → ("৭:০০", "সকাল")
(String, String) bnClockParts(String hhmm) {
  final m = minutesOf(hhmm);
  final h = m ~/ 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return ('${bn(h12)}:${bn((m % 60).toString().padLeft(2, '0'))}', dayPart(h));
}

/// "07:00" → "সকাল ৭:০০"
String bnClock12(String hhmm) {
  final (t, p) = bnClockParts(hhmm);
  return '$p $t';
}

/// Duration of a block in hours, e.g. "২ ঘণ্টা", "১.৫ ঘণ্টা", "৪৫ মিনিট".
String bnDuration(RoutineBlockModel b) {
  var mins = minutesOf(b.endTime) - minutesOf(b.startTime);
  if (mins <= 0) mins += 24 * 60;
  return bnMinutes(mins);
}

String bnMinutes(int mins) {
  if (mins < 60) return '${bn(mins)} মিনিট';
  final h = mins / 60;
  return '${bn(h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1))} ঘণ্টা';
}

int blockMinutes(RoutineBlockModel b) {
  var mins = minutesOf(b.endTime) - minutesOf(b.startTime);
  if (mins <= 0) mins += 24 * 60;
  return mins;
}

String daysLabel(List<int> days) {
  final set = days.toSet();
  if (set.length == 7) return 'প্রতিদিন';
  if (set.length == 6 && !set.contains(5)) return 'শনি–বৃহঃ';
  if (set.length == 1) return 'শুধু ${weekdayShort(set.first)}';
  return [
    for (final d in routineWeekOrder)
      if (set.contains(d)) weekdayShort(d),
  ].join(', ');
}

Color categoryTint(RoutineBlockCategory c) {
  switch (c) {
    case RoutineBlockCategory.study:
      return AppColors.brand;
    case RoutineBlockCategory.prayer:
      return AppColors.success;
    case RoutineBlockCategory.meal:
      return const Color(0xFFB45309);
    case RoutineBlockCategory.rest:
    case RoutineBlockCategory.other:
      return const Color(0xFF8A919C);
  }
}

bool isNow(RoutineBlockModel b, DateTime now) {
  final m = now.hour * 60 + now.minute;
  final s = minutesOf(b.startTime);
  final e = minutesOf(b.endTime);
  return e > s ? m >= s && m < e : m >= s || m < e;
}
