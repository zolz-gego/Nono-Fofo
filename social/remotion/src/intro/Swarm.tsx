// The golden swarm: `cues.particles` particles drawn on a canvas every frame.
// A particle's position is a pure function of (index, time), so frames can be
// rendered in any order on any tab. Between stages each particle flies its own
// curved path (seeded arc + flow swirl, staggered start); while a stage holds,
// the shape breathes (palm sways, river shimmers, brothers bounce, ring spins).
import React, {useEffect, useLayoutEffect, useRef, useState} from 'react';
import {continueRender, delayRender, staticFile, useVideoConfig} from 'remotion';
import {characters} from '../generated/data';
import {FONT_COPTIC} from '../theme';
import {clamp, cues, ease, flow, lerp, prog, rnd} from './anim';
import {buildShapes, COLORED, type Shape} from './shapes';

const N = cues.particles;
const STAGES = cues.stages;
const GOLDS: [number, number, number][] = [
  [255, 214, 102],
  [255, 236, 170],
  [233, 168, 0],
  [255, 200, 69],
  [255, 250, 230],
];

let cache: Record<string, Shape> | null = null;

const loadImage = (src: string) =>
  new Promise<HTMLImageElement>((ok, fail) => {
    const im = new Image();
    im.onload = () => ok(im);
    im.onerror = fail;
    im.src = src;
  });

// Per-particle seeds, computed once.
const R1 = new Float32Array(N);
const R2 = new Float32Array(N);
const R3 = new Float32Array(N);
const R4 = new Float32Array(N);
for (let i = 0; i < N; i++) {
  R1[i] = rnd(i * 1.31 + 0.1);
  R2[i] = rnd(i * 2.17 + 0.2);
  R3[i] = rnd(i * 3.71 + 0.3);
  R4[i] = rnd(i * 5.03 + 0.4);
}

type Frame = {W: number; H: number; S: number; ox: number; oy: number};

// Spin of the ring: accelerates through cues.spinUp.
const spin = (t: number) => {
  const t0 = STAGES[8].land - STAGES[8].lead;
  const x = Math.max(0, t - t0);
  return 1.2 * x + 0.9 * x * x;
};

function stageStart(k: number, i: number, sh: Record<string, Shape>) {
  const s = STAGES[k];
  let d = R1[i];
  if (s.shape === 'logo') {
    // spiral in: centre first, outer ring last
    const L = sh.logo;
    d = clamp(Math.hypot(L.x[i] - 500, L.y[i] - 500) / 520) * 0.9 + R1[i] * 0.1;
  }
  return s.land - s.lead + s.spread * d;
}

// Where particle i sits in stage k (k = -1: the starting dust) at time t.
function place(k: number, i: number, t: number, sh: Record<string, Shape>, f: Frame): [number, number] {
  const {W, H, S, ox, oy} = f;
  if (k < 0) {
    const [fx, fy] = flow(R1[i] * 4, R2[i] * 4, t * 0.4, R3[i] * 6);
    return [R1[i] * W + fx * S * 0.05 + t * S * 0.01 * (R4[i] - 0.5), R2[i] * H + fy * S * 0.05 - t * S * 0.012];
  }
  const name = STAGES[k].shape;
  if (name === 'swarm') {
    // a drifting, folding flock
    const cx = W / 2 + Math.sin(t * 1.4) * S * 0.12;
    const cy = H / 2 + Math.cos(t * 1.0) * S * 0.08;
    const a = Math.sqrt(R1[i]) * 1.0;
    const th = R2[i] * Math.PI * 2;
    let u = Math.cos(th) * a;
    let v = Math.sin(th) * a;
    const [wx, wy] = flow(u * 1.5, v * 1.5, t * 1.6, 1.3);
    u += wx * 0.45;
    v += wy * 0.45;
    const rot = t * 0.9;
    const px = u * S * 0.42;
    const py = v * S * 0.2;
    return [cx + px * Math.cos(rot) - py * Math.sin(rot), cy + px * Math.sin(rot) + py * Math.cos(rot)];
  }
  if (name === 'vortex') {
    const th = R1[i] * Math.PI * 2 + spin(t) * (0.85 + R2[i] * 0.3);
    const r = S * 0.44 * (0.93 + R3[i] * 0.1);
    const tilt = lerp(0.3, 1, ease.inOutCubic(prog(t, cues.spinUp[0], cues.spinUp[1])));
    const lift = (R4[i] - 0.5) * S * 0.04 * (1 - tilt * 0.6);
    return [W / 2 + Math.cos(th) * r, H / 2 + Math.sin(th) * r * tilt + lift];
  }
  const s = sh[name];
  let x = s.x[i];
  let y = s.y[i];
  if (name === 'palm' && y < 860) x += Math.sin(t * 2.4) * 26 * ((860 - y) / 500) ** 1.5;
  if (name === 'brothers') y -= Math.abs(Math.sin(t * 4 + (x < 500 ? 0 : 1.4))) * 14;
  if (name === 'names') y += Math.sin(t * 4 + x * 0.02) * 6;
  if (name === 'nile') x += Math.sin(y * 0.03 - t * 6) * 3;
  const [jx, jy] = flow(R1[i] * 9, R2[i] * 9, t * 2, R3[i] * 4);
  const jitter = name === 'logo' ? 0 : 2.2;
  return [ox + (x / 1000) * S + jx * jitter, oy + (y / 1000) * S + jy * jitter];
}

