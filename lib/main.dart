import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart' show usePathUrlStrategy;
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
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

  if (!kIsWeb) {
    try {
      await GoogleSignIn.instance.initialize();
    } catch (e) {
      debugPrint('GoogleSignIn initialization failed: $e');
    }
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

  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateChangesProvider, (_, next) {
      next.whenOrNull(data: (user) {
        if (user == null && !_redirected) {
          _redirected = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appRouter.go('/login');
          });
        } else if (user != null) {
          _redirected = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Exam Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
