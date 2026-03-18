// Repository where the UI/services will get data from
import 'package:cmpe_137_study_space/models/study_space.dart';

abstract class StudySpaceRepository {
  Future<List<StudySpace>> getAllSpaces();
  Future<List<StudySpace>> getSavedSpaces();
}