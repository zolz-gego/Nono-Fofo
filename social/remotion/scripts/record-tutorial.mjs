// Records a website tutorial as a phone: npm run record -- <tutorial-folder>
//
// Reads social/tutorials/<folder>/tutorial.json, opens the live site in a
// phone-sized Chromium (390×844 CSS px, 3× pixels, touch), runs its "steps"
// (tap / type / scroll / show / play) and saves:
//   recording/frames/NNNNN.jpg  every screen change (CDP screencast, 1170×2532)
//   recording/recording.json    frame times + for every step its time, the
//                               element's box and the tap point (CSS px)
// The Remotion composition (t<folder>) replays these frames at any speed,
// freezes on a step while the voice explains it, zooms and highlights.
//
// Flutter draws on a canvas, so buttons are found through its accessibility
// tree (flt-semantics nodes, turned on by clicking the hidden placeholder).
// "find" is a regex matched against a node's label + text. Games drawn with
// Flame (fish, balloons…) have no nodes: a player in tutorial-games/ finds
// their targets in screenshots.
import {spawn} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import {fileURLToPath} from 'node:url';
import {chromium} from 'playwright';

const REMOTION = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SOCIAL = path.dirname(REMOTION);
const ROOT = path.dirname(SOCIAL);
const id = process.argv[2];
if (!id) {
  console.error('usage: npm run record -- <tutorial-folder>   (social/tutorials/<folder>/tutorial.json)');
  process.exit(1);
}
const DIR = path.join(SOCIAL, 'tutorials', id);
const spec = JSON.parse(fs.readFileSync(path.join(DIR, 'tutorial.json'), 'utf8'));
const OUT = path.join(DIR, 'recording');
const FRAMES = path.join(OUT, 'frames');
fs.rmSync(OUT, {recursive: true, force: true});
fs.mkdirSync(FRAMES, {recursive: true});

export const VIEW = {width: 390, height: 844};
const DPR = 3;
const SETTLE = spec.settle ?? 700; // ms of calm before each step, so its freeze frame is clean

const browser = await chromium.launch();
const ctx = await browser.newContext({viewport: VIEW, deviceScaleFactor: DPR, isMobile: true, hasTouch: true, locale: spec.locale ?? 'ar-EG'});
const page = await ctx.newPage();
const sleep = (ms) => page.waitForTimeout(ms);
console.log(`opening ${spec.site}`);
await page.goto(spec.site, {waitUntil: 'networkidle'});
await page.waitForSelector('flt-semantics-placeholder', {state: 'attached', timeout: 60000});
await sleep(3500);
await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
await sleep(1200);

// ---------------------------------------------------------------- screencast
const cdp = await ctx.newCDPSession(page);
const frames = [];
let t0 = null; // wall-clock seconds of the first frame
const now = () => Date.now() / 1000 - t0;
cdp.on('Page.screencastFrame', async ({data, metadata, sessionId}) => {
  cdp.send('Page.screencastFrameAck', {sessionId}).catch(() => {});
  if (t0 === null) t0 = metadata.timestamp;
  const file = `${String(frames.length).padStart(5, '0')}.jpg`;
  frames.push({t: +(metadata.timestamp - t0).toFixed(3), file});
  fs.writeFileSync(path.join(FRAMES, file), Buffer.from(data, 'base64'));
});
await cdp.send('Page.startScreencast', {format: 'jpeg', quality: 88, maxWidth: VIEW.width * DPR, maxHeight: VIEW.height * DPR, everyNthFrame: 1});
while (t0 === null) await sleep(50);
// Flutter only repaints on change; a still page sends no frames. Nudge a
// 1px invisible element so the screencast keeps ticking (smooth playback).
await page.evaluate(() => {
  const d = document.createElement('div');
  d.style.cssText = 'position:fixed;left:0;top:0;width:1px;height:1px;opacity:0.01;pointer-events:none;z-index:99999';
  document.body.appendChild(d);
  let on = false;
  setInterval(() => { on = !on; d.style.background = on ? '#000' : '#fff'; }, 33);
});
await sleep(800);

// ---------------------------------------------------------------- helpers
const nodes = () =>
  page.evaluate(() =>
    [...document.querySelectorAll('flt-semantics')].map((e) => {
      const r = e.getBoundingClientRect();
      return {label: `${e.getAttribute('aria-label') ?? ''} ${e.childElementCount ? '' : e.textContent}`.replace(/\s+/g, ' ').trim(), role: e.getAttribute('role'), r: [r.x, r.y, r.width, r.height]};
    }).filter((n) => n.r[2] > 0 && n.r[3] > 0),
  );
async function find(re, {visible = true} = {}) {
  const all = (await nodes()).filter((n) => re.test(n.label));
  const seen = all.filter((n) => !visible || (n.r[1] >= 0 && n.r[1] + n.r[3] <= VIEW.height));
  return seen.at(-1) ?? null;
}
async function waitFind(re, ms = 15000) {
  const end = Date.now() + ms;
  while (Date.now() < end) {
    const n = await find(re);
    if (n) return n;
    await sleep(200);
  }
  throw new Error(`not found on screen: ${re}`);
}
const center = (r) => [r[0] + r[2] / 2, r[1] + r[3] / 2];
const round = (a) => a.map((v) => +v.toFixed(1));

