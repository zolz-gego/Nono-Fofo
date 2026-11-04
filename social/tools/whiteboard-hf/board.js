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
// Timing never depends on measured text, so tools/wb_hyperframes.mjs runs
// buildBoard in Node (fake widths) to place the audio clips, and the scene runs
// it again in the browser (real widths) to place the ink: both agree on time.
(function (root) {
  const PANEL_W = 1080;
  const PANEL_H = 1920;
  const BOARD_W = PANEL_W * 2;
  const BOARD_H = PANEL_H * 3;
  const INK = '#1f2328';
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
    for (const m of icon.body.matchAll(/<(path|line|circle|rect|ellipse|polyline|polygon)\b([^>]*)>/g)) {
      const a = Object.fromEntries([...m[2].matchAll(/([\w-]+)="([^"]*)"/g)].map((x) => [x[1], x[2]]));
      const n = (k) => Number(a[k] ?? 0);
      if (m[1] === 'path') ds.push(a.d);
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

  // env: {width(text, script, size), pathLen(d)}; data: see tools/wb_hyperframes.mjs
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
    const piece = (say) => {
      const i = take.text.indexOf(say, cursor);
      if (i < 0) throw new Error(`"${say}" is not in the take (re-run tools/wb_split.py after editing a say)`);
      cursor = i + say.length;
      return [take.start[i], take.end[i + say.length - 1]];
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
      const op = addOp({kind: 'text', x: cx - w / 2, y: cy - h / 2, w, h, dir, chars: s.length, dur});
      items.push({kind: 'text', op, x: cx - w / 2, y: cy - h / 2, w, h, font: FONTS[script], size, weight: WEIGHT[script], dir, spans});
      return {x: cx - w / 2, y: cy - h / 2, w, h};
    };

    const stroke = (d, color, w, dur) => {
      const op = addOp({kind: 'path', d, len: env.pathLen(d), ox: 0, oy: 0, scale: 1, dur});
      items.push({kind: 'stroke', op, d, color, width: w});
    };

    const icon = (id, x, y, size) => {
      const ic = data.icons[id];
      if (!ic) return;
      const d = iconPath(ic);
      const scale = size / ic.size;
      const op = addOp({kind: 'path', d, len: env.pathLen(d), ox: x, oy: y, scale, dur: 1.8});
      items.push({kind: 'icon', op, x, y, size, icon: ic, d});
    };

    // A wobbly hand-drawn underline from x0 to x1 at y.
    const underline = (x0, x1, y) => stroke(`M${rtl ? x1 : x0} ${y} Q${(x0 + x1) / 2} ${y + 14} ${rtl ? x0 : x1} ${y - 4}`, RED, 9, 0.35);

    let panel = '';
    const P = {
      letter: {x: 0, y: 0},
      facts: {x: PANEL_W, y: 0},
      s0: {x: 0, y: PANEL_H},
      s1: {x: PANEL_W, y: PANEL_H},
      end: {x: PANEL_W / 2, y: PANEL_H * 2},
    };
    // the recap view keeps both rows inside y 150–1560 (TikTok caption)
    const camOf = (p) => (p === 'all' ? {cx: PANEL_W, cy: PANEL_H + 270, s: 0.37} : {cx: P[p].x + PANEL_W / 2, cy: P[p].y + PANEL_H / 2, s: 1});

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
      const [a0, a1] = piece(say);
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
    const factRow = (parts, size, cx, cy) => {
      const ws = parts.map((p) => env.width(p.t, p.s, size));
      const gap = size * 0.4;
      const total = ws.reduce((a, b) => a + b, 0) + gap * (parts.length - 1);
      let edge = rtl ? cx + total / 2 : cx - total / 2;
      parts.forEach((p, i) => {
        const c = rtl ? edge - ws[i] / 2 : edge + ws[i] / 2;
        const b = text(p.t, p.s, size, c, cy, hue(p.c));
        if (p.box) {
          const [x0, y0, x1, y1] = [b.x - 30, b.y - 6, b.x + b.w + 30, b.y + b.h + 6];
          stroke(`M${x1} ${y0 + 8} L${x0 + 4} ${y0} L${x0} ${y1} L${x1 - 4} ${y1 + 4} L${x1 + 6} ${y0 - 6}`, RED, 9, 0.9);
        }
        if (p.over) stroke(`M${b.x + b.w * 0.1} ${b.y + b.h * 0.12} L${b.x + b.w * 0.9} ${b.y + b.h * 0.1}`, RED, 12, 0.4);
        edge += (rtl ? -1 : 1) * (ws[i] + gap);
      });
    };
    const factRows = (f, x, y) => {
      const size = f.size ?? 120;
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
    const need = onFacts.reduce((h, f) => h + f.rows.length * (f.size ?? 120) * 1.45, 0) + 110 * (onFacts.length - 1);
    const fit = Math.min(1, (1540 - 330) / need);
    let factY = 330;
    let letterY = 1360;
    for (const f of data.facts) {
      beat(f.say, f.panel === 'letter' ? 'letter' : 'facts', (o) => {
        if (f.panel === 'letter') letterY = factRows(f, o.x + 520, o.y + letterY) + 40;
        else factY = factRows({...f, size: (f.size ?? 120) * fit}, o.x + 500, o.y + factY) + 110 * fit;
      });
    }

    // the word sections
    data.sections.forEach((sec, si) => {
      const id = `s${si}`;
      beat(sec.say, id, (o) => {
        const tt = text(sec.title, AR, 110, o.x + 500, o.y + 250, BLUE);
        underline(tt.x - 10, tt.x + tt.w + 10, tt.y + tt.h - 10);
      });
      const n = sec.words.length;
      const step = Math.min(430, 1080 / n);
      const top = 420 + (1080 - step * n) / 2;
      const big = n <= 2 ? 1.15 : 1;
      sec.words.forEach((w, wi) => {
        beat(w.say, id, (o) => {
          const cy = o.y + top + step * (wi + 0.5);
          const cx = o.x + 640; // text column (x 360–920); the drawing sits on the left
          const ic = 260 * big;
          const cop = {mark: L.small};
          if (sec.group === 'ar') {
            text(w.word, 'ar', 125 * big, cx, cy - 75 * big, INK, {max: 540});
            icon(w.icon, o.x + 215 - ic / 2, cy - ic / 2, ic);
            text(w.coptic, 'cop', 110 * big, cx, cy + 85 * big, INK, {max: 540, ...cop});
          } else {
            const lift = w.meaning ? 0 : 50;
            text(w.coptic, 'cop', 120, cx, cy - 105 + lift, INK, {max: 540, ...cop});
            text(w.ar, 'ar', 88, cx, cy + 15 + lift, INK, {max: 540});
            icon(w.icon, o.x + 215 - ic / 2, cy - ic / 2, ic);
            if (w.meaning) text(w.meaning, 'ar', 80, cx, cy + 120, BLUE, {max: 540});
          }
          cues.push({t: drawAt - GAP, sfx: 'mg_keyword_pop', volume: 0.25});
        });
      });
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

    return {items, ops, clips, beats, cams, cues, duration: Math.max(t, drawAt) + 1.4};
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
          return out > 0 ? {...prev, down: 0, show: out} : {...next, down: clamp(1 - (op.start - sec) / LIFT), show: inn};
        }
        const prev = penOn(ops[i - 1], 1, pathAt);
        const k = ease(clamp((sec - free) / Math.max(gap, 0.01)));
        const edge = Math.min(sec - free, op.start - sec) / LIFT;
        return {x: prev.x + (next.x - prev.x) * k, y: prev.y + (next.y - prev.y) * k, down: Math.max(0, 1 - edge), show: 1};
      }
      if (sec <= op.start + op.dur) return {...penOn(op, progress(op, sec), pathAt), down: 1, show: 1};
    }
    const last = ops[ops.length - 1];
    return {...penOn(last, 1, pathAt), down: 0, show: clamp(1 - (sec - last.start - last.dur) / FADE)};
  }

  const PEN_SVG =
    '<svg width="90" height="430" viewBox="-45 -420 90 430" style="position:absolute;left:-45px;top:-420px;overflow:visible">' +
    '<path d="M-7 -30 L-3 -2 Q0 4 3 -2 L7 -30 Z" fill="#26282b"/>' +
    '<path d="M-20 -78 L-8 -28 L8 -28 L20 -78 Z" fill="#d9dbde"/><path d="M-20 -78 L-8 -28 L-2 -28 L-10 -78 Z" fill="#f4f5f6"/>' +
    '<rect x="-24" y="-330" width="48" height="256" rx="10" fill="#202225"/><rect x="-17" y="-322" width="9" height="240" rx="4" fill="#4a4d52"/>' +
    '<rect x="-24" y="-250" width="48" height="74" fill="#f2f2ef"/><rect x="-24" y="-236" width="48" height="8" fill="#d63b32"/>' +
    '<rect x="-24" y="-196" width="48" height="8" fill="#d63b32"/><rect x="-22" y="-385" width="44" height="60" rx="14" fill="#2b2d31"/>' +
    '<rect x="-15" y="-380" width="8" height="50" rx="4" fill="#55585e"/></svg>';

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
    penEl.innerHTML = PEN_SVG;
    plane.appendChild(penEl);

    const render = (sec) => {
      board.items.forEach((it, i) => views[i](progress(board.ops[it.op], sec)));
      const cam = camera(board.cams, sec);
      plane.style.transform = `translate(${540 - cam.cx * cam.s}px, ${960 - cam.cy * cam.s}px) scale(${cam.s})`;
      const tip = pen(board.ops, sec, pathAt);
      const lift = 1 - tip.down;
      penEl.style.opacity = tip.show;
      penEl.style.visibility = tip.show > 0 ? 'visible' : 'hidden';
      penEl.style.transform = `translate(${tip.x + lift * 10}px, ${tip.y - lift * 22}px) rotate(${32 + lift * 4}deg)`;
      penEl.style.filter = `drop-shadow(${14 + lift * 16}px ${10 + lift * 14}px ${6 + lift * 8}px rgba(0,0,0,${0.22 - lift * 0.06}))`;
    };
    return {board, render};
  }

  const api = {buildBoard, mount, BOARD_W, BOARD_H};
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.WB = api;
})(typeof window !== 'undefined' ? window : globalThis);
