# Whiteboard letter videos

One Coptic letter per reel: a marker (no hand) writes and draws on a white board
in sync with the narration, built and rendered with [HyperFrames](https://hyperframes.heygen.com).
The workflow is the `whiteboard-letter` skill (`.claude/skills/whiteboard-letter/SKILL.md`).

| Path | What |
|---|---|
| `engine/board.js` | The engine: board layout, pen, write-on text, traced + coloured emoji, camera, timing |
| `tools/build.mjs` | Builds a letter's HyperFrames project from its spec and voice |
| `tools/render.py` | Renders a HyperFrames project on this Mac (PNG sequence + own audio mix) |
| `tools/release.py` | The release set: full-quality video, thumbnail, story hook |
| `tools/upload.py` | Copies the release set (video, thumbnail, story, post.md) to Google Drive `gdrive:Whiteboard/<folder>/` (rclone) |
| `tools/split.py` | Times the narration the user recorded (`voice/full.mp3`) per line (Whisper) |
| `package.json` | The emoji (Fluent Emoji, MIT): run `npm install` here once |
| `videos/<wb-NN-letter-ar>/` | *(local)* `whiteboard.json`, `script.md`, `voice/` |
| `projects/<folder>/` | *(local)* the generated HyperFrames project |
| `out/<folder>/` | *(local)* `video.mp4`, `thumbnail.jpg`, `story.mp4`, `post.md` |

```bash
cd social/whiteboard && npm install                                   # once
tools/.venv/bin/python social/whiteboard/tools/split.py <folder>       # after the user drops voice/full.mp3
node social/whiteboard/tools/build.mjs <folder>                         # -> projects/<folder>/
tools/.venv/bin/python social/whiteboard/tools/render.py social/whiteboard/projects/<folder> social/whiteboard/out/<folder>/draft.mp4
tools/.venv/bin/python social/whiteboard/tools/release.py <folder> --thumb <seconds>
python3 social/whiteboard/tools/upload.py <folder>                      # after post.md: upload to Drive
```

The marker scratch is `social/assets/sfx/wb_marker.wav` (made by `social/tools/synth_social_sfx.py`).
