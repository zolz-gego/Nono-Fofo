import 'package:equatable/equatable.dart';

/// Device-wide preferences (set from the parent corner).
class AppSettings extends Equatable {
  const AppSettings({
    this.languageCode = 'ar',
    this.sfxVolume = 1,
    this.voiceVolume = 1,
    this.musicVolume = 0.5,
    this.muted = false,
  });

  final String languageCode;
  final double sfxVolume;
  final double voiceVolume;
  final double musicVolume;
  final bool muted;

  AppSettings copyWith({
    String? languageCode,
    double? sfxVolume,
    double? voiceVolume,
    double? musicVolume,
    bool? muted,
  }) => AppSettings(
    languageCode: languageCode ?? this.languageCode,
    sfxVolume: sfxVolume ?? this.sfxVolume,
    voiceVolume: voiceVolume ?? this.voiceVolume,
    musicVolume: musicVolume ?? this.musicVolume,
    muted: muted ?? this.muted,
  );

  @override
  List<Object?> get props => [
    languageCode,
    sfxVolume,
    voiceVolume,
    musicVolume,
    muted,
  ];
}
