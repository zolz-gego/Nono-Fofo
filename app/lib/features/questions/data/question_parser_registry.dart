import 'package:flutter/foundation.dart';

import '../domain/question.dart';

typedef QuestionParser = Question Function(Map<String, dynamic> json);

/// Maps a question `type` to the parser for its JSON format.
/// Adding a new question type = one subclass of [Question], one parser
/// registered here (see `app/di/injection.dart`), one JSON file.
class QuestionParserRegistry {
  final Map<String, QuestionParser> _parsers = {};

  void register(String type, QuestionParser parser) => _parsers[type] = parser;

  bool supports(String type) => _parsers.containsKey(type);

  Question parse(String type, Map<String, dynamic> json) {
    final parser = _parsers[type];
    if (parser == null) {
      debugPrint('[questions] no parser registered for "$type"; kept as raw');
      return RawQuestion(type: type, json: json);
    }
    return parser(json);
  }
}

/// A question whose type has no parser yet. Keeps the raw JSON so content
/// can be added before the type's code exists.
class RawQuestion extends Question {
  RawQuestion({required super.type, required this.json})
    : super(id: '${json['id'] ?? ''}');

  final Map<String, dynamic> json;

  @override
  List<Object?> get props => [...super.props, json];
}
