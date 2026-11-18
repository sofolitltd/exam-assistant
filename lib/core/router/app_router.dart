import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/views/auth_gate.dart';
import '../../features/auth/views/edit_profile_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/profile_setup_screen.dart';
import '../../features/dashboard/views/leaderboard_view.dart';
import '../../features/dashboard/views/main_navigation_hub.dart';
import '../../features/dashboard/views/profile_view.dart';
import '../../features/notices/views/notices_screen.dart';
import '../../features/learning/views/exam_leaderboard_screen.dart';
import '../../features/learning/views/listen_screen.dart';
import '../../features/learning/views/mistakes_practice_screen.dart';
import '../../features/learning/views/progress_screen.dart';
import '../../features/routine/views/routine_builder_screen.dart';
import '../../features/routine/views/routine_home_screen.dart';
import '../../features/routine/views/study_groups_screen.dart';
import '../../features/routine/views/weekly_summary_screen.dart';
import '../../features/exam/views/all_exams_screen.dart';
import '../../features/exam/views/exam_answer_key_screen.dart';
import '../../features/exam/views/home_screen.dart';
import '../../features/exam/views/live_exam_screen.dart';
import '../../features/exam/views/result_screen.dart';
import '../../features/exam/views/subject_questions_screen.dart';
import '../../features/exam/views/syllabus_browser_screen.dart';
import '../../features/exam/views/taxonomy_questions_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainNavigationHub(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
        ),
        GoRoute(
          path: '/leaderboard',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const LeaderboardView(),
          ),
        ),
        GoRoute(
          path: '/notices',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const NoticesScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const ProfileView()),
          routes: [
            GoRoute(
              path: 'edit',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const EditProfileScreen(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/all-exams',
          builder: (context, state) => const AllExamsScreen(),
        ),
        GoRoute(
          path: '/routine',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const RoutineHomeScreen(),
          ),
          routes: [
            GoRoute(
              path: 'builder',
              builder: (context, state) => const RoutineBuilderRoute(),
            ),
            GoRoute(
              path: 'weekly-summary',
              builder: (context, state) => const WeeklySummaryScreen(),
            ),
            GoRoute(
              path: 'groups',
              builder: (context, state) => const StudyGroupsScreen(),
              routes: [
                GoRoute(
                  path: ':groupId',
                  builder: (context, state) => StudyGroupDetailScreen(
                    groupId: int.parse(state.pathParameters['groupId']!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/exam/:examId',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: LiveExamScreen(examId: state.pathParameters['examId']!),
      ),
    ),
    GoRoute(path: '/result', builder: (context, state) => const ResultScreen()),
    GoRoute(
      path: '/subject/:subjectName',
      builder: (context, state) =>
          SubjectQuestionsScreen(subject: state.pathParameters['subjectName']!),
    ),
    GoRoute(
      path: '/program/:programId',
      builder: (context, state) => SyllabusBrowserScreen(
        programId: int.parse(state.pathParameters['programId']!),
      ),
    ),
    GoRoute(
      path: '/taxonomy-questions/:syllabusId/:nodeId',
      builder: (context, state) => TaxonomyQuestionsScreen(
        syllabusId: int.parse(state.pathParameters['syllabusId']!),
        nodeId: int.parse(state.pathParameters['nodeId']!),
        title: state.uri.queryParameters['title'] ?? 'Practice questions',
      ),
    ),
    GoRoute(
      path: '/exam/:examId/leaderboard',
      builder: (context, state) => ExamLeaderboardScreen(
        examId: state.pathParameters['examId']!,
        title: state.uri.queryParameters['title'] ?? 'লিডারবোর্ড',
      ),
    ),
    GoRoute(
      path: '/practice/mistakes',
      builder: (context, state) => MistakesPracticeScreen(
        examId: state.uri.queryParameters['examId'],
        title: state.uri.queryParameters['title'],
      ),
    ),
    GoRoute(
      path: '/listen',
      builder: (context, state) {
        final query = state.uri.queryParameters;
        return ListenScreen(
          examId: query['examId'],
          syllabusId: int.tryParse(query['syllabusId'] ?? ''),
          nodeId: int.tryParse(query['nodeId'] ?? ''),
          title: query['title'],
        );
      },
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/exam/:examId/answers',
      builder: (context, state) => ExamAnswerKeyScreen(
        examId: state.pathParameters['examId']!,
        title: state.uri.queryParameters['title'] ?? 'Answer key',
      ),
    ),
  ],
);
