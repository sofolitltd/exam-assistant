import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/routine_controller.dart';
import '../data/models/routine_block_model.dart';
import '../widgets/routine_ui.dart';
import '../widgets/subject_picker_dialog.dart';
import 'routine_setup_screen.dart';

/// Router entry point for editing the user's existing routine — loads the
/// current routine first, then hands it to [RoutineBuilderScreen].
class RoutineBuilderRoute extends ConsumerWidget {
  const RoutineBuilderRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineAsync = ref.watch(myRoutineProvider);
    return routineAsync.when(
      data: (routine) => RoutineBuilderScreen(
        title: routine?.title ?? 'My Routine',
        initialBlocks: routine?.blocks ?? const [],
        sourceTemplateId: routine?.sourceTemplateId,
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('রুটিন লোড করা যায়নি: $error'))),
    );
  }
}

/// রুটিন এডিট: pick a day, see and edit that day's blocks, add new ones in
/// a sheet. Opened blank, from a template, or with the current routine.
class RoutineBuilderScreen extends ConsumerStatefulWidget {
  final String title;
  final List<RoutineBlockModel> initialBlocks;
  final String? sourceTemplateId;

  const RoutineBuilderScreen({
    super.key,
    this.title = 'My Routine',
    this.initialBlocks = const [],
    this.sourceTemplateId,
  });

