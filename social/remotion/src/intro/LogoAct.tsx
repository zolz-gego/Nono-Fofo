// Acts 3-4 (16 s to the end): the flat logo comes alive. The camera dives into
// the book (letters rise out of it), whips to the pyramid (pyramid, palms and
// sun fold up like a pop-up book), follows the Nile back out, the ring draws
// itself, a shine sweeps across, and the final sting bursts letters outward.
// The picture behind each close-up is defocused, so only the sharp vector
// rebuilds are seen up close.
import React from 'react';
import {Img, useVideoConfig} from 'remotion';
import {color, FONT_COPTIC} from '../theme';
import {along, clamp, COPTIC, cues, ease, LOGO_PX, lerp, prog, rnd, springAt} from './anim';
import {LOGO_SRC, logoSize} from './BlocksAct';
import {GoldLetter, Palm, Pyramid, Sun} from './Parts';

type Cam = {fx: number; fy: number; k: number; whip: number};

// Centre line of the Nile in the logo (traced from the PNG's blue pixels).
const NILE: [number, number][] = [
  [262, 250], [243, 260], [224, 272], [239, 284], [270, 296], [289, 308], [291, 320],
  [278, 332], [254, 344], [235, 356], [218, 368], [207, 380], [202, 398], [203, 418], [214, 432],
];
const RIVER: [number, number][] = [[262, 232], ...NILE.slice(1, 13)];

function camera(t: number): Cam {
  const c = {fx: 256, fy: 256, k: 1, whip: 0};
  const [z0, z1] = cues.zoomBook;
  const [h0, h1] = cues.whip;
  const [v0, v1] = cues.river;
  if (t < z0) return {...c, k: 1.12 - 0.12 * springAt(t, cues.drop, 1.6, 5)};
  if (t < z1) {
    const p = ease.inOutCubic(prog(t, z0, z1));
    return {...c, fy: lerp(256, 318, p), k: lerp(1, 2.3, p)};
  }
  if (t < h0) {
    const p = prog(t, z1, h0);
    return {...c, fy: 318 - 14 * p, k: 2.3 + 0.15 * p};
  }
  if (t < h1) {
    const p = ease.inOutQuad(prog(t, h0, h1));
    return {fx: lerp(256, 262, p), fy: lerp(304, 236, p), k: lerp(2.45, 3.0, p), whip: Math.sin(Math.PI * p)};
  }
  if (t < v0) {
    const p = prog(t, h1, v0);
    return {...c, fx: 262, fy: 236 - 4 * p, k: 3.0 + 0.12 * p};
  }
  if (t < v1) {
    const p = prog(t, v0, v1);
    if (p < 0.6) {
      const q = ease.inOutQuad(p / 0.6);
      const [x, y] = along(RIVER, q);
      return {...c, fx: x, fy: y, k: lerp(3.12, 2.4, q)};
    }
    const q = ease.inOutCubic((p - 0.6) / 0.4);
    const end = RIVER[RIVER.length - 1];
    return {...c, fx: lerp(end[0], 256, q), fy: lerp(end[1], 256, q), k: lerp(2.4, 1, q)};
  }
  const x = t - cues.final;
  const punch = x > 0 ? Math.exp(-x * 5) * Math.sin(x * 16) * 0.07 : 0;
  const drift = Math.max(0, x) * 0.012;
  const float = x > 0.4 ? Math.sin((x - 0.4) * 1.7) * 3 : 0;
  return {...c, fy: 256 + float, k: 1 + punch + drift};
}

// Pop-up piece standing on (x, y) in logo space, folding up from flat.
const PopUp: React.FC<{x: number; y: number; w: number; h: number; vb: string; up: number; children: React.ReactNode}> = ({x, y, w, h, vb, up, children}) => (
  <div
    style={{
      position: 'absolute',
      left: x - w / 2,
      top: y - h,
      width: w,
      height: h,
      transformOrigin: '50% 100%',
      transform: `rotateX(${(1 - up) * 88}deg)`,
      opacity: up > 0.02 ? 1 : 0,
    }}
  >
    <svg viewBox={vb} width={w} height={h} style={{overflow: 'visible', display: 'block'}}>
      {children}
    </svg>
  </div>
);

