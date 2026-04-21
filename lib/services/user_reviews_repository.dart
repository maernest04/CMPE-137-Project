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
  Stream<List<UserReviewEntry>> watchReviewsForUser(String userId) {
    return _firestore
        .collectionGroup('reviews')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map(UserReviewEntry.fromDocument).toList();
          list.sort((a, b) {
            final ta = a.review.createdAt?.millisecondsSinceEpoch ?? 0;
            final tb = b.review.createdAt?.millisecondsSinceEpoch ?? 0;
            return tb.compareTo(ta);
          });
          return list;
        });
  }
}
