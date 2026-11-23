import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/views/auth_gate.dart';
import '../../features/bcs/data/bcs_models.dart';
import '../../features/bcs/views/analysis_screen.dart';
import '../../features/bcs/views/bcs_screen.dart';
import '../../features/bcs/views/competition_screen.dart';
import '../../features/bcs/views/edition_screen.dart';
import '../../features/bcs/views/merit_screen.dart';
import '../../features/bcs/views/practice_screen.dart';
import '../../features/bcs/views/read_listen_screen.dart';
import '../../features/bcs/views/schedule_screen.dart';
import '../../features/bcs/views/subject_pyq_screen.dart';
import '../../features/bcs/views/syllabus_screen.dart';
import '../../features/learning/views/practice_hub_screen.dart';
import '../../features/auth/views/edit_profile_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/signup_screen.dart';
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
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    // Paper modes run full screen, without the bottom nav.
    GoRoute(
      path: '/bcs/:edition/practice',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          PracticeScreen(number: _edition(state), selection: _selection(state)),
    ),
    GoRoute(
      path: '/bcs/:edition/read',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ReadListenScreen(
        number: _edition(state),
        selection: _selection(state),
      ),
    ),
    GoRoute(
      path: '/bcs/:edition/compete',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => CompetitionScreen(number: _edition(state)),
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
          path: '/practice',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const PracticeHubScreen(),
          ),
        ),
        GoRoute(
          path: '/bcs',
          builder: (context, state) => const BcsScreen(),
          routes: [
            GoRoute(
              path: 'pyq',
              builder: (context, state) => SubjectPyqScreen(
                initialFilter: parsePyqFilter(state.uri.queryParameters['bcs']),
              ),
              routes: [
                GoRoute(
                  path: 'subject',
                  builder: (context, state) => PyqSubjectScreen(
                    subject: state.uri.queryParameters['name'] ?? '',
                    initialFilter: parsePyqFilter(
                      state.uri.queryParameters['bcs'],
                    ),
                  ),
                ),
                GoRoute(
                  path: 'topic',
                  builder: (context, state) {
                    final q = state.uri.queryParameters;
                    return PyqTopicQuestionsScreen(
                      syllabusId: int.tryParse(q['syllabus'] ?? '') ?? 0,
                      nodeId: int.tryParse(q['node'] ?? '') ?? 0,
                      title: q['title'] ?? '',
                      filter: parsePyqFilter(q['bcs']),
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              path: ':edition',
              builder: (context, state) =>
                  EditionScreen(number: _edition(state)),
              routes: [
                GoRoute(
                  path: 'schedule',
                  builder: (context, state) =>
                      ScheduleScreen(number: _edition(state)),
                ),
                GoRoute(
                  path: 'merit',
                  builder: (context, state) =>
                      MeritScreen(number: _edition(state)),
                ),
                GoRoute(
                  path: 'analysis',
                  builder: (context, state) =>
                      AnalysisScreen(number: _edition(state)),
                ),
                GoRoute(
                  path: 'syllabus',
                  builder: (context, state) =>
                      SyllabusScreen(number: _edition(state)),
                ),
              ],
            ),
          ],
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
      path: '/notices',
      builder: (context, state) => const NoticesScreen(),
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

int _edition(GoRouterState state) =>
    int.tryParse(state.pathParameters['edition'] ?? '') ?? 0;

PaperSelection _selection(GoRouterState state) {
  final extra = state.extra;
  return extra is PaperSelection ? extra : PaperSelection.all;
}