export const LogoAct: React.FC<{t: number}> = ({t}) => {
  const {width: W, height: H} = useVideoConfig();
  const LOGO = logoSize(W, H);
  const u = LOGO / LOGO_PX;
  const cam = camera(t);
  const focus = clamp((cam.k - 1.3) / 0.8);

  const fold = 1 - ease.inCubic(prog(t, 20.25, 20.7));
  const [g0, g1] = cues.ring;
  const ringP = ease.inOutCubic(prog(t, g0, g1));
  const ringO = prog(t, g0, g0 + 0.05) * (1 - prog(t, g1 + 0.05, g1 + 0.5));
  const [sh0, sh1] = cues.shine;
  const shineP = prog(t, sh0, sh1);
  const fin = cues.final;
  const afterFin = t - fin;
  const riverO = prog(t, cues.river[0] - 0.1, cues.river[0] + 0.1) * (1 - prog(t, cues.river[1] - 0.1, cues.river[1] + 0.3));
  const sunUp = springAt(t, cues.sunrise, 1.4, 5);

  return (
    <div style={{position: 'absolute', inset: 0, filter: cam.whip > 0.01 ? `blur(${cam.whip * 12}px)` : undefined}}>
      <div
        style={{
          position: 'absolute',
          left: 0,
          top: 0,
          width: LOGO,
          height: LOGO,
          transformOrigin: '0 0',
          transform: `translate(${W / 2 - cam.fx * u * cam.k}px, ${H / 2 - cam.fy * u * cam.k}px) scale(${cam.k})`,
        }}
      >
        {/* soft glow behind the badge */}
        <div
          style={{
            position: 'absolute',
            inset: -LOGO * 0.12,
            borderRadius: '50%',
            background: `radial-gradient(circle, ${color('mistBlue')} 0%, transparent 65%)`,
            opacity: 0.35 + 0.4 * Math.exp(-Math.max(0, afterFin) * 2) * (afterFin > 0 ? 1 : 0),
          }}
        />
        <Img
          src={LOGO_SRC}
          style={{
            position: 'absolute',
            inset: 0,
            width: LOGO,
            height: LOGO,
            filter: focus > 0.01 ? `blur(${focus * 3.4}px) brightness(${1 - 0.3 * focus}) saturate(${1 - 0.2 * focus})` : undefined,
          }}
        />

        {/* shine sweep, clipped to the badge */}
        {shineP > 0 && shineP < 1 && (
          <div style={{position: 'absolute', inset: 0, borderRadius: '50%', overflow: 'hidden', mixBlendMode: 'screen'}}>
            <div
              style={{
                position: 'absolute',
                top: -LOGO * 0.5,
                left: lerp(-LOGO * 1.2, LOGO * 1.2, ease.inOutQuad(shineP)),
                width: LOGO * 0.35,
                height: LOGO * 2,
                transform: 'rotate(20deg)',
                background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.55), transparent)',
              }}
            />
          </div>
        )}

        <svg viewBox={`0 0 ${LOGO_PX} ${LOGO_PX}`} width={LOGO} height={LOGO} style={{position: 'absolute', inset: 0, overflow: 'visible'}}>
          <defs>
            <filter id="la-glow" x="-0.5" y="-0.5" width="2" height="2">
              <feGaussianBlur stdDeviation={6} />
            </filter>
          </defs>

          {/* sun rises behind the pyramid */}
          {t >= cues.sunrise && fold > 0 && (
            <g transform={`translate(345 ${lerp(200, 150, clamp(sunUp))}) scale(${clamp(sunUp, 0, 1.2) * fold})`}>
              <Sun r={15} spin={t * 40} uid="la-sun" />
            </g>
          )}

          {/* the Nile shimmers as the camera follows it */}
          {riverO > 0 && (
            <g opacity={riverO}>
              <path
                d={`M${NILE.map(([x, y]) => `${x},${y}`).join(' L')}`}
                strokeLinejoin="round"
                stroke="white"
                strokeWidth={4}
                strokeLinecap="round"
                strokeDasharray="8 16"
                strokeDashoffset={-t * 90}
                fill="none"
                opacity={0.75}
              />
              {Array.from({length: 7}, (_, i) => {
                const [x, y] = along(NILE, (i + 0.5) / 7);
                const tw = Math.max(0, Math.sin(t * 9 + i * 1.9));
                return <circle key={i} cx={x + 7} cy={y - 3} r={2.4 * tw} fill="white" />;
              })}
            </g>
          )}

          {/* ring draws itself */}
          {ringO > 0 && (
            <g transform="rotate(-90 256 256)" opacity={ringO}>
              <circle cx={256} cy={256} r={244} fill="none" stroke={color('sunYellow')} strokeWidth={14} pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - ringP} filter="url(#la-glow)" />
              <circle cx={256} cy={256} r={244} fill="none" stroke="#FFF4C2" strokeWidth={5} pathLength={1} strokeDasharray="1 1" strokeDashoffset={1 - ringP} />
              <circle cx={256 + 244 * Math.cos(ringP * 2 * Math.PI)} cy={256 + 244 * Math.sin(ringP * 2 * Math.PI)} r={10} fill="white" filter="url(#la-glow)" />
              <circle cx={256 + 244 * Math.cos(ringP * 2 * Math.PI)} cy={256 + 244 * Math.sin(ringP * 2 * Math.PI)} r={4} fill="white" />
            </g>
          )}

          {/* letters rise out of the book */}
          {cues.letters.map((t0, j) => {
            if (t < t0) return null;
            const sx = [165, 200, 236, 276, 312, 350][j];
            const tx = [148, 194, 238, 282, 324, 366][j];
            const tyv = [262, 240, 228, 232, 246, 268][j];
            const fly = ease.outCubic(prog(t, t0, t0 + 0.7));
            const s = clamp(springAt(t, t0, 1.8, 5), 0, 1.3) * (1 - prog(t, cues.whip[0], cues.whip[0] + 0.2));
            const x = lerp(sx, tx, fly) + Math.sin(t * 2 + j) * 3 * fly;
            const y = lerp(345, tyv, fly) + Math.cos(t * 2.4 + j) * 4 * fly;
            if (s <= 0.001) return null;
            return (
              <g key={j}>
                {Array.from({length: 5}, (_, i) => {
                  const q = ease.outCubic(prog(t - (i + 1) * 0.05, t0, t0 + 0.7));
                  return <circle key={i} cx={lerp(sx, tx, q)} cy={lerp(345, tyv, q)} r={3 - i * 0.5} fill={color('sunYellow')} opacity={(1 - i / 5) * 0.6 * (1 - fly * 0.8) * s} />;
                })}
                <g transform={`translate(${x} ${y}) rotate(${Math.sin(t * 3 + j) * 12}) scale(${s})`}>
                  <GoldLetter ch={COPTIC[(j * 4 + 1) % COPTIC.length]} size={34} uid={`la-l${j}`} />
                </g>
              </g>
            );
          })}

          {/* final: shockwaves, burst of letters, confetti, twinkles */}
          {afterFin > 0 &&
            [0, 0.12].map((d0, i) => {
              const p = ease.outCubic(prog(afterFin, d0, d0 + 0.9));
              if (p >= 1 || afterFin < d0) return null;
              return <circle key={i} cx={256} cy={256} r={250 + 330 * p} fill="none" stroke={i ? color('sunYellow') : 'white'} strokeWidth={14 * (1 - p)} opacity={1 - p} />;
            })}
          {afterFin > 0 &&
            Array.from({length: 26}, (_, i) => {
              const a = (i / 26) * Math.PI * 2 + rnd(i + 50) * 0.3;
              const dist = 250 + (260 + rnd(i) * 260) * ease.outExpo(prog(afterFin, 0, 1.6)) + afterFin * 10;
              const o = prog(afterFin, 0, 0.1) * (1 - prog(afterFin, 1.6 + rnd(i + 9), 3.2));
              const tint = [color('sunYellow'), color('coral'), color('mistBlue'), color('leafGreen'), 'white'][i % 5];
              return (
                <text
                  key={i}
                  x={256 + Math.cos(a) * dist}
                  y={256 + Math.sin(a) * dist}
                  textAnchor="middle"
                  fontFamily={FONT_COPTIC}
                  fontSize={26 + rnd(i + 3) * 26}
                  fill={tint}
                  opacity={o}
                  transform={`rotate(${(rnd(i + 7) - 0.5) * 200 * ease.outCubic(prog(afterFin, 0, 1.5))} ${256 + Math.cos(a) * dist} ${256 + Math.sin(a) * dist})`}
                >
                  {COPTIC[i % COPTIC.length]}
                </text>
              );
            })}
          {afterFin > 0 &&
            Array.from({length: 40}, (_, i) => {
              const a = rnd(i + 100) * Math.PI * 2;
              const v = 260 + rnd(i + 200) * 420;
              const x = 256 + Math.cos(a) * (200 + v * afterFin * 0.9);
              const y = 256 + Math.sin(a) * (200 + v * afterFin * 0.9) - 220 * afterFin + 160 * afterFin * afterFin;
              const o = 1 - prog(afterFin, 1.4 + rnd(i) * 0.8, 2.6);
              const tint = [color('sunYellow'), color('coral'), color('leafGreen'), color('mistBlue'), 'white'][i % 5];
              return (
                <rect
                  key={i}
                  x={x - 4}
                  y={y - 7}
                  width={8}
                  height={14}
                  rx={2}
                  fill={tint}
                  opacity={o}
                  transform={`rotate(${afterFin * (300 + rnd(i + 300) * 500)} ${x} ${y}) scale(1 ${Math.cos(afterFin * 9 + i)})`}
                  style={{transformOrigin: `${x}px ${y}px`}}
                />
              );
            })}
          {afterFin > 0.4 &&
            Array.from({length: 9}, (_, i) => {
              const a = rnd(i + 500) * Math.PI * 2;
              const rr = 262 + rnd(i + 600) * 30;
              const tw = Math.max(0, Math.sin((afterFin - 0.4) * 3.2 + i * 2.3)) ** 2;
              const x = 256 + Math.cos(a) * rr;
              const y = 256 + Math.sin(a) * rr;
              const s = 9 * tw;
              return <path key={i} d={`M${x},${y - s} Q${x},${y} ${x + s},${y} Q${x},${y} ${x},${y + s} Q${x},${y} ${x - s},${y} Q${x},${y} ${x},${y - s} Z`} fill="#FFF4C2" opacity={tw} />;
            })}
        </svg>

        {/* pop-up book pieces around the pyramid */}
        <div style={{position: 'absolute', left: 0, top: 0, width: LOGO, height: LOGO, perspective: LOGO * 1.4, transformStyle: 'preserve-3d'}}>
          {[
            {x: 212, y: 262, w: 60, h: 68, at: cues.popups[1], kind: 'palm', seed: 1},
            {x: 238, y: 252, w: 50, h: 56, at: cues.popups[2], kind: 'palm', seed: 2},
            {x: 268, y: 256, w: 115, h: 83, at: cues.popups[0], kind: 'pyramid', seed: 0},
            {x: 310, y: 284, w: 64, h: 72, at: cues.popups[3], kind: 'palm', seed: 3},
          ].map((pc) => {
            const up = clamp(springAt(t, pc.at, 1.8, 6), 0, 1.15) * fold;
            if (t < pc.at || up <= 0.001) return null;
            return (
              <PopUp key={pc.seed} x={pc.x * u} y={pc.y * u} w={pc.w * u} h={pc.h * u} vb={pc.kind === 'pyramid' ? '-55 -76 110 79' : '-50 -112 100 115'} up={up}>
                <ellipse cx={0} cy={1} rx={pc.kind === 'pyramid' ? 52 : 18} ry={3} fill="rgba(60,40,20,0.3)" />
                {pc.kind === 'pyramid' ? <Pyramid uid="la-pyr" /> : <Palm sway={Math.sin(t * 2.2 + pc.seed) * 4} t={t + pc.seed} />}
              </PopUp>
            );
          })}
        </div>
      </div>
    </div>
  );
};
