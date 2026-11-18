import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/routine_controller.dart';
import '../data/models/routine_block_model.dart';
import '../data/models/routine_log_model.dart';

/// Bottom sheet check-in: mark today's blocks done/partial/missed. This is
/// the only place block status gets logged — deliberately not a per-block
/// popup, to avoid notification/alert fatigue.
class RoutineCheckInSheet extends ConsumerStatefulWidget {
  final List<RoutineBlockModel> blocks;
  final RoutineDailyLog? existingLog;

  const RoutineCheckInSheet({
    super.key,
    required this.blocks,
    this.existingLog,
  });

  @override
  ConsumerState<RoutineCheckInSheet> createState() =>
      _RoutineCheckInSheetState();
}

class _RoutineCheckInSheetState extends ConsumerState<RoutineCheckInSheet> {
  late Map<int, RoutineLogStatus> _statuses;

  @override
  void initState() {
    super.initState();
    _statuses = {
      for (final block in widget.blocks)
        if (block.id != null)
          block.id!:
              widget.existingLog?.statusFor(block.id!) ??
              RoutineLogStatus.missed,
    };
  }

  Future<void> _submit() async {
    final entries = _statuses.entries
        .map((e) => RoutineLogEntry(blockId: e.key, status: e.value))
        .toList();
    try {
      await ref
          .read(routineControllerProvider.notifier)
          .submitDailyLog(
            date: formatLogDate(DateTime.now()),
            entries: entries,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('লগ সেভ করা যায়নি: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(routineControllerProvider).isLoading;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('আজকের check-in', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('কোনটা করতে পারলে, কোনটা অর্ধেক, কোনটা miss হলো?'),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView(
              shrinkWrap: true,
              children: widget.blocks.where((b) => b.id != null).map((block) {
                final status = _statuses[block.id] ?? RoutineLogStatus.missed;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(block.title, overflow: TextOverflow.ellipsis),
                            Text(
                              '${block.startTime} - ${block.endTime}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      SegmentedButton<RoutineLogStatus>(
                        segments: const [
                          ButtonSegment(
                            value: RoutineLogStatus.done,
                            icon: Icon(Icons.check, size: 16),
                          ),
                          ButtonSegment(
                            value: RoutineLogStatus.partial,
                            icon: Icon(Icons.remove, size: 16),
                          ),
                          ButtonSegment(
                            value: RoutineLogStatus.missed,
                            icon: Icon(Icons.close, size: 16),
                          ),
                        ],
                        selected: {status},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setState(
                            () => _statuses[block.id!] = selection.first,
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : _submit,
              child: saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('সেভ করো'),
            ),
          ),
        ],
      ),
    );
  }
}
