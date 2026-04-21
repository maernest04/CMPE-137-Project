import 'package:google_maps_flutter/google_maps_flutter.dart';

final LatLngBounds sjsuCampusBounds = LatLngBounds(
  southwest: const LatLng(37.3316, -121.8868),
  northeast: const LatLng(37.3384, -121.8774),
);

const CameraPosition sjsuInitialCamera = CameraPosition(
  target: LatLng(37.3352, -121.8813),
  zoom: 17,
);

const MinMaxZoomPreference sjsuZoomLimits = MinMaxZoomPreference(15.5, 19);

bool studySpaceHasMapPosition(double latitude, double longitude) {
  if (latitude == 0 && longitude == 0) return false;
  final p = LatLng(latitude, longitude);
  return sjsuCampusBounds.contains(p);
}
