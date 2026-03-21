import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String userName;
  final int noiseLevel;
  final int comfort;
  final int crowdLevel;
  final int easeOfAccess;
  final String comment;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.noiseLevel,
    required this.comfort,
    required this.crowdLevel,
    required this.easeOfAccess,
    required this.comment,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'noiseLevel': noiseLevel,
      'comfort': comfort,
      'crowdLevel': crowdLevel,
      'easeOfAccess': easeOfAccess,
      'comment': comment,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Review(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      noiseLevel: data['noiseLevel'] ?? 0,
      comfort: data['comfort'] ?? 0,
      crowdLevel: data['crowdLevel'] ?? 0,
      easeOfAccess: data['easeOfAccess'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'],
      updatedAt: data['updatedAt'],
    );
  }
}