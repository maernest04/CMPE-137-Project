import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/services/study_space_service.dart';
import 'package:cmpe_137_study_space/widgets/study_space_card.dart';
import 'package:cmpe_137_study_space/widgets/create_study_space_sheet.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:go_router/go_router.dart';
import 'package:cmpe_137_study_space/screens/study_space_detail_screen.dart';
import 'package:cmpe_137_study_space/config/buildings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _selectedNoiseLevels = {};
  final Set<String> _selectedBuildings = {};
  bool _filterOutlets = false;
  double _minRating = 0.0;

  List<StudySpace> _spaces = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<List<StudySpace>>? _spacesSubscription;

  @override
  void initState() {
    super.initState();
    _watchSpaces();
  }

  @override
  void dispose() {
    _spacesSubscription?.cancel();
    super.dispose();
  }

  void _watchSpaces() {
    _spacesSubscription = StudySpaceService.instance.watchStudySpaces().listen(
      (spaces) {
        if (!mounted) return;
        setState(() {
          _spaces = spaces;
          _isLoading = false;
          _errorMessage = null;
        });
      },
      onError: (Object e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      },
    );
  }

  Future<void> loadSpaces() async {
    try {
      final spaces = await StudySpaceService.instance.fetchStudySpaces();
      setState(() {
        _spaces = spaces;
        _isLoading = false;
        _errorMessage = null;
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
      if (_selectedBuildings.isNotEmpty &&
          !_selectedBuildings.contains(space.building)) {
        return false;
      }
      if (space.rating < _minRating) {
        return false;
      }
      return true;
    }).toList();
  }

  void _openFilterSheet() {
    final currentNoise = Set<String>.from(_selectedNoiseLevels);
    final currentBuildings = Set<String>.from(_selectedBuildings);
    var currentOutlets = _filterOutlets;
    var currentMinRating = _minRating;

    final majorHubs = {
      'Dr. Martin Luther King Jr. Library': 'MLK Library',
      'Diaz Compean Student Union': 'Student Union',
      'Engineering Building': 'Engineering',
      'Boccardo Business Center (BBC)': 'BBC',
      'Interdisciplinary Science Building (ISB)': 'ISB',
    };

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
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
                                currentBuildings.clear();
                                currentOutlets = false;
                                currentMinRating = 0.0;
                              });
                            },
                            child: const Text('Clear all'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Buildings',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Autocomplete<CampusBuilding>(
                        displayStringForOption: (option) => option.name,
                        optionsBuilder: (textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<CampusBuilding>.empty();
                          }
                          return sjsuBuildings.where(
                            (b) => b.name.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        onSelected: (option) {
                          setModalState(() {
                            currentBuildings.add(option.name);
                          });
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  hintText: 'Search SJSU Building...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              );
                            },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Major Hubs',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: majorHubs.entries.map((entry) {
                          final isSelected = currentBuildings.contains(
                            entry.key,
                          );
                          return FilterChip(
                            label: Text(entry.value),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  currentBuildings.add(entry.key);
                                } else {
                                  currentBuildings.remove(entry.key);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      if (currentBuildings.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Selected Buildings',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: currentBuildings.map((b) {
                            return Chip(
                              label: Text(
                                b,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onDeleted: () {
                                setModalState(() {
                                  currentBuildings.remove(b);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const Divider(height: 32),
                      Text(
                        'Minimum Rating',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [0.0, 3.0, 4.0, 4.5].map((rating) {
                          final label = rating == 0.0 ? 'Any' : '$rating+ ★';
                          return ChoiceChip(
                            label: Text(label),
                            selected: currentMinRating == rating,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => currentMinRating = rating);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const Divider(height: 32),
                      Text(
                        'Noise level',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
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
                        contentPadding: EdgeInsets.zero,
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
                        contentPadding: EdgeInsets.zero,
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
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Has outlets'),
                        value: currentOutlets,
                        onChanged: (value) {
                          setModalState(() {
                            currentOutlets = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedNoiseLevels
                                ..clear()
                                ..addAll(currentNoise);
                              _selectedBuildings
                                ..clear()
                                ..addAll(currentBuildings);
                              _filterOutlets = currentOutlets;
                              _minRating = currentMinRating;
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('Apply filters'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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
        return const CreateStudySpaceSheet(
          initialLatitude: 37.3352,
          initialLongitude: -121.8811,
        );
      },
    );

    if (!mounted || createdSpace == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${createdSpace.name} was added.')));

    setState(() => _isLoading = true);
    await loadSpaces();

    if (!mounted) return;
    context.push(
      '/study-space/${createdSpace.id}',
      extra: StudySpaceDetailArgs(
        space: createdSpace,
        onReviewSubmitted: loadSpaces,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredSpaces = _filteredSpaces;
    final hasActiveFilters =
        _selectedNoiseLevels.isNotEmpty ||
        _filterOutlets ||
        _selectedBuildings.isNotEmpty ||
        _minRating > 0;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text('Error loading spaces: $_errorMessage')),
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
          if (hasActiveFilters)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_minRating > 0)
                    Chip(
                      label: Text('$_minRating+ ★'),
                      onDeleted: () => setState(() => _minRating = 0.0),
                    ),
                  ..._selectedNoiseLevels.map(
                    (level) => Chip(label: Text(level)),
                  ),
                  ..._selectedBuildings.map(
                    (building) => Chip(
                      label: Text(building),
                      onDeleted: () {
                        setState(() {
                          _selectedBuildings.remove(building);
                        });
                      },
                    ),
                  ),
                  if (_filterOutlets) const Chip(label: Text('Has outlets')),
                  ActionChip(
                    label: const Text('Clear filters'),
                    onPressed: () {
                      setState(() {
                        _selectedNoiseLevels.clear();
                        _selectedBuildings.clear();
                        _filterOutlets = false;
                        _minRating = 0.0;
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
                      return StudySpaceCard(
                        space: space,
                        onReviewSubmitted: loadSpaces,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addSpaceBtn',
        onPressed: _openCreateStudySpaceSheet,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add space'),
      ),
    );
  }
}
