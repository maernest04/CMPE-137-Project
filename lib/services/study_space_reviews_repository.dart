import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cmpe_137_study_space/models/review.dart';

/// Reads and mutates reviews under `spaces/{spaceId}/reviews` (same path as
/// [ReviewService.submitReview] in Cloud Functions).
class StudySpaceReviewsRepository {
  StudySpaceReviewsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviewsCol(String spaceId) {
    return _firestore.collection('spaces').doc(spaceId).collection('reviews');
  }

  Stream<List<Review>> watchReviewsForSpace(String spaceId) {
    return _reviewsCol(spaceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Review.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateReview({
    required String spaceId,
    required String reviewId,
    required int noiseLevel,
    required int comfort,
    required int crowdLevel,
    required int easeOfAccess,
    required String comment,
  }) async {
    await _reviewsCol(spaceId).doc(reviewId).update({
      'noiseLevel': noiseLevel,
      'comfort': comfort,
      'crowdLevel': crowdLevel,
      'easeOfAccess': easeOfAccess,
      'comment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview({
    required String spaceId,
    required String reviewId,
  }) async {
    await _reviewsCol(spaceId).doc(reviewId).delete();
  }
}
