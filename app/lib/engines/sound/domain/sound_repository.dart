import 'sound_catalog.dart';

abstract interface class SoundRepository {
  /// Loads the audio manifest + sound map into a [SoundCatalog].
  Future<SoundCatalog> loadCatalog();
}
