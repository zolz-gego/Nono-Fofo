import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _language = 'settings.language';
  static const _sfx = 'settings.sfxVolume';
  static const _voice = 'settings.voiceVolume';
  static const _music = 'settings.musicVolume';
  static const _muted = 'settings.muted';

  @override
  AppSettings read() {
    const d = AppSettings();
    return AppSettings(
      languageCode: _prefs.getString(_language) ?? d.languageCode,
      sfxVolume: _prefs.getDouble(_sfx) ?? d.sfxVolume,
      voiceVolume: _prefs.getDouble(_voice) ?? d.voiceVolume,
      musicVolume: _prefs.getDouble(_music) ?? d.musicVolume,
      muted: _prefs.getBool(_muted) ?? d.muted,
    );
  }

  @override
  Future<void> save(AppSettings s) async {
    await _prefs.setString(_language, s.languageCode);
    await _prefs.setDouble(_sfx, s.sfxVolume);
    await _prefs.setDouble(_voice, s.voiceVolume);
    await _prefs.setDouble(_music, s.musicVolume);
    await _prefs.setBool(_muted, s.muted);
  }
}
