// npm run render -- <video-folder>            -> social/out/<folder>.mp4
// npm run still  -- <video-folder> [seconds]  -> social/out/<folder>@<s>s.jpg
// npm run intro                               -> social/out/intro-landscape.mp4 + intro-portrait.mp4
// npm run still  -- intro-landscape [seconds] (or intro-portrait) for an intro still
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
  console.error('usage: npm run render -- <video-folder>   |   npm run still -- <video-folder> [seconds]   |   npm run intro');
  process.exit(1);
}
const intro = id.startsWith('intro-');
const comp = intro ? id : `v${id}`;
const fps = intro ? JSON.parse(fs.readFileSync(path.join(REMOTION, 'src', 'intro', 'cues.json'), 'utf8')).fps : 30;
run(
  mode === 'still'
    ? ['still', 'src/index.ts', comp, path.join(OUT, `${id}@${sec}s.jpg`), `--frame=${Math.round(Number(sec) * fps)}`]
    : ['render', 'src/index.ts', comp, path.join(OUT, `${id}.mp4`)],
);
