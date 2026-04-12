import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Authentication service that manages user authentication via Firebase.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;
  String? _displayName;
  String? _major;
  int _reviewCount = 0;
  bool _isLoading = false;
  String? _error;

  AuthService() {
    _initializeAuthListener();
  }

  /// Initialize listener for auth state changes
  void _initializeAuthListener() {
    _firebaseAuth.authStateChanges().listen((User? user) async {
      _currentUser = user;
      if (user != null) {
        await _loadUserData(user.uid);
      } else {
        _displayName = null;
        _major = null;
        _reviewCount = 0;
      }
      notifyListeners();
    });
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _displayName = doc['displayName'] ?? '';
        _major = doc['major'] ?? 'Undeclared';
        _reviewCount = (doc['reviewCount'] as num?)?.toInt() ?? 0;
      } else {
        _displayName = _currentUser?.email?.split('@').first ?? '';
        _major = 'Undeclared';
        _reviewCount = 0;
      }
    } catch (e) {
      _error = 'Failed to load user data: $e';
      print(_error);
    }
    notifyListeners();
  }

  /// The currently signed in user email, or null if not signed in.
  String? get userEmail => _currentUser?.email;

  /// The name the user entered when registering.
  String? get displayName => _displayName;

  /// The user's major (also entered during registration).
  String? get major => _major;

  /// Number of reviews the user has submitted.
  int get reviewCount => _reviewCount;

  /// Whether a user is signed in.
  bool get isSignedIn => _currentUser != null;

  /// Whether an async operation is in progress.
  bool get isLoading => _isLoading;

  /// The last error message, if any.
  String? get error => _error;

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Signs in with email and password.
  Future<void> signIn({required String email, required String password}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new account with email and password.
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String major,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name in Firebase Auth
      await userCredential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email.trim(),
        'displayName': displayName,
        'major': major,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Reload user to get updated display name
      await userCredential.user?.reload();
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      rethrow;
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs the user out.
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firebaseAuth.signOut();
    } catch (e) {
      _error = 'Failed to sign out: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reloads display name, major, and review count from Firestore.
  Future<void> refreshUserProfileFromServer() async {
    if (_currentUser == null) return;
    await _loadUserData(_currentUser!.uid);
  }

  /// Call after a new study-space review is successfully created.
  Future<void> incrementReviewCount() async {
    if (_currentUser == null) return;
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).set(
        {'reviewCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      await _loadUserData(_currentUser!.uid);
    } catch (e) {
      _error = 'Failed to update review count: $e';
      notifyListeners();
    }
  }

  /// Call after the user deletes one of their reviews.
  Future<void> decrementReviewCount() async {
    if (_currentUser == null) return;
    try {
      final ref = _firestore.collection('users').doc(_currentUser!.uid);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final n = (snap.data()?['reviewCount'] as num?)?.toInt() ?? 0;
        tx.set(
          ref,
          {'reviewCount': (n - 1).clamp(0, 1 << 20)},
          SetOptions(merge: true),
        );
      });
      await _loadUserData(_currentUser!.uid);
    } catch (e) {
      _error = 'Failed to update review count: $e';
      notifyListeners();
    }
  }

  /// Get user-friendly error message from Firebase error code
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
