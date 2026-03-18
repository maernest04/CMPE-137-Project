import 'study_space_repository.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';

class MockStudySpaceRepository implements StudySpaceRepository {
    @override
    Future<List<StudySpace>> getAllSpaces() async {
        // TODO: replace with real API calls
        return [
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
    }

    @override
    Future<List<StudySpace>> getSavedSpaces() async {
        // TODO: mock or filter from getAllSpaces
        return [];
    }
}