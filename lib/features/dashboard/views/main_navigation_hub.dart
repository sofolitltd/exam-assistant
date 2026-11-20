import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/ds.dart';

/// Four tabs: হোম · রুটিন · অনুশীলন · প্রোফাইল. Notices live behind the bell
/// on the home bar. Exam and practice screens sit outside this shell, so the
/// nav is hidden while the user is answering.
class MainNavigationHub extends StatelessWidget {
  final Widget child;

  const MainNavigationHub({required this.child, super.key});

  static const _tabs = [
    ('/home', 'হোম', LucideIcons.house),
    ('/routine', 'রুটিন', LucideIcons.calendarCheck),
    ('/practice', 'অনুশীলন', LucideIcons.bookOpen),
    ('/profile', 'প্রোফাইল', LucideIcons.user),
  ];

  static int _indexFor(String location) {
    if (location.startsWith('/routine')) return 1;
    if (location.startsWith('/practice')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _indexFor(GoRouterState.of(context).matchedLocation);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selected,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) => context.go(_tabs[i].$1),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Exam\nAssistant',
                      textAlign: TextAlign.center,
                      style: dsText(12, weight: FontWeight.w700),
                    ),
                  ),
                  destinations: [
                    for (final t in _tabs)
                      NavigationRailDestination(
                        icon: Icon(t.$3),
                        label: Text(t.$2),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          body: child,
          bottomNavigationBar: _BottomNav(
            selected: selected,
            onTap: (i) => context.go(_tabs[i].$1),
          ),
        );
      },
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < MainNavigationHub._tabs.length; i++)
                Expanded(child: _item(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final tab = MainNavigationHub._tabs[i];
    final active = i == selected;
    final color = active ? AppColors.brand : AppColors.muted;
    return Semantics(
      selected: active,
      button: true,
      child: InkWell(
        onTap: () => onTap(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab.$3, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              tab.$2,
              style: dsText(
                12,
                color: color,
                weight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
