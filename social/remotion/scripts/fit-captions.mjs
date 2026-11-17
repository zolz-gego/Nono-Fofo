// Checks that every subtitle shows as ONE line: each chunk's Arabic (62 px,
// weight 800, 18 px word gaps) and its English (40 px, weight 700) must fit the
// caption box (790 px), measured in Chromium with the real fonts.
//
//   npm run captions -- <video-or-tutorial id> [--large]
//
// Reads social/videos/<id>/video.json or social/tutorials/<id>/tutorial.json,
// finds every line ({id, ar, en}), and prints each chunk with its widths.
// Lines that are too long get a suggested `chunks` split (Arabic breaks,
// preferring commas / "..."); write the English for each chunk yourself.
// Exits 1 if anything overflows.
import fs from 'fs';
import path from 'path';
import {fileURLToPath} from 'url';
import {chromium} from 'playwright';

const here = path.dirname(fileURLToPath(import.meta.url));
const SOCIAL = path.resolve(here, '..', '..');
const FONTS = path.join(SOCIAL, 'remotion', 'public', 'app', 'fonts');
const id = process.argv[2];
const large = process.argv.includes('--large');
const MAX = large ? 860 - 68 - 12 : 860 - 56 - 12; // SAFE width − padding − border
if (!id) {
  console.error('usage: npm run captions -- <video-or-tutorial id> [--large]');
  process.exit(2);
}
const file = [path.join(SOCIAL, 'videos', id, 'video.json'), path.join(SOCIAL, 'tutorials', id, 'tutorial.json')].find((f) => fs.existsSync(f));
if (!file) {
  console.error(`no video.json or tutorial.json for "${id}"`);
  process.exit(2);
}
const lines = [];
const walk = (o) => {
  if (Array.isArray(o)) return o.forEach(walk);
  if (!o || typeof o !== 'object') return;
  if (typeof o.id === 'string' && typeof o.ar === 'string' && typeof o.en === 'string') lines.push(o);
  Object.values(o).forEach(walk);
};
walk(JSON.parse(fs.readFileSync(file, 'utf8')));

const browser = await chromium.launch();
const page = await browser.newPage();
const ar = large ? 76 : 62;
const en = large ? 50 : 40;
await page.setContent(`<style>
@font-face{font-family:A;src:url(file://${FONTS}/BalooBhaijaan2.ttf);font-weight:400 800}
@font-face{font-family:E;src:url(file://${FONTS}/Baloo2.ttf);font-weight:400 800}
.a{font:800 ${ar}px A;white-space:nowrap;display:inline-flex;gap:0 18px}.e{font:700 ${en}px E;white-space:nowrap;display:inline-block}
</style><body></body>`);
await page.evaluate(() => document.fonts.ready);
const report = await page.evaluate(({lines, MAX}) => {
  const box = document.createElement('div');
  document.body.append(box);
  const arW = (words) => {
    box.innerHTML = `<div class="a" dir="rtl">${words.map((w) => `<span>${w}</span>`).join('')}</div>`;
    return Math.ceil(box.firstChild.getBoundingClientRect().width);
  };
  const enW = (t) => {
    box.innerHTML = `<div class="e"></div>`;
    box.firstChild.textContent = t;
    return Math.ceil(box.firstChild.getBoundingClientRect().width);
  };
  return lines.map((l) => {
    const words = l.ar.split(/\s+/).filter(Boolean);
    const chunks = l.chunks ?? [{from: 0, en: l.en}];
    const rows = chunks.map((c, i) => {
      const part = words.slice(c.from, chunks[i + 1]?.from ?? words.length);
      return {ar: part.join(' '), en: c.en, arW: arW(part), enW: enW(c.en)};
    });
    // greedy split: fill a chunk up to MAX, then go back to its last comma / "..." if there is one
    let suggest = null;
    if (rows.some((r) => r.arW > MAX)) {
      suggest = [];
      let from = 0;
      while (from < words.length) {
        let to = from + 1;
        while (to < words.length && arW(words.slice(from, to + 1)) <= MAX) to++;
        if (to < words.length) {
          for (let k = to; k > from + 1; k--) if (/[،,.!?؟…]$|\.\.\.$/.test(words[k - 1])) { to = k; break; }
        }
        suggest.push({from, ar: words.slice(from, to).join(' ')});
        from = to;
      }
    }
    return {id: l.id, rows, suggest};
  });
}, {lines, MAX});
await browser.close();

let bad = 0;
for (const l of report) {
  for (const r of l.rows) {
    const over = r.arW > MAX || r.enW > MAX;
    if (over) bad++;
    console.log(`${over ? '!!' : 'ok'} ${l.id.padEnd(14)} ar ${String(r.arW).padStart(4)}  en ${String(r.enW).padStart(4)}  ${r.ar} | ${r.en}`);
  }
  if (l.suggest) console.log(`   suggest "chunks" for ${l.id}: ${l.suggest.map((s) => `{from: ${s.from}} ${s.ar}`).join('  /  ')}`);
}
console.log(bad ? `\n${bad} subtitle(s) wider than one line (${MAX} px).` : `\nall subtitles fit on one line (${MAX} px).`);
process.exit(bad ? 1 : 0);
