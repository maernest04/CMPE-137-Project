import 'package:google_maps_flutter/google_maps_flutter.dart';

class CampusBuilding {
  final String name;
  final LatLng location;
  final bool isOther;

  const CampusBuilding({
    required this.name,
    required this.location,
    this.isOther = false,
  });
}

/// A comprehensive list of SJSU buildings and their coordinates.
/// These are filtered for locations where students typically study or reside.
final List<CampusBuilding> sjsuBuildings = [
  const CampusBuilding(
    name: 'Art Building',
    location: LatLng(37.3355, -121.8833),
  ),
  const CampusBuilding(
    name: 'Boccardo Business Center (BBC)',
    location: LatLng(37.3364, -121.8785),
  ),
  const CampusBuilding(
    name: 'Business Tower',
    location: LatLng(37.3367, -121.8785),
  ),
  const CampusBuilding(
    name: 'Campus Village (Complex)',
    location: LatLng(37.3350, -121.8780),
  ),
  const CampusBuilding(
    name: 'Central Classroom Building',
    location: LatLng(37.3353, -121.8830),
  ),
  const CampusBuilding(
    name: 'Clark Hall',
    location: LatLng(37.3362, -121.8824),
  ),
  const CampusBuilding(
    name: 'Diaz Compean Student Union',
    location: LatLng(37.3360, -121.8814),
  ),
  const CampusBuilding(
    name: 'Dr. Martin Luther King Jr. Library',
    location: LatLng(37.3358428, -121.8850228),
  ),
  const CampusBuilding(
    name: 'Dudley Moorhead Hall',
    location: LatLng(37.3357, -121.8825),
  ),
  const CampusBuilding(
    name: 'Duncan Hall',
    location: LatLng(37.3328, -121.8825),
  ),
  const CampusBuilding(
    name: 'Dwight Bentel Hall',
    location: LatLng(37.3352, -121.8845),
  ),
  const CampusBuilding(
    name: 'Engineering Building',
    location: LatLng(37.3352, -121.8811),
  ),
  const CampusBuilding(
    name: 'Health Building',
    location: LatLng(37.3358, -121.8838),
  ),
  const CampusBuilding(
    name: 'Hugh Gillis Hall',
    location: LatLng(37.3361, -121.8845),
  ),
  const CampusBuilding(
    name: 'Industrial Studies',
    location: LatLng(37.3368, -121.8835),
  ),
  const CampusBuilding(
    name: 'Interdisciplinary Science Building (ISB)',
    location: LatLng(37.3340, -121.8805),
  ),
  const CampusBuilding(
    name: 'International House',
    location: LatLng(37.3320, -121.8755),
  ),
  const CampusBuilding(
    name: 'Joe West Hall',
    location: LatLng(37.3340, -121.8778),
  ),
  const CampusBuilding(
    name: 'MacQuarrie Hall',
    location: LatLng(37.3345, -121.8820),
  ),
  const CampusBuilding(
    name: 'Music Building',
    location: LatLng(37.3350, -121.8840),
  ),
  const CampusBuilding(
    name: 'Provident Credit Union Event Center',
    location: LatLng(37.3350, -121.8795),
  ),
  const CampusBuilding(
    name: 'Science Building',
    location: LatLng(37.3349, -121.8838),
  ),
  const CampusBuilding(
    name: 'Spartan Recreation & Aquatic Center (SRAC)',
    location: LatLng(37.3335, -121.8790),
  ),
  const CampusBuilding(
    name: 'Student Services Center',
    location: LatLng(37.3375, -121.8810),
  ),
  const CampusBuilding(
    name: 'Student Wellness Center',
    location: LatLng(37.3368, -121.8800),
  ),
  const CampusBuilding(
    name: 'Sweeney Hall',
    location: LatLng(37.3341, -121.8787),
  ),
  const CampusBuilding(
    name: 'Tower Hall',
    location: LatLng(37.3355, -121.8820),
  ),
  const CampusBuilding(
    name: 'Washburn Hall',
    location: LatLng(37.3335, -121.8785),
  ),
  const CampusBuilding(
    name: 'Washington Square Hall',
    location: LatLng(37.3340, -121.8845),
  ),
  const CampusBuilding(
    name: 'Yoshihiro Uchida Hall',
    location: LatLng(37.3335, -121.8837),
  ),
  const CampusBuilding(
    name: 'Spartan Village on the Paseo',
    location: LatLng(37.3330, -121.8890),
  ),
  const CampusBuilding(
    name: 'Other (Off-campus or Custom)',
    location: LatLng(37.3352, -121.8813),
    isOther: true,
  ),
];

CampusBuilding? findBuildingByName(String name) {
  try {
    return sjsuBuildings.firstWhere(
      (b) => b.name.toLowerCase() == name.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
}
