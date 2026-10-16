import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nonofofo/features/games/writing/domain/letter_strokes.dart';
import 'package:nonofofo/features/games/writing/domain/writing_config.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  test('reads the shipped writing.json', () {
    final config = WritingConfig.fromJson(
      _json('assets/content/games/writing.json'),
    );
    expect(config.passAt, 0.85);
    expect(config.wipesToFail, 3);
    expect(config.chalkSizes, hasLength(3));
    expect(config.startSize, inInclusiveRange(0, 2));
    expect(config.warnAt, lessThan(1));
  });

  test('missing keys fall back to defaults', () {
    final config = WritingConfig.fromJson(const {});
    expect(config.passAt, 0.85);
    expect(config.background, isNull);
    expect(config.board, isNull);
  });

  test('every letter has a stroke order for both forms, inside 0..1', () {
    final letters = (_json('assets/content/letters.json')['letters'] as List)
        .map((l) => (l as Map<String, dynamic>)['id'] as String);
    final book = StrokeBook.fromJson(
      _json('assets/content/games/writing_strokes.json'),
    );
    for (final id in letters) {
      for (final form in LetterForm.values) {
        final strokes = book.of(id, form);
        expect(strokes.isEmpty, isFalse, reason: '$id ${form.name}');
        for (final s in strokes.strokes) {
          expect(s.length, greaterThanOrEqualTo(2), reason: '$id ${form.name}');
          for (final p in s) {
            expect(p.dx, inInclusiveRange(0, 1));
            expect(p.dy, inInclusiveRange(0, 1));
          }
        }
      }
    }
  });
}
