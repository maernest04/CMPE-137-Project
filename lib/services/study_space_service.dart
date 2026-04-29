import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';

class StudySpaceService {
  StudySpaceService._();

  static final StudySpaceService instance = StudySpaceService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String mapNoiseLevel(dynamic value) {
    final noise = ((value ?? 0) as num).toDouble();
    if (noise <= 2) return 'Quiet';
    if (noise <= 3.5) return 'Moderate';
    return 'Loud';
  }

  double mapNoiseLevelLabelToAverage(String value) {
    switch (value) {
      case 'Quiet':
        return 2.0;
      case 'Loud':
        return 4.5;
      case 'Moderate':
      default:
        return 3.0;
    }
  }

  StudySpace studySpaceFromFirestore(String id, Map<String, dynamic> data) {
    final coords = StudySpace.coordinatesFromFirestoreMap(data);

    return StudySpace(
      id: id,
      name: data['name'] ?? '',
      building: data['buildingName'] ?? '',
      noiseLevel: mapNoiseLevel(data['noiseLevelAvg']),
      hasOutlets: data['hasPowerOutlets'] ?? false,
      latitude: coords.latitude,
      longitude: coords.longitude,
      rating: ((data['overallAvg'] ?? 0) as num).toDouble(),
      comfortRating: ((data['comfortAvg'] ?? 0) as num).toDouble(),
      crowdRating: ((data['crowdLevelAvg'] ?? 0) as num).toDouble(),
      accessRating: ((data['accessAvg'] ?? 0) as num).toDouble(),
      createdBy: data['createdBy'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] is String
          ? data['description'] as String
          : null,
      imageUrl: data['imageUrl'] is String ? data['imageUrl'] as String : null,
      floor: data['floor'] is String ? data['floor'] as String : null,
      areaDescription: data['areaDescription'] is String
          ? data['areaDescription'] as String
          : null,
    );
  }

  Future<List<StudySpace>> fetchStudySpaces() async {
    final snapshot = await _firestore.collection('spaces').get();
    return snapshot.docs
        .map((doc) => studySpaceFromFirestore(doc.id, doc.data()))
        .toList();
  }

  Stream<List<StudySpace>> watchStudySpaces() {
    return _firestore
        .collection('spaces')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => studySpaceFromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<StudySpace?> fetchStudySpaceById(String id) async {
    final doc = await _firestore.collection('spaces').doc(id).get();
    final data = doc.data();
    if (data == null) return null;
    return studySpaceFromFirestore(id, data);
  }

  Stream<StudySpace?> watchStudySpaceById(String id) {
    return _firestore.collection('spaces').doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return studySpaceFromFirestore(doc.id, data);
    });
  }

  Future<String> uploadStudySpaceImage(String spaceId, String imagePath) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('You must be signed in to upload an image.');
    }

    final ref = _storage.ref().child(
      'study_spaces/$spaceId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putFile(File(imagePath));
    return await ref.getDownloadURL();
  }

  Future<void> updateStudySpaceImageUrl(String spaceId, String imageUrl) async {
    await _firestore.collection('spaces').doc(spaceId).update({
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<StudySpace> createStudySpace({
    required String name,
    required String building,
    required String noiseLevel,
    required bool hasOutlets,
    required double latitude,
    required double longitude,
    required String address,
    String? description,
    String? imageUrl,
    String? floor,
    String? areaDescription,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('You must be signed in to create a study space.');
    }

    final payload = <String, dynamic>{
      'name': name.trim(),
      'buildingName': building.trim(),
      'noiseLevelAvg': mapNoiseLevelLabelToAverage(noiseLevel),
      'hasPowerOutlets': hasOutlets,
      'latitude': latitude,
      'longitude': longitude,
      'address': address.trim(),
      'overallAvg': 0,
      'reviewCount': 0,
      'createdBy': currentUser.uid,
      'createdByName':
          currentUser.displayName ?? currentUser.email ?? 'Unknown user',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isNotEmpty) {
      payload['description'] = trimmedDescription;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      payload['imageUrl'] = imageUrl;
    }
    if (floor != null && floor.isNotEmpty) {
      payload['floor'] = floor.trim();
    }
    if (areaDescription != null && areaDescription.isNotEmpty) {
      payload['areaDescription'] = areaDescription.trim();
    }

    final ref = await _firestore.collection('spaces').add(payload);
    return StudySpace(
      id: ref.id,
      name: name.trim(),
      building: building.trim(),
      noiseLevel: noiseLevel,
      hasOutlets: hasOutlets,
      latitude: latitude,
      longitude: longitude,
      rating: 0,
      createdBy: currentUser.uid,
      address: address.trim(),
      description: trimmedDescription,
      imageUrl: imageUrl,
      floor: floor?.trim(),
      areaDescription: areaDescription?.trim(),
    );
  }

  Future<void> deleteStudySpace(String spaceId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('You must be signed in to delete a study space.');
    }

    final docRef = _firestore.collection('spaces').doc(spaceId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw StateError('Study space does not exist.');
    }

    if (doc.data()?['createdBy'] != currentUser.uid) {
      throw StateError('You can only delete study spaces you created.');
    }

    await docRef.delete();
  }
}
