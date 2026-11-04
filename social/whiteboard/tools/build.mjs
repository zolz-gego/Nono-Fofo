// Builds the HyperFrames version of a whiteboard letter video.
//
//   node social/whiteboard/tools/build.mjs wb-01-alpha-ar
//
// Reads social/whiteboard/videos/<folder>/whiteboard.json and voice/take.mp3 +
// take.json (tools/split.py), and writes a HyperFrames project in
// social/whiteboard/projects/<folder>/ (git-ignored, like the videos):
//   index.html             root: the board scene host, the voice clips, the
//                          marker scratch under every stroke, pops, whooshes, music
//   compositions/board.html the board scene (engine: social/whiteboard/engine/board.js, inlined)
//   assets/                fonts, logo, voice, music, sfx
// The engine is run here with fake text widths only to time the audio: timing
// never depends on measured text, so it matches what the scene draws.
// Render: tools/.venv/bin/python social/whiteboard/tools/render.py social/whiteboard/projects/<folder>
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath} from 'node:url';

const WHITEBOARD = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const SOCIAL = path.dirname(WHITEBOARD);
const ROOT = path.dirname(SOCIAL);
const require = createRequire(import.meta.url);
const WB = require(path.join(WHITEBOARD, 'engine', 'board.js'));

const folder = process.argv[2];
if (!folder) {
  console.error('usage: node social/whiteboard/tools/build.mjs <video-folder>');
  process.exit(1);
}
const src = path.join(WHITEBOARD, 'videos', folder);
const out = path.join(WHITEBOARD, 'projects', folder);
const json = (f) => JSON.parse(fs.readFileSync(f, 'utf8'));

// ---------------------------------------------------------------- data (same shape as the Remotion one)
const spec = json(path.join(src, 'whiteboard.json'));
const take = json(path.join(src, 'voice', 'take.json'));
const l = json(path.join(ROOT, 'app', 'assets', 'content', 'letters.json')).letters.find((x) => x.id === spec.letter);
if (!l) throw new Error(`unknown letter "${spec.letter}"`);
const ICONS = path.join(WHITEBOARD, 'node_modules', '@iconify-json'); // npm install in social/whiteboard
const hc = json(path.join(ICONS, 'fluent-emoji-high-contrast', 'icons.json'));
const flat = json(path.join(ICONS, 'fluent-emoji-flat', 'icons.json'));
const icons = {};
for (const s of spec.sections) {
  for (const w of s.words) {
    if (!hc.icons[w.icon]) throw new Error(`unknown icon "${w.icon}"`);
    icons[w.icon] = {size: 32, stroke: false, body: hc.icons[w.icon].body, color: flat.icons[w.icon]?.body ?? null};
  }
}
const data = {
  ...spec,
  letter: {small: l.small, capital: l.capital, name: l.name, sounds: l.sounds},
  take: {text: take.text, start: take.start, end: take.end},
  icons,
  logo: 'assets/logo.png',
};

// timing only: fake widths and path lengths
const board = WB.buildBoard(data, {width: (s, _script, size) => s.length * size * 0.6, pathLen: () => 1});
const D = Math.ceil(board.duration * 30) / 30;
const r = (x) => Math.round(x * 1000) / 1000;

// ---------------------------------------------------------------- assets
fs.mkdirSync(path.join(out, 'compositions'), {recursive: true});
for (const d of ['fonts', 'audio']) fs.mkdirSync(path.join(out, 'assets', d), {recursive: true});
const copy = (from, to) => fs.copyFileSync(from, path.join(out, 'assets', to));
copy(path.join(ROOT, 'app', 'assets', 'fonts', 'Avva_Shenouda.ttf'), 'fonts/Avva_Shenouda.ttf');
copy(path.join(ROOT, 'app', 'assets', 'fonts', 'BalooBhaijaan2.ttf'), 'fonts/BalooBhaijaan2.ttf');
copy(path.join(ROOT, 'app', 'assets', 'fonts', 'Baloo2.ttf'), 'fonts/Baloo2.ttf');
copy(path.join(ROOT, 'app', 'assets', 'brand', 'logo.png'), 'logo.png');
copy(path.join(src, 'voice', 'take.mp3'), 'audio/voice.mp3');
const music = spec.music ? path.join(ROOT, 'app', 'assets', 'audio', 'music', `${spec.music.track}.m4a`) : null;
if (music) copy(music, 'audio/music.m4a');
for (const s of ['wb_marker', 'mg_whoosh_in', 'mg_keyword_pop', 'mg_sparkle']) copy(path.join(SOCIAL, 'assets', 'sfx', `${s}.wav`), `audio/${s}.wav`);

