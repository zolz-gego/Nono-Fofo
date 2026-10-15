# Nono & Fofo (نونو وفوفو)

Flutter app (web, Android, iOS) that teaches kids Coptic letters with the
brothers Nono and Fofo. Package id: `com.nonofofo`.

```bash
flutter run -d chrome        # or: flutter run -d web-server --web-port 8080
flutter test
flutter analyze
```

## Architecture

Clean architecture, feature-first. Each feature/engine has the same layers:

- `domain/`: entities, repository interfaces and use cases. Pure Dart, no Flutter widgets and no packages.
- `data/`: repository implementations that read JSON assets, prefs and audio packages.
- `presentation/`: widgets and Cubits (`flutter_bloc`).

Dependencies point inward (presentation → domain ← data). Everything is
wired in `lib/app/di/injection.dart` (`get_it`). Inner layers receive
dependencies through constructors and never call `sl` themselves.

```
lib/
  main.dart
  app/                 app.dart (MaterialApp, l10n, theme), router.dart (go_router), di/
  core/
    theme/             app_colors.dart (all colors), app_theme.dart, app_dimens.dart
    typography/        app_text_styles.dart (fonts + header/body sizes)
    widgets/text/      CopticText / ArabicText / EnglishText / AppText
    l10n/              arb/app_ar.arb (default), arb/app_en.arb, generated/
    assets/            asset_paths.dart, json_asset_loader.dart
    domain/            character_id.dart
  engines/
    characters/        pose roster, motions, reactions, AnimatedCharacter, Flame component
    sound/             SoundService, sound events, audio engine port + audioplayers impl
  features/
    settings/          language + volumes (shared_preferences)
    questions/         JSON question loading (one file per type)
    playground/        dev screen showing every engine (temporary home)
```

## Rules of the house

| Topic | Rule |
|---|---|
| Colors | Only in `core/theme/app_colors.dart`. Widgets use the semantic names (`AppColors.primary`, `.correct`…). To re-theme the app, change that file. |
| Text | Use `CopticText`, `ArabicText`, `EnglishText` (fixed script) or `AppText` (follows the UI language). Each has `.h1 .h2 .h3 .body` + `caption`/`bodySmall` variants. Sizes and weights are set in `app_text_styles.dart`. |
| Coptic | Stored **exactly as typed with the Avva Shenouda keyboard** (legacy font: `a` shows ⲁ). Never Unicode Coptic. |
| UI strings | Never hard-coded. Add them to both `.arb` files and use `context.l10n.key`. To add a language, add `app_<code>.arb` and list it in `AppLocales.supported`. |
| Sounds | Code plays **events**, never files: `sound.play(SoundEvent.correctAnswer, by: CharacterId.nono)`. `assets/audio/sound_map.json` maps each event to sfx ids (picked at random, never the same twice in a row) and optional per-brother voice ids. To change a sound, edit the JSON. Game sounds use string keys: `sound.playKey('fishing.fish_catch')`. |
| Music | `sound.playMusic(MusicTrack.nile)`. Slots map to music ids in `sound_map.json` → `music`. |
| Characters | Never place pose images by hand. Create a `CharacterController`, show it with `AnimatedCharacter`, then call `react(CharacterReaction.correct, say: '…')`, `play(CharacterAction.run)` or `say('…')`. In Flame games, use `CharacterComponent`. Motion tuning lives in `character_motion.dart`. Reaction presets (pose + sound + hold time) live in `character_reaction.dart`. |
| Questions | One JSON file per question type in `assets/content/questions/`, found automatically. Envelope: `{"type": "...", "version": 1, "questions": [ ... ]}`. The per-question format is still **TBD**. To add a type: subclass `Question`, register its parser in `injection.dart`, and drop in the JSON. Types without a parser load as `RawQuestion`. |

## Asset pipelines (in `../tools`)

These scripts write straight into `app/assets/`:

- `tools/characters/process_poses.py` → `assets/characters/` (PNG poses + manifest)
- `tools/audio/synth_sfx.py` → `assets/audio/sfx/` + manifest `sfx` section
- `tools/audio/process_audio.py` → `assets/audio/music|voice/` + manifest sections

`sound_map.json` is edited by hand. In debug builds, unknown ids in it are
logged as `[sound_map] …`.

## Packages

- State and DI: `flutter_bloc`, `get_it`, `equatable`.
- Navigation: `go_router`.
- Languages: `flutter_localizations`, `intl`.
- Animation: `flutter_animate`, `lottie`, `confetti`, and `flame` (action mini-games).
- Sound: `audioplayers`.
- Storage: `shared_preferences`.
- Tests: `bloc_test`, `mocktail`.