  @override
  ConsumerState<RoutineBuilderScreen> createState() =>
      _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends ConsumerState<RoutineBuilderScreen> {
  late List<RoutineBlockModel> _blocks = [...widget.initialBlocks];
  int _day = DateTime.now().weekday;

  Future<void> _edit({RoutineBlockModel? existing}) async {
    final result = await showBlockSheet(context, initial: existing);
    if (result == null) return;
    setState(() {
      final index = existing == null ? -1 : _blocks.indexOf(existing);
      if (result.delete) {
        if (index >= 0) _blocks.removeAt(index);
      } else if (index >= 0) {
        _blocks[index] = result.block!;
      } else {
        _blocks = [..._blocks, result.block!];
      }
    });
  }

  Future<void> _save() async {
    if (_blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কমপক্ষে একটি ব্লক যুক্ত করো।')),
      );
      return;
    }
    final sorted = [..._blocks]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    try {
      await ref
          .read(routineControllerProvider.notifier)
          .saveRoutine(
            title: widget.title,
            sourceTemplateId: widget.sourceTemplateId,
            blocks: [
              for (var i = 0; i < sorted.length; i++)
                sorted[i].copyWith(sortOrder: i),
            ],
          );
      if (!mounted) return;
      context.go('/routine');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('রুটিন সেভ করা যায়নি: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(routineControllerProvider).isLoading;
    final templates = ref.watch(routineTemplatesProvider).value ?? const [];
    final template = templates
        .where((t) => t.templateId == widget.sourceTemplateId)
        .firstOrNull;
    final dayBlocks = _blocks.where((b) => b.daysOfWeek.contains(_day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final studyMinutes = dayBlocks
        .where((b) => b.category == RoutineBlockCategory.study)
        .fold<int>(0, (sum, b) => sum + blockMinutes(b));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: 'রুটিন এডিট',
        bordered: false,
        trailing: DsButton(
          label: saving ? 'সেভ হচ্ছে…' : 'সেভ',
          height: 36,
          fontSize: 14,
          onPressed: saving ? null : _save,
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                for (final (i, d) in routineWeekOrder.indexed) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(child: _dayButton(d)),
                ],
              ],
            ),
          ),
          Expanded(
            child: DsPage(
              children: [
                DsCard(
                  color: AppColors.brandSoft,
                  borderWidth: 0,
                  radius: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RoutineSetupScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template == null
                                  ? 'নিজের বানানো রুটিন'
                                  : 'টেমপ্লেট থেকে শুরু করা',
                              style: dsText(12, color: AppColors.brandInk2),
                            ),
                            Text(
                              template?.title ?? widget.title,
                              style: dsText(
                                14,
                                weight: FontWeight.w600,
                                color: AppColors.brandStrong,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        template == null ? 'টেমপ্লেট দেখো' : 'বদলাও',
                        style: dsText(
                          13,
                          weight: FontWeight.w600,
                          color: AppColors.brandStrong,
                        ),
                      ),
                    ],
                  ),
                ),
                SectionLabel(
                  '${weekdayFull(_day)}-এর ব্লক',
                  trailing: 'মোট পড়া ${bnMinutes(studyMinutes)}',
                ),
                if (dayBlocks.isEmpty)
                  DsCard(
                    child: Text(
                      'এই দিনে কোনো ব্লক নেই।',
                      style: dsText(14, color: AppColors.muted),
                    ),
                  )
                else
                  DsListCard(
                    radius: 16,
                    children: [for (final b in dayBlocks) _blockRow(b)],
                  ),
                Text(
                  'যে ব্লক কয়েক দিনে আছে, সেটা এডিট করলে সব দিনেই বদলাবে',
                  textAlign: TextAlign.center,
                  style: dsText(12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: SafeArea(
              top: false,
              child: Material(
                color: AppColors.paper,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.brand, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _edit(),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.plus,
                          size: 18,
                          color: AppColors.brand,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'নতুন ব্লক',
                          style: dsText(
                            15,
                            weight: FontWeight.w600,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayButton(int d) {
    final on = d == _day;
    final count = _blocks.where((b) => b.daysOfWeek.contains(d)).length;
    return Material(
      color: on ? AppColors.ink : AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: on ? BorderSide.none : const BorderSide(color: Color(0xFFDADDE1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _day = d),
        child: SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekdayShort(d),
                style: dsText(
                  12,
                  weight: on ? FontWeight.w600 : FontWeight.w400,
                  color: on ? Colors.white : AppColors.ink,
                ),
              ),
              Text(
                '${bn(count)}টি',
                style: dsText(11, color: on ? Colors.white70 : AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blockRow(RoutineBlockModel b) {
    final meta = [
      b.category.label,
      ?b.subjectName,
      daysLabel(b.daysOfWeek),
    ].join(' · ');
    return InkWell(
      onTap: () => _edit(existing: b),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: categoryTint(b.category),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 76,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bnClock12(b.startTime),
                    style: dsText(13, weight: FontWeight.w600),
                  ),
                  Text(
                    bnClockParts(b.endTime).$1,
                    style: dsText(12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.title,
                    style: dsText(15, weight: FontWeight.w600, height: 1.3),
                  ),
                  const SizedBox(height: 3),
                  Text(meta, style: dsText(12, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF8A919C),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the block sheet returns: a new/edited block, or a delete.
class BlockSheetResult {
  final RoutineBlockModel? block;
  final bool delete;

  const BlockSheetResult.save(RoutineBlockModel this.block) : delete = false;
  const BlockSheetResult.delete() : block = null, delete = true;
}

Future<BlockSheetResult?> showBlockSheet(
  BuildContext context, {
  RoutineBlockModel? initial,
}) {
  return showModalBottomSheet<BlockSheetResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: AppColors.paper,
    barrierColor: const Color(0x73101216),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _BlockSheet(initial: initial),
  );
}

class _BlockSheet extends StatefulWidget {
  final RoutineBlockModel? initial;

  const _BlockSheet({this.initial});

  @override
  State<_BlockSheet> createState() => _BlockSheetState();
}

class _BlockSheetState extends State<_BlockSheet> {
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late RoutineBlockCategory _cat =
      widget.initial?.category ?? RoutineBlockCategory.study;
  late String _start = widget.initial?.startTime ?? '16:00';
  late String _end = widget.initial?.endTime ?? '18:00';
  late Set<int> _days = (widget.initial?.daysOfWeek ?? routineWeekOrder)
      .toSet();
  late int? _subjectId = widget.initial?.syllabusNodeId;
  late String? _subjectName = widget.initial?.subjectName;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _start : _end;
    final m = minutesOf(current);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
    setState(() => start ? _start = value : _end = value);
  }

  Future<void> _pickSubject() async {
    final choice = await showDialog<SubjectChoice>(
      context: context,
      builder: (_) => SubjectPickerDialog(selectedNodeId: _subjectId),
    );
    if (choice == null) return;
    setState(() {
      _subjectId = choice.nodeId;
      _subjectName = choice.name;
    });
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty || _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            title.isEmpty ? 'ব্লকের নাম দাও' : 'অন্তত একটা দিন বেছে নাও',
          ),
        ),
      );
      return;
    }
    final study = _cat == RoutineBlockCategory.study;
    Navigator.of(context).pop(
      BlockSheetResult.save(
        RoutineBlockModel(
          id: widget.initial?.id,
          title: title,
          category: _cat,
          startTime: _start,
          endTime: _end,
          daysOfWeek: _days.toList()..sort(),
          sortOrder: widget.initial?.sortOrder ?? 0,
          syllabusNodeId: study ? _subjectId : null,
          subjectName: study ? _subjectName : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = dsText(13, weight: FontWeight.w600, color: AppColors.ink2);
    final editing = widget.initial != null;
    final field = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.lineStrong, width: 1.5),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6D8DC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                editing ? 'ব্লক এডিট' : 'নতুন ব্লক',
                style: dsText(18, weight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text('নাম', style: label),
              const SizedBox(height: 6),
              TextField(
                controller: _title,
                style: dsText(15),
                decoration: InputDecoration(
                  hintText: 'যেমন: আন্তর্জাতিক বিষয়াবলি',
                  filled: true,
                  fillColor: AppColors.paper,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: field,
                  enabledBorder: field,
                  focusedBorder: field.copyWith(
                    borderSide: const BorderSide(
                      color: AppColors.brand,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('ধরন', style: label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in RoutineBlockCategory.values)
                    DsChip(
                      label: c.label,
                      selected: c == _cat,
                      onTap: () => setState(() => _cat = c),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              DsGrid(
                children: [
                  _timeBox('শুরু', _start, () => _pickTime(true)),
                  _timeBox('শেষ', _end, () => _pickTime(false)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text('কোন দিন', style: label)),
                  _link(
                    'প্রতিদিন',
                    () => setState(() => _days = routineWeekOrder.toSet()),
                  ),
                  const SizedBox(width: 12),
                  _link(
                    'শনি–বৃহঃ',
                    () => setState(() => _days = routineWorkWeek.toSet()),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final (i, d) in routineWeekOrder.indexed) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(child: _dayToggle(d)),
                  ],
                ],
              ),
              if (_cat == RoutineBlockCategory.study) ...[
                const SizedBox(height: 16),
                Material(
                  color: AppColors.paper,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: AppColors.lineStrong,
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _pickSubject,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'সিলেবাসের বিষয় (ঐচ্ছিক)',
                                  style: dsText(12, color: AppColors.muted),
                                ),
                                Text(
                                  _subjectName ?? 'কোনো বিষয় বাছাই করা হয়নি',
                                  style: dsText(15, weight: FontWeight.w600),
                                ),
                                Text(
                                  'সাপ্তাহিক সামারিতে এই বিষয়ের পরীক্ষার ফলও দেখাবে',
                                  style: dsText(12, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronDown, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DsButton(
                label: editing ? 'সেভ করো' : 'যুক্ত করো',
                height: 50,
                fontSize: 16,
                onPressed: _submit,
              ),
              if (editing) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(const BlockSheetResult.delete()),
                  child: Text(
                    'ব্লকটা মুছে দাও',
                    style: dsText(
                      14,
                      weight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeBox(String label, String value, VoidCallback onTap) {
    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lineStrong, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: dsText(12, color: AppColors.muted)),
              Text(
                bnClock12(value),
                style: dsText(16, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _link(String text, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Text(
      text,
      style: dsText(13, weight: FontWeight.w600, color: AppColors.brand),
    ),
  );

  Widget _dayToggle(int d) {
    final on = _days.contains(d);
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? AppColors.brand : AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: on
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFDADDE1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => on ? _days.remove(d) : _days.add(d)),
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                weekdayShort(d),
                style: dsText(
                  12,
                  weight: on ? FontWeight.w600 : FontWeight.w400,
                  color: on ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
