import React from 'react';
import {Img, interpolate, spring, staticFile} from 'remotion';
import {color, FONT_AR, FONT_EN} from '../theme';
import type {PropSpec} from '../types';

// Teaser props: app screens, big title slams, the alarm, the secret box and
// speech bubbles. Times are seconds from the voice start, like Props.tsx.

type P<K extends PropSpec['kind']> = Extract<PropSpec, {kind: K}> & {t: number; fps: number};

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const sp = (sec: number, fps: number, damping = 11, stiffness = 160) =>
  sec < 0 ? 0 : spring({frame: sec * fps, fps, config: {damping, stiffness}});
const COCOA = color('cocoa');
// thick cartoon outline for big text
const outline = (w: number) => ({WebkitTextStroke: `${w}px ${COCOA}`, paintOrder: 'stroke fill' as const});

// ---------------------------------------------------------------- app screen in a tablet

// A screenshot of the app (repo screenshots/, synced to public/app/screens) in a tablet frame.
export const Screen: React.FC<P<'screen'>> = ({t, fps, shot, at, outAt, x = 540, y = 760, size = 1, tilt = -4, from = 'bottom', to = 'left'}) => {
  const k = t - at;
  if (k < 0) return null;
  const inP = sp(k, fps, 12, 170);
  const o = outAt === undefined ? 0 : interpolate(t - outAt, [0, 0.28], [0, 1], clamp);
  if (o >= 1) return null;
  const W = 900 * size;
  const H = W * (800 / 1280);
  const start: Record<string, [number, number, number]> = {
    bottom: [0, 1200, 1],
    top: [0, -1200, 1],
    left: [-1300, 0, 1],
    right: [1300, 0, 1],
    zoom: [0, 0, 0.1],
    box: [0, 520, 0.05], // rises out of the secret box below
  };
  const end: Record<string, [number, number]> = {left: [-1400, 0], right: [1400, 0], up: [0, -1500], down: [0, 1500]};
  const [sx, sy, ss] = start[from];
  const [ex, ey] = end[to];
  const dx = sx * (1 - inP) + ex * o;
  const dy = sy * (1 - inP) + ey * o + Math.sin(t * 2.2) * 8;
  const s = ss + (1 - ss) * inP;
  const r = tilt * inP + (1 - inP) * (from === 'left' ? -20 : from === 'right' ? 20 : 0) + Math.sin(t * 1.7) * 1.2;
  return (
    <div style={{position: 'absolute', left: x - W / 2, top: y - H / 2, width: W, height: H, transform: `translate(${dx}px, ${dy}px) rotate(${r}deg) scale(${s})`}}>
      <div
        style={{
          position: 'absolute',
          inset: -26 * size,
          borderRadius: 54 * size,
          background: color('ink'),
          border: `${9 * size}px solid ${COCOA}`,
          boxShadow: `0 ${22 * size}px 0 ${COCOA}, 0 0 ${80 * size}px ${color('sunGlow')}`,
        }}
      />
      <Img src={staticFile(`app/screens/${shot}.jpg`)} style={{position: 'absolute', inset: 0, width: W, height: H, borderRadius: 22 * size, objectFit: 'cover'}} />
      {/* a quick shine sweeps across when it lands */}
      <div style={{position: 'absolute', inset: 0, borderRadius: 22 * size, overflow: 'hidden'}}>
        <div
          style={{
            position: 'absolute',
            top: -H,
            left: interpolate(k, [0.15, 0.7], [-W * 0.6, W * 1.3], clamp),
            width: W * 0.22,
            height: H * 3,
            transform: 'rotate(20deg)',
            background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.55), transparent)',
          }}
        />
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- big title slam

