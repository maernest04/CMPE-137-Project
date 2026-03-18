import 'package:cmpe_137_study_space/api/api_client.dart';
import 'package:cmpe_137_study_space/api/endpoints.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'study_space_repository.dart';

class ApiStudySpaceRepository implements StudySpaceRepository {
  final ApiClient apiClient;

  ApiStudySpaceRepository(this.apiClient);

  @override
  Future<List<StudySpace>> getAllSpaces() async {
    final data = await apiClient.get(ApiEndpoints.studySpaces);
    // parse data into List<StudySpace>
    throw UnimplementedError();
  }

  @override
  Future<List<StudySpace>> getSavedSpaces() async {
    // similar
    throw UnimplementedError();
  }
}