function current(i: number, t: number, sh: Record<string, Shape>) {
  let k = -1;
  for (let j = 0; j < STAGES.length; j++) if (t >= stageStart(j, i, sh)) k = j;
  return k;
}

function position(i: number, t: number, sh: Record<string, Shape>, f: Frame): {x: number; y: number; k: number; e: number} {
  const k = current(i, t, sh);
  if (k < 0) {
    const [x, y] = place(-1, i, t, sh, f);
    return {x, y, k, e: 1};
  }
  const st = STAGES[k];
  const p = (t - stageStart(k, i, sh)) / st.dur;
  const [bx, by] = place(k, i, t, sh, f);
  if (p >= 1) return {x: bx, y: by, k, e: 1};
  const e = ease.inOutCubic(clamp(p));
  const [ax, ay] = place(k - 1, i, t, sh, f);
  let x = lerp(ax, bx, e);
  let y = lerp(ay, by, e);
  const arc = Math.sin(Math.PI * e);
  // curved flight: sideways bow + swirl
  x += -(by - ay) * (R2[i] - 0.5) * 0.7 * arc;
  y += (bx - ax) * (R2[i] - 0.5) * 0.7 * arc;
  const [fx, fy] = flow(x / f.S * 3, y / f.S * 3, t, R3[i] * 5);
  x += fx * f.S * 0.07 * arc;
  y += fy * f.S * 0.07 * arc;
  if (st.shape === 'swarm') {
    // the alpha/omega shatters outward first
    x += (ax - f.W / 2) * 1.2 * arc * (0.5 + R4[i]);
    y += (ay - f.H / 2) * 1.2 * arc * (0.5 + R4[i]);
  }
  if (st.shape === 'logo') {
    // spiral into place
    const a = (1 - e) * 2.2;
    const dx = x - f.W / 2;
    const dy = y - f.H / 2;
    x = f.W / 2 + dx * Math.cos(a) - dy * Math.sin(a);
    y = f.H / 2 + dx * Math.sin(a) + dy * Math.cos(a);
  }
  return {x, y, k, e};
}

function colorOf(k: number, i: number, sh: Record<string, Shape>): [number, number, number] {
  if (k >= 0 && COLORED.has(STAGES[k].shape)) {
    const c = sh[STAGES[k].shape].col!;
    return [c[i * 3], c[i * 3 + 1], c[i * 3 + 2]];
  }
  return GOLDS[Math.floor(R4[i] * GOLDS.length)];
}