export const Title: React.FC<P<'title'>> = ({t, fps, ar, en, at, outAt, y = 330, size = 1, fill = 'sunYellow', style = 'slam', rot = -3}) => {
  const k = t - at;
  if (k < 0) return null;
  const o = outAt === undefined ? 0 : interpolate(t - outAt, [0, 0.2], [0, 1], clamp);
  if (o >= 1) return null;
  // slam: drops from huge with a thump; pop: springs up from nothing; stamp: lands tilted like a rubber stamp
  const p = sp(k, fps, style === 'pop' ? 9 : 14, style === 'pop' ? 200 : 260);
  const scale = (style === 'pop' ? p : 1 + (1 - p) * (style === 'stamp' ? 1.2 : 2.4)) * (1 - o * 0.6);
  const wobble = style === 'pop' ? Math.sin(t * 6) * 1.5 : 0;
  const shake = k < 0.25 && style !== 'pop' ? Math.sin(k * 120) * 10 * (1 - k / 0.25) : 0;
  const arSize = Math.min(150, 1700 / Math.max(6, ar.length)) * size;
  return (
    <div
      style={{
        position: 'absolute',
        left: 70,
        width: 860,
        top: y,
        textAlign: 'center',
        transform: `translateX(${shake}px) rotate(${rot + wobble}deg) scale(${scale})`,
        opacity: Math.min(1, k * 10) * (1 - o),
      }}
    >
      <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: arSize, lineHeight: 1.05, color: color(fill), ...outline(16 * size), textShadow: `0 ${10 * size}px 0 ${COCOA}`}}>
        {ar}
      </div>
      {en && (
        <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: arSize * 0.5, lineHeight: 1.1, color: 'white', ...outline(10 * size), textShadow: `0 ${6 * size}px 0 ${COCOA}`}}>
          {en}
        </div>
      )}
    </div>
  );
};

// ---------------------------------------------------------------- alarm

// Friendly cartoon alarm: a spinning siren light at the top and a pulsing coral glow at the edges.
export const Alarm: React.FC<P<'alarm'>> = ({t, at, until = 99}) => {
  const k = t - at;
  if (k < 0 || t > until + 0.3) return null;
  const fade = interpolate(t, [until, until + 0.3], [1, 0], clamp);
  const pulse = 0.5 + 0.5 * Math.sin(k * 14);
  const beam = k * 400;
  return (
    <>
      <div style={{position: 'absolute', inset: 0, boxShadow: `inset 0 0 ${180 + pulse * 140}px ${color('coral')}`, opacity: fade}} />
      <div style={{position: 'absolute', inset: 0, background: color('coral'), opacity: fade * pulse * 0.16}} />
      <div style={{position: 'absolute', left: 540, top: 250, opacity: fade}}>
        {[0, 180].map((a) => (
          <div
            key={a}
            style={{
              position: 'absolute',
              left: 0,
              top: 0,
              width: 1400,
              height: 260,
              marginTop: -130,
              transformOrigin: '0 50%',
              transform: `rotate(${beam + a}deg)`,
              background: `linear-gradient(90deg, color-mix(in srgb, ${color('sunYellow')} 70%, transparent), transparent 80%)`,
              clipPath: 'polygon(0 45%, 100% 0, 100% 100%, 0 55%)',
            }}
          />
        ))}
        {/* the siren dome */}
        <div style={{position: 'absolute', left: -80, top: -70, width: 160, height: 120, borderRadius: '80px 80px 14px 14px', background: color('coral'), border: `8px solid ${COCOA}`, boxShadow: `0 0 ${40 + pulse * 60}px ${color('coral')}`}}>
          <div style={{position: 'absolute', left: 26, top: 16, width: 34, height: 50, borderRadius: 20, background: 'rgba(255,255,255,0.7)'}} />
        </div>
        <div style={{position: 'absolute', left: -110, top: 46, width: 220, height: 40, borderRadius: 12, background: color('slateTeal'), border: `8px solid ${COCOA}`}} />
      </div>
    </>
  );
};

// ---------------------------------------------------------------- secret box

