import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// ReviewService now sends reviews to the HTTPS Cloud Function `submitReview`.
///
/// Set `functionsBaseUrl` to your project functions URL (e.g.
/// https://us-central1-YOUR-PROJECT.cloudfunctions.net) or pass a different
/// base when constructing the service.
class ReviewService {
  final String functionsBaseUrl;

  ReviewService({this.functionsBaseUrl = 'https://us-central1-spartan-space-16b26.cloudfunctions.net'});

  Future<void> submitReview({
    required String spaceId,
    String? userId,
    String? userName,
    required int noiseLevel,
    required int comfort,
    required int crowdLevel,
    required int easeOfAccess,
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not signed in. Obtain a Firebase ID token before submitting.');
    }

    final idToken = await user.getIdToken();

    final base = functionsBaseUrl.endsWith('/')
      ? functionsBaseUrl.substring(0, functionsBaseUrl.length - 1)
      : functionsBaseUrl;

    final url = Uri.parse('$base/submitReview');

    final payload = {
      'spaceId': spaceId,
      // include provided userId/userName if caller supplied them; backend verifies token anyway
      'userId': userId ?? user.uid,
      'userName': userName ?? user.displayName ?? user.email ?? 'Anonymous',
      'noiseLevel': noiseLevel,
      'comfort': comfort,
      'crowdLevel': crowdLevel,
      'easeOfAccess': easeOfAccess,
      'comment': comment,
    };

    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(payload),
    );

    if (resp.statusCode != 200) {
      String message = 'Failed to submit review: ${resp.statusCode}';
      try {
        final body = jsonDecode(resp.body);
        if (body is Map && body['error'] != null) message = body['error'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }
}