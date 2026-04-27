import 'package:flutter/widgets.dart';

import 'auth_service.dart';

/// Provides access to [AuthService] throughout the widget tree.
///
/// This is a simple alternative to using a full dependency injection
/// or state management library.
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({
    super.key,
    required AuthService authService,
    required super.child,
  }) : super(notifier: authService);

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    if (scope == null) {
      throw FlutterError(
        'AuthScope.of() called with a context that does not contain an AuthScope.',
      );
    }
    return scope.notifier!;
  }
}
