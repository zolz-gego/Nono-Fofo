// "Write the letter" player for tutorial recordings (Grandpa's chalkboard).
// step: {"do": "play", "game": "writing",
//        "actions": [                         (in order; each may carry a voice "line")
//          {"do": "show", "what": "demo"},             wait for the chalk demo to end; box = the letter
//          {"do": "tap", "what": "size", "find": "^تخين$"},  a chalk size (tray buttons have labels)
//          {"do": "tap", "what": "color", "pick": 1},  a chalk colour: nth stick, top row first, left to right
//          {"do": "draw", "what": "fill", "until": "halfway"},  colour the letter row by row until the
//                                                      halfway cheer ("passed": until the board passes)
//          {"do": "draw", "what": "mess", "ok": false},  scribble under the letter until the warning
//          {"do": "show", "what": "capital"}           the capital board after its demo
//        ],
//        "finish": {...}}   then colour the capital off camera until the pass card shows
// The letter's inside is found in a screenshot by social/tools/tutorial/find_hollow.py.
// Returns {actions: [{t, t1, rect, point?, path?, meter?, ok?}], shownEnd, finish: {t, rect, share}}.
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// the green of the board on a 390×844 phone (inside the wooden frame)
const BOARD = {x: 34, y: 92, w: 323, h: 490};
const MESS_BAR = [92, 20, 74, 30]; // the "mess outside the letter" meter in the HUD
const FILL_BAR = [156, 20, 104, 30]; // the "coloured" bar in the HUD
const SAID = {
  halfway: /نص الحرف خلص|halfway/i,
  warn: /حاسب!|Careful/i,
  passed: /يلا نكتب الحرف الكبير|capital letter/i,
  wipe: /هامسحها|wipe/i,
};

