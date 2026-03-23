import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:cmpe_137_study_space/services/auth_service.dart';
import 'package:cmpe_137_study_space/theme/app_theme.dart';
import 'package:cmpe_137_study_space/screens/home_screen.dart';
import 'package:cmpe_137_study_space/screens/map_screen.dart';
import 'package:cmpe_137_study_space/screens/saved_screen.dart';
import 'package:cmpe_137_study_space/screens/profile_screen.dart';
import 'package:cmpe_137_study_space/screens/scaffold_with_nav_bar.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
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
  ],
);

class SpartanSpacesApp extends StatelessWidget {
  const SpartanSpacesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authService: AuthService(),
      child: MaterialApp.router(
        title: 'SpartanSpaces',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: goRouter,
      ),
    );
  }
}
