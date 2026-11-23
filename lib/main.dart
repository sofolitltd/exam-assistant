import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart' show usePathUrlStrategy;
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/routine/controllers/routine_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  GoRouter.optionURLReflectsImperativeAPIs = true;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const ProviderScope(child: ExamAssistantApp()));
}

class ExamAssistantApp extends ConsumerStatefulWidget {
  const ExamAssistantApp({super.key});

  @override
  ConsumerState<ExamAssistantApp> createState() => _ExamAssistantAppState();
}

class _ExamAssistantAppState extends ConsumerState<ExamAssistantApp> {
  bool _redirected = false;
  bool _notificationsArmed = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateChangesProvider, (_, next) {
      next.whenOrNull(
        data: (user) {
          if (user == null && !_redirected) {
            _redirected = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              appRouter.go('/login');
            });
          } else if (user != null) {
            _redirected = false;
            if (!_notificationsArmed) {
              _notificationsArmed = true;
              _armRoutineReminders();
            }
          }
        },
      );
    });
  }

  Future<void> _armRoutineReminders() async {
    final prefs = await ReminderPrefs.load();
    if (!prefs.anyOn) return;
    final notifications = ref.read(routineNotificationServiceProvider);
    final granted = await notifications.requestPermission();
    if (granted) {
      await notifications.scheduleRoutineReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Exam Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        // The learner's text size multiplies the phone's own font setting.
        final factor =
            ref.watch(textSizeProvider).value?.factor ?? TextSize.medium.factor;
        final media = MediaQuery.of(context);
        final system = media.textScaler.scale(100) / 100;
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(system * factor)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
