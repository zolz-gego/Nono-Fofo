import 'question.dart';

abstract interface class QuestionRepository {
  /// Every question file found in `assets/content/questions/`.
  Future<List<QuestionSet>> loadAll();

  /// All questions of [type] (merged if several files share a type).
  Future<List<Question>> loadType(String type);
}
