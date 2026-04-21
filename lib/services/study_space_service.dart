import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';

class StudySpaceService {
  StudySpaceService._();

  static final StudySpaceService instance = StudySpaceService._();

  String mapNoiseLevel(dynamic value) {
    final noise = ((value ?? 0) as num).toDouble();
    if (noise <= 2) return 'Quiet';
    if (noise <= 3.5) return 'Moderate';
    return 'Loud';
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
    );
  }

  Future<List<StudySpace>> fetchStudySpaces() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('spaces').get();
    return snapshot.docs
        .map((doc) => studySpaceFromFirestore(doc.id, doc.data()))
        .toList();
  }
}
