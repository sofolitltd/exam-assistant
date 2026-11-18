import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';

class MainNavigationHub extends ConsumerWidget {
  final Widget child;

  const MainNavigationHub({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    int selectedIndex = 0;
    if (location.startsWith('/routine')) selectedIndex = 1;
    if (location.startsWith('/leaderboard')) selectedIndex = 2;
    if (location.startsWith('/notices')) selectedIndex = 3;
    if (location.startsWith('/profile')) selectedIndex = 4;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _wideLayout(context, selectedIndex);
        }
        return _narrowLayout(context, selectedIndex);
      },
    );
  }

  Widget _wideLayout(BuildContext context, int selectedIndex) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/home');
                case 1:
                  context.go('/routine');
                case 2:
                  context.go('/leaderboard');
                case 3:
                  context.go('/notices');
                case 4:
                  context.go('/profile');
              }
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school_rounded,
                    size: 36,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Exam\nAssistant',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(LucideIcons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.listChecks),
                label: Text('Routine'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.trophy),
                label: Text('Leaderboard'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.bell),
                label: Text('Notices'),
              ),
              NavigationRailDestination(
                icon: Icon(LucideIcons.user),
                label: Text('Profile'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _narrowLayout(BuildContext context, int selectedIndex) {
    return SafeArea(
      child: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/home');
              case 1:
                context.go('/routine');
              case 2:
                context.go('/leaderboard');
              case 3:
                context.go('/notices');
              case 4:
                context.go('/profile');
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(LucideIcons.home), label: 'Home'),
            NavigationDestination(
              icon: Icon(LucideIcons.listChecks),
              label: 'Routine',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.trophy),
              label: 'Leaderboard',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.bell),
              label: 'Notices',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.user),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
