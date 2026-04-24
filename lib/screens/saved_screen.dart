import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/services/auth_scope.dart';
import 'package:cmpe_137_study_space/services/study_space_service.dart';
import 'package:cmpe_137_study_space/widgets/study_space_card.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<StudySpace>? _allSpaces;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllSpaces();
  }

  Future<void> _loadAllSpaces() async {
    try {
      final allSpaces = await StudySpaceService.instance.fetchStudySpaces();
      
      if (!mounted) return;
      setState(() {
        _allSpaces = allSpaces;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load spaces: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-filter spaces synchronously based on authService.savedSpaces
    // in case a space was unsaved from another screen or detail view
    final authService = AuthScope.of(context);
    final savedIds = authService.savedSpaces;
    final currentSavedSpaces = _allSpaces == null 
        ? <StudySpace>[] 
        : _allSpaces!.where((s) => savedIds.contains(s.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Spaces'),
      ),
      body: _buildBody(currentSavedSpaces),
    );
  }

  Widget _buildBody(List<StudySpace> spaces) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    if (spaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Saved Spaces',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon on a space to save it here.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: spaces.length,
      itemBuilder: (context, index) {
        return StudySpaceCard(
          space: spaces[index],
          onReviewSubmitted: _loadAllSpaces,
        );
      },
    );
  }
}
