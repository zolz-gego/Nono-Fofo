/// Low-level playback port. The app talks to `SoundService`; only the
/// service talks to this, so the audio package can be swapped in one place.
/// All paths are full asset paths, e.g. `assets/audio/sfx/ui_tap.wav`.
abstract interface class AudioEngine {
  Future<void> init();
  Future<void> playEffect(String assetPath, {double volume = 1});

  /// Voices never overlap: a new clip stops the previous one.
  Future<void> playVoice(String assetPath, {double volume = 1});
  Future<void> playMusic(
    String assetPath, {
    double volume = 1,
    bool loop = true,
  });
  Future<void> setMusicVolume(double volume);
  Future<void> stopMusic();
  Future<void> pauseAll();
  Future<void> resumeAll();
  Future<void> dispose();
}
