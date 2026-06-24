import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/views/add_exam_screen.dart';
import '../../features/admin/views/add_question_screen.dart';
import '../../features/admin/views/admin_upload_screen.dart';
import '../../features/admin/views/exam_detail_screen.dart';
import '../../features/admin/views/manage_exams_screen.dart';
import '../../features/auth/views/auth_gate.dart';
import '../../features/auth/views/edit_profile_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/profile_setup_screen.dart';
import '../../features/dashboard/views/leaderboard_view.dart';
import '../../features/dashboard/views/main_navigation_hub.dart';
import '../../features/dashboard/views/profile_view.dart';
import '../../features/notices/views/notices_screen.dart';
import '../../features/exam/views/all_exams_screen.dart';
import '../../features/exam/views/exam_list_screen.dart';
import '../../features/exam/views/live_exam_screen.dart';
import '../../features/exam/views/result_screen.dart';
import '../../features/exam/views/subject_questions_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
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
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
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
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ProfileView(),
          ),
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
      
      ],
    ),
    GoRoute(
      path: '/exam/:examId',
      builder: (context, state) => LiveExamScreen(
        examId: state.pathParameters['examId']!,
      ),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const ResultScreen(),
    ),
    GoRoute(
      path: '/subject/:subjectName',
      builder: (context, state) => SubjectQuestionsScreen(
        subject: state.pathParameters['subjectName']!,
      ),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminUploadScreen(),
      routes: [
        GoRoute(
          path: 'exam',
          builder: (context, state) => const ManageExamsScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddExamScreen(),
            ),
            GoRoute(
              path: 'edit/:examId',
              builder: (context, state) => AddExamScreen(
                examId: state.pathParameters['examId'],
              ),
            ),
            GoRoute(
              path: ':examId',
              builder: (context, state) {
                final id = state.pathParameters['examId'] ?? '';
                return ExamDetailScreen(examId: id);
              },
              routes: [
                GoRoute(
                  path: 'add-question',
                  builder: (context, state) {
                    final id = state.pathParameters['examId'] ?? '';
                    return AddQuestionScreen(examId: id);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
