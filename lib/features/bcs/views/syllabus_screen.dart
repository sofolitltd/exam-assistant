import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../data/bcs_models.dart';
import '../data/bcs_sample_data.dart';
import '../data/bcs_api.dart';
import 'bcs_format.dart';

enum _View { old, current, compare }

/// The old syllabus (the one this paper was set on), the new one, and what
/// changed between them.
class SyllabusScreen extends ConsumerStatefulWidget {
  final int number;

  const SyllabusScreen({required this.number, super.key});

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> {
  _View _view = _View.compare;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(bcsRepositoryProvider);
    final running = ref.watch(bcsRunningNumberProvider);
    final edition = repo.edition(widget.number);
    final oldRef = edition.status == EditionStatus.running ? 44 : widget.number;
    final rows = repo.syllabus();
    final oldTotal = rows.fold<int>(0, (s, r) => s + r.oldMarks);
    final newTotal = rows.fold<int>(0, (s, r) => s + r.newMarks);
    final cmp = _view == _View.compare;

    final (title, text, bg, ink) = switch (_view) {
      _View.old => (
        'এই সিলেবাসে ${bnOrdinal(oldRef)} প্রিলি হয়েছিল',
        '৩৫তম বিসিএস থেকে যে ২০০ নম্বরের সিলেবাস চলছিল। এই প্রশ্নপত্র '
            'practice করার সময় এটাই মাথায় রাখো।',
        AppColors.sunken,
        AppColors.heroSoft,
      ),
      _View.current => (
        '${bnOrdinal(running)}-র প্রস্তুতি এই সিলেবাসে',
        'BPSC-র সর্বশেষ প্রকাশিত সিলেবাস। চলমান প্রস্তুতির সূচি এটা ধরেই বানানো।',
        AppColors.brandSoft,
        AppColors.brandStrong,
      ),
      _View.compare => (
        'কোথায় নম্বর বদলেছে',
        'সবুজ = নতুন সিলেবাসে নম্বর বেড়েছে, লাল = কমেছে। পুরনো প্রশ্নপত্র '
            'পড়ার সময় কোন বিষয়ে বেশি জোর দেবে তা বুঝতে কাজে লাগবে।',
        AppColors.warmSoft,
        AppColors.warmInk,
      ),
    };

    Widget row(List<Widget> cells, {Color? color, VoidCallback? onTap}) {
      return Material(
        color: color ?? Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.lineSoft)),
            ),
            child: Row(
              children: [
                Expanded(child: cells[0]),
                const SizedBox(width: 8),
                SizedBox(width: 56, child: cells[1]),
                const SizedBox(width: 8),
                SizedBox(width: 56, child: cells[2]),
              ],
            ),
          ),
        ),
      );
    }

    Text right(String s, TextStyle style) =>
        Text(s, textAlign: TextAlign.right, style: style);

    final head = dsText(12, weight: FontWeight.w600, color: AppColors.muted);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(title: 'সিলেবাস', subtitle: editionName(widget.number)),
      body: DsPage(
        children: [
          DsSegmented<_View>(
            height: 38,
            value: _view,
            onChanged: (v) => setState(() => _view = v),
            items: [
              (_View.old, 'পুরনো (${bnOrdinal(oldRef)})', null),
              (_View.current, 'নতুন (${bnOrdinal(running)})', null),
              (_View.compare, 'তুলনা', null),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: dsText(14, weight: FontWeight.w600, color: ink),
                ),
                const SizedBox(height: 2),
                Text(text, style: dsText(12, height: 1.5, color: ink)),
              ],
            ),
          ),
          DsCard(
            padding: EdgeInsets.zero,
            radius: 14,
            child: Column(
              children: [
                row([
                  Text('বিষয়', style: head),
                  right(cmp ? bnOrdinal(oldRef) : '', head),
                  right(cmp ? bnOrdinal(running) : 'নম্বর', head),
                ]),
                for (final r in rows) _subjectRow(r, cmp, row, right),
                row([
                  Text('মোট', style: dsText(14, weight: FontWeight.w700)),
                  right(
                    cmp ? bn(oldTotal) : '',
                    dsText(14, weight: FontWeight.w700),
                  ),
                  right(
                    bn(_view == _View.old ? oldTotal : newTotal),
                    dsText(14, weight: FontWeight.w700),
                  ),
                ], color: AppColors.canvas),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              text:
                  'কোনো বিষয়ে চাপলে সেই বিষয়ের topic আর বিগত প্রশ্ন খুলবে। '
                  'সিলেবাসের মূল PDF: ',
              children: [
                TextSpan(
                  text: 'BPSC-র প্রকাশিত কপি',
                  style: dsText(
                    12,
                    weight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
            style: dsText(12, color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _subjectRow(
    SyllabusSubject r,
    bool cmp,
    Widget Function(List<Widget>, {Color? color, VoidCallback? onTap}) row,
    Text Function(String, TextStyle) right,
  ) {
    final diff = r.newMarks - r.oldMarks;
    final String b;
    final TextStyle bStyle;
    if (cmp) {
      b =
          '${bn(r.newMarks)}${diff > 0
              ? ' ↑'
              : diff < 0
              ? ' ↓'
              : ''}';
      bStyle = dsText(
        14,
        weight: diff == 0 ? FontWeight.w600 : FontWeight.w700,
        color: diff > 0
            ? AppColors.success
            : diff < 0
            ? AppColors.danger
            : AppColors.ink,
      );
    } else {
      b = bn(_view == _View.old ? r.oldMarks : r.newMarks);
      bStyle = dsText(14, weight: FontWeight.w600);
    }
    return row(
      [
        Text(r.name, style: dsText(14)),
        right(cmp ? bn(r.oldMarks) : '', dsText(14, color: AppColors.muted)),
        right(b, bStyle),
      ],
      onTap: () =>
          context.push('/bcs/pyq/subject?name=${Uri.encodeComponent(r.name)}'),
    );
  }
}
