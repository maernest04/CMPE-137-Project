import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:cmpe_137_study_space/services/auth_service.dart';
import 'package:cmpe_137_study_space/theme/app_theme.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/screens/home_screen.dart';
import 'package:cmpe_137_study_space/screens/study_space_detail_screen.dart';
import 'package:cmpe_137_study_space/screens/map_screen.dart';
import 'package:cmpe_137_study_space/screens/saved_screen.dart';
import 'package:cmpe_137_study_space/screens/profile_screen.dart';
import 'package:cmpe_137_study_space/screens/scaffold_with_nav_bar.dart';
import 'package:cmpe_137_study_space/screens/login_screen.dart';
import 'package:cmpe_137_study_space/screens/register_screen.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SpartanSpacesApp());
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _sectionANavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'sectionANav',
);
final _sectionBNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'sectionBNav',
);
final _sectionCNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'sectionCNav',
);
final _sectionDNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'sectionDNav',
);

GoRouter _buildGoRouter(AuthService authService) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: authService,
    redirect: (context, state) {
      // Redirect to login if not authenticated, unless already going to login/register
      final isLoggedIn = authService.isSignedIn;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (!isLoggedIn && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      // If already logged in and trying to access login/register, go to home
      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _sectionANavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'space/:id',
                    name: 'studySpaceDetail',
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is StudySpaceDetailArgs) {
                        return StudySpaceDetailScreen(
                          space: extra.space,
                          onReviewSubmitted: extra.onReviewSubmitted,
                        );
                      }
                      if (extra is StudySpace) {
                        return StudySpaceDetailScreen(space: extra);
                      }
                      return Scaffold(
                        appBar: AppBar(title: const Text('Space')),
                        body: const Center(
                          child: Text('This space could not be loaded.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _sectionBNavigatorKey,
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _sectionCNavigatorKey,
            routes: [
              GoRoute(
                path: '/saved',
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _sectionDNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/study-space/:id',
        name: 'studySpaceDetailRoot',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is StudySpaceDetailArgs) {
            return StudySpaceDetailScreen(
              space: extra.space,
              onReviewSubmitted: extra.onReviewSubmitted,
            );
          }
          if (extra is StudySpace) {
            return StudySpaceDetailScreen(space: extra);
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Space')),
            body: const Center(
              child: Text('This space could not be loaded.'),
            ),
          );
        },
      ),
    ],
  );
}

class SpartanSpacesApp extends StatefulWidget {
  const SpartanSpacesApp({super.key});

  @override
  State<SpartanSpacesApp> createState() => _SpartanSpacesAppState();
}

class _SpartanSpacesAppState extends State<SpartanSpacesApp> {
  late AuthService _authService;
  late GoRouter _goRouter;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _goRouter = _buildGoRouter(_authService);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authService: _authService,
      child: MaterialApp.router(
        title: 'SpartanSpaces',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _goRouter,
      ),
    );
  }
}
