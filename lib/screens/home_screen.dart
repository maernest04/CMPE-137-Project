import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/widgets/study_space_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _selectedNoiseLevels = {};
  bool _filterOutlets = false;

  List<StudySpace> _spaces = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadSpaces();
  }

  String _mapNoiseLevel(dynamic value) {
  final noise = ((value ?? 0) as num).toDouble();

  if (noise <= 2) return 'Quiet';
  if (noise <= 3.5) return 'Moderate';
  return 'Loud';
  }

Future<void> loadSpaces() async {
  try {
    final snapshot =
        await FirebaseFirestore.instance.collection('spaces').get();

    final spaces = snapshot.docs.map((doc) {
      final data = doc.data();

    return StudySpace(
      id: doc.id,
      name: data['name'] ?? '',
      building: data['buildingName'] ?? '',  // ✅ FIXED
      noiseLevel: _mapNoiseLevel(data['noiseLevelAvg']),
      hasOutlets: data['hasPowerOutlets'] ?? false,
      latitude: 0.0,   // temporary placeholder
      longitude: 0.0,  // temporary placeholder
      rating: ((data['overallAvg'] ?? 0) as num).toDouble(),
    );

    }).toList();

    setState(() {
      _spaces = spaces;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
      _isLoading = false;
    });
  }
}

  List<StudySpace> get _filteredSpaces {
    return _spaces.where((space) {
      if (_selectedNoiseLevels.isNotEmpty &&
          !_selectedNoiseLevels.contains(space.noiseLevel)) {
        return false;
      }
      if (_filterOutlets && !space.hasOutlets) {
        return false;
      }
      return true;
    }).toList();
  }

  void _openFilterSheet() {
    final currentNoise = Set<String>.from(_selectedNoiseLevels);
    var currentOutlets = _filterOutlets;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            currentNoise.clear();
                            currentOutlets = false;
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Noise level'),
                  CheckboxListTile(
                    title: const Text('Quiet'),
                    value: currentNoise.contains('Quiet'),
                    onChanged: (value) {
                      setModalState(() {
                        if (value == true) {
                          currentNoise.add('Quiet');
                        } else {
                          currentNoise.remove('Quiet');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Moderate'),
                    value: currentNoise.contains('Moderate'),
                    onChanged: (value) {
                      setModalState(() {
                        if (value == true) {
                          currentNoise.add('Moderate');
                        } else {
                          currentNoise.remove('Moderate');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Loud'),
                    value: currentNoise.contains('Loud'),
                    onChanged: (value) {
                      setModalState(() {
                        if (value == true) {
                          currentNoise.add('Loud');
                        } else {
                          currentNoise.remove('Loud');
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Has outlets'),
                    value: currentOutlets,
                    onChanged: (value) {
                      setModalState(() {
                        currentOutlets = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedNoiseLevels
                          ..clear()
                          ..addAll(currentNoise);
                        _filterOutlets = currentOutlets;
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSpaces = _filteredSpaces;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text('Error loading spaces: $_errorMessage'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Spaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterSheet,
            tooltip: 'Filter spaces',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedNoiseLevels.isNotEmpty || _filterOutlets)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedNoiseLevels.map(
                    (level) => Chip(label: Text(level)),
                  ),
                  if (_filterOutlets) const Chip(label: Text('Has outlets')),
                  ActionChip(
                    label: const Text('Clear filters'),
                    onPressed: () {
                      setState(() {
                        _selectedNoiseLevels.clear();
                        _filterOutlets = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: filteredSpaces.isEmpty
                ? Center(
                    child: Text(
                      'No study spaces match your filters.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredSpaces.length,
                    itemBuilder: (context, index) {
                      final space = filteredSpaces[index];
                      return StudySpaceCard(space: space);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
