// Copies everything the videos use into public/ and writes src/generated/data.ts.
//
// The Flutter app stays the single source of truth for characters, colors,
// fonts, music and SFX: they are copied from app/assets on every run, never
// edited here. Social-only resources live in social/assets (see its
// manifest.json) and each video's voice lines in social/videos/<id>/voice.
//
// Run: npm run sync   (studio / still / render run it first automatically)
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const REMOTION = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SOCIAL = path.dirname(REMOTION);
const ROOT = path.dirname(SOCIAL);
const APP = path.join(ROOT, 'app', 'assets');
const PUB = path.join(REMOTION, 'public');
const GEN = path.join(REMOTION, 'src', 'generated');

const warnings = [];
const warn = (msg) => warnings.push(msg);

// Copy a folder, skipping files that are already up to date.
function sync(src, dst, skip = () => false) {
  if (!fs.existsSync(src)) return;
  fs.mkdirSync(dst, {recursive: true});
  for (const e of fs.readdirSync(src, {withFileTypes: true})) {
    if (e.name.startsWith('.') || skip(e.name)) continue;
    const s = path.join(src, e.name);
    const d = path.join(dst, e.name);
    if (e.isDirectory()) {
      sync(s, d, skip);
    } else {
      const a = fs.statSync(s);
      const b = fs.existsSync(d) && fs.statSync(d);
      if (!b || b.size !== a.size || b.mtimeMs < a.mtimeMs) fs.copyFileSync(s, d);
    }
  }
}

sync(path.join(APP, 'characters'), path.join(PUB, 'app', 'characters'), (n) => n === 'small');
sync(path.join(APP, 'audio', 'music'), path.join(PUB, 'app', 'audio', 'music'));
sync(path.join(APP, 'audio', 'sfx'), path.join(PUB, 'app', 'audio', 'sfx'));
sync(path.join(APP, 'brand'), path.join(PUB, 'app', 'brand'));
sync(path.join(APP, 'fonts'), path.join(PUB, 'app', 'fonts'), (n) => n.endsWith('.txt'));
sync(path.join(SOCIAL, 'assets'), path.join(PUB, 'social'), (n) => n === 'manifest.json');

// ---------------------------------------------------------------- colors (app_colors.dart)
const dart = fs.readFileSync(path.join(ROOT, 'app', 'lib', 'core', 'theme', 'app_colors.dart'), 'utf8');
const colors = {};
for (const m of dart.matchAll(/static const Color (\w+) = Color\(0x([0-9A-Fa-f]{8})\);/g)) {
  const [a, r, g, b] = m[2].match(/../g).map((h) => parseInt(h, 16));
  colors[m[1]] = a === 255 ? `rgb(${r}, ${g}, ${b})` : `rgba(${r}, ${g}, ${b}, ${(a / 255).toFixed(3)})`;
}
for (const m of dart.matchAll(/static const Color (\w+) = (\w+);/g)) {
  if (colors[m[2]]) colors[m[1]] = colors[m[2]];
}

// ---------------------------------------------------------------- characters
const charManifest = JSON.parse(fs.readFileSync(path.join(APP, 'characters', 'manifest.json'), 'utf8'));
const characters = {};
for (const [who, poses] of Object.entries(charManifest.characters)) {
  characters[who] = {};
  for (const [pose, p] of Object.entries(poses)) {
    characters[who][pose] = {file: `app/characters/${p.file}`, width: p.width, height: p.height, head: p.head_center};
  }
}

// ---------------------------------------------------------------- sounds
const ids = (dir) => (fs.existsSync(dir) ? fs.readdirSync(dir).filter((f) => !f.startsWith('.')) : []);
const sfx = {};
for (const f of ids(path.join(APP, 'audio', 'sfx'))) sfx[path.parse(f).name] = `app/audio/sfx/${f}`;
for (const f of ids(path.join(SOCIAL, 'assets', 'sfx'))) sfx[path.parse(f).name] = `social/sfx/${f}`;
const music = {};
for (const f of ids(path.join(APP, 'audio', 'music'))) music[path.parse(f).name] = `app/audio/music/${f}`;

// ---------------------------------------------------------------- videos
const videos = [];
for (const dir of ids(path.join(SOCIAL, 'videos')).sort()) {
  const folder = path.join(SOCIAL, 'videos', dir);
  const specFile = path.join(folder, 'video.json');
  if (!fs.existsSync(specFile)) continue;
  const spec = JSON.parse(fs.readFileSync(specFile, 'utf8'));
  sync(path.join(folder, 'voice'), path.join(PUB, 'videos', dir, 'voice'));
  spec.id = dir;
  if (spec.music && !music[spec.music.track]) warn(`${dir}: unknown music track "${spec.music.track}"`);
  for (const scene of spec.scenes) {
    const at = `${dir} / ${scene.id}`;
    if (scene.line) {
      const voice = ['mp3', 'wav', 'm4a'].map((ext) => `${scene.line.id}.${ext}`).find((f) => fs.existsSync(path.join(folder, 'voice', f)));
      scene.line.voice = voice ? `videos/${dir}/voice/${voice}` : null;
      if (!voice) warn(`${at}: no voice yet for "${scene.line.id}" (using ${scene.line.estimate}s estimate, silent)`);
    }
    for (const c of scene.characters ?? []) {
      for (const pose of [c.pose, ...(c.swaps ?? []).map((s) => s.pose)]) {
        if (!characters[c.who]?.[pose]) warn(`${at}: ${c.who} has no pose "${pose}"`);
      }
    }
    for (const s of scene.sfx ?? []) if (!sfx[s.id]) warn(`${at}: unknown sfx "${s.id}"`);
  }
  videos.push(spec);
}

fs.mkdirSync(GEN, {recursive: true});
fs.writeFileSync(
  path.join(GEN, 'data.ts'),
  `// Generated by scripts/sync-assets.mjs. Do not edit.\n` +
    `import type {VideoSpec, PoseInfo} from '../types';\n\n` +
    `export const colors = ${JSON.stringify(colors, null, 2)} as const;\n\n` +
    `export const characters: Record<string, Record<string, PoseInfo>> = ${JSON.stringify(characters, null, 2)};\n\n` +
    `export const sfx: Record<string, string> = ${JSON.stringify(sfx, null, 2)};\n\n` +
    `export const music: Record<string, string> = ${JSON.stringify(music, null, 2)};\n\n` +
    `export const videos: VideoSpec[] = ${JSON.stringify(videos, null, 2)};\n`,
);

console.log(`synced ${videos.length} video(s), ${Object.keys(sfx).length} sfx, ${Object.keys(colors).length} colors`);
for (const w of warnings) console.log(`  ! ${w}`);
