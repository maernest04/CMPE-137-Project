import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cmpe_137_study_space/services/auth_service.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:cmpe_137_study_space/theme/app_theme.dart';
import 'package:cmpe_137_study_space/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AuthTestApp());
}

class AuthTestApp extends StatelessWidget {
  const AuthTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authService: AuthService(),
      child: MaterialApp(
        title: 'Auth Test',
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );
  }
}