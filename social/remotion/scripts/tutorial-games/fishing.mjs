// Fishing game player for tutorial recordings.
// step: {"do": "play", "game": "fishing", "letter": "a",
//        "catches": [{"ok": true}, {"ok": false}, {"ok": true}],  (or a number: that many right ones)
//        "finish": {...}  (then keep catching off camera until the round's result card shows),
//        "letters": "a,b,e,z,3,i,k,l,m,n,o,c,t,w", "after": 2500}
// {"ok": false} taps a fish with a different letter (the referee says "that's X not Y").
// Finds the fish whose badge shows the target letter (Avva key) with
// social/tools/tutorial/find_letters.py, taps it a little ahead of where it
// swims, and waits for the catch. Logs every tap with the badge size and the
// fish speed so the video can keep the highlight on the moving fish.
import {spawn} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import readline from 'node:readline';

const SWIM_SECONDS = 14; // app/assets/content/games/fishing.json "swimSeconds"

export async function play({page, sleep, now, nodes, VIEW, DPR, ROOT}, step) {
  const py = spawn(path.join(ROOT, 'tools', '.venv', 'bin', 'python'), [path.join(ROOT, 'social', 'tools', 'tutorial', 'find_letters.py'), '--serve'], {stdio: ['pipe', 'pipe', 'inherit']});
  const lines = readline.createInterface({input: py.stdout})[Symbol.asyncIterator]();
  const shot = path.join(os.tmpdir(), `tut-fish-${process.pid}.png`);
  const top = Math.round(VIEW.height * 0.5); // water starts about here on a phone
  const detect = async () => {
    await page.screenshot({path: shot, clip: {x: 0, y: top, width: VIEW.width, height: VIEW.height - top}});
    py.stdin.write(`${shot} ${step.letters ?? 'a,b,e,z,3,i,k,l,m,n,o,c,t,w'} 0\n`);
    const {value} = await lines.next();
    return JSON.parse(value).map((b) => ({...b, x: b.x / DPR, y: b.y / DPR + top, r: b.r / DPR}));
  };

  // fish swim left to right, crossing the screen (plus a fish length) in SWIM_SECONDS
  const speed = (VIEW.width * 1.25) / SWIM_SECONDS;
  const plan = typeof step.catches === 'number' || step.catches === undefined ? Array.from({length: step.catches ?? 3}, () => ({ok: true})) : step.catches;
  const taps = [];
  const deadline = Date.now() + (step.timeout ?? 90) * 1000;
  // one catch: find a fish (right letter or, for ok:false, any other), tap ahead of it
  const catchOne = async (ok) => {
    while (Date.now() < deadline) {
      const t = now();
      const found = (await detect()).filter((b) => (ok ? b.key === step.letter : b.key !== step.letter) && b.score >= (ok ? 0.55 : 0.7) && b.x > VIEW.width * 0.12 && b.x < VIEW.width * 0.78);
      if (!found.length) {
        await sleep(250);
        continue;
      }
      const b = found.sort((a, c) => a.x - c.x)[0]; // the one with the most water ahead of it
      const lag = now() - t + 0.05;
      const point = [b.x + speed * lag, b.y];
      const tapT = now();
      await page.touchscreen.tap(point[0], point[1]);
      console.log(`    ${ok ? 'catch' : 'wrong'}: ${b.key} (${b.score}) at ${point.map(Math.round).join(',')}`);
      await sleep(step.between ?? 3200); // cast, hook, reel, cheer (or the referee's "no!")
      return {t: +tapT.toFixed(3), point: point.map((v) => +v.toFixed(1)), r: +b.r.toFixed(1), speed: +speed.toFixed(2), ok, key: b.key};
    }
    return null;
  };
  await sleep(step.warmup ?? 2500); // let the first fish swim in
  for (const c of plan) {
    const tap = await catchOne(c.ok !== false);
    if (!tap) break;
    taps.push(tap);
  }
  if (taps.length < plan.length) console.log(`    ! only ${taps.length}/${plan.length} catches before the timeout`);
  const shownEnd = now();
  await sleep(step.after ?? 2500);

  // keep playing off camera until the result card (stars + "العب تاني") shows
  let finish = null;
  if (step.finish) {
    const end = Date.now() + (step.finishTimeout ?? 120) * 1000;
    while (Date.now() < end && !finish) {
      const card = await resultCard(page);
      if (card) {
        await sleep(1500); // let it pop in and settle
        finish = {t: +now().toFixed(3), rect: (await resultCard(page)) ?? card};
        console.log(`    result card at ${finish.rect.map(Math.round).join(',')}`);
        break;
      }
      await catchOne(true);
    }
    if (!finish) console.log('    ! the round did not finish before the timeout');
    await sleep(1000);
  }
  py.stdin.end();
  fs.rmSync(shot, {force: true});
  return {taps, shownEnd: +shownEnd.toFixed(3), finish};
}

// the result card's box: the smallest node holding the "play again" button that isn't the whole screen
async function resultCard(page) {
  return page.evaluate(() => {
    const els = [...document.querySelectorAll('flt-semantics')];
    const btn = els.find((e) => /العب تاني|Play again/.test(e.textContent ?? '') && !e.querySelector('flt-semantics'));
    if (!btn) return null;
    const b = btn.getBoundingClientRect();
    let best = null;
    for (const e of els) {
      const r = e.getBoundingClientRect();
      if (r.width < 100 || r.height > window.innerHeight * 0.92) continue;
      if (r.left <= b.left && r.right >= b.right && r.top <= b.top && r.bottom >= b.bottom && (!best || r.width * r.height < best[2] * best[3])) {
        if (r.height > b.height * 2) best = [r.x, r.y, r.width, r.height];
      }
    }
    return best ?? [Math.max(0, b.x - 40), Math.max(0, b.y - 360), b.width + 80, b.height + 420];
  });
}
