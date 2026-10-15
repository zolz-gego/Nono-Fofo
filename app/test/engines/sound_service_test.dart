import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nonofofo/core/domain/character_id.dart';
import 'package:nonofofo/engines/sound/application/sound_service.dart';
import 'package:nonofofo/engines/sound/domain/audio_engine.dart';
import 'package:nonofofo/engines/sound/domain/sound_catalog.dart';
import 'package:nonofofo/engines/sound/domain/sound_event.dart';
import 'package:nonofofo/engines/sound/domain/sound_repository.dart';

class _MockEngine extends Mock implements AudioEngine {}

class _FakeRepo implements SoundRepository {
  @override
  Future<SoundCatalog> loadCatalog() async => const SoundCatalog(
        cues: {
          'correctAnswer': SoundCue(
            sfx: ['c1', 'c2'],
            voice: {CharacterId.nono: ['yay']},
          ),
        },
        musicSlots: {'map': 'map_theme'},
        sfxPaths: {'c1': 'assets/audio/sfx/c1.wav', 'c2': 'assets/audio/sfx/c2.wav'},
        voicePaths: {
          CharacterId.nono: {'yay': 'assets/audio/voice/nono/yay.m4a'},
        },
        musicPaths: {'map_theme': 'assets/audio/music/map_theme.m4a'},
      );
}

void main() {
  late _MockEngine engine;
  late SoundService service;

  setUp(() async {
    engine = _MockEngine();
    when(() => engine.init()).thenAnswer((_) async {});
    when(() => engine.playEffect(any(), volume: any(named: 'volume')))
        .thenAnswer((_) async {});
    when(() => engine.playVoice(any(), volume: any(named: 'volume')))
        .thenAnswer((_) async {});
    when(() => engine.playMusic(any(),
        volume: any(named: 'volume'),
        loop: any(named: 'loop'))).thenAnswer((_) async {});
    when(() => engine.setMusicVolume(any())).thenAnswer((_) async {});
    service = SoundService(_FakeRepo(), engine);
    await service.init();
  });

  test('event plays an effect and the brother voice', () async {
    await service.play(SoundEvent.correctAnswer, by: CharacterId.nono);
    verify(() => engine.playEffect(any(that: startsWith('assets/audio/sfx/c')),
        volume: 1)).called(1);
    verify(() => engine.playVoice('assets/audio/voice/nono/yay.m4a', volume: 1))
        .called(1);
  });

  test('variants never repeat twice in a row', () async {
    final played = <String>[];
    when(() => engine.playEffect(any(), volume: any(named: 'volume')))
        .thenAnswer((i) async => played.add(i.positionalArguments.first as String));
    for (var i = 0; i < 10; i++) {
      await service.play(SoundEvent.correctAnswer);
    }
    for (var i = 1; i < played.length; i++) {
      expect(played[i], isNot(played[i - 1]));
    }
  });

  test('muted plays nothing', () async {
    await service.applySettings(sfx: 1, voice: 1, music: 1, muted: true);
    await service.play(SoundEvent.correctAnswer, by: CharacterId.nono);
    verifyNever(() => engine.playEffect(any(), volume: any(named: 'volume')));
  });

  test('music slot resolves through the sound map', () async {
    await service.playMusic(MusicTrack.map);
    verify(() => engine.playMusic('assets/audio/music/map_theme.m4a',
        volume: 0.5, loop: true)).called(1);
  });
}