// a finger swipe (touch drag) with a natural fling; dy > 0 scrolls down
async function swipe(dy, x = VIEW.width / 2, ms = 380) {
  const y0 = dy > 0 ? 640 : 260;
  const steps = Math.max(8, Math.round(ms / 16));
  await cdp.send('Input.dispatchTouchEvent', {type: 'touchStart', touchPoints: [{x, y: y0}]});
  for (let i = 1; i <= steps; i++) {
    const k = i / steps;
    const e = 1 - (1 - k) * (1 - k);
    await cdp.send('Input.dispatchTouchEvent', {type: 'touchMove', touchPoints: [{x, y: y0 - dy * e}]});
    await sleep(ms / steps);
  }
  await cdp.send('Input.dispatchTouchEvent', {type: 'touchEnd', touchPoints: []});
}

// wait until the screen stops changing (pages fade in, fonts and images load);
// gives up after `max` ms (some pages always move, e.g. a game)
async function waitStable(max = 5000) {
  const end = Date.now() + max;
  let last = null;
  let same = 0;
  while (Date.now() < end) {
    const b = await page.screenshot({clip: {x: 0, y: 4, width: VIEW.width, height: VIEW.height - 4}, scale: 'css', type: 'jpeg', quality: 40});
    same = last && b.equals(last) ? same + 1 : 0;
    if (same >= 2) return;
    last = b;
    await sleep(150);
  }
}

const log = [];
const ctxObj = {page, cdp, sleep, now, find, waitFind, nodes, center, round, VIEW, DPR, ROOT, spec};

// ---------------------------------------------------------------- steps
for (const step of spec.steps) {
  if (step.do !== 'play' && step.do !== 'scroll') await waitStable(step.stable ?? 5000);
  await sleep(step.settle ?? SETTLE);
  const ev = {id: step.id, do: step.do, t0: +now().toFixed(3)};
  const re = step.find ? new RegExp(step.find) : null;
  if (step.do === 'show' || step.do === 'tap') {
    const n = await waitFind(re);
    ev.rect = round(n.r);
    ev.point = round(center(n.r));
    ev.t = +now().toFixed(3);
    if (step.do === 'tap') await page.touchscreen.tap(...ev.point);
    else await sleep(step.hold ?? 600);
  } else if (step.do === 'scroll') {
    // swipe until the target sits in the upper-middle of the screen
    for (let i = 0; i < 20; i++) {
      const all = (await nodes()).filter((n) => re.test(n.label));
      const n = all.at(-1);
      const cy = n ? n.r[1] + n.r[3] / 2 : Infinity;
      const goal = step.goal ?? 0.45 * VIEW.height;
      if (n && Math.abs(cy - goal) < 90) break;
      const dy = n ? Math.max(-380, Math.min(380, cy - goal)) : 380;
      await swipe(dy);
      await sleep(650);
    }
    ev.t = +now().toFixed(3);
    const n = await waitFind(re);
    ev.rect = round(n.r);
  } else if (step.do === 'type') {
    // Flutter's text field is a real <input> while focused
    const r = await page.evaluate(() => {
      const e = document.querySelector('input, textarea');
      if (!e) return null;
      const b = e.getBoundingClientRect();
      return [b.x, b.y, b.width, b.height];
    });
    let rect = r && r[2] > 4 ? r : null;
    if (!rect && step.near) {
      const n = await waitFind(new RegExp(step.near));
      rect = [n.r[0], n.r[1] + n.r[3] + 8, n.r[2], 52];
    }
    if (step.rect) rect = step.rect;
    ev.rect = rect ? round(rect) : null;
    ev.t = +now().toFixed(3);
    ev.keys = [];
    for (const ch of step.text) {
      ev.keys.push(+now().toFixed(3));
      await page.keyboard.type(ch);
      await sleep(step.delay ?? 220);
    }
  } else if (step.do === 'wait') {
    ev.t = +now().toFixed(3);
    await sleep(step.ms ?? 1000);
  } else if (step.do === 'play') {
    const game = await import(`./tutorial-games/${step.game}.mjs`);
    ev.t = +now().toFixed(3);
    Object.assign(ev, await game.play(ctxObj, step));
  } else {
    throw new Error(`unknown step "${step.do}" (${step.id})`);
  }
  ev.t1 = +now().toFixed(3);
  console.log(`  ${step.id.padEnd(10)} ${step.do.padEnd(6)} t=${ev.t}s ${ev.rect ? `box ${ev.rect.join(',')}` : ''}${ev.taps ? ` ${ev.taps.length} taps` : ''}`);
  log.push(ev);
}
await sleep(spec.tail ?? 1500);
const end = +now().toFixed(3);
await cdp.send('Page.stopScreencast');
await sleep(300);
await browser.close();

fs.writeFileSync(
  path.join(OUT, 'recording.json'),
  JSON.stringify({site: spec.site, viewport: VIEW, dpr: DPR, recorded: new Date().toISOString(), end, steps: log, frames}, null, 1),
);
console.log(`recorded ${end.toFixed(1)}s, ${frames.length} frames -> ${path.relative(ROOT, OUT)}`);
