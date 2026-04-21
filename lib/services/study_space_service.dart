import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';

class StudySpaceService {
  StudySpaceService._();

  static final StudySpaceService instance = StudySpaceService._();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      description: data['description'] is String
          ? data['description'] as String
          : null,
    );
  }

  Future<List<StudySpace>> fetchStudySpaces() async {
    final snapshot = await _firestore.collection('spaces').get();
    return snapshot.docs
        .map((doc) => studySpaceFromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<StudySpace> createStudySpace({
    required String name,
    required String building,
    required String noiseLevel,
    required bool hasOutlets,
    required double latitude,
    required double longitude,
    String? description,
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
      'overallAvg': 0,
      'reviewCount': 0,
      'createdBy': currentUser.uid,
      'createdByName': currentUser.displayName ?? currentUser.email ?? 'Unknown user',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final trimmedDescription = description?.trim();
    if (trimmedDescription != null && trimmedDescription.isNotEmpty) {
      payload['description'] = trimmedDescription;
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
      description: trimmedDescription,
    );
  }
}
