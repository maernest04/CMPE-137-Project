import 'package:cmpe_137_study_space/config/sjsu_campus_map.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/services/study_space_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    try {
      final spaces = await StudySpaceService.instance.fetchStudySpaces();
      final firestoreMappable =
          spaces.where((s) => studySpaceHasMapPosition(s.latitude, s.longitude)).toList();
      final mappable = firestoreMappable.isNotEmpty
          ? firestoreMappable
          : mockStudySpaces
              .where((s) => studySpaceHasMapPosition(s.latitude, s.longitude))
              .toList();
      final Map<String, List<StudySpace>> groupedSpaces = {};
      for (final space in mappable) {
        final key = '${space.latitude},${space.longitude}';
        groupedSpaces.putIfAbsent(key, () => []).add(space);
      }

      final markers = <Marker>{
        for (final entry in groupedSpaces.entries)
          Marker(
            markerId: MarkerId(entry.key),
            position: LatLng(entry.value.first.latitude, entry.value.first.longitude),
            infoWindow: InfoWindow(
              title: entry.value.first.building,
              snippet: '${entry.value.length} space${entry.value.length > 1 ? 's' : ''}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(_getHueForSpaces(entry.value)),
            onTap: () => _showSpacesSheet(
              entry.value,
              entry.value.first.building,
              entry.value.first.latitude,
              entry.value.first.longitude,
            ),
          ),
      };
      if (!mounted) return;
      setState(() {
        _markers = markers;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }



  double _getHueForSpaces(List<StudySpace> spaces) {
    if (spaces.isEmpty) return BitmapDescriptor.hueRed;
    final avgRating = spaces.map((s) => s.rating).reduce((a, b) => a + b) / spaces.length;
    if (avgRating >= 4.5) return BitmapDescriptor.hueGreen;
    if (avgRating >= 3.5) return BitmapDescriptor.hueOrange;
    return BitmapDescriptor.hueRed;
  }

  Future<void> _showSpacesSheet(
    List<StudySpace> spaces,
    String buildingName,
    double latitude,
    double longitude,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    buildingName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: spaces.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final space = spaces[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.menu_book,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(space.name),
                          subtitle: Text(
                            'Rating: ${space.rating.toStringAsFixed(1)} • Noise: ${space.noiseLevel}\n'
                            '${space.hasOutlets ? '🔌 Has Outlets' : 'No Outlets'}',
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openAppleMaps(latitude, longitude);
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Open in Apple Maps'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openGoogleMaps(latitude, longitude);
                    },
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Open in Google Maps'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openAppleMaps(double latitude, double longitude) async {
    final uri = Uri.parse('https://maps.apple.com/?daddr=$latitude,$longitude');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Campus Map')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Campus Map')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load spaces.\n$_errorMessage',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }



    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadSpaces();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: sjsuInitialCamera,
            cameraTargetBounds: CameraTargetBounds(sjsuCampusBounds),
            minMaxZoomPreference: sjsuZoomLimits,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),
          Positioned(
            right: 16,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomInBtn',
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOutBtn',
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
