
import 'package:cloud_firestore/cloud_firestore.dart';

class StudySpace {
  final String id;
  final String name;
  final String building;
  final String noiseLevel;
  final bool hasOutlets;
  final double latitude;
  final double longitude;
  final double rating;
  final String address;
  final String createdBy;
  /// Optional longer description from Firestore or mock data.
  final String? description;

  StudySpace({
    required this.id,
    required this.name,
    required this.building,
    required this.noiseLevel,
    required this.hasOutlets,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.createdBy,
    this.address = '',
    this.description,
  });

  /// Maps stored average noise (1–5 scale) to list filter labels.
  static String mapNoiseLevelAvgToLabel(dynamic value) {
    final noise = ((value ?? 0) as num).toDouble();
    if (noise <= 2) return 'Quiet';
    if (noise <= 3.5) return 'Moderate';
    return 'Loud';
  }

  /// Reads map position from a `spaces` document: numeric `latitude` /
  /// `longitude`, or a Firestore [GeoPoint] field `location` if numbers are absent.
  static ({double latitude, double longitude}) coordinatesFromFirestoreMap(
    Map<String, dynamic> data,
  ) {
    double latitude = 0;
    double longitude = 0;
    final latRaw = data['latitude'];
    final lngRaw = data['longitude'];
    if (latRaw is num) latitude = latRaw.toDouble();
    if (lngRaw is num) longitude = lngRaw.toDouble();

    final loc = data['location'];
    if (latitude == 0 && longitude == 0 && loc is GeoPoint) {
      latitude = loc.latitude;
      longitude = loc.longitude;
    }
    return (latitude: latitude, longitude: longitude);
  }

  factory StudySpace.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      return StudySpace(
        id: doc.id,
        name: 'Unknown space',
        building: '',
        noiseLevel: 'Moderate',
        hasOutlets: false,
        latitude: 0,
        longitude: 0,
        rating: 0,
        createdBy: '',
      );
    }
    final coords = coordinatesFromFirestoreMap(data);
    return StudySpace(
      id: doc.id,
      name: data['name'] ?? '',
      building: data['buildingName'] ?? '',
      noiseLevel: mapNoiseLevelAvgToLabel(data['noiseLevelAvg']),
      hasOutlets: data['hasPowerOutlets'] ?? false,
      latitude: coords.latitude,
      longitude: coords.longitude,
      rating: ((data['overallAvg'] ?? 0) as num).toDouble(),
      createdBy: data['createdBy'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] is String
          ? data['description'] as String
          : null,
    );
  }
}

// Mock Data for the UI team to build components against
final List<StudySpace> mockStudySpaces = [
  StudySpace(
    id: '1',
    name: 'MLK Library',
    building: 'Dr. Martin Luther King Jr. Library',
    noiseLevel: 'Quiet',
    hasOutlets: true,
    latitude: 37.33584281843284,
    longitude: -121.8850228166373,
    rating: 4.8,
    createdBy: '',
    description:
        'Dedicated quiet floor with long tables, good lighting, and reliable '
        'Wi‑Fi. Popular during finals—arrive early for a seat near outlets.',
  ),
  StudySpace(
    id: '2',
    name: 'SU Cafeteria',
    building: 'Student Union',
    noiseLevel: 'Loud',
    hasOutlets: false,
    latitude: 37.3360,
    longitude: -121.8814,
    rating: 3.9,
    createdBy: '',
    description:
        'High-energy spot with food nearby. Better for group work or casual '
        'reading than deep focus sessions.',
  ),
  StudySpace(
    id: '3',
    name: 'ISB Corner Lounge',
    building: 'Interdisciplinary Science Building',
    noiseLevel: 'Moderate',
    hasOutlets: true,
    latitude: 37.3340,
    longitude: -121.8805,
    rating: 4.5,
    createdBy: '',
    description:
        'Comfortable seating between classes. Foot traffic picks up midday; '
        'mornings are usually calmer.',
  ),
];
