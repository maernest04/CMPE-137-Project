import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cmpe_137_study_space/models/review.dart';

/// One of the current user's reviews, with the parent study space id from the path
/// `spaces/{spaceId}/reviews/{reviewId}`.
class UserReviewEntry {
  final Review review;
  final String spaceId;

  const UserReviewEntry({
    required this.review,
    required this.spaceId,
  });

  static UserReviewEntry fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final parent = doc.reference.parent.parent;
    final spaceId = parent?.id ?? '';
    return UserReviewEntry(
      review: Review.fromFirestore(doc),
      spaceId: spaceId,
    );
  }
}

class UserReviewsRepository {
  UserReviewsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// All reviews authored by [userId] across every study space.
  Stream<List<UserReviewEntry>> watchReviewsForUser(String userId) async* {
    try {
      final spacesSnap = await _firestore.collection('spaces').get();
      List<UserReviewEntry> allReviews = [];

      for (final spaceDoc in spacesSnap.docs) {
        final reviewsSnap = await spaceDoc.reference
            .collection('reviews')
            .where('userId', isEqualTo: userId)
            .get();
        for (final reviewDoc in reviewsSnap.docs) {
          allReviews.add(UserReviewEntry.fromDocument(reviewDoc));
        }
      }

      allReviews.sort((a, b) {
        final ta = a.review.createdAt?.millisecondsSinceEpoch ?? 0;
        final tb = b.review.createdAt?.millisecondsSinceEpoch ?? 0;
        return tb.compareTo(ta);
      });

      yield allReviews;
    } catch (e) {
      yield [];
    }
  }
}
