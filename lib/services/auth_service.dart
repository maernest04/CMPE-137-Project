import 'package:flutter/foundation.dart';

/// A very small in-memory auth service used to prototype the UI.
///
/// This is intentionally not tied to any real backend (e.g. Firebase).
/// Replace with real auth wiring later.
class AuthService extends ChangeNotifier {
  String? _userEmail;
  String? _displayName;
  String? _major;
  int _reviewCount = 0;

  /// The currently signed in user email, or null if not signed in.
  String? get userEmail => _userEmail;

  /// The name the user entered when registering.
  String? get displayName => _displayName;

  /// The user's major (also entered during registration).
  String? get major => _major;

  /// Number of reviews the user has submitted in this session.
  int get reviewCount => _reviewCount;

  /// Whether a user is signed in.
  bool get isSignedIn => _userEmail != null;

  /// Simulates a sign-in call.
  ///
  /// In a real app, this would call Firebase Auth and throw on failure.
  Future<void> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Fake validation: password must be at least 6 characters and email contains @
    if (!email.contains('@') || password.length < 6) {
      throw Exception('Invalid credentials');
    }

    // In this mock service, we don't persist user details; just give a reasonable default.
    _userEmail = email;
    _displayName = email.split('@').first;
    _major = 'Undeclared';
    _reviewCount = 0;
    notifyListeners();
  }

  /// Simulates creating a new account.
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String major,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!email.contains('@') || password.length < 6) {
      throw Exception('Invalid registration details');
    }

    _userEmail = email;
    _displayName = displayName;
    _major = major;
    _reviewCount = 0;
    notifyListeners();
  }

  /// Signs the user out.
  void signOut() {
    _userEmail = null;
    _displayName = null;
    _major = null;
    _reviewCount = 0;
    notifyListeners();
  }

  /// Records that the user left a review.
  void addReview() {
    _reviewCount += 1;
    notifyListeners();
  }
}
