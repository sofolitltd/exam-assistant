import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/ds.dart';
import '../controllers/routine_controller.dart';
import '../data/models/streak_models.dart';

/// স্টাডি গ্রুপ: the user's groups as chips, the selected group's invite
/// code and members ranked by streak.
class StudyGroupsScreen extends ConsumerStatefulWidget {
  final int? initialGroupId;

  const StudyGroupsScreen({this.initialGroupId, super.key});

  @override
  ConsumerState<StudyGroupsScreen> createState() => _StudyGroupsScreenState();
}

/// Kept for the `/routine/groups/:groupId` route.
class StudyGroupDetailScreen extends StatelessWidget {
  final int groupId;

  const StudyGroupDetailScreen({required this.groupId, super.key});

  @override
  Widget build(BuildContext context) =>
      StudyGroupsScreen(initialGroupId: groupId);
}

class _StudyGroupsScreenState extends ConsumerState<StudyGroupsScreen> {
  late int? _selected = widget.initialGroupId;
  bool _copied = false;

  Future<void> _joinOrCreate() async {
    final result = await showModalBottomSheet<(bool, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _JoinCreateSheet(),
    );
    if (result == null) return;
    final (join, value) = result;
    final api = ref.read(routineApiServiceProvider);
    try {
      if (join) {
        final groups = await api.joinStudyGroup(value);
        ref.invalidate(studyGroupsProvider);
        final joined = groups
            .where((g) => g.inviteCode.toUpperCase() == value.toUpperCase())
            .firstOrNull;
        if (joined != null) setState(() => _selected = joined.groupId);
      } else {
        final group = await api.createStudyGroup(value);
        ref.invalidate(studyGroupsProvider);
        setState(() => _selected = group.groupId);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            join ? 'যোগ দেওয়া যায়নি: $error' : 'গ্রুপ বানানো যায়নি: $error',
          ),
        ),
      );
    }
  }

  Future<void> _leave(StudyGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'গ্রুপ ছেড়ে যাবে?',
          style: dsText(18, weight: FontWeight.w700),
        ),
        content: Text(
          '"${group.name}" থেকে বের হলে আবার invite code লাগবে।',
          style: dsText(14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ছেড়ে যাও'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(routineApiServiceProvider).leaveStudyGroup(group.groupId);
      ref.invalidate(studyGroupsProvider);
      setState(() => _selected = null);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('বের হওয়া যায়নি: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(studyGroupsProvider);
    final groups = groupsAsync.value ?? const <StudyGroup>[];
    final current =
        groups.where((g) => g.groupId == _selected).firstOrNull ??
        groups.firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const DsHeader(title: 'স্টাডি গ্রুপ', bordered: false),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.paper,
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final g in groups) ...[
                    DsChip(
                      label: g.name,
                      selected: g.groupId == current?.groupId,
                      onTap: () => setState(() {
                        _selected = g.groupId;
                        _copied = false;
                      }),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Material(
                    color: AppColors.paper,
                    shape: const StadiumBorder(
                      side: BorderSide(color: AppColors.brand, width: 1.5),
                    ),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _joinOrCreate,
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        child: Text(
                          '+ যোগ দাও / বানাও',
                          style: dsText(
                            13,
                            weight: FontWeight.w600,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: groupsAsync.isLoading && groups.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : current == null
                ? _empty()
                : _GroupBody(
                    group: current,
                    copied: _copied,
                    onCopy: () async {
                      await Clipboard.setData(
                        ClipboardData(text: current.inviteCode),
                      );
                      setState(() => _copied = true);
                    },
                    onLeave: () => _leave(current),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => DsPage(
    children: [
      DsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'এখনো কোনো গ্রুপে নেই',
              style: dsText(17, weight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'বন্ধুদের সাথে গ্রুপ বানাও বা invite code দিয়ে যোগ দাও। '
              'সবার streak আর check-in একসাথে দেখবে।',
              style: dsText(13, color: AppColors.ink2, height: 1.5),
            ),
            const SizedBox(height: 14),
            DsButton(label: 'যোগ দাও / বানাও', onPressed: _joinOrCreate),
          ],
        ),
      ),
    ],
  );
}

class _GroupBody extends ConsumerWidget {
  final StudyGroup group;
  final bool copied;
  final VoidCallback onCopy;
  final VoidCallback onLeave;

  const _GroupBody({
    required this.group,
    required this.copied,
    required this.onCopy,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(studyGroupDetailProvider(group.groupId));
    final members = [...?detailAsync.value?.members]
      ..sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
    final checkedIn = members.where((m) => m.checkedInToday).length;

    return RefreshIndicator(
      onRefresh: () =>
          ref.refresh(studyGroupDetailProvider(group.groupId).future),
      child: DsPage(
        children: [
          DsCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(group.name, style: dsText(17, weight: FontWeight.w700)),
                Text(
                  '${bn(group.memberCount)} জন সদস্য',
                  style: dsText(12, color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.sunken,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'invite code',
                                style: dsText(12, color: AppColors.muted),
                              ),
                            ),
                            SelectableText(
                              group.inviteCode,
                              style: dsText(
                                17,
                                weight: FontWeight.w700,
                              ).copyWith(letterSpacing: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 96,
                      child: DsButton.secondary(
                        label: copied ? 'কপি হয়েছে' : 'কপি',
                        height: 44,
                        fontSize: 13,
                        onPressed: onCopy,
                      ),
                    ),
                  ],
                ),
                if (members.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'আজ ${bn(members.length)} জনের ${bn(checkedIn)} জন check-in করেছে',
                    style: dsText(13, color: AppColors.ink2),
                  ),
                ],
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: SectionLabel(
              'সদস্য · streak অনুযায়ী',
              trailing: 'এই সপ্তাহ %',
            ),
          ),
          if (detailAsync.isLoading && members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (detailAsync.hasError)
            Text(
              'সদস্যদের লোড করা যায়নি: ${detailAsync.error}',
              style: dsText(13, color: AppColors.danger),
            )
          else
            DsListCard(
              radius: 16,
              children: [for (final m in members) _MemberRow(member: m)],
            ),
          Center(
            child: TextButton(
              onPressed: onLeave,
              child: Text(
                'গ্রুপ ছেড়ে যাও',
                style: dsText(
                  13,
                  weight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final StudyGroupMember member;

  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final m = member;
    final name = m.isYou ? 'তুমি' : m.name;
    final initial = m.name.isEmpty ? '?' : m.name.characters.first;
    return Container(
      color: m.isYou ? const Color(0xFFF3F6FE) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: dsText(
                15,
                weight: FontWeight.w700,
                color: AppColors.brandStrong,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: dsText(15, weight: FontWeight.w600)),
                Text(
                  m.checkedInToday ? 'আজ check-in করেছে' : 'আজ এখনো করেনি',
                  style: dsText(
                    12,
                    color: m.checkedInToday
                        ? AppColors.successInk
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${bn(m.currentStreak)} দিন',
                style: dsText(14, weight: FontWeight.w700),
              ),
              Text(
                'সপ্তাহ ${bn((m.weekAdherence * 100).round())}%',
                style: dsText(12, color: AppColors.muted),
              ),
            ],
          ),
          if (!m.checkedInToday && !m.isYou) ...[
            const SizedBox(width: 10),
            Material(
              color: AppColors.paper,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.brand),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => showComingSoon(context, 'বন্ধুকে মনে করানো'),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  child: Text(
                    'মনে করাও',
                    style: dsText(
                      12,
                      weight: FontWeight.w600,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JoinCreateSheet extends StatefulWidget {
  const _JoinCreateSheet();

  @override
  State<_JoinCreateSheet> createState() => _JoinCreateSheetState();
}

class _JoinCreateSheetState extends State<_JoinCreateSheet> {
  bool _join = true;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        18 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DsSegmented<bool>(
            height: 40,
            fontSize: 14,
            value: _join,
            onChanged: (v) => setState(() => _join = v),
            items: const [
              (true, 'code দিয়ে যোগ দাও', null),
              (false, 'নতুন বানাও', null),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            autofocus: true,
            textCapitalization: _join
                ? TextCapitalization.characters
                : TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _join ? 'invite code, যেমন K7Q-29M' : 'গ্রুপের নাম',
            ),
          ),
          const SizedBox(height: 16),
          DsButton(
            label: _join ? 'যোগ দাও' : 'গ্রুপ বানাও',
            onPressed: () {
              final v = _text.text.trim();
              if (v.isEmpty) return;
              Navigator.of(context).pop((_join, v));
            },
          ),
        ],
      ),
    );
  }
}
