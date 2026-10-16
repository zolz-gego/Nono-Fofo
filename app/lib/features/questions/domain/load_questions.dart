import 'question.dart';
import 'question_repository.dart';

/// Use case: get the questions of one type, optionally shuffled/limited.
class LoadQuestions {
  const LoadQuestions(this._repository);

  final QuestionRepository _repository;

  Future<List<Question>> call(
    String type, {
    int? limit,
    bool shuffle = false,
  }) async {
    final all = [...await _repository.loadType(type)];
    if (shuffle) all.shuffle();
    return limit == null || limit >= all.length ? all : all.sublist(0, limit);
  }
}
