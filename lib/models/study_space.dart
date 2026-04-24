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
  /// Optional longer description from Firestore or mock data.
  final String? description;
  /// Optional image URL from Firebase Storage.
  final String? imageUrl;

  StudySpace({
    required this.id,
    required this.name,
    required this.building,
    required this.noiseLevel,
    required this.hasOutlets,
    required this.latitude,
    required this.longitude,
    required this.rating,
    this.description,
    this.imageUrl,
  });

  StudySpace copyWith({
    String? id,
    String? name,
    String? building,
    String? noiseLevel,
    bool? hasOutlets,
    double? latitude,
    double? longitude,
    double? rating,
    String? description,
    String? imageUrl,
  }) {
    return StudySpace(
      id: id ?? this.id,
      name: name ?? this.name,
      building: building ?? this.building,
      noiseLevel: noiseLevel ?? this.noiseLevel,
      hasOutlets: hasOutlets ?? this.hasOutlets,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Maps stored average noise (1–5 scale) to list filter labels.
  static String mapNoiseLevelAvgToLabel(dynamic value) {
    final noise = ((value ?? 0) as num).toDouble();
    if (noise <= 2) return 'Quiet';
    if (noise <= 3.5) return 'Moderate';
    return 'Loud';
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
      );
    }
    return StudySpace(
      id: doc.id,
      name: data['name'] ?? '',
      building: data['buildingName'] ?? '',
      noiseLevel: mapNoiseLevelAvgToLabel(data['noiseLevelAvg']),
      hasOutlets: data['hasPowerOutlets'] ?? false,
      latitude: 0.0,
      longitude: 0.0,
      rating: ((data['overallAvg'] ?? 0) as num).toDouble(),
      description: data['description'] is String
          ? data['description'] as String
          : null,
      imageUrl: data['imageUrl'] is String ? data['imageUrl'] as String : null,
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
    description:
        'Comfortable seating between classes. Foot traffic picks up midday; '
        'mornings are usually calmer.',
  ),
];
