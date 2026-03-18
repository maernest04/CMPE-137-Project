import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/widgets/study_space_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Spaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter modal
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: mockStudySpaces.length,
        itemBuilder: (context, index) {
          final space = mockStudySpaces[index];
          return StudySpaceCard(space: space);
        },
      ),
    );
  }
}
