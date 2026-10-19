// npm run render -- <video-folder>            -> social/out/<folder>.mp4
// npm run still  -- <video-folder> [seconds]  -> social/out/<folder>@<s>s.jpg
import {execFileSync} from 'node:child_process';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const REMOTION = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const OUT = path.join(path.dirname(REMOTION), 'out');
const [mode, id, sec = '1'] = process.argv.slice(2);
if (!id) {
  console.error('usage: npm run render -- <video-folder>   |   npm run still -- <video-folder> [seconds]');
  process.exit(1);
}
const bin = path.join(REMOTION, 'node_modules', '.bin', 'remotion');
const args =
  mode === 'still'
    ? ['still', 'src/index.ts', `v${id}`, path.join(OUT, `${id}@${sec}s.jpg`), `--frame=${Math.round(Number(sec) * 30)}`]
    : ['render', 'src/index.ts', `v${id}`, path.join(OUT, `${id}.mp4`)];
execFileSync(bin, args, {cwd: REMOTION, stdio: 'inherit'});
