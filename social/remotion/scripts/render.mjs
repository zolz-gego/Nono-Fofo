// npm run render -- <video-folder>            -> social/out/<folder>.mp4
// npm run still  -- <video-folder> [seconds]  -> social/out/<folder>@<s>s.jpg
// npm run intro                               -> social/out/intro-landscape.mp4 + intro-portrait.mp4
// npm run still  -- intro-landscape [seconds] (or intro-portrait) for an intro still
// npm run release -- <video-folder> <thumb-seconds>  -> social/out/release/<folder>/
//   video.mp4 (high quality: H.264 CRF 12 slow, AAC 320k) + thumbnail.jpg (full size)
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const REMOTION = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const OUT = path.join(path.dirname(REMOTION), 'out');
const [mode, id, sec = '1'] = process.argv.slice(2);
const bin = path.join(REMOTION, 'node_modules', '.bin', 'remotion');
const run = (args) => execFileSync(bin, args, {cwd: REMOTION, stdio: 'inherit'});

if (mode === 'intro') {
  for (const comp of ['intro-landscape', 'intro-portrait']) {
    run(['render', 'src/index.ts', comp, path.join(OUT, `${comp}.mp4`), '--crf=16']);
  }
  process.exit(0);
}
if (!id) {
  console.error('usage: npm run render -- <video-folder>   |   npm run still -- <video-folder> [seconds]   |   npm run release -- <video-folder> <thumb-seconds>   |   npm run intro');
  process.exit(1);
}
const intro = id.startsWith('intro-');
const comp = intro ? id : `v${id}`;
const fps = intro ? JSON.parse(fs.readFileSync(path.join(REMOTION, 'src', 'intro', 'cues.json'), 'utf8')).fps : 30;
if (mode === 'release') {
  const dir = path.join(OUT, 'release', id);
  fs.mkdirSync(dir, {recursive: true});
  run(['render', 'src/index.ts', comp, path.join(dir, 'video.mp4'), '--codec=h264', '--crf=12', '--x264-preset=slow', '--audio-codec=aac', '--audio-bitrate=320k', '--pixel-format=yuv420p']);
  run(['still', 'src/index.ts', comp, path.join(dir, 'thumbnail.jpg'), `--frame=${Math.round(Number(sec) * fps)}`, '--image-format=jpeg', '--jpeg-quality=95']);
  console.log(`release -> ${dir} (write post.md with the captions next to it)`);
  process.exit(0);
}
run(
  mode === 'still'
    ? ['still', 'src/index.ts', comp, path.join(OUT, `${id}@${sec}s.jpg`), `--frame=${Math.round(Number(sec) * fps)}`]
    : ['render', 'src/index.ts', comp, path.join(OUT, `${id}.mp4`)],
);
