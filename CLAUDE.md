# Nono & Fofo

## Git workflow (every chat)

- **Exception: social media videos** (`social/`, the `social-media` skill) don't get a new branch; stay on the current one. Only resources and the skill go in git, never videos (see the skill's "Git" section).
- **Start of every chat:** before making any file changes, create a new branch from the latest default branch:
  1. `git fetch origin` and check out the default branch, then pull it.
  2. `git checkout -b <type>/<short-kebab-description>` (e.g. `feat/sound-board`, `fix/map-audio-loop`), named after the task in the first message.
  - If the session is already on a non-default branch created for this chat (or in a worktree the app made), use it instead of creating another.
- **Work on that branch only.** Commit as you go with clear messages. Never commit directly to the default branch.
- **When the user says the task is completed** (e.g. "done", "task completed", "ship it"):
  1. **Ask the user whether to add screenshots** for this task. Only if they say yes, screenshot every screen the task added or changed and save it in `screenshots/` (see "Screenshots" below).
  2. Then, without asking for any more confirmation, commit any remaining changes (including the screenshots, if any).
  3. `git push -u origin <branch>`.
  4. Open a PR into `dev` with `gh pr create --base dev`. Give it a clear title and a body that summarizes what changed and why, and embed each new or updated screenshot (if any).
  5. Merge that PR (`gh pr merge --merge`).
  6. Open a PR from `dev` into `main` (`gh pr create --base main --head dev`) with a title and body summarizing the change, then merge it too (`gh pr merge --merge`).
  7. Reply with both PR links.
- Don't open a PR before the user says the task is completed.

## UI conventions

- Every screen's `Scaffold` uses `AppTopBar` (`app/lib/core/widgets/app_top_bar.dart`) as its `appBar`, so the logo shows on every screen. Inner pages pass `onLogoTap` to go home.
- **Games are the exception:** a game page uses `GameScaffold` (`app/lib/features/games/shell/presentation/game_scaffold.dart`) instead. While playing it is full screen with no top bar, and a see-through settings button (top left in Arabic, top right in English) pauses the game and opens a pop-up with resume, the game's own `GameAction`s, home, language and sound. Pass `onPause`/`onResume` to stop the game's engine, clock and `GameTimers`; set `playing: false` for a picker inside the page (it gets the normal top bar). Game HUDs leave `GameScaffold.cornerSize` free at the top end.
- Small icons (buttons, labels, list items) use Font Awesome through `font_awesome_flutter`: add the icon to `AppIcons` (`app/lib/core/theme/app_icons.dart`) and show it with `FaIcon(AppIcons.xxx)`. Don't add image files for small icons. Image assets are only for the logo, characters, and illustrations.

## Screenshots

- Capture from the web build (the `app-web` preview in `.claude/launch.json`) at 1280×800 (tablet landscape), in the built-in browser.
- Save as JPG in `screenshots/`, named `NN-screen-name.jpg` (e.g. `08-settings.jpg`): continue the numbering for a new screen, and overwrite the existing file for a changed one.
- Add or update the screen's section in `screenshots/README.md` (a heading, one line on what the screen does, and the image).
- If a screen also looks different in English, add an `-english` shot too (e.g. `07-home-english.jpg`).

## Social media videos

- TikTok / Instagram videos live in `social/` and follow the `social-media` skill (`.claude/skills/social-media/SKILL.md`). The videos themselves (`social/videos/`, `social/previews/`, `social/out/`, the logo intro) are local only and git-ignored.
- Any new resource made for the videos (sound, image, icon) goes in `social/assets/` and is registered in `social/assets/manifest.json` and the asset catalog in `social/README.md`. App assets (characters, colors, fonts, music, SFX) stay in the app; the videos pick them up automatically.
