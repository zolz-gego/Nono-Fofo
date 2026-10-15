import 'package:equatable/equatable.dart';

/// Base of every question type. Each type (e.g. "pick_letter",
/// "match_sound") gets its own subclass + parser once its JSON format is
/// decided, and its own JSON file in `assets/content/questions/`.
abstract class Question extends Equatable {
  const Question({required this.id, required this.type});

  final String id;
  final String type;

  @override
  List<Object?> get props => [id, type];
}

/// All questions of one type, read from one JSON file.
class QuestionSet extends Equatable {
  const QuestionSet({
    required this.type,
    required this.version,
    required this.questions,
    required this.source,
  });

  final String type;
  final int version;
  final List<Question> questions;

  /// Asset path the set was read from (for error messages).
  final String source;

  @override
  List<Object?> get props => [type, version, questions, source];
}