// ---------------------------------------------------------------- root: scene host + audio
const takeEnd = take.end[take.end.length - 1]; // the voice file ends here
const audio = [];
board.clips.forEach((c, i) => {
  const a0 = Math.max(0, c.a0 - 0.04);
  audio.push(`<audio id="voice-${i + 1}" class="clip" src="assets/audio/voice.mp3" data-start="${r(c.from)}" data-media-start="${r(a0)}" data-duration="${r(Math.min(c.a1 + 0.12, takeEnd) - a0)}" data-track-index="2" data-volume="1"></audio>`);
});
board.ops.forEach((op, i) => {
  // the marker scratches only while the pen moves
  audio.push(`<audio id="scratch-${i + 1}" class="clip" src="assets/audio/wb_marker.wav" data-start="${r(op.start)}" data-media-start="${r((i * 1.37) % 5.5)}" data-duration="${r(op.dur)}" data-track-index="3" data-volume="0.5" data-fade-in="0.08" data-fade-out="0.08"></audio>`);
});
const track = {mg_keyword_pop: 4, mg_whoosh_in: 5, mg_sparkle: 6};
const len = {mg_keyword_pop: 0.9, mg_whoosh_in: 0.4, mg_sparkle: 1.5};
board.cues.forEach((c, i) => {
  audio.push(`<audio id="sfx-${i + 1}" class="clip" src="assets/audio/${c.sfx}.wav" data-start="${r(c.t)}" data-duration="${len[c.sfx]}" data-track-index="${track[c.sfx]}" data-volume="${c.volume}"></audio>`);
});
if (music) audio.push(`<audio id="music" class="clip" src="assets/audio/music.m4a" data-start="0" data-duration="${D}" data-track-index="7" data-volume="${spec.music.volume ?? 0.06}" data-fade-out="2"></audio>`);

fs.writeFileSync(
  path.join(out, 'index.html'),
  `<!doctype html>
<!-- Generated by social/whiteboard/tools/build.mjs from social/whiteboard/videos/${folder}. Rebuild instead of editing. -->
<html lang="ar" data-resolution="portrait">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=1080, height=1920" />
    <script src="https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js"></script>
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { margin: 0; width: 1080px; height: 1920px; overflow: hidden; background: #fbfbf8; }
      #root { position: relative; width: 100%; height: 100%; }
    </style>
  </head>
  <body>
    <div id="root" data-composition-id="main" data-start="0" data-duration="${D}" data-width="1080" data-height="1920">
      <div id="board" data-composition-id="board" data-composition-src="compositions/board.html" data-start="0" data-duration="${D}" data-track-index="1" data-track-kind="graphics" data-width="1080" data-height="1920"></div>
      ${audio.join('\n      ')}
    </div>
    <script>
      window.__timelines["main"] = gsap.timeline({ paused: true });
    </script>
  </body>
</html>
`,
);

// ---------------------------------------------------------------- the board scene
const engine = fs.readFileSync(path.join(WHITEBOARD, 'engine', 'board.js'), 'utf8');
fs.writeFileSync(
  path.join(out, 'compositions', 'board.html'),
  `<template>
  <style>
    @font-face { font-family: "AvvaShenouda"; src: url("assets/fonts/Avva_Shenouda.ttf"); }
    @font-face { font-family: "BalooBhaijaan2"; src: url("assets/fonts/BalooBhaijaan2.ttf"); font-weight: 400 800; }
    @font-face { font-family: "Baloo2"; src: url("assets/fonts/Baloo2.ttf"); font-weight: 400 800; }
    #root { position: absolute; inset: 0; overflow: hidden; }
    #board-stage { position: absolute; inset: 0; overflow: hidden; background: radial-gradient(ellipse at 50% 40%, #ffffff 0%, #f7f7f4 70%, #ecece8 100%); }
  </style>
  <div id="root" data-composition-id="board" data-width="1080" data-height="1920" data-layout-allow-overflow>
    <div id="board-stage"></div>
  </div>
  <script>
${engine}
  </script>
  <script>
    (async () => {
      const DATA = ${JSON.stringify(data)};
      // text is measured, so the fonts load before the board is laid out
      await Promise.all(["700 100px BalooBhaijaan2", "700 100px Baloo2", "100px AvvaShenouda"].map((f) => document.fonts.load(f)));
      const {render} = WB.mount(document.getElementById("board-stage"), DATA);
      const clock = { t: 0 };
      const tl = gsap.timeline({ paused: true });
      tl.to(clock, { t: ${D}, duration: ${D}, ease: "none", onUpdate: () => render(clock.t) }, 0);
      render(0);
      window.__timelines["board"] = tl;
    })();
  </script>
</template>
`,
);

for (const [f, body] of [
  ['hyperframes.json', {$schema: 'https://hyperframes.heygen.com/schema/hyperframes.json', paths: {blocks: 'compositions', assets: 'assets'}, media: {autoProxy: true}, authoringSkill: 'hyperframes'}],
  ['meta.json', {id: folder, name: folder}],
  ['package.json', {name: folder, private: true, type: 'module', scripts: {dev: 'npx --yes hyperframes@0.9.9 preview', check: 'npx --yes hyperframes@0.9.9 check', render: 'npx --yes hyperframes@0.9.9 render'}}],
]) {
  if (!fs.existsSync(path.join(out, f))) fs.writeFileSync(path.join(out, f), JSON.stringify(body, null, 2) + '\n');
}
// beat timing for the release tool (story cut, thumbnail)
fs.writeFileSync(path.join(out, 'timing.json'), JSON.stringify({duration: D, clips: board.clips.map((c) => ({start: r(c.from), end: r(c.from + c.a1 - c.a0)})), beats: board.beats, cams: board.cams}, null, 1) + '\n');
console.log(`${folder}: ${D.toFixed(1)} s, ${board.ops.length} strokes, ${board.clips.length} voice clips -> ${path.relative(ROOT, out)}`);
