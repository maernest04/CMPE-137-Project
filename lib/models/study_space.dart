class StudySpace {
  final String id;
  final String name;
  final String building;
  final String noiseLevel;
  final bool hasOutlets;
  final double latitude;
  final double longitude;
  final double rating;

  StudySpace({
    required this.id,
    required this.name,
    required this.building,
    required this.noiseLevel,
    required this.hasOutlets,
    required this.latitude,
    required this.longitude,
    required this.rating,
  });
}

// Mock Data for the UI team to build components against
final List<StudySpace> mockStudySpaces = [
  StudySpace(
    id: '1',
    name: 'MLK Library 4th Floor',
    building: 'Dr. Martin Luther King Jr. Library',
    noiseLevel: 'Quiet',
    hasOutlets: true,
    latitude: 37.3355,
    longitude: -121.8850,
    rating: 4.8,
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
  ),
];
