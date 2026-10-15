import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/l10n/l10n.dart';
import '../../../engines/sound/application/sound_service.dart';
import '../../../engines/sound/domain/sound_event.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._repository, this._sound) : super(_repository.read()) {
    _applySound(state);
  }

  final SettingsRepository _repository;
  final SoundService _sound;

  Locale get locale => AppLocales.supported.firstWhere(
    (l) => l.languageCode == state.languageCode,
    orElse: () => AppLocales.fallback,
  );

  void setLanguage(String code) => _update(state.copyWith(languageCode: code));

  void setVolume(SoundChannel channel, double value) =>
      _update(switch (channel) {
        SoundChannel.sfx => state.copyWith(sfxVolume: value),
        SoundChannel.voice => state.copyWith(voiceVolume: value),
        SoundChannel.music => state.copyWith(musicVolume: value),
      });

  void setMuted(bool muted) => _update(state.copyWith(muted: muted));

  void _update(AppSettings next) {
    emit(next);
    _applySound(next);
    _repository.save(next);
  }

  void _applySound(AppSettings s) => _sound.applySettings(
    sfx: s.sfxVolume,
    voice: s.voiceVolume,
    music: s.musicVolume,
    muted: s.muted,
  );
}
