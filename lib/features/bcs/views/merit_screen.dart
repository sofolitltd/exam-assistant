import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../data/bcs_models.dart';
import '../data/bcs_sample_data.dart';
import 'bcs_format.dart';

class MeritScreen extends ConsumerStatefulWidget {
  final int number;

  const MeritScreen({required this.number, super.key});

  @override
  ConsumerState<MeritScreen> createState() => _MeritScreenState();
}

class _MeritScreenState extends ConsumerState<MeritScreen> {
  bool _overall = false;
  LiveSlot? _slot;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(bcsRepositoryProvider);
    final edition = repo.edition(widget.number);
    final running = edition.status == EditionStatus.running;
    final taken = repo
        .schedule()
        .where((s) => s.state == SlotState.done)
        .toList();
    final slot = _slot ?? (taken.isEmpty ? null : taken.last);
    final board = repo.meritBoard(
      overall: _overall || !running,
      label: slot?.subject,
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: DsHeader(
        title: 'মেধাতালিকা',
        subtitle: editionName(widget.number),
        trailing: running ? const LivePill('চলছে') : const NeutralPill('শেষ'),
      ),
      body: DsPage(
        children: [
          if (running)
            Row(
              children: [
                Expanded(
                  child: _SlotPicker(
                    enabled: !_overall,
                    slots: taken,
                    current: slot,
                    onPick: (s) => setState(() => _slot = s),
                  ),
                ),
                const SizedBox(width: 8),
                DsSegmented<bool>(
                  expand: false,
                  value: _overall,
                  onChanged: (v) => setState(() => _overall = v),
                  items: const [
                    (false, 'এই পরীক্ষা', null),
                    (true, 'সামগ্রিক', null),
                  ],
                ),
              ],
            ),
          _MyPosition(board: board, number: widget.number),
          DsCard(
            padding: EdgeInsets.zero,
            radius: 14,
            child: Column(
              children: [
                _row(const ['ক্রম', 'নাম', 'নম্বর', 'সময়'], header: true),
                for (final e in board.top)
                  _row([
                    bn(e.rank),
                    e.name,
                    bnScore(e.score),
                    bn(e.time),
                  ], top3: e.rank <= 3),
              ],
            ),
          ),
          Text(
            running
                ? 'নম্বর সমান হলে যে কম সময়ে শেষ করেছে সে আগে থাকবে'
                : 'শুধু প্রথম চেষ্টা গোনা হয়। নম্বর সমান হলে কম সময় আগে।',
            textAlign: TextAlign.center,
            style: dsText(12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> cells, {bool header = false, bool top3 = false}) {
    final style = header
        ? dsText(12, weight: FontWeight.w600, color: AppColors.muted)
        : dsText(14, weight: top3 ? FontWeight.w600 : FontWeight.w400);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: header ? 10 : 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lineSoft)),
      ),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text(cells[0], style: style)),
          Expanded(
            child: Text(
              cells[1],
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 64,
            child: Text(cells[2], style: style, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: 56,
            child: Text(
              cells[3],
              textAlign: TextAlign.right,
              style: header ? style : dsText(14, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotPicker extends StatelessWidget {
  final bool enabled;
  final List<LiveSlot> slots;
  final LiveSlot? current;
  final ValueChanged<LiveSlot> onPick;

  const _SlotPicker({
    required this.enabled,
    required this.slots,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final label = !enabled
        ? 'সব পরীক্ষা মিলিয়ে'
        : current == null
        ? 'কোনো পরীক্ষা দাওনি'
        : '${bnDayMonth(current!.date)} · ${current!.subject.split(' ').first}';
    return Material(
      color: AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.lineStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled && slots.isNotEmpty
            ? () async {
                final picked = await showModalBottomSheet<LiveSlot>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final s in slots.reversed)
                          ListTile(
                            title: Text(s.subject),
                            subtitle: Text(bnDayMonth(s.date)),
                            trailing: Text(
                              '${bnScore(s.score ?? 0)}/${bnScore(s.fullMarks ?? 0)}',
                            ),
                            onTap: () => Navigator.pop(ctx, s),
                          ),
                      ],
                    ),
                  ),
                );
                if (picked != null) onPick(picked);
              }
            : null,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: dsText(
                    14,
                    weight: FontWeight.w600,
                    color: enabled ? AppColors.ink : AppColors.muted,
                  ),
                ),
              ),
              const Icon(LucideIcons.chevronDown, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyPosition extends StatelessWidget {
  final MeritBoard board;
  final int number;

  const _MyPosition({required this.board, required this.number});

  @override
  Widget build(BuildContext context) {
    final me = board.me;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 64),
            child: Column(
              children: [
                Text(
                  'মেধাক্রম',
                  style: dsText(
                    12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  bn(me.rank),
                  style: dsText(
                    26,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'তুমি · ${bnScore(me.score)} / ${bnScore(board.fullMarks)}',
                  style: dsText(
                    15,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${bnCount(board.participants)} জনের মধ্যে · শীর্ষ '
                  '${bn(board.topPercent)}% · সময় ${bn(me.time)}',
                  style: dsText(12, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.push('/bcs/$number/practice'),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: Text(
                  'উত্তর দেখো',
                  style: dsText(
                    13,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