// A golden treasure box with a big "?": drops in, shakes, its lid peeks open with light
// pouring out, then slams shut; `lockAt` hangs a padlock on it.
export const Box: React.FC<P<'box'>> = ({t, fps, at = 0, x = 540, y = 1380, size = 1, shakes = [], opens = [], lockAt}) => {
  const k = t - at;
  if (k < 0) return null;
  const W = 520 * size;
  const H = 330 * size;
  const drop = sp(k, fps, 9, 140);
  const dy = (1 - drop) * -1600;
  const shaking = shakes.some((s) => t >= s && t < s + 0.7);
  const sh = shaking ? Math.sin(t * 70) * 9 : 0;
  // lid: how far open (0 closed, 1 wide open); snaps shut with a little overshoot
  let lid = 0;
  for (const o of opens) {
    const amount = o.wide ? 1 : 0.55;
    if (t >= o.at && t < o.until) lid = Math.max(lid, sp(t - o.at, fps, 10, 120) * amount);
    else if (t >= o.until && t < o.until + 0.25) lid = Math.max(lid, interpolate(t - o.until, [0, 0.12], [amount, 0], clamp));
  }
  const glow = 0.6 + 0.3 * Math.sin(t * 4);
  const lock = lockAt === undefined ? 0 : sp(t - lockAt, fps, 8, 180);
  const gold = color('letterGold');
  const wood = color('monasteryWood');
  return (
    <div style={{position: 'absolute', left: x, top: y, transform: `translate(${sh}px, ${dy}px) rotate(${sh * 0.3}deg)`}}>
      {/* light pouring out of the open lid */}
      {lid > 0.05 && (
        <div
          style={{
            position: 'absolute',
            left: -W * 0.9,
            top: -H * 0.5 - 1100 * lid,
            width: W * 1.8,
            height: 1100 * lid,
            background: `linear-gradient(0deg, ${color('sunGlow')}, color-mix(in srgb, ${color('sunYellow')} 40%, transparent) 60%, transparent)`,
            clipPath: 'polygon(30% 100%, 70% 100%, 100% 0, 0 0)',
            opacity: 0.85,
          }}
        />
      )}
      {/* glow on the floor */}
      <div style={{position: 'absolute', left: -W, top: -H, width: W * 2, height: H * 2, borderRadius: '50%', background: `radial-gradient(circle, ${color('foundGlow')}, transparent 65%)`, opacity: glow}} />
      {/* body */}
      <div
        style={{
          position: 'absolute',
          left: -W / 2,
          top: -H / 2,
          width: W,
          height: H,
          borderRadius: 30 * size,
          background: `linear-gradient(180deg, ${wood}, ${color('monasteryWoodDark')})`,
          border: `${10 * size}px solid ${COCOA}`,
          boxShadow: `0 ${16 * size}px 0 ${COCOA}`,
        }}
      >
        {[0.18, 0.82].map((f) => (
          <div key={f} style={{position: 'absolute', left: `${f * 100 - 5}%`, top: 0, width: '10%', height: '100%', background: gold, borderLeft: `${5 * size}px solid ${COCOA}`, borderRight: `${5 * size}px solid ${COCOA}`}} />
        ))}
        <div style={{position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT_EN, fontWeight: 800, fontSize: 230 * size, color: color('sunYellow'), ...outline(12 * size), textShadow: `0 0 ${40 * glow}px ${color('sunGlow')}`}}>
          ?
        </div>
      </div>
      {/* lid, hinged at the back: lifts and tilts open */}
      <div
        style={{
          position: 'absolute',
          left: -W / 2 - 20 * size,
          top: -H / 2 - 110 * size,
          width: W + 40 * size,
          height: 130 * size,
          transformOrigin: '100% 100%',
          transform: `translateY(${-lid * 160 * size}px) rotate(${lid * 28}deg)`,
          borderRadius: `${70 * size}px ${70 * size}px ${16 * size}px ${16 * size}px`,
          background: `linear-gradient(180deg, ${color('monasteryBrass')}, ${wood})`,
          border: `${10 * size}px solid ${COCOA}`,
        }}
      >
        <div style={{position: 'absolute', left: '42%', top: '35%', width: '16%', height: '65%', background: gold, borderRadius: 10 * size, border: `${5 * size}px solid ${COCOA}`}} />
      </div>
      {/* padlock */}
      {lock > 0 && (
        <div style={{position: 'absolute', left: -75 * size, top: -H / 2 - 40 * size, width: 150 * size, height: 170 * size, transform: `scale(${lock}) rotate(${(1 - lock) * 40}deg)`}}>
          <div style={{position: 'absolute', left: 30 * size, top: 0, width: 90 * size, height: 100 * size, borderRadius: `${50 * size}px ${50 * size}px 0 0`, border: `${18 * size}px solid ${color('slateTeal')}`, borderBottom: 'none'}} />
          <div style={{position: 'absolute', left: 0, top: 70 * size, width: 150 * size, height: 110 * size, borderRadius: 24 * size, background: color('sunYellow'), border: `${9 * size}px solid ${COCOA}`}}>
            <div style={{position: 'absolute', left: 54 * size, top: 24 * size, width: 24 * size, height: 44 * size, borderRadius: 12 * size, background: COCOA}} />
          </div>
        </div>
      )}
    </div>
  );
};

