import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/routine_controller.dart';
import '../data/models/routine_block_model.dart';
import '../widgets/subject_picker_dialog.dart';

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

/// Lets the user add, edit, reorder (by sort), and save their own routine
/// blocks. Opened either blank (custom routine) or pre-filled from a
/// template the user picked.
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
  late final TextEditingController _titleController;
  late List<RoutineBlockModel> _blocks;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _blocks = [...widget.initialBlocks];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addOrEditBlock({
    RoutineBlockModel? existing,
    int? index,
  }) async {
    final result = await showModalBottomSheet<RoutineBlockModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BlockEditorSheet(initial: existing),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _blocks[index] = result;
      } else {
        _blocks.add(result);
      }
    });
  }

  void _removeBlock(int index) {
    setState(() => _blocks.removeAt(index));
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
    final ordered = [
      for (var i = 0; i < sorted.length; i++) sorted[i].copyWith(sortOrder: i),
    ];
    try {
      await ref
          .read(routineControllerProvider.notifier)
          .saveRoutine(
            title: _titleController.text.trim().isEmpty
                ? 'My Routine'
                : _titleController.text.trim(),
            sourceTemplateId: widget.sourceTemplateId,
            blocks: ordered,
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
    final sorted = [..._blocks]
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('রুটিন তৈরি করো'),
        actions: [
          IconButton(
            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            onPressed: saving ? null : _save,
            tooltip: 'সেভ করো',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'রুটিনের নাম',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('এখনও কোনো ব্লক যুক্ত করা হয়নি।')),
            )
          else
            ...sorted.map((block) {
              final index = _blocks.indexOf(block);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      block.startTime.split(':').first,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  title: Text(block.title),
                  subtitle: Text(
                    '${block.startTime} - ${block.endTime} · ${block.category.label}'
                    '${block.subjectName == null ? '' : ' · ${block.subjectName}'}',
                  ),
                  onTap: () => _addOrEditBlock(existing: block, index: index),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeBlock(index),
                  ),
                ),
              );
            }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _addOrEditBlock(),
            icon: const Icon(Icons.add),
            label: const Text('নতুন ব্লক যুক্ত করো'),
          ),
        ],
      ),
    );
  }
}

class _BlockEditorSheet extends StatefulWidget {
  final RoutineBlockModel? initial;

  const _BlockEditorSheet({this.initial});

  @override
  State<_BlockEditorSheet> createState() => _BlockEditorSheetState();
}

class _BlockEditorSheetState extends State<_BlockEditorSheet> {
  late final TextEditingController _titleController;
  late RoutineBlockCategory _category;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late Set<int> _days;
  int? _subjectId;
  String? _subjectName;

  static const _dayLabels = [
    'সোম',
    'মঙ্গল',
    'বুধ',
    'বৃহ',
    'শুক্র',
    'শনি',
    'রবি',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _category = initial?.category ?? RoutineBlockCategory.study;
    _start = initial != null
        ? _parseTime(initial.startTime)
        : const TimeOfDay(hour: 6, minute: 0);
    _end = initial != null
        ? _parseTime(initial.endTime)
        : const TimeOfDay(hour: 7, minute: 0);
    _days = (initial?.daysOfWeek ?? const [1, 2, 3, 4, 5, 6, 7]).toSet();
    _subjectId = initial?.syllabusNodeId;
    _subjectName = initial?.subjectName;
  }

  Future<void> _pickSubject() async {
    final choice = await showDialog<SubjectChoice>(
      context: context,
      builder: (context) => SubjectPickerDialog(selectedNodeId: _subjectId),
    );
    if (choice == null) return;
    setState(() {
      _subjectId = choice.nodeId;
      _subjectName = choice.name;
    });
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _save() {
    if (_titleController.text.trim().isEmpty || _days.isEmpty) return;
    final isStudy = _category == RoutineBlockCategory.study;
    Navigator.of(context).pop(
      RoutineBlockModel(
        id: widget.initial?.id,
        title: _titleController.text.trim(),
        category: _category,
        startTime: _formatTime(_start),
        endTime: _formatTime(_end),
        daysOfWeek: _days.toList()..sort(),
        syllabusNodeId: isStudy ? _subjectId : null,
        subjectName: isStudy ? _subjectName : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.initial == null ? 'নতুন ব্লক' : 'ব্লক এডিট করো',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'ব্লকের নাম',
                hintText: 'যেমন: Math Practice',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RoutineBlockCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'ধরন',
                border: OutlineInputBorder(),
              ),
              items: RoutineBlockCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            if (_category == RoutineBlockCategory.study) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickSubject,
                icon: const Icon(Icons.link, size: 18),
                label: Text(
                  _subjectName == null
                      ? 'সিলেবাসের বিষয় যুক্ত করো (ঐচ্ছিক)'
                      : 'বিষয়: $_subjectName',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'যুক্ত করলে সাপ্তাহিক সামারিতে এই বিষয়ে পরীক্ষার ফলাফলও দেখাবে।',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(true),
                    child: Text('শুরু: ${_formatTime(_start)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickTime(false),
                    child: Text('শেষ: ${_formatTime(_end)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final day = i + 1;
                final selected = _days.contains(day);
                return FilterChip(
                  label: Text(_dayLabels[i]),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _days.add(day);
                      } else {
                        _days.remove(day);
                      }
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('যুক্ত করো'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
