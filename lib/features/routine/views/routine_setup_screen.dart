import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../controllers/routine_controller.dart';
import 'routine_builder_screen.dart';

/// First-run screen for the routine feature: start from a published
/// template (clone + customize) or build a completely custom routine.
class RoutineSetupScreen extends ConsumerWidget {
  const RoutineSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(routineTemplatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('তোমার রুটিন শুরু করো')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'নিজের পড়াশোনা, নামাজ, খাবার, বিশ্রামের সময় একটা রুটিনে সাজাও — '
            'আমরা তোমাকে দিনে check-in করতে আর সাপ্তাহিক সামারি দেখতে সাহায্য করবো।',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Card(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            child: ListTile(
              leading: const Icon(
                Icons.edit_note,
                color: AppTheme.primaryColor,
              ),
              title: const Text('নিজের মতো রুটিন বানাও'),
              subtitle: const Text('শুরু থেকেই কাস্টম ব্লক যুক্ত করো'),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RoutineBuilderScreen(),
                  ),
                );
                if (context.mounted) context.go('/routine');
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'অথবা একটা টেমপ্লেট থেকে শুরু করো',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          templatesAsync.when(
            data: (templates) {
              if (templates.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('এখনও কোনো টেমপ্লেট যুক্ত করা হয়নি।'),
                );
              }
              return Column(
                children: templates.map((template) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(template.title),
                      subtitle: Text(template.description),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final full = await ref
                            .read(routineApiServiceProvider)
                            .getTemplate(template.templateId);
                        if (!context.mounted) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RoutineBuilderScreen(
                              title: full.title,
                              initialBlocks: [
                                for (final block in full.blocks)
                                  block.withoutId(),
                              ],
                              sourceTemplateId: full.templateId,
                            ),
                          ),
                        );
                        if (context.mounted) context.go('/routine');
                      },
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('টেমপ্লেট লোড করা যায়নি: $error'),
          ),
        ],
      ),
    );
  }
}
