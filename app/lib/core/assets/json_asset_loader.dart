import 'dart:convert';

import 'package:flutter/services.dart';

import '../error/failure.dart';

/// Reads JSON files bundled as assets. Injected so tests can swap the bundle.
class JsonAssetLoader {
  const JsonAssetLoader(this._bundle);

  final AssetBundle _bundle;

  Future<Map<String, dynamic>> load(String path) async {
    try {
      final raw = await _bundle.loadString(path);
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      throw Failure('Could not read JSON asset "$path"', e);
    }
  }

  /// All bundled asset paths that start with [prefix] and end with `.json`.
  Future<List<String>> listJson(String prefix) async {
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    return manifest
        .listAssets()
        .where((p) => p.startsWith(prefix) && p.endsWith('.json'))
        .toList()
      ..sort();
  }
}
