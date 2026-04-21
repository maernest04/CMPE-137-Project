import 'package:cmpe_137_study_space/config/sjsu_campus_map.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/screens/study_space_detail_screen.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:cmpe_137_study_space/services/study_space_service.dart';
import 'package:cmpe_137_study_space/widgets/create_study_space_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<StudySpace> _spaces = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  bool _isPickingNewSpaceLocation = false;
  String? _errorMessage;
  GoogleMapController? _mapController;
  LatLng _currentMapCenter = sjsuInitialCamera.target;

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
        _spaces = spaces;
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

  Future<void> _openCreateStudySpaceSheet() async {
    final authService = AuthScope.of(context);
    if (!authService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create a study space.')),
      );
      return;
    }

    final createdSpace = await showModalBottomSheet<StudySpace>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return CreateStudySpaceSheet(
          initialLatitude: _currentMapCenter.latitude,
          initialLongitude: _currentMapCenter.longitude,
        );
      },
    );

    if (!mounted || createdSpace == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${createdSpace.name} was added to the map.')),
    );

    setState(() => _isLoading = true);
    await _loadSpaces();

    await _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(createdSpace.latitude, createdSpace.longitude),
      ),
    );

    if (!mounted) return;
    context.push(
      '/study-space/${createdSpace.id}',
      extra: StudySpaceDetailArgs(
        space: createdSpace,
        onReviewSubmitted: _loadSpaces,
      ),
    );
  }

  Future<void> _startAddSpaceFlow() async {
    setState(() => _isPickingNewSpaceLocation = true);
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
    final selectedLat = _currentMapCenter.latitude.toStringAsFixed(5);
    final selectedLng = _currentMapCenter.longitude.toStringAsFixed(5);

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
            onCameraMove: (position) {
              _currentMapCenter = position.target;
            },
          ),
          if (_isPickingNewSpaceLocation)
            IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'New study space will use this point',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$selectedLat, $selectedLng',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Icon(
                        Icons.location_on,
                        size: 44,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isPickingNewSpaceLocation)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.72),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Pan the map until the center pin is on your study spot, then tap Continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
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
                const SizedBox(height: 12),
                if (!_isPickingNewSpaceLocation)
                  FloatingActionButton.extended(
                    heroTag: 'addSpaceBtn',
                    onPressed: _startAddSpaceFlow,
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('Add space'),
                  ),
              ],
            ),
          ),
          if (_isPickingNewSpaceLocation)
            Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: SafeArea(
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Choose a map point',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pan and zoom until the center pin is on the study spot, then continue.',
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _openCreateStudySpaceSheet,
                          child: const Text('Continue'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _isPickingNewSpaceLocation = false);
                          },
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