export const Swarm: React.FC<{t: number}> = ({t}) => {
  const {width: W, height: H, fps} = useVideoConfig();
  const ref = useRef<HTMLCanvasElement>(null);
  const bloom = useRef<HTMLCanvasElement | null>(null);
  const [shapes, setShapes] = useState(cache);
  const [handle] = useState(() => (cache ? null : delayRender('Sampling swarm shapes')));

  useEffect(() => {
    if (cache || handle === null) return;
    Promise.all([
      loadImage(staticFile('app/brand/logo.png')),
      loadImage(staticFile(characters.nono.wave.file)),
      loadImage(staticFile(characters.fofo.wave.file)),
      document.fonts.load(`80px ${FONT_COPTIC}`),
    ]).then(([logo, nono, fofo]) => {
      cache = buildShapes(N, {logo, nono, fofo}, FONT_COPTIC);
      setShapes(cache);
      continueRender(handle);
    });
  }, [handle]);

  useLayoutEffect(() => {
    const cv = ref.current;
    if (!cv || !shapes) return;
    const ctx = cv.getContext('2d')!;
    const S = Math.min(W, H) * 0.86;
    const f: Frame = {W, H, S, ox: (W - S) / 2, oy: (H - S) / 2};
    ctx.clearRect(0, 0, W, H);
    const fade = 1 - prog(t, cues.resolve[0] + 0.2, cues.resolve[1] + 0.15);
    if (fade <= 0) return;
    const dt = 1.6 / fps;
    ctx.lineCap = 'round';
    for (let i = 0; i < N; i++) {
      const a = position(i, t, shapes, f);
      const b = position(i, t - dt, shapes, f);
      const name = a.k >= 0 ? STAGES[a.k].shape : 'dust';
      let [r, g, bl] = colorOf(a.k, i, shapes);
      if (a.e < 1 && a.k > 0) {
        const [r0, g0, b0] = colorOf(a.k - 1, i, shapes);
        r = lerp(r0, r, a.e);
        g = lerp(g0, g, a.e);
        bl = lerp(b0, bl, a.e);
      }
      let alpha = (0.68 + 0.32 * Math.sin(t * (3 + R1[i] * 5) + R2[i] * 30)) * fade;
      let size = S * 0.004 * (0.7 + 0.6 * R3[i]);
      if (name === 'dust') {
        alpha *= 0.35 + 0.65 * prog(t, 0, 1.2) * 0.4;
      } else if (name === 'vortex' && a.e >= 1) {
        const th = R1[i] * Math.PI * 2 + spin(t) * (0.85 + R2[i] * 0.3);
        const back = Math.sin(th) < 0 ? 1 : 0;
        alpha *= back ? 0.45 : 1;
        size *= back ? 0.75 : 1.15;
      } else if (name === 'brothers') {
        size = S * 0.0046;
        alpha = Math.max(alpha, 0.85 * fade);
      } else if (name === 'logo') {
        size = lerp(size, S * 0.0072, a.e);
        alpha = lerp(alpha, fade, a.e);
      } else if (name === 'nile' && a.e >= 1) {
        const wave = ((b.y / H) - t * 0.5) % 0.25;
        if (wave > 0 && wave < 0.03) alpha = Math.min(1, alpha + 0.6);
      }
      ctx.strokeStyle = `rgba(${r | 0},${g | 0},${bl | 0},${alpha.toFixed(3)})`;
      ctx.lineWidth = size;
      // cap the streak so fast flights stay sparks, not straw
      let tx = b.x - a.x;
      let ty = b.y - a.y;
      const len = Math.hypot(tx, ty);
      const cap = S * 0.035;
      if (len > cap) {
        tx *= cap / len;
        ty *= cap / len;
      }
      ctx.beginPath();
      ctx.moveTo(a.x + tx, a.y + ty);
      ctx.lineTo(a.x + 0.01, a.y);
      ctx.stroke();
    }
    // bloom: blurred quarter-size copy added back on top
    if (!bloom.current) bloom.current = document.createElement('canvas');
    const bc = bloom.current;
    bc.width = Math.ceil(W / 4);
    bc.height = Math.ceil(H / 4);
    const bx = bc.getContext('2d')!;
    bx.filter = `blur(${Math.max(2, S * 0.006)}px)`;
    bx.drawImage(cv, 0, 0, bc.width, bc.height);
    ctx.save();
    ctx.globalCompositeOperation = 'lighter';
    ctx.globalAlpha = 0.7;
    ctx.drawImage(bc, 0, 0, W, H);
    ctx.restore();
  }, [t, shapes, W, H, fps]);

  return <canvas ref={ref} width={W} height={H} style={{position: 'absolute', inset: 0}} />;
};
