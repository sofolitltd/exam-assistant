import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/bangla_digits.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../controllers/routine_controller.dart';
import '../data/models/streak_models.dart';

/// Small accountability groups: friends join with a 6-character code and
/// see each other's routine streak and weekly adherence (never their
/// routine details or exam scores).
class StudyGroupsScreen extends ConsumerWidget {
  const StudyGroupsScreen({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await _askText(
      context,
      title: 'নতুন গ্রুপ',
      hint: 'যেমন: BCS 47 পড়ার সাথী',
      action: 'তৈরি করো',
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      final group = await ref
          .read(routineApiServiceProvider)
          .createStudyGroup(name.trim());
      ref.invalidate(studyGroupsProvider);
      if (context.mounted) await _showInviteCode(context, group);
    } catch (error) {
      if (context.mounted) _snack(context, 'গ্রুপ তৈরি করা যায়নি: $error');
    }
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    final code = await _askText(
      context,
      title: 'গ্রুপে যোগ দাও',
      hint: '৬ অক্ষরের invite code',
      action: 'যোগ দাও',
      maxLength: 6,
    );
    if (code == null || code.trim().isEmpty) return;
    try {
      await ref.read(routineApiServiceProvider).joinStudyGroup(code.trim());
      ref.invalidate(studyGroupsProvider);
      if (context.mounted) _snack(context, 'গ্রুপে যোগ দেওয়া হয়েছে।');
    } catch (error) {
      if (context.mounted) _snack(context, '$error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(studyGroupsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('স্টাডি গ্রুপ')),
      body: ResponsiveWrapper(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'বন্ধুদের সাথে গ্রুপ বানাও — একে অপরের routine streak দেখে '
              'নিয়মিত থাকা সহজ হয়। গ্রুপে শুধু streak আর সাপ্তাহিক % দেখা যায়।',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _create(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('গ্রুপ বানাও'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _join(context, ref),
                    icon: const Icon(Icons.login),
                    label: const Text('যোগ দাও'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('গ্রুপ লোড করা যায়নি: $error'),
              data: (groups) {
                if (groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('তুমি এখনো কোনো গ্রুপে নেই।')),
                  );
                }
                return Column(
                  children: [
                    for (final group in groups)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppColors.brandSoft,
                            child: Icon(
                              Icons.groups,
                              color: AppColors.brandStrong,
                            ),
                          ),
                          title: Text(group.name),
                          subtitle: Text(
                            '${toBanglaNumber(group.memberCount)} জন সদস্য · কোড ${group.inviteCode}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push('/routine/groups/${group.groupId}'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class StudyGroupDetailScreen extends ConsumerWidget {
  final int groupId;

  const StudyGroupDetailScreen({super.key, required this.groupId});

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('গ্রুপ ছেড়ে যাবে?'),
        content: const Text('আবার যোগ দিতে invite code লাগবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ছেড়ে যাও'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(routineApiServiceProvider).leaveStudyGroup(groupId);
      ref.invalidate(studyGroupsProvider);
      if (context.mounted) context.pop();
    } catch (error) {
      if (context.mounted) _snack(context, 'গ্রুপ ছাড়া যায়নি: $error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(studyGroupDetailProvider(groupId));
    return Scaffold(
      appBar: AppBar(
        title: Text(detailAsync.value?.group.name ?? 'গ্রুপ'),
        actions: [
          if (detailAsync.value != null)
            IconButton(
              tooltip: 'Invite code শেয়ার',
              icon: const Icon(Icons.person_add_alt),
              onPressed: () =>
                  _showInviteCode(context, detailAsync.value!.group),
            ),
          PopupMenuButton<String>(
            onSelected: (_) => _leave(context, ref),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'leave', child: Text('গ্রুপ ছেড়ে যাও')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studyGroupDetailProvider(groupId).future),
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('গ্রুপ লোড করা যায়নি: $error'),
              ),
            ],
          ),
          data: (detail) => ResponsiveWrapper(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Streak অনুযায়ী সাজানো। ✓ মানে আজ check-in করেছে।',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < detail.members.length; i++)
                  _MemberRow(position: i + 1, member: detail.members[i]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final int position;
  final StudyGroupMember member;

  const _MemberRow({required this.position, required this.member});

  @override
  Widget build(BuildContext context) {
    final percent = (member.weekAdherence * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: member.isYou ? AppColors.brandSoft : AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: member.isYou ? AppColors.brand : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              toBanglaNumber(position),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.isYou ? '${member.name} (তুমি)' : member.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'এই সপ্তাহে ${toBanglaNumber(percent)}% routine',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (member.checkedInToday)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 20,
              ),
            ),
          const Icon(
            Icons.local_fire_department,
            color: Color(0xFFE07B12),
            size: 20,
          ),
          Text(
            toBanglaNumber(member.currentStreak),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

Future<void> _showInviteCode(BuildContext context, StudyGroup group) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(group.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('বন্ধুদের এই কোড দাও — তারা "যোগ দাও" থেকে ঢুকতে পারবে।'),
          const SizedBox(height: 16),
          SelectableText(
            group.inviteCode,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
              color: AppColors.brandStrong,
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            final messenger = ScaffoldMessenger.of(context);
            Clipboard.setData(ClipboardData(text: group.inviteCode));
            Navigator.pop(context);
            messenger.showSnackBar(
              const SnackBar(content: Text('কোড কপি হয়েছে।')),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('কপি করো'),
        ),
      ],
    ),
  );
}

Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String hint,
  required String action,
  int? maxLength,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _TextPromptDialog(
      title: title,
      hint: hint,
      action: action,
      maxLength: maxLength,
    ),
  );
}

/// Owns its controller so it's disposed only after the dialog's exit
/// animation, not while the field is still on screen.
class _TextPromptDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String action;
  final int? maxLength;

  const _TextPromptDialog({
    required this.title,
    required this.hint,
    required this.action,
    this.maxLength,
  });

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        textCapitalization: widget.maxLength != null
            ? TextCapitalization.characters
            : TextCapitalization.sentences,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('বাতিল'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.action),
        ),
      ],
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
