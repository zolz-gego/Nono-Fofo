// Balloons game player ("امسك البالونة") for tutorial recordings.
// step: {"do": "play", "game": "balloons", "letter": "e",
//        "catches": [{"ok": true}, {"ok": false}, {"ok": true}], "finish": {...}}
// Balloons rise from the bottom with the letter on a cream circle. Finds them
// with social/tools/tutorial/find_letters.py, measures how fast each rises
// (two looks; the bunch the other brother holds stays still, so it is
// skipped), taps the one with the target (or, for ok:false, another letter) a
// little above where it is, and waits while the buddy runs, jumps, grabs it
// and hands it over (a wrong one is held up, then pops).
import {spawn} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import readline from 'node:readline';
import {resultCard} from './fishing.mjs';

const LETTERS = 'a,b,e,z,3,i,k,l,m,n,o,c,t,w'; // Level 1 letters (Avva keys)

export async function play({page, sleep, now, VIEW, DPR, ROOT}, step) {
  const py = spawn(path.join(ROOT, 'tools', '.venv', 'bin', 'python'), [path.join(ROOT, 'social', 'tools', 'tutorial', 'find_letters.py'), '--serve'], {stdio: ['pipe', 'pipe', 'inherit']});
  const lines = readline.createInterface({input: py.stdout})[Symbol.asyncIterator]();
  const shot = path.join(os.tmpdir(), `tut-balloons-${process.pid}.png`);
  // the whole screen (a clipped screenshot leaks into the screencast as a
  // flash); find_letters skips the question card at the top
  const detect = async () => {
    await page.screenshot({path: shot});
    const t = now(); // the picture shows the scene as the screenshot returns
    py.stdin.write(`${shot} ${step.letters ?? LETTERS} 0.14\n`);
    const {value} = await lines.next();
    return {t, found: JSON.parse(value).map((b) => ({...b, x: b.x / DPR, y: b.y / DPR, r: b.r / DPR}))};
  };
  // two looks: match each balloon with the same letter nearby, keep the rising ones
  const rising = async () => {
    const a = await detect();
    await sleep(120);
    const b = await detect();
    const dt = b.t - a.t;
    const out = [];
    for (const p of b.found) {
      const q = a.found.filter((o) => o.key === p.key && Math.abs(o.x - p.x) < 14 && o.y > p.y - 2 && o.y - p.y < 200 * dt).sort((u, v) => Math.abs(u.x - p.x) - Math.abs(v.x - p.x))[0];
      if (!q) continue;
      const vy = (p.y - q.y) / dt;
      if (vy < -25) out.push({...p, vy, seen: b.t});
    }
    return out;
  };

  const plan = typeof step.catches === 'number' || step.catches === undefined ? Array.from({length: step.catches ?? 3}, () => ({ok: true})) : step.catches;
  const taps = [];
  const deadline = Date.now() + (step.timeout ?? 90) * 1000;
  const catchOne = async (ok, rush = false) => {
    while (Date.now() < deadline) {
      const found = (await rising()).filter((b) => (ok ? b.key === step.letter : b.key !== step.letter) && b.score >= (ok ? 0.55 : 0.7) && b.y > VIEW.height * (rush ? 0.22 : 0.3) && b.y < VIEW.height * 0.72);
      if (!found.length) {
        await sleep(150);
        continue;
      }
      // on camera the lowest (most sky above it); off camera the highest, before it floats away
      const b = found.sort((u, v) => (rush ? u.y - v.y : v.y - u.y))[0];
      const lag = now() - b.seen;
      const point = [b.x, b.y + b.vy * lag];
      const tapT = now();
      await page.touchscreen.tap(point[0], point[1]);
      console.log(`    ${ok ? 'catch' : 'wrong'}: ${b.key} (${b.score}) at ${point.map(Math.round).join(',')} rising ${Math.round(-b.vy)} px/s`);
      // the whole balloon: the letter circle sits a bit above its middle, the string hangs below
      const r = b.r;
      const rect = [point[0] - 2.6 * r, point[1] - 2.6 * r, 5.2 * r, 6.4 * r];
      // a wrong one: the buddy holds it up beside the other brother, then it pops
      const react = [0, VIEW.height * 0.36, VIEW.width, VIEW.height * 0.6];
      await sleep(ok ? (rush ? 1800 : (step.between ?? 2600)) : (step.betweenWrong ?? 3800));
      return {t: +tapT.toFixed(3), point: point.map((v) => +v.toFixed(1)), r: +r.toFixed(1), speed: 0, vy: +b.vy.toFixed(2), ok, key: b.key, rect: rect.map((v) => +v.toFixed(1)), react: react.map((v) => +v.toFixed(1))};
    }
    return null;
  };
  await sleep(step.warmup ?? 2000);
  for (const c of plan) {
    const tap = await catchOne(c.ok !== false);
    if (!tap) break;
    taps.push(tap);
  }
  if (taps.length < plan.length) console.log(`    ! only ${taps.length}/${plan.length} catches before the timeout`);
  const shownEnd = now();
  await sleep(step.after ?? 2000);

  let finish = null;
  if (step.finish) {
    const end = Date.now() + (step.finishTimeout ?? 120) * 1000;
    while (Date.now() < end && !finish) {
      const card = await resultCard(page);
      if (card) {
        await sleep(1500);
        finish = {t: +now().toFixed(3), rect: (await resultCard(page)) ?? card};
        console.log(`    result card at ${finish.rect.map(Math.round).join(',')}`);
        break;
      }
      await catchOne(true, true);
    }
    if (!finish) console.log('    ! the round did not finish before the timeout');
    await sleep(1000);
  }
  py.stdin.end();
  fs.rmSync(shot, {force: true});
  return {taps, shownEnd: +shownEnd.toFixed(3), finish};
}
