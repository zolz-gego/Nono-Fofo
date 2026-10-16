import '../../../core/assets/asset_paths.dart';
import '../../../core/assets/json_asset_loader.dart';
import '../../../core/error/failure.dart';
import '../domain/question.dart';
import '../domain/question_repository.dart';
import 'question_parser_registry.dart';

/// Reads every `*.json` in `assets/content/questions/` — no index to keep in
/// sync; drop a file in and it is picked up.
///
/// File envelope (the per-question format is decided per type later):
/// ```json
/// { "type": "pick_letter", "version": 1, "questions": [ { "id": "q1", ... } ] }
/// ```
class QuestionRepositoryImpl implements QuestionRepository {
  QuestionRepositoryImpl(this._loader, this._registry);

  final JsonAssetLoader _loader;
  final QuestionParserRegistry _registry;
  List<QuestionSet>? _cache;

  @override
  Future<List<QuestionSet>> loadAll() async {
    if (_cache != null) return _cache!;
    final paths = await _loader.listJson(AssetPaths.questions);
    final sets = <QuestionSet>[];
    for (final path in paths) {
      sets.add(_parseFile(path, await _loader.load(path)));
    }
    return _cache = sets;
  }

  @override
  Future<List<Question>> loadType(String type) async => [
    for (final set in await loadAll())
      if (set.type == type) ...set.questions,
  ];

  QuestionSet _parseFile(String path, Map<String, dynamic> json) {
    final type = json['type'];
    final items = json['questions'];
    if (type is! String || items is! List) {
      throw Failure('$path: needs a "type" string and a "questions" list');
    }
    return QuestionSet(
      type: type,
      version: (json['version'] as num?)?.toInt() ?? 1,
      source: path,
      questions: [
        for (final q in items) _registry.parse(type, q as Map<String, dynamic>),
      ],
    );
  }
}
