import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bcs_models.dart';

/// SAMPLE DATA for the parts of the বিসিএস flow the API cannot serve yet:
/// the running/upcoming edition's live-exam schedule and live merit lists.
///
/// Finished papers (the edition list, their questions, the user's scores,
/// ranks and mistakes) and syllabus comparison are real and come from
/// `bcs_api.dart`.
class BcsRepository {
  const BcsRepository();

  /// Fallback only, while the real list (bcsListProvider) loads.
  BcsEdition runningEdition() =>
      const BcsEdition(number: 50, status: EditionStatus.running);

  BcsEdition edition(int number) => BcsEdition(
    number: number,
    status: number == runningEdition().number
        ? EditionStatus.running
        : EditionStatus.completed,
  );

  /// Daily quiz progress: answered / total.
  (int, int) dailyQuiz() => (12, 15);

  /// Days in a row the user has studied, and the last 7 days.
  (int, List<bool>) readingStreak() =>
      (6, const [true, true, true, true, true, true, false]);

  /// 100-day preparation: live exams taken out of the total.
  (int, int) preparationProgress() => (18, 40);

  List<LiveSlot> schedule() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime day(int offset) => today.add(Duration(days: offset));
    return [
      LiveSlot(
        date: day(-6),
        subject: 'বাংলাদেশ বিষয়াবলি',
        questions: 30,
        minutes: 20,
        state: SlotState.missed,
      ),
      LiveSlot(
        date: day(-3),
        subject: 'বাংলা ভাষা ও সাহিত্য',
        questions: 35,
        minutes: 20,
        state: SlotState.done,
        score: 31.5,
        fullMarks: 35,
        rank: 140,
      ),
      LiveSlot(
        date: day(-1),
        subject: 'English Language',
        questions: 35,
        minutes: 20,
        state: SlotState.done,
        score: 28.5,
        fullMarks: 35,
        rank: 212,
      ),
      LiveSlot(
        date: today.add(const Duration(hours: 21)),
        subject: 'আন্তর্জাতিক বিষয়াবলি',
        topics: 'জাতিসংঘ, আঞ্চলিক জোট, সমসাময়িক ঘটনা',
        questions: 25,
        minutes: 15,
        materials: 2,
        state: SlotState.today,
      ),
      LiveSlot(
        date: day(3),
        subject: 'কম্পিউটার ও তথ্যপ্রযুক্তি',
        questions: 15,
        minutes: 10,
        materials: 13,
        state: SlotState.upcoming,
      ),
      LiveSlot(
        date: day(5),
        subject: 'গাণিতিক যুক্তি',
        questions: 15,
        minutes: 15,
        state: SlotState.upcoming,
      ),
      LiveSlot(
        date: day(8),
        subject: 'মানসিক দক্ষতা',
        questions: 15,
        minutes: 10,
        state: SlotState.upcoming,
      ),
    ];
  }

  LiveSlot todaySlot() =>
      schedule().firstWhere((s) => s.state == SlotState.today);

  LiveSlot? nextSlot() {
    for (final slot in schedule()) {
      if (slot.state == SlotState.upcoming) return slot;
    }
    return null;
  }

  MeritBoard meritBoard({required bool overall, String? label}) {
    const top = [
      MeritEntry(rank: 1, name: 'নাফিস রহমান', score: 34.5, time: '8:12'),
      MeritEntry(rank: 2, name: 'তানজিলা আক্তার', score: 34.5, time: '9:05'),
      MeritEntry(rank: 3, name: 'আরিফ হোসেন', score: 34, time: '7:58'),
      MeritEntry(rank: 4, name: 'সাদিয়া ইসলাম', score: 33.5, time: '10:20'),
      MeritEntry(rank: 5, name: 'মেহেদী হাসান', score: 33, time: '8:44'),
      MeritEntry(rank: 6, name: 'রুমানা পারভীন', score: 33, time: '9:51'),
      MeritEntry(rank: 7, name: 'ফাহিম আহমেদ', score: 32.5, time: '11:02'),
      MeritEntry(rank: 8, name: 'ইশরাত জাহান', score: 32, time: '9:15'),
    ];
    if (overall) {
      return MeritBoard(
        label: 'সামগ্রিক',
        fullMarks: 105,
        participants: 5230,
        me: const MeritEntry(
          rank: 188,
          name: 'তুমি',
          score: 88.5,
          time: '42:10',
          isMe: true,
        ),
        top: [
          for (final e in top)
            MeritEntry(
              rank: e.rank,
              name: e.name,
              score: e.score * 3,
              time: e.time,
            ),
        ],
      );
    }
    return MeritBoard(
      label: label ?? 'English',
      fullMarks: 35,
      participants: 4810,
      me: const MeritEntry(
        rank: 212,
        name: 'তুমি',
        score: 28.5,
        time: '11:40',
        isMe: true,
      ),
      top: top,
    );
  }

  List<SyllabusSubject> syllabus() => const [
    SyllabusSubject(
      id: 'bn',
      name: 'বাংলা ভাষা ও সাহিত্য',
      oldMarks: 35,
      newMarks: 30,
    ),
    SyllabusSubject(
      id: 'en',
      name: 'English Language & Literature',
      oldMarks: 35,
      newMarks: 30,
    ),
    SyllabusSubject(
      id: 'bd',
      name: 'বাংলাদেশ বিষয়াবলি',
      oldMarks: 30,
      newMarks: 25,
    ),
    SyllabusSubject(
      id: 'intl',
      name: 'আন্তর্জাতিক বিষয়াবলি',
      oldMarks: 20,
      newMarks: 25,
    ),
    SyllabusSubject(
      id: 'geo',
      name: 'ভূগোল, পরিবেশ ও দুর্যোগ',
      oldMarks: 10,
      newMarks: 10,
    ),
    SyllabusSubject(
      id: 'sci',
      name: 'সাধারণ বিজ্ঞান',
      oldMarks: 15,
      newMarks: 15,
    ),
    SyllabusSubject(
      id: 'ict',
      name: 'কম্পিউটার ও তথ্যপ্রযুক্তি',
      oldMarks: 15,
      newMarks: 15,
    ),
    SyllabusSubject(
      id: 'math',
      name: 'গাণিতিক যুক্তি',
      oldMarks: 15,
      newMarks: 20,
    ),
    SyllabusSubject(
      id: 'mental',
      name: 'মানসিক দক্ষতা',
      oldMarks: 15,
      newMarks: 15,
    ),
    SyllabusSubject(
      id: 'ethics',
      name: 'নৈতিকতা, মূল্যবোধ ও সুশাসন',
      oldMarks: 10,
      newMarks: 15,
    ),
  ];

  List<PaperSubject> paperSubjects() => const [
    PaperSubject(id: 'all', label: 'সব', count: 200),
    PaperSubject(
      id: 'bn',
      label: 'বাংলা',
      count: 35,
      topics: [('gram', 'ব্যাকরণ', 20), ('lit', 'সাহিত্য', 15)],
    ),
    PaperSubject(
      id: 'en',
      label: 'English',
      count: 35,
      topics: [('gram', 'Grammar', 20), ('lit', 'Literature', 15)],
    ),
    PaperSubject(id: 'bd', label: 'বাংলাদেশ', count: 30),
    PaperSubject(
      id: 'intl',
      label: 'আন্তর্জাতিক',
      count: 20,
      topics: [
        ('un', 'জাতিসংঘ', 5),
        ('bloc', 'আঞ্চলিক জোট', 4),
        ('treaty', 'চুক্তি ও সম্মেলন', 4),
        ('cur', 'সমসাময়িক', 7),
      ],
    ),
    PaperSubject(id: 'geo', label: 'ভূগোল', count: 10),
    PaperSubject(id: 'sci', label: 'বিজ্ঞান', count: 15),
    PaperSubject(id: 'ict', label: 'কম্পিউটার', count: 15),
    PaperSubject(id: 'math', label: 'গাণিতিক যুক্তি', count: 15),
    PaperSubject(id: 'mental', label: 'মানসিক দক্ষতা', count: 15),
    PaperSubject(id: 'ethics', label: 'নৈতিকতা', count: 10),
  ];
}

final bcsRepositoryProvider = Provider<BcsRepository>(
  (ref) => const BcsRepository(),
);