export async function play({page, cdp, sleep, now, nodes, find, VIEW, DPR, ROOT}, step) {
  const shot = path.join(os.tmpdir(), `tut-writing-${process.pid}.png`);
  const py = path.join(ROOT, 'tools', '.venv', 'bin', 'python');
  const tool = path.join(ROOT, 'social', 'tools', 'tutorial', 'find_hollow.py');
  // the brothers' speech bubbles are short: the page logs every one it shows (with its time)
  await page.evaluate(() => {
    window.__heard = [];
    const seen = new Set();
    setInterval(() => {
      const now = Date.now();
      const live = new Set();
      for (const e of document.querySelectorAll('flt-semantics')) {
        const l = `${e.getAttribute('aria-label') ?? ''} ${e.childElementCount ? '' : e.textContent}`.trim();
        if (l.length < 6) continue;
        live.add(l);
        if (!seen.has(l)) window.__heard.push({t: now, l});
      }
      seen.clear();
      for (const l of live) seen.add(l);
    }, 120);
  });
  let since = Date.now(); // only bubbles from the current action count
  const said = (re) => page.evaluate(([src, t]) => window.__heard.some((h) => h.t >= t && new RegExp(src, 'i').test(h.l)), [re.source, since]);
  const rowStep = step.rowStep ?? 14; // CSS px between chalk rows (thick chalk is ~21 px wide)
  const inset = step.inset ?? 5; // keep the chalk's edge inside the outline

  const detect = async () => {
    await page.screenshot({path: shot, clip: {x: BOARD.x, y: BOARD.y, width: BOARD.w, height: BOARD.h}});
    const out = execFileSync(py, [tool, shot, '--scale', String(DPR), '--origin', `${BOARD.x},${BOARD.y}`, '--step', String(rowStep), '--inset', String(inset)], {encoding: 'utf8'});
    return JSON.parse(out);
  };
  // the board stops changing: the demo is over and the guide dots are up
  const boardStill = async (max = 15000) => {
    const end = Date.now() + max;
    let last = null;
    let same = 0;
    while (Date.now() < end) {
      const b = await page.screenshot({clip: {x: BOARD.x, y: BOARD.y, width: BOARD.w, height: BOARD.h}, scale: 'css', type: 'jpeg', quality: 50});
      same = last && b.equals(last) ? same + 1 : 0;
      if (same >= 3) return;
      last = b;
      await sleep(200);
    }
  };

  // one chalk line from a to b (a touch drag), logged for the finger
  let trail = [];
  // (few moves: the game does a lot of work per move, and joins them with chalk anyway)
  const drag = async ([x0, y0], [x1, y1], ms = 140) => {
    const n = Math.max(2, Math.min(4, Math.round(Math.hypot(x1 - x0, y1 - y0) / 45)));
    await cdp.send('Input.dispatchTouchEvent', {type: 'touchStart', touchPoints: [{x: x0, y: y0}]});
    trail.push([+now().toFixed(3), x0, y0]);
    for (let i = 1; i <= n; i++) {
      const x = x0 + ((x1 - x0) * i) / n;
      const y = y0 + ((y1 - y0) * i) / n;
      await cdp.send('Input.dispatchTouchEvent', {type: 'touchMove', touchPoints: [{x, y}]});
      trail.push([+now().toFixed(3), +x.toFixed(1), +y.toFixed(1)]);
      if (ms > 0) await sleep(ms / n);
    }
    await cdp.send('Input.dispatchTouchEvent', {type: 'touchEnd', touchPoints: []});
  };

  let letter = null; // the current board's find_hollow result
  let row = 0; // next chalk row on this board
  const newBoard = async () => {
    await boardStill();
    letter = await detect();
    row = 0;
    if (!letter.bbox) throw new Error('writing: no letter found on the board');
    console.log(`    letter at ${letter.bbox.map(Math.round).join(',')}, ${letter.rows.length} rows`);
  };
  // colour the letter until `stop` says so: rows, then columns (corners the rows miss), then rows in between
  const jobs = () => [
    ...letter.rows.map(([a, b, y]) => [[a, y], [b, y]]),
    ...letter.cols.map(([a, b, x]) => [[x, a], [x, b]]),
    ...letter.rows.map(([a, b, y]) => [[a, y + rowStep / 2], [b, y + rowStep / 2]]),
  ];
  const fill = async (stop) => {
    const list = jobs();
    while (row < list.length) {
      const [p0, p1] = list[row++];
      if (process.env.TUT_DEBUG) console.log(`      job ${row}/${list.length} t=${now().toFixed(2)}`);
      await drag(p0, p1, 0);
      if (await stop()) return true;
    }
    return stop();
  };

  const actions = [];
  const tCss = (r) => r.map((v) => +v.toFixed(1));
  for (const a of step.actions ?? []) {
    const ev = {do: a.do, what: a.what, t: +now().toFixed(3)};
    if (!(a.do === 'show' && a.what === 'capital')) since = Date.now(); // (the capital waits for the pass of the action before)
    if (a.do === 'show' && (a.what === 'demo' || a.what === 'capital')) {
      if (a.what === 'capital') {
        // the board passes, the capital board comes up, its demo plays
        const end = Date.now() + 12000;
        while (Date.now() < end && !(await said(SAID.passed))) await sleep(200);
        await sleep(2600);
        ev.t = +now().toFixed(3);
      }
      await newBoard();
      ev.rect = tCss(letter.bbox);
    } else if (a.do === 'tap') {
      let r;
      if (a.what === 'color') {
        const sticks = (await nodes()).filter((n) => !n.label && Math.abs(n.r[2] - 38) < 4 && Math.abs(n.r[3] - 31) < 4 && n.r[1] > VIEW.height * 0.6);
        sticks.sort((p, q) => p.r[1] - q.r[1] || p.r[0] - q.r[0]);
        r = sticks[a.pick ?? 0]?.r;
      } else {
        r = (await find(new RegExp(a.find)))?.r;
      }
      if (!r) throw new Error(`writing: ${a.what} not found on screen`);
      ev.rect = tCss(r);
      ev.point = tCss([r[0] + r[2] / 2, r[1] + r[3] / 2]);
      ev.t = +now().toFixed(3);
      await page.touchscreen.tap(...ev.point);
      await sleep(a.after ?? 700);
    } else if (a.do === 'draw') {
      trail = [];
      ev.t = +now().toFixed(3);
      if (a.what === 'mess') {
        // scribble outside the letter until the brother warns: inside its holes first,
        // then on the empty board under and over it
        const [lx, ly, lw, lh] = letter.bbox;
        const x0 = Math.max(BOARD.x + 16, lx + lw * 0.1);
        const x1 = Math.min(BOARD.x + BOARD.w - 16, lx + lw * 0.9);
        const bands = [];
        for (let y = ly + lh + 16; y < BOARD.y + BOARD.h - 10; y += rowStep) bands.push([x0, x1, y]);
        for (let y = ly - 16; y > BOARD.y + 10; y -= rowStep) bands.push([x0, x1, y]);
        const scribbles = [...letter.holes, ...bands];
        const used = [];
        for (const [a0, a1, y] of scribbles) {
          if (await said(SAID.warn)) break;
          await drag([a0, y], [a1, y + rowStep * 0.3], 0);
          used.push([Math.min(a0, a1), y]);
          used.push([Math.max(a0, a1), y]);
        }
        if (!(await said(SAID.warn))) console.log('    ! no warning after the scribble');
        const xs = used.map((u) => u[0]);
        const ys = used.map((u) => u[1]);
        ev.rect = tCss([Math.min(...xs) - 14, Math.min(...ys) - 14, Math.max(...xs) - Math.min(...xs) + 28, Math.max(...ys) - Math.min(...ys) + 28]);
        ev.meter = MESS_BAR;
        ev.t1Draw = +now().toFixed(3);
        await sleep(a.after ?? 1500); // the brother's warning
        ev.ok = false;
      } else {
        const until = SAID[a.until ?? 'passed'];
        const ok = await fill(() => said(until));
        if (!ok) console.log(`    ! the board didn't say "${a.until}"`);
        ev.rect = tCss(letter.bbox);
        ev.meter = FILL_BAR;
        ev.t1Draw = +now().toFixed(3);
        await sleep(a.after ?? 900);
      }
      ev.path = trail;
      ev.point = trail.length ? [trail[0][1], trail[0][2]] : null;
    }
    ev.t1 = +now().toFixed(3);
    console.log(`    ${a.do} ${a.what ?? ''} t=${ev.t}→${ev.t1}${ev.path ? ` ${ev.path.length} pts` : ''}`);
    actions.push(ev);
  }
  const shownEnd = now();

  // colour the rest (the capital) off camera until the pass card shows
  let finish = null;
  if (step.finish) {
    const end = Date.now() + (step.finishTimeout ?? 120) * 1000;
    const card = async () => (await nodes()).find((n) => /شارك الرسمة|Share/.test(n.label));
    since = Date.now();
    while (Date.now() < end) {
      if (await card()) break;
      await fill(async () => !!(await card()) || (await said(SAID.passed)));
      if (await said(SAID.passed)) {
        // (only if the small board was still on: now the capital)
        since = Date.now();
        await sleep(2600);
        await newBoard();
      } else if (!(await card())) row = 0; // all done and not passed yet: go over it again
      await sleep(400);
    }
    const end2 = Date.now() + 10000;
    while (Date.now() < end2 && !(await card())) await sleep(200);
    await sleep(1500); // let it pop in
    const rect = await resultCard(page);
    if (rect) {
      const share = await card();
      finish = {t: +now().toFixed(3), rect, share: share ? tCss(share.r) : null};
      console.log(`    pass card at ${rect.map(Math.round).join(',')}`);
    } else console.log('    ! no pass card');
    await sleep(1000);
  }
  fs.rmSync(shot, {force: true});
  return {actions, shownEnd: +shownEnd.toFixed(3), finish};
}

// the pass card's box: the smallest node holding the share button that isn't the whole screen
async function resultCard(page) {
  return page.evaluate(() => {
    const els = [...document.querySelectorAll('flt-semantics')];
    const btn = els.find((e) => /شارك الرسمة|Share/.test(e.textContent ?? '') && !e.querySelector('flt-semantics'));
    if (!btn) return null;
    const b = btn.getBoundingClientRect();
    let best = null;
    for (const e of els) {
      const r = e.getBoundingClientRect();
      if (r.width < 100 || r.height > window.innerHeight * 0.92) continue;
      if (r.left <= b.left && r.right >= b.right && r.top <= b.top && r.bottom >= b.bottom && r.height > b.height * 3 && (!best || r.width * r.height < best[2] * best[3])) best = [r.x, r.y, r.width, r.height];
    }
    return best ?? [16, Math.max(0, b.y - 420), 358, b.height + 560];
  });
}
