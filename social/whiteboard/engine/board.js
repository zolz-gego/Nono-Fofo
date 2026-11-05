// Whiteboard letter video engine for HyperFrames (plain JS, no build step).
// See the whiteboard-letter skill.
//
// The board is a grid of portrait panels (each one screen, 1080×1920)
//   row 0: [letter]  [facts]
//   row 1: [Arabic words] [Coptic words]
//   row 2:      [end card]
// a marker (no hand) writes the text and traces the drawings while the camera
// pans panel to panel, zooms out for the recap and drops to the end card.
//
// Timing never depends on measured text, so tools/build.mjs runs
// buildBoard in Node (fake widths) to place the audio clips, and the scene runs
// it again in the browser (real widths) to place the ink: both agree on time.
(function (root) {
  const PANEL_W = 1080;
  const PANEL_H = 1920;
  const INK = '#1f2328';
  const GRAPHITE = '#6b7078'; // pencil notes (e.g. the Arabic sound under each Coptic letter)
  const RED = '#d63b32';
  const BLUE = '#2459c9';
  const PAN = 0.9; // camera move between panels (s)
  const GAP = 0.15; // pen lift between two items (s)
  const PAD = 0.45; // after a beat (s)
  const PAUSE = 1.3; // empty moment before the recap and before the end card (s)
  const FONTS = {ar: 'BalooBhaijaan2', en: 'Baloo2', cop: 'AvvaShenouda'};
  const WEIGHT = {ar: 700, en: 700, cop: 400};

  // The path data of an icon body (every <path d>; Tabler icons also use lines, circles and rects).
  function iconPath(icon) {
    const ds = [];
    // shapes inside <defs> (clip paths, masks) are not drawn
    const body = icon.body.replace(/<defs>[\s\S]*?<\/defs>/g, '').replace(/<(clipPath|mask)\b[\s\S]*?<\/\1>/g, '');
    for (const m of body.matchAll(/<(path|line|circle|rect|ellipse|polyline|polygon)\b([^>]*)>/g)) {
      const a = Object.fromEntries([...m[2].matchAll(/([\w-]+)="([^"]*)"/g)].map((x) => [x[1], x[2]]));
      const n = (k) => Number(a[k] ?? 0);
      // a path's first "m" is absolute; once joined after another path it would turn relative
      if (m[1] === 'path') ds.push(a.d.trim().replace(/^m/, 'M'));
      else if (m[1] === 'line') ds.push(`M${n('x1')} ${n('y1')}L${n('x2')} ${n('y2')}`);
      else if (m[1] === 'circle' || m[1] === 'ellipse') {
        const rx = n('r') || n('rx');
        const ry = n('r') || n('ry');
        ds.push(`M${n('cx') - rx} ${n('cy')}a${rx} ${ry} 0 1 0 ${rx * 2} 0a${rx} ${ry} 0 1 0 ${-rx * 2} 0`);
      } else if (m[1] === 'rect') ds.push(`M${n('x')} ${n('y')}h${n('width')}v${n('height')}h${-n('width')}z`);
      else ds.push(`M${a.points}${m[1] === 'polygon' ? 'z' : ''}`);
    }
    return ds.join(' ');
  }

  // env: {width(text, script, size), pathLen(d)}; data: see tools/build.mjs
  function buildBoard(data, env) {
    const items = [];
    const ops = [];
    const clips = [];
    const beats = []; // per say: when its camera move starts, its voice and its drawing (release tool: story cut)
    const cams = [];
    const cues = [];
    const rtl = data.lang === 'ar';
    const take = data.take;

    let cursor = 0;
    let line = {i: 0, say: '', a0: 0, t: 0}; // the beat being drawn
    const piece = (say) => {
      const i = take.text.indexOf(say, cursor);
      if (i < 0) throw new Error(`"${say}" is not in the take (re-run social/whiteboard/tools/split.py after editing a say)`);
      cursor = i + say.length;
      return [take.start[i], take.end[i + say.length - 1], i];
    };
    // Board time when the narrator says character `c` of the current line.
    const saidAt = (c) => line.t + take.start[line.i + Math.min(c, line.say.length - 1)] - line.a0;
    // The pen waits until the narrator reaches `sub` (its k-th match) in the current line.
    const waitFor = (sub, k = 0, lead = 0.1) => {
      let c = -1;
      for (let n = 0; n <= k; n++) c = line.say.indexOf(sub, c + 1);
      if (c < 0) throw new Error(`"${sub}" is not in the line "${line.say}"`);
      drawAt = Math.max(drawAt, saidAt(c) - lead);
    };
    // Spelling: the k-th letter is written when the narrator starts naming it,
    // i.e. at the phrase holding the k-th "بيقول" (after the "..." or ":" before it).
    const waitForLetter = (k) => {
      let c = -1;
      for (let n = 0; n <= k; n++) c = line.say.indexOf('بيقول', c + 1);
      if (c < 0) return;
      const before = line.say.slice(0, c);
      let from = Math.max(before.lastIndexOf('...') + 3, before.lastIndexOf(':') + 1, 0);
      while (line.say[from] === ' ') from++;
      drawAt = Math.max(drawAt, saidAt(from) - 0.05);
    };

    let t = 0.15; // beat clock
    let drawAt = 0; // next free moment for the pen
    const addOp = (op) => {
      const start = drawAt;
      ops.push({...op, start});
      drawAt = start + op.dur + GAP;
      return ops.length - 1;
    };

    // Text centred on (cx, cy); `max` shrinks it to fit a width. `mark` = Avva key drawn in red.
    const text = (s, script, size, cx, cy, color = INK, opts = {}) => {
      const dur = opts.dur ?? Math.min(1.8, 0.4 + 0.07 * s.length * Math.sqrt(size / 100));
      let w = env.width(s, script, size);
      if (opts.max && w > opts.max) {
        size *= opts.max / w;
        w = opts.max;
      }
      const h = size * 1.25;
      const dir = script === 'ar' ? 'rtl' : 'ltr';
      const spans = opts.mark ? [...s].map((c) => ({text: c, color: c === opts.mark ? RED : color})) : [{text: s, color}];
      const op = addOp({kind: 'text', x: cx - w / 2, y: cy - h / 2, w, h, dir, chars: s.length, dur, tool: opts.tool ?? 'marker'});
      items.push({kind: 'text', op, x: cx - w / 2, y: cy - h / 2, w, h, font: FONTS[script], size, weight: WEIGHT[script], dir, spans});
      return {x: cx - w / 2, y: cy - h / 2, w, h};
    };

    const stroke = (d, color, w, dur) => {
      const op = addOp({kind: 'path', d, len: env.pathLen(d), ox: 0, oy: 0, scale: 1, dur, tool: 'marker'});
      items.push({kind: 'stroke', op, d, color, width: w});
    };

    const icon = (id, x, y, size) => {
      const ic = data.icons[id];
      if (!ic) return;
      const d = iconPath(ic);
      const scale = size / ic.size;
      const op = addOp({kind: 'path', d, len: env.pathLen(d), ox: x, oy: y, scale, dur: 1.8, tool: 'marker'});
      items.push({kind: 'icon', op, x, y, size, icon: ic, d});
    };

    // A wobbly hand-drawn underline from x0 to x1 at y.
    const underline = (x0, x1, y) => stroke(`M${rtl ? x1 : x0} ${y} Q${(x0 + x1) / 2} ${y + 14} ${rtl ? x0 : x1} ${y - 4}`, RED, 9, 0.35);

    let panel = '';
    // Panels in board order: letter, facts, then one per word section, or with
    // `screens: true` one per word (+ one for the section's note). 2 columns for
    // up to 4 panels, else 3; the end card sits centred under them.
    const names = ['letter', 'facts'];
    data.sections.forEach((sec, si) => {
      if (!sec.screens) names.push(`s${si}`);
      else {
        sec.words.forEach((_, wi) => names.push(`s${si}w${wi}`));
        if (sec.note) names.push(`s${si}n`);
      }
    });
    const COLS = names.length <= 4 ? 2 : 3;
    const ROWS = Math.ceil(names.length / COLS);
    const P = Object.fromEntries(names.map((n, i) => [n, {x: (i % COLS) * PANEL_W, y: Math.floor(i / COLS) * PANEL_H}]));
    P.end = {x: ((COLS - 1) * PANEL_W) / 2, y: ROWS * PANEL_H};
    const BOARD_W = COLS * PANEL_W;
    const BOARD_H = (ROWS + 1) * PANEL_H;
    // the recap view shows every panel, its top at y 150 and its bottom above the caption (~1560)
    const allS = COLS === 2 ? 0.37 : Math.min(1080 / BOARD_W, 1390 / (ROWS * PANEL_H));
    const camOf = (p) => (p === 'all' ? {cx: BOARD_W / 2, cy: 810 / allS, s: allS} : {cx: P[p].x + PANEL_W / 2, cy: P[p].y + PANEL_H / 2, s: 1});

    const beat = (say, to, draw) => {
      const camAt = t;
      if (to !== panel) {
        if (panel) {
          cams.push({t, ...camOf(panel)}, {t: t + PAN, ...camOf(to)});
          cues.push({t, sfx: 'mg_whoosh_in', volume: 0.35});
          t += PAN * 0.75;
        } else {
          cams.push({t: 0, ...camOf(to)});
        }
        panel = to;
      }
      const [a0, a1, li] = piece(say);
      line = {i: li, say, a0, t};
      clips.push({from: t, a0, a1});
      drawAt = Math.max(drawAt, t + 0.1);
      const firstOp = ops.length;
      draw(P[to === 'all' ? 'letter' : to]);
      const mine = ops.slice(firstOp);
      beats.push({say, cam: to === panel && camAt === t ? null : camAt, voice: [t, t + a1 - a0], draw: mine.length ? [mine[0].start, mine[mine.length - 1].start + mine[mine.length - 1].dur] : null});
      t = Math.max(t + (a1 - a0), drawAt) + PAD;
    };

    const L = data.letter;
    const [say1, say2, say3] = data.intro.say;
    const AR = rtl ? 'ar' : 'en';
    let letterBox = {x: 0, y: 0, w: 0, h: 0};
    const hue = (c) => (c === 'red' ? RED : c === 'blue' ? BLUE : INK);

    // One fact row: its parts side by side in reading order, plus any box / bar.
    // `join`: no gap before this part (e.g. one letter of a word in another colour);
    // `at`: the pen waits for these words in the narration; rows wider than `maxW` shrink.
    const factRow = (parts, size, cx, cy, maxW = 940) => {
      const measure = (sz) => {
        const ws = parts.map((p) => env.width(p.t, p.s, sz));
        const gaps = parts.map((p, i) => (i && !p.join ? sz * 0.4 : 0));
        return {ws, gaps, total: ws.reduce((a, b) => a + b, 0) + gaps.reduce((a, b) => a + b, 0)};
      };
      let m = measure(size);
      if (m.total > maxW) {
        size *= maxW / m.total;
        m = measure(size);
      }
      const {ws, gaps, total} = m;
      const rl = rtl && !parts.some((p) => p.join); // a row with joined parts is one Latin word: left to right
      let edge = rl ? cx + total / 2 : cx - total / 2;
      parts.forEach((p, i) => {
        edge += (rl ? -1 : 1) * gaps[i];
        if (p.at) waitFor(p.at);
        const c = rl ? edge - ws[i] / 2 : edge + ws[i] / 2;
        const b = text(p.t, p.s, size, c, cy, hue(p.c), p.mark ? {mark: L.small} : {});
        if (p.box) {
          const [x0, y0, x1, y1] = [b.x - 30, b.y - 6, b.x + b.w + 30, b.y + b.h + 6];
          stroke(`M${x1} ${y0 + 8} L${x0 + 4} ${y0} L${x0} ${y1} L${x1 - 4} ${y1 + 4} L${x1 + 6} ${y0 - 6}`, RED, 9, 0.9);
        }
        if (p.over) stroke(`M${b.x + b.w * 0.1} ${b.y + b.h * 0.12} L${b.x + b.w * 0.9} ${b.y + b.h * 0.1}`, RED, 12, 0.4);
        edge += (rl ? -1 : 1) * ws[i];
      });
    };

    // How to write the letter by hand: each stroke in ink (in time with its `at`),
    // its number in red at the start and a red arrowhead at the end.
    // hand: {box: [w, h], strokes: [{d, at?, num: [x, y], head: d}]}, coordinates in the box.
    const handRows = (hand, scale, cx, y) => {
      const [bw, bh] = hand.box;
      const ox = cx - (bw * scale) / 2;
      const map = (d) => d.replace(/(-?\d+(?:\.\d+)?)\s*[ ,]\s*(-?\d+(?:\.\d+)?)/g, (_, x, yy) => `${(ox + x * scale).toFixed(1)} ${(y + yy * scale).toFixed(1)}`);
      hand.strokes.forEach((st, i) => {
        if (st.at) waitFor(st.at);
        if (st.num) text(String(i + 1).replace(/\d/g, (n) => '٠١٢٣٤٥٦٧٨٩'[n]), 'ar', 70 * scale, ox + st.num[0] * scale, y + st.num[1] * scale, RED, {dur: 0.3});
        stroke(map(st.d), INK, 26 * scale, st.dur ?? 1.1);
        if (st.head) stroke(map(st.head), RED, 10 * scale, 0.3);
      });
      return y + bh * scale;
    };
    const factRows = (f, x, y) => {
      const size = f.size ?? 120;
      if (f.hand) return handRows(f.hand, f.hand.scale ?? 1, x, y);
      f.rows.forEach((r, i) => factRow(r, size, x, y + i * size * 1.45 + size * 0.6));
      return y + f.rows.length * size * 1.45;
    };

    // the letter: capital first (the hook), then its name, its rank, its two forms
    beat(say1, 'letter', (o) => {
      letterBox = text(L.capital, 'cop', 480, o.x + 310, o.y + 540, INK, {dur: 1.6});
      const n = text(rtl ? L.name.ar : L.name.en, AR, 170, o.x + 520, o.y + 1080);
      underline(n.x - 10, n.x + n.w + 10, n.y + n.h - 6);
    });
    beat(say2, 'letter', (o) => {
      text(data.intro.rank, AR, 90, o.x + 520, o.y + 1260, BLUE);
    });
    beat(say3, 'letter', (o) => {
      text(data.intro.capital, AR, 72, o.x + 310, o.y + 860, BLUE);
      text(L.small, 'cop', 480, o.x + 740, o.y + 540, INK, {dur: 1.3});
      text(data.intro.small, AR, 72, o.x + 740, o.y + 860, BLUE);
    });

    // more about the letter: under its name, then on its own panel, shrunk to stay above the caption
    const onFacts = data.facts.filter((f) => f.panel !== 'letter');
    // a hand-writing fact keeps its own size; the rows shrink around it (and start higher)
    const hasHand = onFacts.some((f) => f.hand);
    const FTOP = hasHand ? 190 : 330;
    const FGAP = hasHand ? 80 : 110;
    const handH = onFacts.reduce((h, f) => h + (f.hand ? f.hand.box[1] * (f.hand.scale ?? 1) : 0), 0);
    const rowsH = onFacts.reduce((h, f) => h + (f.hand ? 0 : f.rows.length * (f.size ?? 120) * 1.45), 0);
    const fit = Math.min(1, (1540 - FTOP - handH - FGAP * (onFacts.length - 1)) / rowsH);
    let factY = FTOP;
    let letterY = 1360;
    for (const f of data.facts) {
      beat(f.say, f.panel === 'letter' ? 'letter' : 'facts', (o) => {
        if (f.panel === 'letter') letterY = factRows(f, o.x + 520, o.y + letterY) + 40;
        else factY = factRows({...f, size: (f.size ?? 120) * fit}, o.x + 500, o.y + factY) + (hasHand ? FGAP : 110 * fit);
      });
    }

    // A Coptic word written letter by letter, each when the narrator names it, with
    // (pencil) the Arabic letter it sounds like under it. Returns the word's box.
    const spelled = (w, size, cx, cy, maxW) => {
      let ws = w.spell.map((k) => env.width(k, 'cop', size));
      let total = ws.reduce((a, b) => a + b, 0);
      if (total > maxW) {
        size *= maxW / total;
        ws = ws.map((x) => (x * maxW) / total);
        total = maxW;
      }
      let x = cx - total / 2;
      w.spell.forEach((k, i) => {
        waitForLetter(i);
        text(k, 'cop', size, x + ws[i] / 2, cy, k === L.small ? RED : INK, {dur: 0.35});
        if (w.sounds && w.sounds[i]) text(w.sounds[i], 'ar', size * 0.42, x + ws[i] / 2, cy + size * 0.78, k === L.small ? RED : GRAPHITE, {dur: 0.3, tool: 'pencil'});
        x += ws[i];
      });
      return {size, total};
    };
    // after the spelling, the narrator says the whole word (after the last "...")
    const waitForWord = () => waitFor('...', (line.say.match(/\.\.\./g) || []).length - 1, -0.1);

    // a word on its own screen: Coptic + pencil sounds on top, drawing, then the Arabic, then the meaning
    const wordScreen = (sec, si, w, wi) => {
      const id = `s${si}w${wi}`;
      const COP_Y = 520;
      const ICON_Y = 960;
      const AR_Y = 1290;
      const MEAN_Y = 1440;
      const IC = 400;
      const pop = () => cues.push({t: drawAt - GAP, sfx: 'mg_keyword_pop', volume: 0.25});
      const drawIcon = (o) => icon(w.icon, o.x + 540 - IC / 2, o.y + ICON_Y - IC / 2, IC);
      if (sec.group === 'ar') {
        beat(w.say, id, (o) => {
          drawIcon(o);
          if (!w.spellSay) text(w.word, 'ar', 150, o.x + 540, o.y + AR_Y, INK, {max: 900});
          pop();
        });
        if (w.spellSay) {
          beat(w.spellSay, id, (o) => {
            spelled(w, 210, o.x + 540, o.y + COP_Y, 900);
            waitForWord();
            text(w.word, 'ar', 150, o.x + 540, o.y + AR_Y, INK, {max: 900});
            pop();
          });
        }
      } else {
        beat(w.say, id, (o) => {
          spelled(w, 210, o.x + 540, o.y + COP_Y, 900);
          waitForWord();
          text(w.ar, 'ar', 140, o.x + 540, o.y + AR_Y, INK, {max: 900});
          if (line.say.includes('يعني')) waitFor('يعني', 0, 0);
          drawIcon(o);
          if (w.meaning) text(w.meaning, 'ar', 110, o.x + 540, o.y + MEAN_Y, BLUE, {max: 900});
          pop();
        });
      }
    };

    // the word sections
    data.sections.forEach((sec, si) => {
      if (sec.screens) {
        beat(sec.say, `s${si}w0`, (o) => {
          const tt = text(sec.title, AR, 110, o.x + 540, o.y + 250, BLUE);
          underline(tt.x - 10, tt.x + tt.w + 10, tt.y + tt.h - 10);
        });
        sec.words.forEach((w, wi) => wordScreen(sec, si, w, wi));
        const note = sec.note;
        if (note) {
          beat(note.say, `s${si}n`, (o) => {
            if (note.title) {
              if (line.say.includes(note.title)) waitFor(note.title);
              const tt = text(note.title, AR, 120, o.x + 540, o.y + 300, BLUE);
              underline(tt.x - 10, tt.x + tt.w + 10, tt.y + tt.h - 10);
            }
            const sz = note.size ?? 130;
            let y = o.y + 960 - ((note.rows.length - 1) * sz * 1.7) / 2;
            note.rows.forEach((r) => {
              factRow(r, sz, o.x + 540, y, 940);
              y += sz * 1.7;
            });
            cues.push({t: drawAt - GAP, sfx: 'mg_keyword_pop', volume: 0.25});
          });
        }
        return;
      }
      const id = `s${si}`;
      beat(sec.say, id, (o) => {
        const tt = text(sec.title, AR, 110, o.x + 500, o.y + 250, BLUE);
        underline(tt.x - 10, tt.x + tt.w + 10, tt.y + tt.h - 10);
      });
      const n = sec.words.length;
      const note = sec.note;
      const noteH = note ? note.rows.length * 135 + 60 : 0;
      const step = Math.min(430, Math.max(330, (1080 - noteH) / n));
      const top = 420 + (note ? 0 : (1080 - step * n) / 2);
      const big = n <= 2 ? 1.15 : 1;
      const cop = {mark: L.small};
      // A Coptic word, written whole, or letter by letter in time with the narrator naming each letter.
      const coptic = (w, size, cx, cy) => {
        if (!w.spell) return text(w.coptic, 'cop', size, cx, cy, INK, {max: 540, ...cop});
        let ws = w.spell.map((k) => env.width(k, 'cop', size));
        let total = ws.reduce((a, b) => a + b, 0);
        if (total > 540) {
          size *= 540 / total;
          ws = ws.map((x) => (x * 540) / total);
          total = 540;
        }
        let x = cx - total / 2;
        w.spell.forEach((k, i) => {
          waitForLetter(i);
          text(k, 'cop', size, x + ws[i] / 2, cy, k === L.small ? RED : INK, {dur: 0.35});
          x += ws[i];
        });
      };
      sec.words.forEach((w, wi) => {
        const cy0 = top + step * (wi + 0.5);
        const cx0 = 640; // text column (x 360–920); the drawing sits on the left
        const ic = 260 * big;
        const pop = () => cues.push({t: drawAt - GAP, sfx: 'mg_keyword_pop', volume: 0.25});
        beat(w.say, id, (o) => {
          const cy = o.y + cy0;
          const cx = o.x + cx0;
          if (sec.group === 'ar') {
            text(w.word, 'ar', 125 * big, cx, cy - 75 * big, INK, {max: 540});
            icon(w.icon, o.x + 215 - ic / 2, cy - ic / 2, ic);
            if (!w.spellSay) coptic(w, 110 * big, cx, cy + 85 * big);
          } else {
            const lift = w.meaning ? 0 : 50;
            coptic(w, 120, cx, cy - 105 + lift);
            if (w.spell) waitFor('...', (line.say.match(/\.\.\./g) || []).length - 1, -0.1);
            text(w.ar, 'ar', 88, cx, cy + 15 + lift, INK, {max: 540});
            icon(w.icon, o.x + 215 - ic / 2, cy - ic / 2, ic);
            if (w.meaning) {
              if (line.say.includes('يعني')) waitFor('يعني', 0, 0);
              text(w.meaning, 'ar', 80, cx, cy + 120, BLUE, {max: 540});
            }
          }
          pop();
        });
        if (sec.group === 'ar' && w.spellSay) {
          beat(w.spellSay, id, (o) => {
            coptic(w, 110 * big, o.x + cx0, o.y + cy0 + 85 * big);
            pop();
          });
        }
      });
      // a closing note under the words (e.g. a church verse with the section's words in it)
      if (note) {
        beat(note.say, id, (o) => {
          let y = o.y + top + step * n + 40;
          note.rows.forEach((r) => {
            factRow(r, 100, o.x + 540, y + 60, 960);
            y += 135;
          });
          cues.push({t: drawAt - GAP, sfx: 'mg_keyword_pop', volume: 0.25});
        });
      }
    });

    // a breath, then the recap: zoom out over the whole board and circle the letter
    t = Math.max(t, drawAt) + PAUSE;
    beat(data.recap.say, 'all', () => {
      const cx = 525;
      const cy = letterBox.y + letterBox.h / 2 + 10;
      const [rx, ry] = [480, 340];
      const pts = Array.from({length: 41}, (_, i) => {
        const a = -Math.PI * 0.6 + (i / 40) * Math.PI * 2.15;
        const k = 1 + 0.04 * Math.sin(i * 0.7);
        return `${(cx + Math.cos(a) * rx * k).toFixed(1)} ${(cy + Math.sin(a) * ry * k).toFixed(1)}`;
      });
      stroke(`M${pts.join(' L')}`, RED, 14, 1.1);
      cues.push({t: drawAt, sfx: 'mg_sparkle', volume: 0.3});
    });

    // another breath, then the end card
    t = Math.max(t, drawAt) + PAUSE;
    beat(data.end.say, 'end', (o) => {
      text(data.end.text, AR, 125, o.x + 500, o.y + 680, INK, {max: 820});
      const op = addOp({kind: 'text', x: o.x + 340, y: o.y + 860, w: 320, h: 320, dir: 'ltr', chars: 6, dur: 0.9});
      items.push({kind: 'image', op, x: o.x + 340, y: o.y + 860, w: 320, h: 320, src: data.logo});
    });

    return {items, ops, clips, beats, cams, cues, size: {w: BOARD_W, h: BOARD_H}, duration: Math.max(t, drawAt) + 1.4};
  }

  // ------------------------------------------------------------ playback (browser)

  const clamp = (x) => Math.min(1, Math.max(0, x));
  const ease = (x) => (x < 0.5 ? 2 * x * x : 1 - (-2 * x + 2) ** 2 / 2);
  const progress = (op, sec) => clamp((sec - op.start) / op.dur);

  function camera(cams, sec) {
    let c = cams[0];
    for (let i = 1; i < cams.length; i++) {
      const a = cams[i - 1];
      const b = cams[i];
      if (sec < b.t) {
        if (sec <= a.t || (a.cx === b.cx && a.cy === b.cy && a.s === b.s)) return a;
        const k = ease((sec - a.t) / (b.t - a.t));
        return {cx: a.cx + (b.cx - a.cx) * k, cy: a.cy + (b.cy - a.cy) * k, s: a.s + (b.s - a.s) * k};
      }
      c = b;
    }
    return c;
  }

  // Where the pen tip is on an op at progress p. Text: sweeps across in reading
  // direction with a quick up-and-down, like handwriting.
  function penOn(op, p, pathAt) {
    if (op.kind === 'text') {
      const x = op.dir === 'rtl' ? op.x + op.w * (1 - p) : op.x + op.w * p;
      const wave = Math.sin(p * Math.PI * 2 * Math.max(2, op.chars * 1.3));
      return {x, y: op.y + op.h * (0.52 + 0.2 * wave)};
    }
    const q = pathAt(op.d, Math.min(op.len, p * op.len));
    return {x: op.ox + q.x * op.scale, y: op.oy + q.y * op.scale};
  }

  // The pen is only on screen while it writes or draws: between beats it fades
  // out where it stopped and back in where it starts next; between two items of
  // one beat it lifts and glides.
  function pen(ops, sec, pathAt) {
    const LIFT = 0.07;
    const HIDE = 0.6;
    const FADE = 0.18;
    for (let i = 0; i < ops.length; i++) {
      const op = ops[i];
      if (sec < op.start) {
        const next = penOn(op, 0, pathAt);
        const free = i > 0 ? ops[i - 1].start + ops[i - 1].dur : -1;
        const gap = op.start - free;
        if (i === 0 || gap > HIDE) {
          const prev = i > 0 ? penOn(ops[i - 1], 1, pathAt) : next;
          const out = i > 0 ? clamp(1 - (sec - free) / FADE) : 0;
          const inn = clamp(1 - (op.start - sec) / FADE);
          return out > 0 ? {...prev, down: 0, show: out, tool: ops[i - 1].tool} : {...next, down: clamp(1 - (op.start - sec) / LIFT), show: inn, tool: op.tool};
        }
        const prev = penOn(ops[i - 1], 1, pathAt);
        const k = ease(clamp((sec - free) / Math.max(gap, 0.01)));
        const edge = Math.min(sec - free, op.start - sec) / LIFT;
        return {x: prev.x + (next.x - prev.x) * k, y: prev.y + (next.y - prev.y) * k, down: Math.max(0, 1 - edge), show: 1, tool: k < 0.5 ? ops[i - 1].tool : op.tool};
      }
      if (sec <= op.start + op.dur) return {...penOn(op, progress(op, sec), pathAt), down: 1, show: 1, tool: op.tool};
    }
    const last = ops[ops.length - 1];
    return {...penOn(last, 1, pathAt), down: 0, show: clamp(1 - (sec - last.start - last.dur) / FADE), tool: last.tool};
  }

  const PEN_SVG =
    '<svg width="90" height="430" viewBox="-45 -420 90 430" style="position:absolute;left:-45px;top:-420px;overflow:visible">' +
    '<path d="M-7 -30 L-3 -2 Q0 4 3 -2 L7 -30 Z" fill="#26282b"/>' +
    '<path d="M-20 -78 L-8 -28 L8 -28 L20 -78 Z" fill="#d9dbde"/><path d="M-20 -78 L-8 -28 L-2 -28 L-10 -78 Z" fill="#f4f5f6"/>' +
    '<rect x="-24" y="-330" width="48" height="256" rx="10" fill="#202225"/><rect x="-17" y="-322" width="9" height="240" rx="4" fill="#4a4d52"/>' +
    '<rect x="-24" y="-250" width="48" height="74" fill="#f2f2ef"/><rect x="-24" y="-236" width="48" height="8" fill="#d63b32"/>' +
    '<rect x="-24" y="-196" width="48" height="8" fill="#d63b32"/><rect x="-22" y="-385" width="44" height="60" rx="14" fill="#2b2d31"/>' +
    '<rect x="-15" y="-380" width="8" height="50" rx="4" fill="#55585e"/></svg>';

  // a wooden pencil (yellow body, sharpened tip, pink eraser), same frame as the marker
  const PENCIL_SVG =
    '<svg width="90" height="430" viewBox="-45 -420 90 430" style="position:absolute;left:-45px;top:-420px;overflow:visible">' +
    '<path d="M-4 -16 L0 0 L4 -16 Z" fill="#3d4046"/>' +
    '<path d="M-16 -62 L-4 -16 L4 -16 L16 -62 Z" fill="#e9c891"/>' +
    '<rect x="-16" y="-340" width="32" height="280" fill="#f5b82e"/><rect x="-16" y="-340" width="10" height="280" fill="#f9cf5f"/><rect x="6" y="-340" width="10" height="280" fill="#dd9a16"/>' +
    '<rect x="-17" y="-372" width="34" height="34" fill="#b9bcc2"/><rect x="-17" y="-364" width="34" height="5" fill="#9a9da3"/><rect x="-17" y="-352" width="34" height="5" fill="#9a9da3"/>' +
    '<rect x="-16" y="-404" width="32" height="34" rx="9" fill="#ef8fa0"/></svg>';

  // Builds the board's DOM inside `stage` and returns render(sec), which sets
  // every element from the time alone (seek-safe: no state carried between frames).
  function mount(stage, data) {
    const NS = 'http://www.w3.org/2000/svg';
    const probe = document.createElementNS(NS, 'path');
    const ctx = document.createElement('canvas').getContext('2d');
    const env = {
      width: (s, script, size) => {
        ctx.font = `${WEIGHT[script]} ${size}px ${FONTS[script]}`;
        ctx.direction = script === 'ar' ? 'rtl' : 'ltr';
        return ctx.measureText(s).width;
      },
      pathLen: (d) => (probe.setAttribute('d', d), probe.getTotalLength()),
    };
    const pathAt = (d, l) => (probe.setAttribute('d', d), probe.getPointAtLength(l));
    const board = buildBoard(data, env);

    const plane = document.createElement('div');
    const {w: BOARD_W, h: BOARD_H} = board.size;
    plane.style.cssText = `position:absolute;left:0;top:0;width:${BOARD_W}px;height:${BOARD_H}px;transform-origin:0 0`;
    stage.appendChild(plane);
    const views = board.items.map((it) => {
      if (it.kind === 'text') {
        const pad = it.h * 0.35;
        const el = document.createElement('div');
        el.style.cssText = `position:absolute;left:${it.x - 30}px;top:${it.y - pad}px;width:${it.w + 60}px;height:${it.h + pad * 2}px;line-height:${it.h + pad * 2}px;text-align:center;white-space:nowrap;direction:${it.dir};font-family:${it.font};font-size:${it.size}px;font-weight:${it.weight};visibility:hidden`;
        el.innerHTML = it.spans.map((s) => `<span style="color:${s.color}">${s.text.replace(/&/g, '&amp;').replace(/</g, '&lt;')}</span>`).join('');
        plane.appendChild(el);
        return (p) => {
          el.style.visibility = p > 0 ? 'visible' : 'hidden';
          const cut = `${((1 - p) * 100).toFixed(2)}%`;
          el.style.clipPath = it.dir === 'rtl' ? `inset(0 0 0 ${cut})` : `inset(0 ${cut} 0 0)`;
        };
      }
      if (it.kind === 'image') {
        const el = document.createElement('img');
        el.src = it.src;
        el.style.cssText = `position:absolute;left:${it.x}px;top:${it.y}px;width:${it.w}px;height:${it.h}px;visibility:hidden`;
        plane.appendChild(el);
        return (p) => {
          el.style.visibility = p > 0 ? 'visible' : 'hidden';
          el.style.clipPath = `inset(0 ${((1 - p) * 100).toFixed(2)}% 0 0)`;
        };
      }
      if (it.kind === 'stroke') {
        const svg = document.createElementNS(NS, 'svg');
        svg.setAttribute('width', BOARD_W);
        svg.setAttribute('height', BOARD_H);
        svg.style.cssText = 'position:absolute;left:0;top:0;overflow:visible;visibility:hidden';
        svg.innerHTML = `<path d="${it.d}" fill="none" stroke="${it.color}" stroke-width="${it.width}" stroke-linecap="round" stroke-linejoin="round" pathLength="1" stroke-dasharray="1 1"/>`;
        plane.appendChild(svg);
        const path = svg.firstChild;
        return (p) => {
          svg.style.visibility = p > 0 ? 'visible' : 'hidden';
          path.setAttribute('stroke-dashoffset', 1 - p);
        };
      }
      // icon: trace the black outline, then the colour emoji fills in
      const {icon} = it;
      const svg = document.createElementNS(NS, 'svg');
      svg.setAttribute('width', it.size);
      svg.setAttribute('height', it.size);
      svg.setAttribute('viewBox', `0 0 ${icon.size} ${icon.size}`);
      svg.style.cssText = `position:absolute;left:${it.x}px;top:${it.y}px;overflow:visible;color:${INK};visibility:hidden`;
      svg.innerHTML =
        (icon.stroke ? '' : `<g class="fill">${icon.color || icon.body}</g>`) +
        `<path class="line" d="${it.d}" fill="none" stroke="${INK}" stroke-width="${icon.stroke ? 2 : 0.45}" stroke-linecap="round" stroke-linejoin="round" pathLength="1" stroke-dasharray="1 1"/>`;
      plane.appendChild(svg);
      const fillG = svg.querySelector('.fill');
      const line = svg.querySelector('.line');
      return (p) => {
        svg.style.visibility = p > 0 ? 'visible' : 'hidden';
        const l = clamp(p / 0.75);
        const f = clamp((p - 0.6) / 0.4);
        line.setAttribute('stroke-dashoffset', 1 - l);
        if (fillG) {
          fillG.style.opacity = f;
          line.style.opacity = 1 - f;
        }
      };
    });
    const penEl = document.createElement('div');
    penEl.style.cssText = 'position:absolute;left:0;top:0;width:0;height:0';
    penEl.innerHTML = PEN_SVG + PENCIL_SVG;
    const [markerEl, pencilEl] = penEl.children;
    plane.appendChild(penEl);

    const render = (sec) => {
      board.items.forEach((it, i) => views[i](progress(board.ops[it.op], sec)));
      const cam = camera(board.cams, sec);
      plane.style.transform = `translate(${540 - cam.cx * cam.s}px, ${960 - cam.cy * cam.s}px) scale(${cam.s})`;
      const tip = pen(board.ops, sec, pathAt);
      const lift = 1 - tip.down;
      penEl.style.opacity = tip.show;
      markerEl.style.display = tip.tool === 'pencil' ? 'none' : '';
      pencilEl.style.display = tip.tool === 'pencil' ? '' : 'none';
      penEl.style.visibility = tip.show > 0 ? 'visible' : 'hidden';
      penEl.style.transform = `translate(${tip.x + lift * 10}px, ${tip.y - lift * 22}px) rotate(${32 + lift * 4}deg)`;
      penEl.style.filter = `drop-shadow(${14 + lift * 16}px ${10 + lift * 14}px ${6 + lift * 8}px rgba(0,0,0,${0.22 - lift * 0.06}))`;
    };
    return {board, render};
  }

  const api = {buildBoard, mount};
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.WB = api;
})(typeof window !== 'undefined' ? window : globalThis);
