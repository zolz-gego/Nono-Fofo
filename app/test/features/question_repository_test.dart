import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/core/assets/json_asset_loader.dart';
import 'package:nonofofo/features/questions/data/question_parser_registry.dart';
import 'package:nonofofo/features/questions/data/question_repository_impl.dart';
import 'package:nonofofo/features/questions/domain/question.dart';

class _PickLetter extends Question {
  const _PickLetter({required super.id, required this.letter})
    : super(type: 'pick_letter');
  final String letter;
}

class _FakeLoader extends JsonAssetLoader {
  _FakeLoader(this.files) : super(rootBundle);
  final Map<String, Object> files;

  @override
  Future<List<String>> listJson(String prefix) async =>
      files.keys.where((k) => k.startsWith(prefix)).toList()..sort();

  @override
  Future<Map<String, dynamic>> load(String path) async =>
      jsonDecode(jsonEncode(files[path])) as Map<String, dynamic>;
}

void main() {
  test('each JSON file becomes a typed set; unknown types stay raw', () async {
    final registry = QuestionParserRegistry()
      ..register(
        'pick_letter',
        (j) =>
            _PickLetter(id: j['id'] as String, letter: j['letter'] as String),
      );
    final repo = QuestionRepositoryImpl(
      _FakeLoader({
        'assets/content/questions/pick_letter.json': {
          'type': 'pick_letter',
          'version': 1,
          'questions': [
            {'id': 'q1', 'letter': 'a'},
            {'id': 'q2', 'letter': 'b'},
          ],
        },
        'assets/content/questions/new_type.json': {
          'type': 'new_type',
          'questions': [
            {'id': 'n1', 'anything': true},
          ],
        },
      }),
      registry,
    );

    final picks = await repo.loadType('pick_letter');
    expect(picks, hasLength(2));
    expect((picks.first as _PickLetter).letter, 'a');

    final raw = await repo.loadType('new_type');
    expect(raw.single, isA<RawQuestion>());
    expect((raw.single as RawQuestion).json['anything'], true);
  });
}