// ---------------------------------------------------------------- speech bubble

// Comic speech bubble with Arabic + English; `wrongAt` stamps a big red X over it.
export const Bubble: React.FC<P<'bubble'>> = ({t, fps, ar, en, at, outAt, x = 540, y = 520, tail = 'left', wrongAt}) => {
  const k = t - at;
  if (k < 0) return null;
  const o = outAt === undefined ? 0 : interpolate(t - outAt, [0, 0.2], [0, 1], clamp);
  if (o >= 1) return null;
  const p = sp(k, fps, 9, 190) * (1 - o);
  const w = wrongAt === undefined ? -1 : t - wrongAt;
  const x2 = w >= 0 ? sp(w, fps, 12, 280) : 0;
  const jolt = w >= 0 && w < 0.35 ? Math.sin(w * 90) * 14 * (1 - w / 0.35) : 0;
  const W = 680;
  return (
    <div style={{position: 'absolute', left: x - W / 2, top: y, width: W, transform: `translateX(${jolt}px) scale(${p}) rotate(${tail === 'left' ? -2 : 2}deg)`, transformOrigin: tail === 'left' ? '15% 100%' : '85% 100%'}}>
      <div style={{position: 'relative', background: 'white', border: `9px solid ${COCOA}`, borderRadius: 60, padding: '26px 40px 30px', textAlign: 'center', boxShadow: `0 12px 0 ${COCOA}`}}>
        <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 92, lineHeight: 1.1, color: color('deepTeal')}}>
          {ar}
        </div>
        {en && <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 50, lineHeight: 1.1, color: color('coral')}}>{en}</div>}
        {/* tail */}
        <svg width={110} height={90} style={{position: 'absolute', bottom: -84, [tail === 'left' ? 'left' : 'right']: 80}}>
          <polygon points={tail === 'left' ? '10,0 90,0 20,82' : '20,0 100,0 90,82'} fill="white" stroke={COCOA} strokeWidth={9} strokeLinejoin="round" />
          <rect x={14} y={0} width={82} height={12} fill="white" />
        </svg>
        {x2 > 0 && (
          <svg width={W} height={260} viewBox="0 0 680 260" style={{position: 'absolute', left: -9, top: '50%', marginTop: -130, transform: `scale(${0.4 + x2 * 0.6})`, opacity: Math.min(1, x2 * 2)}}>
            {[
              [150, 30, 530, 230],
              [530, 30, 150, 230],
            ].map(([a, b, c, d], i) => (
              <g key={i}>
                <line x1={a} y1={b} x2={c} y2={d} stroke={COCOA} strokeWidth={70} strokeLinecap="round" />
                <line x1={a} y1={b} x2={c} y2={d} stroke={color('coral')} strokeWidth={46} strokeLinecap="round" />
              </g>
            ))}
          </svg>
        )}
      </div>
    </div>
  );
};
