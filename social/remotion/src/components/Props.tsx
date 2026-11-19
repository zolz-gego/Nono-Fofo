import {FontAwesomeIcon} from '@fortawesome/react-fontawesome';
import React from 'react';
import {Img, interpolate, random, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {characters, images} from '../generated/data';
import {ICONS} from '../icons';
import {color, FONT_AR, FONT_COPTIC, FONT_EN} from '../theme';
import type {PropSpec} from '../types';
import {Alarm, Box, Bubble, Picture, Screen, Title} from './TeaserProps';

// Motion-graphics props for story scenes. Every time is in seconds from the
// voice start (`t`), so props line up with the spoken words like keywords do.

type P<K extends PropSpec['kind']> = Extract<PropSpec, {kind: K}> & {t: number; fps: number};

const GOLD = color('letterGold');
const GLOW = color('foundGlow');
const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const since = (t: number, at: number | undefined) => (at === undefined ? -1 : t - at);
const sp = (sec: number, fps: number, damping = 11, stiffness = 160) =>
  sec < 0 ? 0 : spring({frame: sec * fps, fps, config: {damping, stiffness}});
// Coptic letters (Avva keys) used for flying / page letters.
const KEYS = 'abjdezqiklmnxoprctvfywABJDEZW'.split('');

// Big gold Coptic letter with a soft glow.
const GoldLetter: React.FC<{k: string; size: number; style?: React.CSSProperties}> = ({k, size, style}) => (
  <div
    style={{
      fontFamily: FONT_COPTIC,
      fontSize: size,
      lineHeight: 1,
      color: GOLD,
      textShadow: `0 0 ${size * 0.12}px ${GLOW}, 0 ${size * 0.04}px 0 ${color('cocoa')}`,
      ...style,
    }}
  >
    {k}
  </div>
);

// Spiky comic burst behind a crash.
const Starburst: React.FC<{size: number; fill: string}> = ({size, fill}) => {
  const n = 16;
  const pts = Array.from({length: n * 2}, (_, i) => {
    const r = i % 2 ? size * 0.32 : size * 0.5;
    const a = (i / (n * 2)) * Math.PI * 2;
    return `${size / 2 + r * Math.cos(a)},${size / 2 + r * Math.sin(a)}`;
  }).join(' ');
  return (
    <svg width={size} height={size}>
      <polygon points={pts} fill={fill} stroke="white" strokeWidth={10} strokeLinejoin="round" />
    </svg>
  );
};

// ---------------------------------------------------------------- Grandpa's golden book

const Book: React.FC<P<'book'>> = ({t, fps, x = 540, y = 860, size = 1, dropAt, openAt, burstAt, letterInAt, letterFrom = [540, 420], letter = 'A', found, only}) => {
  const W = 640 * size;
  const H = 400 * size;
  // closed cover flips away, then the open book unfolds
  const o = openAt === undefined ? 1 : interpolate(since(t, openAt), [0, 0.6], [0, 1], clamp);
  const coverX = interpolate(o, [0, 0.5], [1, 0], clamp);
  const openX = interpolate(o, [0.5, 1], [0, 1], clamp);
  const b = since(t, burstAt);
  const burst = burstAt !== undefined && b >= 0;
  const hit = burst ? Math.sin(Math.min(1, b / 0.35) * Math.PI) : 0;
  const glow = 0.55 + 0.25 * Math.sin(t * 5) + (burst ? interpolate(b, [0, 0.15, 0.8], [0, 1.2, 0], clamp) : 0);
  const li = since(t, letterInAt);
  // dropAt: falls from the sky and lands with a bounce
  if (dropAt !== undefined && t < dropAt) return null;
  const dropY = dropAt === undefined ? 0 : (1 - sp(t - dropAt, fps, 9, 110)) * -1400;

  return (
    <div style={{position: 'absolute', left: x, top: y + dropY, width: 0, height: 0}}>
      {/* glow + slowly turning rays */}
      <div
        style={{
          position: 'absolute',
          left: -W,
          top: -W,
          width: W * 2,
          height: W * 2,
          borderRadius: '50%',
          background: `radial-gradient(circle, ${GLOW} 0%, ${color('sunGlow')} 35%, transparent 68%)`,
          opacity: o * Math.min(1, glow),
        }}
      />
      <svg width={W * 2} height={W * 2} style={{position: 'absolute', left: -W, top: -W, opacity: o * 0.5}}>
        <g transform={`rotate(${t * 12} ${W} ${W})`}>
          {Array.from({length: 12}, (_, i) => {
            const a = (i / 12) * Math.PI * 2;
            return <line key={i} x1={W} y1={W} x2={W + Math.cos(a) * W * 0.9} y2={W + Math.sin(a) * W * 0.9} stroke={color('sunYellow')} strokeWidth={14 * size} strokeLinecap="round" opacity={0.6} />;
          })}
        </g>
      </svg>
      {burst && b < 0.8 && (
        <div style={{position: 'absolute', left: -W * 0.9, top: -W * 0.9, transform: `scale(${interpolate(b, [0, 0.18], [0.2, 1.15], clamp)}) rotate(${b * 40}deg)`, opacity: interpolate(b, [0.45, 0.8], [1, 0], clamp)}}>
          <Starburst size={W * 1.8} fill={color('sunYellow')} />
        </div>
      )}
      <div style={{position: 'absolute', transform: `translateY(${-hit * 60 * size}px) rotate(${hit * -8}deg) scale(${1 + hit * 0.08})`}}>
        {/* closed cover */}
        {coverX > 0 && (
          <div
            style={{
              position: 'absolute',
              left: -W * 0.28,
              top: -H * 0.6,
              width: W * 0.56,
              height: H * 1.2,
              transform: `scaleX(${coverX})`,
              borderRadius: 26 * size,
              background: `linear-gradient(135deg, ${color('monasteryWood')}, ${color('monasteryWoodDark')})`,
              border: `${10 * size}px solid ${GOLD}`,
              boxShadow: `0 ${18 * size}px 0 ${color('cocoa')}`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <div style={{position: 'absolute', inset: 18 * size, border: `${5 * size}px solid ${GOLD}`, borderRadius: 14 * size, opacity: 0.7}} />
            <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 * size}}>
              <GoldLetter k="A" size={130 * size} />
              <div style={{width: 120 * size, height: 6 * size, borderRadius: 3, background: GOLD}} />
              <GoldLetter k="W" size={130 * size} />
            </div>
          </div>
        )}
        {/* open book */}
        {openX > 0 && (
          <div style={{position: 'absolute', left: -W / 2, top: -H / 2, width: W, height: H, transform: `scaleX(${openX})`}}>
            <div
              style={{
                position: 'absolute',
                left: -16 * size,
                top: 10 * size,
                width: W + 32 * size,
                height: H + 18 * size,
                borderRadius: 30 * size,
                background: color('monasteryWoodDark'),
                border: `${8 * size}px solid ${GOLD}`,
              }}
            />
            {[0, 1].map((side) => (
              <div
                key={side}
                style={{
                  position: 'absolute',
                  left: side * (W / 2),
                  top: 0,
                  width: W / 2,
                  height: H,
                  background: `linear-gradient(${side ? 90 : 270}deg, ${color('cream')} 70%, ${color('studyWall')})`,
                  borderRadius: side ? `0 ${40 * size}px ${16 * size}px 0` : `${40 * size}px 0 0 ${16 * size}px`,
                  boxShadow: 'inset 0 -6px 0 rgba(0,0,0,0.06)',
                  display: 'grid',
                  gridTemplateColumns: 'repeat(3, 1fr)',
                  alignContent: 'center',
                  justifyItems: 'center',
                  padding: `${30 * size}px ${34 * size}px`,
                  rowGap: 6 * size,
                }}
              >
                {Array.from({length: 9}, (_, i) => {
                  const key = KEYS[(i + side * 9) % KEYS.length];
                  // letters found earlier sit big on the left page, side by side in the middle row
                  const foundKeys = found ? found.split('') : [];
                  const slots = foundKeys.length === 1 ? [4] : foundKeys.length === 2 ? [3, 5] : foundKeys.length === 3 ? [3, 4, 5] : [1, 3, 5, 7, 4, 0, 2, 6, 8];
                  const slot = side === 0 ? slots.indexOf(i) : -1;
                  // page letters vanish when they burst out; one comes back with letterIn
                  const back = side === 1 && i === 4 && li >= 0.55;
                  const had = slot >= 0 && slot < foundKeys.length;
                  const gone = burst && !back && !had;
                  // only: a clean page with just the letters found so far
                  if (only && !back && !had) return <div key={i} />;
                  return (
                    <GoldLetter
                      key={i}
                      k={back ? letter : had ? foundKeys[slot] : key}
                      size={(back ? 110 : had ? (foundKeys.length > 1 ? 95 : 110) : 70) * size}
                      style={{opacity: gone ? 0.08 : 1, transform: back ? `scale(${sp(li - 0.55, fps, 8, 200)})` : undefined}}
                    />
                  );
                })}
              </div>
            ))}
            <div style={{position: 'absolute', left: W / 2 - 3 * size, top: 0, width: 6 * size, height: H, background: color('studyWallShade')}} />
          </div>
        )}
      </div>
      {/* the letters burst out and fly everywhere */}
      {burst &&
        Array.from({length: 26}, (_, i) => {
          const a = -Math.PI / 2 + (random(`ba${i}`) - 0.5) * Math.PI * 1.7;
          const v = 1100 + random(`bv${i}`) * 1400;
          const px = Math.cos(a) * v * b;
          const py = Math.sin(a) * v * b + 900 * b * b;
          const s = 70 + random(`bs${i}`) * 90;
          return (
            <GoldLetter
              key={i}
              k={KEYS[i % KEYS.length]}
              size={s * size}
              style={{position: 'absolute', left: px - s / 2, top: py - s / 2, transform: `rotate(${(random(`br${i}`) - 0.5) * 900 * b}deg) scale(${interpolate(b, [0, 0.12], [0.2, 1], clamp)})`}}
            />
          );
        })}
      {/* one letter flies back in */}
      {li >= 0 && li < 0.6 && (
        <GoldLetter
          k={letter}
          size={interpolate(li, [0, 0.55], [220, 110 * size], clamp)}
          style={{
            position: 'absolute',
            left: interpolate(li, [0, 0.55], [letterFrom[0] - x, W * 0.25], clamp) - 60,
            top: interpolate(li, [0, 0.55], [letterFrom[1] - y, -60 * size], clamp) - 60 - Math.sin((li / 0.55) * Math.PI) * 160,
            transform: `rotate(${li * 720}deg)`,
          }}
        />
      )}
      {li >= 0.55 && li < 1.3 &&
        Array.from({length: 10}, (_, i) => {
          const k = li - 0.55;
          const a = (i / 10) * Math.PI * 2;
          const d = 60 + k * 420;
          return <div key={i} style={{position: 'absolute', left: W * 0.25 + Math.cos(a) * d - 10, top: -60 * size + Math.sin(a) * d, width: 22, height: 22, borderRadius: 6, background: i % 2 ? 'white' : color('sunYellow'), opacity: 1 - k / 0.75, transform: `rotate(${k * 600}deg)`}} />;
        })}
    </div>
  );
};

// ---------------------------------------------------------------- Egypt map

// lon/lat -> map box (0..100)
const geo = (lon: number, lat: number): [number, number] => [((lon - 24.7) / 12.3) * 100, ((31.8 - lat) / 10) * 100];
const OUTLINE: [number, number][] = [
  [25, 31.6], [27, 31.35], [29.9, 31.25], [31, 31.6], [32.3, 31.3], [34.2, 31.3], [34.9, 29.5], [34.3, 27.8],
  [32.6, 29.9], [32.4, 29.6], [33.6, 27.2], [35.5, 23.9], [36.9, 22], [25, 22],
];
const NILE: [number, number][] = [[31.4, 22], [32.9, 24.1], [32.7, 25.7], [31.4, 27.2], [30.9, 28.5], [31.2, 30]];
const DELTA: [number, number][][] = [[[31.2, 30], [30.4, 31.4]], [[31.2, 30], [31.8, 31.4]]];
// Places from the story, where the letters land.
const PLACES: {at: [number, number]; icon?: string; pyramids?: boolean}[] = [
  {at: [29.9, 31.15], icon: 'anchor'}, // Alexandria & the sea
  {at: [30.7, 29.9], pyramids: true}, // Giza pyramids
  {at: [32.3, 28.9], icon: 'church'}, // desert monastery
  {at: [31.6, 27.0], icon: 'house'}, // village on the Nile
  {at: [33.4, 25.0], icon: 'sailboat'}, // the Nile
];
const EXTRA: [number, number][] = [[27.5, 29], [28.5, 25.5], [34, 30.2], [26.5, 23.5], [30, 23.2]];

const EgyptMap: React.FC<P<'egypt'>> = ({t, fps, at = 0}) => {
  const MW = 860;
  const MH = 780;
  const LEFT = 540 - MW / 2;
  const TOP = 250;
  const p = sp(t - at, fps, 12, 120);
  const toPx = ([lon, lat]: [number, number]): [number, number] => {
    const [u, v] = geo(lon, lat);
    return [(u / 100) * MW, (v / 100) * MH];
  };
  const path = (pts: [number, number][]) => pts.map((q, i) => `${i ? 'L' : 'M'}${toPx(q).join(' ')}`).join(' ');
  const targets = [...PLACES.map((pl) => pl.at), ...EXTRA];
  const nileDraw = interpolate(t - at, [0.2, 0.9], [0, 1], clamp);

  return (
    <div style={{position: 'absolute', left: LEFT, top: TOP, width: MW, height: MH, transform: `scale(${p}) rotate(${(1 - p) * -10}deg)`}}>
      <svg width={MW} height={MH} style={{position: 'absolute', overflow: 'visible'}}>
        <path d={`${path(OUTLINE)} Z`} fill={color('monasteryDesert')} stroke={color('cocoa')} strokeWidth={10} strokeLinejoin="round" />
        <path d={`${path(OUTLINE)} Z`} fill="none" stroke={color('monasteryDesertDark')} strokeWidth={26} strokeLinejoin="round" opacity={0.35} transform="translate(0 10)" />
        <path d={path(NILE)} fill="none" stroke={color('waterTop')} strokeWidth={16} strokeLinecap="round" strokeLinejoin="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - nileDraw} />
        {DELTA.map((d, i) => (
          <path key={i} d={path(d)} fill="none" stroke={color('waterTop')} strokeWidth={12} strokeLinecap="round" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - interpolate(nileDraw, [0.8, 1], [0, 1], clamp)} />
        ))}
      </svg>
      {PLACES.map((pl, i) => {
        const [px, py] = toPx(pl.at);
        const s = sp(t - at - 0.3 - i * 0.08, fps, 9, 200);
        return (
          <div key={i} style={{position: 'absolute', left: px - 40, top: py - 40, width: 80, height: 80, transform: `scale(${s})`}}>
            {pl.pyramids ? (
              <svg width={110} height={80} style={{marginLeft: -30}}>
                {[[0, 26, 52], [36, 6, 70], [74, 34, 44]].map(([ox, oy, w], j) => (
                  <g key={j}>
                    <polygon points={`${ox},${oy + w * 0.8} ${ox + w / 2},${oy} ${ox + w},${oy + w * 0.8}`} fill={color('sunYellow')} stroke={color('cocoa')} strokeWidth={5} strokeLinejoin="round" />
                    <polygon points={`${ox + w / 2},${oy} ${ox + w},${oy + w * 0.8} ${ox + w * 0.62},${oy + w * 0.8}`} fill={color('pyramidShade')} />
                  </g>
                ))}
              </svg>
            ) : (
              <div style={{width: 76, height: 76, borderRadius: 40, background: color('deepTeal'), border: `6px solid ${color('cream')}`, color: 'white', fontSize: 36, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
                <FontAwesomeIcon icon={ICONS[pl.icon!]} />
              </div>
            )}
          </div>
        );
      })}
      {/* letters fly in from the top and land all over Egypt */}
      {targets.map((q, i) => {
        const k = t - at - 0.5 - i * 0.11;
        if (k < 0) return null;
        const [tx, ty] = toPx(q);
        const f = Math.min(1, k / 0.55);
        const e = 1 - Math.pow(1 - f, 2);
        const sx = MW / 2 + (random(`ex${i}`) - 0.5) * 300;
        const sy = -400;
        const lx = sx + (tx - sx) * e;
        const ly = sy + (ty - 70 - sy) * e - Math.sin(f * Math.PI) * 120;
        const bob = f >= 1 ? Math.sin((k - 0.55) * 6 + i) * 8 : 0;
        return (
          <React.Fragment key={i}>
            <GoldLetter k={KEYS[(i * 5) % KEYS.length]} size={86} style={{position: 'absolute', left: lx - 30, top: ly - 50 + bob, transform: `rotate(${(1 - e) * 360 * (i % 2 ? 1 : -1)}deg)`}} />
            {f >= 1 && k < 0.95 &&
              Array.from({length: 6}, (_, j) => {
                const a = (j / 6) * Math.PI * 2;
                const d = 20 + (k - 0.55) * 200;
                return <div key={j} style={{position: 'absolute', left: tx + Math.cos(a) * d - 7, top: ty - 30 + Math.sin(a) * d, width: 14, height: 14, borderRadius: 4, background: 'white', opacity: 1 - (k - 0.55) / 0.4}} />;
              })}
          </React.Fragment>
        );
      })}
    </div>
  );
};

// ---------------------------------------------------------------- Coptic letter (float / pyramid / card)

const Pyramid: React.FC<{size: number}> = ({size}) => (
  <svg width={size} height={size * 0.82} viewBox="0 0 100 82">
    <polygon points="4,78 50,6 96,78" fill={color('pyramidDune')} stroke={color('cocoa')} strokeWidth={4} strokeLinejoin="round" />
    <polygon points="50,6 96,78 62,78" fill={color('pyramidShade')} />
    {[30, 46, 62].map((yy) => (
      <line key={yy} x1={50 - (yy - 6) * 0.64} y1={yy} x2={50 + (yy - 6) * 0.64} y2={yy} stroke={color('cocoa')} strokeWidth={2} opacity={0.35} />
    ))}
  </svg>
);

const Letter: React.FC<P<'letter'>> = ({t, fps, capital, small, ar, en, sound, soundEn, start = 'float', at = 0, pyramidAt, letterAt, cardAt, pulseAt, soundAt, outAt}) => {
  // float: drops in from the top and sways
  const drop = start === 'float' ? sp(t - at, fps, 10, 70) : 1;
  // pyramid weight: 1 = pyramid showing
  let pyr = start === 'pyramid' ? 1 : 0;
  if (pyramidAt !== undefined) pyr = interpolate(t - pyramidAt, [0, 0.25], [pyr, 1], clamp);
  if (letterAt !== undefined) pyr = Math.min(pyr, interpolate(t - letterAt, [0, 0.3], [1, 0], clamp));
  const card = start === 'card' ? 1 : cardAt !== undefined ? sp(t - cardAt, fps, 12, 140) : 0;
  const cardIn = Math.min(1, card);
  const smallIn = start === 'card' ? 1 : cardAt !== undefined ? sp(t - cardAt - 0.25, fps, 8, 200) : 0;
  const out = outAt !== undefined ? interpolate(t - outAt, [0, 0.25], [1, 0], clamp) : 1;
  if (out <= 0) return null;

  const pk = pulseAt !== undefined ? t - pulseAt : -1;
  const pulse = pk >= 0 ? Math.sin(Math.min(1, pk / 0.5) * Math.PI) : 0;
  const sa = soundAt ?? pulseAt;
  const chip = sa !== undefined && t >= sa ? sp(t - sa, fps, 9, 200) : 0;
  const sway = Math.sin(t * 3) * 6 * (1 - cardIn);
  const melt = pyr > 0 && pyr < 1 ? Math.sin(pyr * Math.PI) : 0;

  // layout of the card: ribbon with the name, two tiles (capital | small)
  const C = {x: 110, y: 170, w: 860, h: 510};
  const TILE = 250;
  const tiles = [
    {x: C.x + 110, k: capital, ar: 'كبير', en: 'Capital'},
    {x: C.x + C.w - 110 - TILE, k: small, ar: 'صغير', en: 'Small'},
  ];
  const tileY = C.y + 140;
  // the floating capital flies into its tile
  const fx = 540;
  const fy = interpolate(drop, [0, 1], [-300, 600]);
  const tx = tiles[0].x + TILE / 2;
  const ty = tileY + TILE / 2;
  const cx = fx + (tx - fx) * card;
  const cy = fy + (ty - fy) * card;
  const size = 340 + (200 - 340) * card;
  const tile = (i: number, inP: number) => (
    <div
      key={i}
      style={{
        position: 'absolute',
        left: tiles[i].x,
        top: tileY,
        width: TILE,
        height: TILE,
        borderRadius: 44,
        background: `radial-gradient(circle at 50% 40%, ${color('slateTeal')}, ${color('deepTeal')})`,
        border: `8px solid ${GOLD}`,
        boxShadow: `0 10px 0 ${color('cocoa')}`,
        transform: `scale(${inP * (i === 1 ? 1 + pulse * 0.18 : 1)})`,
      }}
    >
      <div style={{position: 'absolute', left: 0, right: 0, top: TILE + 14, textAlign: 'center', whiteSpace: 'nowrap'}}>
        <span dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 44, color: color('deepTeal')}}>
          {tiles[i].ar}
        </span>
        <span style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 36, color: color('coral'), marginLeft: 12}}>{tiles[i].en}</span>
      </div>
    </div>
  );

  return (
    <div style={{position: 'absolute', left: 0, top: 0, width: 1080, height: 1920, transform: `scale(${out})`, transformOrigin: `540px ${C.y + C.h / 2}px`}}>
      {card > 0 && (
        <div style={{position: 'absolute', left: 0, top: 0, width: 1080, height: 1920, transform: `scale(${0.6 + 0.4 * card})`, transformOrigin: `540px ${C.y + C.h / 2}px`, opacity: cardIn}}>
          {/* card */}
          <div style={{position: 'absolute', left: C.x, top: C.y, width: C.w, height: C.h, borderRadius: 64, background: color('cream'), border: `10px solid ${color('cocoa')}`, boxShadow: `0 20px 0 ${GOLD}`}}>
            {Array.from({length: 4}, (_, i) => (
              <div key={i} style={{position: 'absolute', left: i % 2 ? undefined : 26, right: i % 2 ? 26 : undefined, top: i < 2 ? 26 : undefined, bottom: i < 2 ? undefined : 26, fontSize: 40, color: GOLD}}>
                <FontAwesomeIcon icon={ICONS.star} />
              </div>
            ))}
          </div>
          {/* name ribbon */}
          <div style={{position: 'absolute', left: 540 - 260, top: C.y - 46, width: 520, height: 130, borderRadius: 65, background: color('coral'), border: `9px solid ${color('cocoa')}`, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 26, transform: `rotate(${-2 + Math.sin(t * 2) * 1.5}deg)`}}>
            <span dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 84, color: 'white', lineHeight: 1}}>
              {ar}
            </span>
            <span style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 60, color: color('cream'), lineHeight: 1}}>{en}</span>
          </div>
          {tile(0, 1)}
          {tile(1, smallIn)}
          {smallIn > 0 && (
            <div style={{position: 'absolute', left: tiles[1].x, top: tileY, width: TILE, height: TILE, display: 'flex', alignItems: 'center', justifyContent: 'center', transform: `scale(${smallIn * (1 + pulse * 0.18)})`}}>
              <GoldLetter k={small} size={200} />
            </div>
          )}
        </div>
      )}
      {/* sound rings from the small letter */}
      {pk >= 0 && pk < 1.2 &&
        [0, 0.25, 0.5].map((d, i) => {
          const k = pk - d;
          if (k < 0 || k > 0.7) return null;
          const r = 150 + k * 320;
          return <div key={i} style={{position: 'absolute', left: tiles[1].x + TILE / 2 - r, top: tileY + TILE / 2 - r, width: r * 2, height: r * 2, borderRadius: '50%', border: `10px solid ${color('coral')}`, opacity: 1 - k / 0.7}} />;
        })}
      {/* the sound chip: ا = a */}
      {chip > 0 && sound && (
        <div style={{position: 'absolute', left: 540 - 230, top: C.y + C.h + 34, width: 460, height: 140, borderRadius: 70, background: color('leafGreen'), border: `9px solid ${color('cocoa')}`, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 30, color: 'white', transform: `scale(${chip}) rotate(${2 * chip}deg)`}}>
          <span style={{fontSize: 60}}>
            <FontAwesomeIcon icon={ICONS.sound} />
          </span>
          <span dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 120, lineHeight: 1}}>
            {sound}
          </span>
          <span style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 72, lineHeight: 1, color: color('cream')}}>= {soundEn}</span>
        </div>
      )}
      {/* glow behind the floating letter */}
      <div style={{position: 'absolute', left: cx - 300, top: cy - 300, width: 600, height: 600, borderRadius: '50%', background: `radial-gradient(circle, ${GLOW} 0%, transparent 65%)`, opacity: (1 - cardIn) * (0.7 + 0.3 * Math.sin(t * 5))}} />
      {/* the capital letter (floats, then sits in its tile) */}
      <div style={{position: 'absolute', left: cx - size / 2, top: cy - size / 2, width: size, height: size, display: 'flex', alignItems: 'center', justifyContent: 'center', opacity: 1 - pyr, transform: `rotate(${sway}deg) scale(${1 - melt * 0.4}, ${1 + melt * 0.3})`}}>
        <GoldLetter k={capital} size={size} />
      </div>
      {/* Nono's pyramid */}
      {pyr > 0 && (
        <div style={{position: 'absolute', left: fx - 170, top: fy - 130, opacity: pyr, transform: `scale(${0.6 + 0.4 * pyr}, ${0.6 + 0.4 * pyr - melt * 0.3}) rotate(${sway}deg)`}}>
          <Pyramid size={340} />
        </div>
      )}
    </div>
  );
};

// ---------------------------------------------------------------- football

const Ball: React.FC<P<'ball'>> = ({t, at, x, y, size = 150}) => {
  const k = t - at;
  if (k < 0) return null;
  const f = Math.min(1, k / 1.0);
  const bx = 1250 + (x - 1250) * (1 - Math.pow(1 - f, 2));
  // three bounces getting smaller, then a little keepy-uppy hop
  const hop = f < 1 ? Math.abs(Math.sin(f * Math.PI * 3)) * 380 * (1 - f) : Math.abs(Math.sin((k - 1) * 5)) * 40;
  const spin = -k * 540 * (f < 1 ? 1 : 0.3);
  return (
    <>
      <div style={{position: 'absolute', left: bx - size * 0.45, top: y + size * 0.42, width: size * 0.9, height: size * 0.2, borderRadius: '50%', background: 'rgba(0,0,0,0.18)', transform: `scale(${1 - hop / 600})`}} />
      <div style={{position: 'absolute', left: bx - size / 2, top: y - size / 2 - hop, width: size, height: size, borderRadius: '50%', background: 'white', color: color('ink'), fontSize: size, lineHeight: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', transform: `rotate(${spin}deg)`, boxShadow: `0 0 0 6px ${color('cocoa')}`}}>
        <FontAwesomeIcon icon={ICONS.football} />
      </div>
    </>
  );
};

// ---------------------------------------------------------------- Coptic letters raining down on the brothers

const HEADS = [
  {x: 330, y: 560},
  {x: 750, y: 640},
];

const Rain: React.FC<P<'rain'>> = ({t, at = 0, count = 26}) => {
  const g = 2600;
  return (
    <>
      {Array.from({length: count}, (_, i) => {
        const k = t - at - i * 0.09;
        if (k < 0) return null;
        const x0 = 90 + random(`rx${i}`) * 900;
        const y0 = -160;
        const v0 = 300 + random(`rv${i}`) * 300;
        const head = HEADS.find((h) => Math.abs(h.x - x0) < 110);
        const ground = 1240 + random(`rg${i}`) * 80;
        const stop = head ? head.y : ground;
        // time to reach the head / ground: y0 + v0 t + g t^2 / 2 = stop
        const t1 = (-v0 + Math.sqrt(v0 * v0 + 2 * g * (stop - y0))) / g;
        let x = x0;
        let y: number;
        let rot = (random(`rr${i}`) - 0.5) * 200 * k;
        if (k < t1) {
          y = y0 + v0 * k + (g * k * k) / 2;
        } else {
          const b = k - t1;
          const vb = head ? 900 : 500;
          const vx = head ? (x0 < head.x ? -1 : 1) * 380 : 0;
          x = x0 + vx * b;
          y = stop - vb * b + (g * b * b) / 2;
          if (!head) y = Math.min(stop, y);
          rot += b * 400 * (vx >= 0 ? 1 : -1);
        }
        const fade = head ? 1 : interpolate(k - t1, [0.6, 1.2], [1, 0], clamp);
        if (y > 2000 || fade <= 0) return null;
        return <GoldLetter key={i} k={KEYS[i % KEYS.length]} size={80 + random(`rs${i}`) * 50} style={{position: 'absolute', left: x - 40, top: y - 50, transform: `rotate(${rot}deg)`, opacity: fade}} />;
      })}
    </>
  );
};

// ---------------------------------------------------------------- letter slots (counting the letters)

const Slots: React.FC<P<'slots'>> = ({t, fps, total, filled, to, stretchAt, labels}) => {
  const S = 68;
  const GAP = 11;
  const st = to !== undefined && stretchAt !== undefined ? t - stretchAt : -1;
  const n = st >= 0 ? to! : total;
  const cols = n > 10 ? 8 : n;
  const layout = (i: number, c: number) => {
    const rows = Math.ceil(n / c);
    const r = Math.floor(i / c);
    const col = i % c;
    const w = c * S + (c - 1) * GAP;
    return [540 - w / 2 + col * (S + GAP), 250 + r * (S + GAP) + (rows > 1 ? 0 : 30)];
  };
  const move = st >= 0 ? sp(st, fps, 13, 140) : 1;
  const label = (labels ?? []).filter((l) => t >= l.at).pop();
  const lp = label ? sp(t - label.at, fps, 9, 200) : 0;
  const rows = Math.ceil(n / cols);
  const labelTop = 250 + rows * (S + GAP) + (rows > 1 ? 4 : 60);

  return (
    <>
      {Array.from({length: n}, (_, i) => {
        const [x1, y1] = layout(i, cols);
        let x = x1;
        let y = y1;
        let s = sp(t + 0.4 - i * 0.04, fps, 10, 200);
        if (st >= 0) {
          if (i < total) {
            const [x0, y0] = (() => {
              const c = total;
              const w = c * S + (c - 1) * GAP;
              return [540 - w / 2 + i * (S + GAP), 280];
            })();
            x = x0 + (x1 - x0) * move;
            y = y0 + (y1 - y0) * move;
            s = 1;
          } else {
            s = sp(st - 0.1 - (i - total) * 0.035, fps, 9, 220);
          }
        }
        const full = i < filled;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x,
              top: y,
              width: S,
              height: S,
              borderRadius: 18,
              background: full ? color('cream') : 'rgba(255,255,255,0.35)',
              border: `6px ${full ? 'solid' : 'dashed'} ${full ? GOLD : color('cocoa')}`,
              transform: `scale(${s})`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {full && <GoldLetter k="A" size={56} />}
          </div>
        );
      })}
      {label && (
        <div style={{position: 'absolute', left: 0, right: 0, top: labelTop, display: 'flex', justifyContent: 'center'}}>
          <div style={{background: color('coral'), border: `7px solid ${color('cocoa')}`, borderRadius: 40, padding: '6px 40px 10px', textAlign: 'center', transform: `scale(${lp}) rotate(${-3 * lp}deg)`}}>
            <span dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 80, color: 'white'}}>
              {label.ar}
            </span>
            <span style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 56, color: color('cream'), marginLeft: 24}}>{label.en}</span>
          </div>
        </div>
      )}
    </>
  );
};

// ---------------------------------------------------------------- speed lines & arrow

const Speed: React.FC<P<'speed'>> = ({t, at = -1, until = 99}) => {
  if (t < at || t > until) return null;
  return (
    <>
      {Array.from({length: 14}, (_, i) => {
        const y = 500 + random(`sy${i}`) * 900;
        const len = 200 + random(`sl${i}`) * 300;
        const x = ((t * (2400 + random(`sv${i}`) * 1600) + random(`sx${i}`) * 1500) % 1800) - 400;
        return <div key={i} style={{position: 'absolute', left: x, top: y, width: len, height: 14, borderRadius: 8, background: 'white', opacity: 0.55}} />;
      })}
    </>
  );
};

const Arrow: React.FC<P<'arrow'>> = ({t, fps, at, x, y, dir}) => {
  const p = sp(t - at, fps, 9, 200);
  if (p <= 0) return null;
  const nudge = Math.sin((t - at) * 12) * 18 * (dir === 'right' ? 1 : -1);
  return (
    <div style={{position: 'absolute', left: x - 90 + nudge, top: y - 90, width: 180, height: 180, borderRadius: 90, background: color('leafGreen'), border: `9px solid ${color('cocoa')}`, color: 'white', fontSize: 96, display: 'flex', alignItems: 'center', justifyContent: 'center', transform: `scale(${p})`}}>
      <FontAwesomeIcon icon={ICONS[dir === 'right' ? 'arrowRight' : 'arrowLeft']} />
    </div>
  );
};

// ---------------------------------------------------------------- running letter (Ⲉ on little legs)

const Runner: React.FC<P<'runner'>> = ({t, k, size = 260, path}) => {
  if (!path.length || t < path[0].at) return null;
  // where along the path: between keyframe i and i+1 (hop = arc height)
  let i = path.length - 1;
  for (let j = 0; j < path.length - 1; j++) if (t < path[j + 1].at) { i = j; break; }
  const a = path[i];
  const b = path[Math.min(i + 1, path.length - 1)];
  const p = b === a ? 1 : Math.min(1, (t - a.at) / (b.at - a.at));
  const x = a.x + (b.x - a.x) * p;
  const arc = Math.sin(p * Math.PI) * (b.hop ?? 0);
  const y = a.y + (b.y - a.y) * p - arc;
  const moving = b !== a && p < 1;
  const dir = b.x < a.x ? -1 : 1;
  const step = t * 26;
  const bob = moving && !b.hop ? Math.abs(Math.sin(step)) * 16 : 0;
  const spin = b.hop ? p * 360 * dir : 0;
  const lean = moving && !b.hop ? 10 * dir : 0;
  const leg = (side: number) => {
    const sw = moving ? Math.sin(step + side * Math.PI) * 32 : 0;
    return <line x1={side * 30} y1={0} x2={side * 30 + sw} y2={size * 0.32} stroke={color('cocoa')} strokeWidth={16} strokeLinecap="round" />;
  };
  return (
    <div style={{position: 'absolute', left: x, top: y - bob, width: 0, height: 0, transform: `rotate(${lean + spin}deg)`}}>
      {/* dust puffs behind */}
      {moving &&
        !b.hop &&
        [0, 1, 2].map((n) => {
          const q = ((t * 3 + n / 3) % 1);
          return <div key={n} style={{position: 'absolute', left: -dir * (60 + q * 160) - 30, top: size * 0.3 - q * 30, width: 60 + q * 50, height: 60 + q * 50, borderRadius: '50%', background: 'white', opacity: 0.7 * (1 - q)}} />;
        })}
      <svg width={200} height={size * 0.4} style={{position: 'absolute', left: -100, top: size * 0.3, overflow: 'visible'}}>
        <g transform={`translate(100 0)`}>
          {leg(-1)}
          {leg(1)}
        </g>
      </svg>
      <div style={{position: 'absolute', left: -size / 2, top: -size / 2, width: size, height: size, display: 'flex', alignItems: 'center', justifyContent: 'center', transform: dir < 0 ? 'scaleX(-1)' : undefined}}>
        {/* white outline so the gold letter stands out against sandstone */}
        <GoldLetter k={k} size={size} style={{textShadow: [...Array.from({length: 12}, (_, n) => `${Math.cos((n / 12) * Math.PI * 2) * 7}px ${Math.sin((n / 12) * Math.PI * 2) * 7}px 0 white`), `0 0 ${size * 0.15}px ${GLOW}`].join(', ')}} />
        {/* eyes */}
        {[-1, 1].map((e) => (
          <div key={e} style={{position: 'absolute', left: size / 2 + e * size * 0.1 - size * 0.06, top: size * 0.3, width: size * 0.12, height: size * 0.15, borderRadius: '50%', background: 'white', border: `5px solid ${color('cocoa')}`}}>
            <div style={{position: 'absolute', left: '45%', top: '35%', width: '45%', height: '45%', borderRadius: '50%', background: color('cocoa')}} />
          </div>
        ))}
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- little living statues

const STONE = color('fortWall');
const STONE_DARK = `color-mix(in srgb, ${STONE} 70%, black)`;
const STATUES: {w: number; h: number; draw: React.ReactNode}[] = [
  // cat (Bastet)
  {w: 130, h: 200, draw: <path d="M30 200 L30 90 L15 20 L50 55 L80 55 L115 20 L100 90 L105 200 Z" fill={color('ink')} />},
  // canopic jar
  {w: 130, h: 190, draw: <><path d="M20 80 Q15 190 65 190 Q115 190 110 80 Z" fill={STONE} /><circle cx={65} cy={55} r={42} fill={color('sunYellow')} /></>},
  // queen bust
  {w: 140, h: 210, draw: <><path d="M15 210 Q20 130 70 125 Q120 130 125 210 Z" fill={color('mistBlue')} /><circle cx={70} cy={95} r={42} fill={STONE} /><path d="M35 70 L45 0 L105 0 L110 70 Z" fill={color('deepTeal')} /></>},
  // ankh
  {w: 110, h: 210, draw: <><ellipse cx={55} cy={45} rx={30} ry={40} fill="none" stroke={color('letterGold')} strokeWidth={22} /><path d="M45 80 L65 80 L65 210 L45 210 Z M10 95 L100 95 L100 115 L10 115 Z" fill={color('letterGold')} /></>},
];

// Social images of the little statues (drawn shapes stand in until they exist).
const STATUE_IMAGES = ['statue-cat', 'statue-ushabti'];

const Statues: React.FC<P<'statues'>> = ({t, fps, at = -1, y = 1300, chaseAt, chase = 'left', passAt}) => {
  const xs = [330, 750];
  return (
    <>
      {STATUES.slice(0, 2).map((st, i) => {
        const dir = chase === 'left' ? -1 : 1;
        // pass: they come in from the other side and run across the screen in a line
        const pk = passAt !== undefined ? t - passAt - i * 0.18 : -1;
        if (passAt !== undefined && pk < 0) return null;
        const inP = passAt !== undefined ? 1 : sp(t - at - i * 0.12, fps, 10, 180);
        if (inP <= 0) return null;
        const c = passAt !== undefined ? pk : chaseAt !== undefined ? t - chaseAt - i * 0.1 : -1;
        // tiptoe: little hops and looking around; chase: running off-screen
        const run = passAt !== undefined ? (-1100 + pk * 1700) * dir - (xs[i] - 540) : c > 0 ? c * 1500 * dir : 0;
        const hopF = c > 0 ? 9 : 4.5;
        const hop = Math.abs(Math.sin(t * hopF + i * 1.7)) * (c > 0 ? 40 : 22);
        const look = c > 0 ? dir : Math.sin(t * 1.6 + i * 2) > 0 ? 1 : -1;
        const tilt = Math.sin(t * hopF + i) * (c > 0 ? 12 : 6);
        const s = 1.15;
        return (
          <div key={i} style={{position: 'absolute', left: xs[i] - (st.w * s) / 2 + run, top: y - st.h * s - hop, width: st.w * s, height: st.h * s, transformOrigin: '50% 100%', transform: `scale(${inP}) rotate(${tilt}deg) scaleX(${look})`}}>
            {images[STATUE_IMAGES[i]] ? (
              <Img src={staticFile(images[STATUE_IMAGES[i]])} style={{position: 'absolute', left: '50%', bottom: 0, height: 270, transform: 'translateX(-50%)'}} />
            ) : (
            <svg viewBox={`0 0 ${st.w} ${st.h}`} width="100%" height="100%" style={{overflow: 'visible'}}>
              <g stroke={color('cocoa')} strokeWidth={7} strokeLinejoin="round">{st.draw}</g>
              {/* searching eyes */}
              {[-1, 1].map((e) => (
                <g key={e}>
                  <circle cx={st.w / 2 + e * 16} cy={i === 3 ? 45 : i === 0 ? 80 : i === 1 ? 55 : 95} r={12} fill="white" stroke={color('cocoa')} strokeWidth={4} />
                  <circle cx={st.w / 2 + e * 16 + 5} cy={i === 3 ? 45 : i === 0 ? 80 : i === 1 ? 55 : 95} r={6} fill={color('cocoa')} />
                </g>
              ))}
            </svg>
            )}
            <div style={{position: 'absolute', left: '10%', right: '10%', bottom: -10, height: 16, borderRadius: '50%', background: 'rgba(0,0,0,0.15)'}} />
          </div>
        );
      })}
    </>
  );
};

// ---------------------------------------------------------------- dizzy stars, panting, comparison, confetti

const Dizzy: React.FC<P<'dizzy'>> = ({t, at, x, y, until}) => {
  const k = t - at;
  if (k < 0 || (until !== undefined && t > until)) return null;
  const grow = Math.min(1, k / 0.2);
  return (
    <>
      {Array.from({length: 5}, (_, i) => {
        const a = k * 7 + (i / 5) * Math.PI * 2;
        const front = Math.sin(a) > 0;
        return (
          <div key={i} style={{position: 'absolute', left: x + Math.cos(a) * 150 * grow - 30, top: y + Math.sin(a) * 40 * grow - 30, fontSize: 60, color: i % 2 ? color('sunYellow') : 'white', opacity: front ? 1 : 0.6, transform: `scale(${front ? 1 : 0.75}) rotate(${k * 300}deg)`, filter: `drop-shadow(0 0 2px ${color('cocoa')})`}}>
            <FontAwesomeIcon icon={ICONS.star} />
          </div>
        );
      })}
    </>
  );
};

const Pant: React.FC<P<'pant'>> = ({t, at, x, y, until, dir = 'right'}) => {
  const k = t - at;
  if (k < 0 || (until !== undefined && t > until)) return null;
  const d = dir === 'right' ? 1 : -1;
  return (
    <>
      {/* breath puffs, one every 0.45 s */}
      {[0, 1, 2].map((n) => {
        const q = (k / 0.45 + n / 3) % 1;
        return <div key={`b${n}`} style={{position: 'absolute', left: x + d * (20 + q * 130) - 30, top: y - q * 30 - 30, width: 50 + q * 60, height: 40 + q * 45, borderRadius: '50%', background: 'white', border: `5px solid ${color('mistBlue')}`, opacity: 0.9 * (1 - q)}} />;
      })}
      {/* sweat drops popping off the head */}
      {[0, 1].map((n) => {
        const q = (k / 0.7 + n / 2) % 1;
        const sx = (n ? 1 : -1) * (60 + q * 90);
        return (
          <svg key={`s${n}`} width={36} height={50} style={{position: 'absolute', left: x + sx - 18, top: y - 170 - Math.sin(q * Math.PI) * 70 + q * 60, opacity: 1 - q * 0.8, transform: `rotate(${sx * 0.3}deg)`}}>
            <path d="M18 2 Q34 30 18 48 Q2 30 18 2 Z" fill={color('mistBlue')} stroke={color('deepTeal')} strokeWidth={4} />
          </svg>
        );
      })}
    </>
  );
};

const Compare: React.FC<P<'compare'>> = ({t, fps, at, k, latin, y = 470, outAt}) => {
  const out = outAt !== undefined ? interpolate(t - outAt, [0, 0.25], [1, 0], clamp) : 1;
  const a = sp(t - at, fps, 10, 170) * out;
  const b = sp(t - at - 0.35, fps, 9, 200) * out;
  const eq = sp(t - at - 0.2, fps, 9, 220) * out;
  if (a <= 0) return null;
  const S = 280;
  const tile = (left: number, p: number, bg: string, child: React.ReactNode) => (
    <div style={{position: 'absolute', left, top: y, width: S, height: S, borderRadius: 50, background: bg, border: `9px solid ${color('cocoa')}`, boxShadow: `0 12px 0 ${color('cocoa')}`, display: 'flex', alignItems: 'center', justifyContent: 'center', transform: `scale(${p}) rotate(${(left < 540 ? -4 : 4) + Math.sin(t * 2.5) * 2}deg)`}}>
      {child}
    </div>
  );
  return (
    <>
      {tile(110, a, `radial-gradient(circle at 50% 40%, ${color('slateTeal')}, ${color('deepTeal')})`, <GoldLetter k={k} size={230} />)}
      <div style={{position: 'absolute', left: 540 - 60, top: y + S / 2 - 70, width: 120, textAlign: 'center', fontFamily: FONT_EN, fontWeight: 800, fontSize: 130, lineHeight: 1, color: 'white', textShadow: `0 6px 0 ${color('cocoa')}`, transform: `scale(${eq})`}}>≈</div>
      {tile(1080 - 110 - S, b, color('coral'), <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 230, lineHeight: 1, color: 'white', marginTop: 30, textShadow: `0 8px 0 ${color('cocoa')}`}}>{latin}</div>)}
    </>
  );
};

// Two Iotas slide together, a line joins them into the letter (`k`, e.g. Ita),
// then a small Arabic sound letter grows into a big one ("a big ي").
const TwoIotas: React.FC<P<'twoIotas'>> = ({t, fps, at, joinAt, soundAt, outAt, k = '#', iota = 'I', sound = 'ي', y = 330}) => {
  const out = outAt !== undefined ? interpolate(t - outAt, [0, 0.25], [1, 0], clamp) : 1;
  const a = sp(t - at, fps, 10, 170) * out;
  if (a <= 0) return null;
  const W = 760;
  const H = 520;
  const slide = interpolate(t - at, [0.35, 0.9], [150, 0], {...clamp, easing: (v) => 1 - (1 - v) ** 3});
  const draw = interpolate(t - joinAt, [0, 0.45], [0, 1], clamp);
  const morph = interpolate(t - joinAt, [0.55, 0.85], [0, 1], clamp);
  const pop = sp(t - joinAt - 0.55, fps, 8, 220);
  const s1 = sp(t - soundAt, fps, 10, 200);
  const grow = sp(t - soundAt - 0.55, fps, 8, 160);
  const legX = 205 + slide;
  const iotaLeg = (left: boolean) => (
    <div style={{position: 'absolute', top: 40, width: 220, textAlign: 'center', left: left ? W / 2 - legX - 110 : W / 2 + legX - 110, opacity: 1 - morph}}>
      <GoldLetter k={iota} size={360} />
      <div style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 44, color: 'white', marginTop: -10, textShadow: `0 4px 0 ${color('cocoa')}`}}>يوتا</div>
    </div>
  );
  const big = 64 + grow * 120;
  return (
    <div style={{position: 'absolute', left: 540 - W / 2, top: y, width: W, height: H + 330, transform: `scale(${a})`}}>
      <div style={{position: 'absolute', inset: 0, height: H, borderRadius: 60, background: `radial-gradient(circle at 50% 40%, ${color('slateTeal')}, ${color('deepTeal')})`, border: `10px solid ${color('cocoa')}`, boxShadow: `0 14px 0 ${color('cocoa')}`}} />
      {iotaLeg(true)}
      {iotaLeg(false)}
      <svg width={W} height={H} style={{position: 'absolute', left: 0, top: 0, opacity: 1 - morph}}>
        <line x1={W / 2 - legX + 20} y1={H * 0.4} x2={W / 2 - legX + 20 + (2 * legX - 40) * draw} y2={H * 0.4} stroke={color('cocoa')} strokeWidth={40} strokeLinecap="round" opacity={draw > 0 ? 1 : 0} />
        <line x1={W / 2 - legX + 20} y1={H * 0.4} x2={W / 2 - legX + 20 + (2 * legX - 40) * draw} y2={H * 0.4} stroke={color('coral')} strokeWidth={26} strokeLinecap="round" opacity={draw > 0 ? 1 : 0} />
      </svg>
      {morph > 0 && (
        <div style={{position: 'absolute', left: 0, top: 30, width: W, display: 'flex', justifyContent: 'center', opacity: morph, transform: `scale(${0.8 + 0.2 * pop})`}}>
          <GoldLetter k={k} size={420} />
        </div>
      )}
      {s1 > 0 && (
        <div style={{position: 'absolute', left: 0, top: H + 40, width: W, display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 30, transform: `scale(${s1})`}}>
          <div style={{minWidth: 150, height: 150 + grow * 110, padding: '0 34px', borderRadius: 44, background: color('coral'), border: `8px solid ${color('cocoa')}`, boxShadow: `0 10px 0 ${color('cocoa')}`, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
            <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: big, lineHeight: 1, color: 'white', textShadow: `0 6px 0 ${color('cocoa')}`}}>{sound}</div>
          </div>
          {grow > 0.05 && (
            <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 70, color: 'white', textShadow: `0 6px 0 ${color('cocoa')}`, opacity: grow}}>كبيرة!</div>
          )}
        </div>
      )}
    </div>
  );
};

const CONFETTI = ['coral', 'sunYellow', 'leafGreen', 'mistBlue', 'letterGold', 'white'];
const Confetti: React.FC<P<'confetti'>> = ({t, at, count = 70}) => {
  const k = t - at;
  if (k < 0) return null;
  return (
    <>
      {Array.from({length: count}, (_, i) => {
        const r = (n: string) => random(`conf-${i}-${n}`);
        const x0 = 540 + (r('x') - 0.5) * 300;
        const vx = (r('vx') - 0.5) * 1400;
        const vy = -900 - r('vy') * 900;
        const x = x0 + vx * k;
        const y = 900 + vy * k + 1200 * k * k;
        if (y > 2000) return null;
        return <div key={i} style={{position: 'absolute', left: x, top: y, width: 22 + r('w') * 16, height: 12 + r('h') * 10, borderRadius: 4, background: color(CONFETTI[i % CONFETTI.length]), transform: `rotate(${k * (300 + r('rot') * 600)}deg) scaleY(${Math.cos(k * 12 + i)})`}} />;
      })}
    </>
  );
};

// ---------------------------------------------------------------- sand (digging spray, sand pyramid)

const SAND = ['pyramidDune', 'pyramidShade', 'sunYellow'];
const Sand: React.FC<P<'sand'>> = ({t, at, x, y, until, dir = 'up', burst, fall}) => {
  const end = burst ? at + 0.05 : (until ?? at + 1);
  if (fall) {
    // grains thrown up come raining down onto (x, y)
    return (
      <>
        {Array.from({length: 70}, (_, i) => {
          const r = (n: string) => random(`fall-${at}-${i}-${n}`);
          const k = t - (at + (i / 70) * (end - at));
          if (k < 0 || k > 0.6) return null;
          const px = x + (r('x') - 0.5) * 170 + (r('d') - 0.5) * 60 * k;
          const py = y - 320 + 1800 * k * k + r('y') * 40;
          const s = 9 + r('w') * 14;
          return <div key={i} style={{position: 'absolute', left: px - s / 2, top: py - s / 2, width: s, height: s, borderRadius: '45%', background: color(SAND[i % SAND.length]), border: `2px solid ${color('cocoa')}`, opacity: k > 0.45 ? (0.6 - k) / 0.15 : 1}} />;
        })}
      </>
    );
  }
  return (
    <>
      {Array.from({length: burst ? 60 : 90}, (_, i) => {
        const r = (n: string) => random(`sand-${at}-${i}-${n}`);
        const born = burst ? at : at + (i / 90) * (end - at);
        const k = t - born;
        if (k < 0 || k > 0.9) return null;
        const side = dir === 'left' ? -1 : dir === 'right' ? 1 : r('s') < 0.5 ? -1 : 1;
        const vx = side * (burst ? 200 + r('vx') * 700 : 150 + r('vx') * 450);
        const vy = -(burst ? 500 + r('vy') * 900 : 700 + r('vy') * 700);
        const px = x + vx * k;
        const py = y + vy * k + 2200 * k * k;
        const s = 10 + r('w') * 16;
        return <div key={i} style={{position: 'absolute', left: px - s / 2, top: py - s / 2, width: s, height: s, borderRadius: '45%', background: color(SAND[i % SAND.length]), border: `2px solid ${color('cocoa')}`, opacity: 1 - k / 0.9}} />;
      })}
    </>
  );
};

const SandPile: React.FC<P<'sandpile'>> = ({t, fps, x, y, size = 360, grow, peekAt, glowAt, k = 'I', outAt}) => {
  // each `grow` time adds a step of height (a sand pat); no times = already built
  const steps = grow?.length ? grow.reduce((h, g) => h + sp(t - g, fps, 8, 220) / grow.length, 0) : 1;
  if (steps <= 0.01) return null;
  const glow = glowAt !== undefined ? interpolate(t - glowAt, [0, 0.4], [0, 1], clamp) : 0;
  const pulse = 0.75 + Math.sin(t * 8) * 0.25;
  const pop = outAt !== undefined ? sp(t - outAt, fps, 9, 170) : 0;
  const h = size * 0.8 * steps;
  // after popping out it hands over (e.g. to a `runner` flying to a hand)
  const popFade = outAt !== undefined ? interpolate(t - outAt, [0.45, 0.6], [1, 0], clamp) : 1;
  // the letter's top sticking out of the sand by the peak, with a glint now and then
  const peek = peekAt !== undefined && t >= peekAt && pop <= 0.02 ? Math.min(1, (t - peekAt) / 0.3) : 0;
  const glint = Math.max(0, Math.sin(t * 4.5)) ** 8;
  return (
    <div style={{position: 'absolute', left: x - size / 2, top: y - h, width: size, height: h}}>
      {peek > 0 && (
        <>
          <GoldLetter k={k} size={size * 0.4} style={{position: 'absolute', left: size * 0.42, top: -size * 0.2 + (1 - peek) * size * 0.2, transform: 'rotate(14deg)'}} />
          <svg width={60} height={60} viewBox="-30 -30 60 60" style={{position: 'absolute', left: size * 0.52 - 30, top: -size * 0.18 - 30, transform: `scale(${glint})`}}>
            <path d="M0 -28 L6 -6 L28 0 L6 6 L0 28 L-6 6 L-28 0 L-6 -6 Z" fill="white" stroke={color('sunYellow')} strokeWidth={3} />
          </svg>
        </>
      )}
      {glow > 0 && <div style={{position: 'absolute', left: size * 0.1, top: -size * 0.15, width: size * 0.8, height: h + size * 0.2, borderRadius: '50%', background: `radial-gradient(circle, ${GLOW} 0%, transparent 65%)`, opacity: glow * pulse}} />}
      <svg width={size} height={h} viewBox="0 0 100 80" preserveAspectRatio="none" style={{position: 'absolute', left: 0, top: 0}}>
        <path d="M2,79 Q8,74 14,64 L46,6 Q50,0 54,6 L86,64 Q92,74 98,79 Z" fill={color('pyramidDune')} stroke={color('cocoa')} strokeWidth={3} strokeLinejoin="round" />
        <path d="M50,3 L86,64 Q92,74 98,79 L64,79 Z" fill={color('pyramidShade')} />
        {[[30, 40], [55, 58], [40, 70], [62, 34]].map(([cx, cy]) => (
          <circle key={`${cx}`} cx={cx} cy={cy} r={1.6} fill={color('cocoa')} opacity={0.35} />
        ))}
      </svg>
      {glow > 0 && popFade > 0 && <GoldLetter k={k} size={size * 0.42} style={{position: 'absolute', left: size * 0.3, top: h * 0.4 - pop * size * 0.9, opacity: (peekAt !== undefined ? pop : Math.max(glow * 0.5, pop)) * popFade, transform: `scale(${1 + pop * 0.5}) rotate(${pop * -10}deg)`}} />}
    </div>
  );
};

// ---------------------------------------------------------------- speech bubble (kids-magazine style, on screen)

const Speech: React.FC<P<'speech'>> = ({t, fps, ar, en, at, outAt, x = 540, y = 190, width = 900, height, size = 70, tailTo, tailX}) => {
  const out = outAt !== undefined ? interpolate(t - outAt, [0, 0.2], [1, 0], clamp) : 1;
  const p = sp(t - at, fps, 10, 190) * out;
  if (p <= 0.01) return null;
  const [tx, ty] = tailTo;
  const H = height ?? (en ? 230 : 160);
  const bottom = y + H;
  const bx = Math.min(x + width / 2 - 110, Math.max(x - width / 2 + 110, tailX ?? tx));
  const wob = Math.sin(t * 3) * 1.2;
  return (
    <div style={{position: 'absolute', inset: 0, transform: `scale(${0.6 + 0.4 * p}) rotate(${wob}deg)`, transformOrigin: `${bx}px ${bottom}px`, opacity: Math.min(1, p * 1.5)}}>
      <svg width={1080} height={1920} style={{position: 'absolute', left: 0, top: 0}}>
        <polygon points={`${bx - 46},${bottom - 20} ${bx + 46},${bottom - 20} ${tx},${ty}`} fill="white" stroke={color('cocoa')} strokeWidth={9} strokeLinejoin="round" />
      </svg>
      <div style={{position: 'absolute', left: x - width / 2, top: y, width, height: H, boxSizing: 'border-box', background: 'white', border: `9px solid ${color('cocoa')}`, borderRadius: 70, boxShadow: `0 12px 0 ${color('cocoa')}`, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 40px'}}>
        <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: size, lineHeight: 1.15, color: color('deepTeal'), textAlign: 'center'}}>{ar}</div>
        {en && <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: Math.round(size * 0.55), lineHeight: 1.1, color: color('coral'), textAlign: 'center'}}>{en}</div>}
      </div>
      {/* hide the tail's outline where it meets the bubble */}
      <div style={{position: 'absolute', left: bx - 37, top: bottom - 16, width: 74, height: 14, background: 'white'}} />
    </div>
  );
};

// ---------------------------------------------------------------- warning banner (a yellow note on screen)

const Banner: React.FC<P<'banner'>> = ({t, fps, at, ar, en, y = 250, outAt}) => {
  const out = outAt !== undefined ? interpolate(t - outAt, [0, 0.25], [1, 0], clamp) : 1;
  const p = sp(t - at, fps, 10, 190) * out;
  if (p <= 0) return null;
  const blink = 0.85 + 0.15 * Math.sin((t - at) * 9);
  return (
    <div
      style={{
        position: 'absolute',
        left: 90,
        top: y,
        width: 900,
        padding: '22px 30px',
        borderRadius: 28,
        background: color('sunYellow'),
        border: `8px solid ${color('cocoa')}`,
        boxShadow: `0 14px 0 ${color('cocoa')}`,
        display: 'flex',
        alignItems: 'center',
        gap: 26,
        transform: `scale(${p}) rotate(${-2 + Math.sin(t * 2) * 0.8}deg)`,
        opacity: out,
      }}
    >
      <div style={{fontSize: 92, color: color('cocoa'), opacity: blink, flexShrink: 0}}>
        <FontAwesomeIcon icon={ICONS.warning} />
      </div>
      <div style={{flex: 1, textAlign: 'center'}}>
        <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 72, lineHeight: 1.1, color: color('cocoa')}}>
          {ar}
        </div>
        <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 40, lineHeight: 1.15, color: color('deepTeal')}}>{en}</div>
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- magic swirl (دوامة): an electric-blue 3D tunnel

// Neon rings and spiral arms rush out of a white-hot centre towards the camera,
// with light streaks flying past, so it feels like flying down a glowing tunnel.
const Vortex: React.FC<P<'vortex'>> = ({t, fps, at, outAt, x = 540, y = 900, size = 760, full, to}) => {
  if (t < at) return null;
  const open = full ? 1 : sp(t - at, fps, 14, 90);
  const close = outAt !== undefined ? interpolate(t - outAt, [0, 0.35], [1, 0], clamp) : 1;
  // full screen, then (to) it shrinks and slides away
  const m = full && to ? interpolate(t - to.at, [0, to.dur ?? 0.8], [0, 1], clamp) : 0;
  const me = m < 0.5 ? 2 * m * m : 1 - Math.pow(-2 * m + 2, 2) / 2;
  const R = (full ? 1250 + ((to?.size ?? 0) / 2 - 1250) * me : size / 2) * open * close;
  const cx = full ? 540 + ((to?.x ?? 540) - 540) * me : x;
  const cy = full ? 960 + ((to?.y ?? 960) - 960) * me : y;
  if (R < 2) return null;
  const k = t - at;
  const speed = full ? 0.9 : 0.55; // rings per second towards the camera
  const RINGS = 18;
  const ring = (i: number) => {
    const d = (i / RINGS + k * speed) % 1; // 0 = deep in the tunnel, 1 = at the camera
    const r = R * Math.pow(d, 2.1);
    const tw = d * 220 + k * 140; // the tunnel twists as it comes closer
    const pts: string[] = [];
    for (let j = 0; j <= 72; j++) {
      const a = (j / 72) * Math.PI * 2;
      const rr = r * (1 + 0.07 * Math.sin(6 * a + (tw * Math.PI) / 180));
      pts.push(`${(Math.cos(a) * rr).toFixed(1)},${(Math.sin(a) * rr).toFixed(1)}`);
    }
    const w = 2 + 22 * d * d;
    const o = Math.min(1, d * 3) * (full ? 1 : 1 - Math.pow(d, 6));
    return {pts: pts.join(' '), w, o, hue: i % 3};
  };
  const ARMS = 5;
  const arm = (n: number) => {
    const pts: string[] = [];
    for (let j = 0; j <= 48; j++) {
      const f = j / 48;
      const r = R * Math.pow(f, 1.6);
      const a = ((n * 360) / ARMS + f * 320 - k * 200) * (Math.PI / 180);
      pts.push(`${(Math.cos(a) * r).toFixed(1)},${(Math.sin(a) * r).toFixed(1)}`);
    }
    return pts.join(' ');
  };
  const NEON = ['#00E5FF', '#2F7BFF', '#9FD8FF'];
  const rings = Array.from({length: RINGS}, (_, i) => ring(i)).sort((p, q) => p.w - q.w);
  return (
    <div style={{position: 'absolute', left: cx, top: cy, width: 0, height: 0}}>
      {/* see-through: only a soft white glow in the middle (the scene shows behind the rings) */}
      <div style={{position: 'absolute', left: -R, top: -R, width: R * 2, height: R * 2, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(255,255,255,0.95) 0%, rgba(220,248,255,0.7) 6%, rgba(160,225,255,0.28) 18%, rgba(120,200,255,0.1) 38%, rgba(255,255,255,0) 62%)'}} />
      <svg width={R * 2} height={R * 2} style={{position: 'absolute', left: -R, top: -R, overflow: 'visible'}}>
        <g transform={`translate(${R} ${R})`}>
          {/* spiral arms (soft glow + bright core) */}
          {Array.from({length: ARMS}, (_, n) => (
            <g key={`a${n}`}>
              <polyline points={arm(n)} fill="none" stroke="#2F7BFF" strokeWidth={Math.max(8, R * 0.07)} strokeLinecap="round" opacity={0.35} />
              <polyline points={arm(n)} fill="none" stroke="#7FE9FF" strokeWidth={Math.max(3, R * 0.018)} strokeLinecap="round" opacity={0.85} />
            </g>
          ))}
          {/* tunnel rings rushing towards the camera */}
          {rings.map((g, i) => (
            <g key={`r${i}`} opacity={g.o}>
              <polygon points={g.pts} fill="none" stroke={NEON[g.hue]} strokeWidth={g.w * 2.6} opacity={0.22} strokeLinejoin="round" />
              <polygon points={g.pts} fill="none" stroke={g.hue === 2 ? '#FFFFFF' : NEON[g.hue]} strokeWidth={g.w} opacity={0.9} strokeLinejoin="round" />
            </g>
          ))}
        </g>
      </svg>
      {/* light streaks flying past */}
      {Array.from({length: full ? 34 : 16}, (_, i) => {
        const q = (k * (full ? 1.4 : 1) + random(`vs${i}`)) % 1;
        const a = random(`va${i}`) * Math.PI * 2;
        const r0 = R * 0.08 + R * Math.pow(q, 2) * 1.1;
        const len = 20 + R * 0.35 * q * q;
        return (
          <div key={i} style={{position: 'absolute', left: Math.cos(a) * r0, top: Math.sin(a) * r0, width: len, height: Math.max(2, 7 * q),
            borderRadius: 4, background: i % 4 ? '#BFF6FF' : 'white', opacity: Math.min(1, q * 3) * 0.9, transformOrigin: '0 50%', transform: `rotate(${(a * 180) / Math.PI}deg)`,
            boxShadow: '0 0 12px #29B6FF'}} />
        );
      })}
    </div>
  );
};

// ---------------------------------------------------------------- a dropped gold letter (falls, tumbles, rests and glows)

const Drop: React.FC<P<'drop'>> = ({t, k, size = 200, outAt, path}) => {
  if (!path.length || t < path[0].at) return null;
  const out = outAt !== undefined ? interpolate(t - outAt, [0, 0.2], [1, 0], clamp) : 1;
  if (out <= 0) return null;
  let i = path.length - 1;
  for (let j = 0; j < path.length - 1; j++) if (t < path[j + 1].at) { i = j; break; }
  const a = path[i];
  const b = path[Math.min(i + 1, path.length - 1)];
  const p = b === a ? 1 : Math.min(1, (t - a.at) / (b.at - a.at));
  const x = a.x + (b.x - a.x) * p;
  const y = a.y + (b.y - a.y) * p - Math.sin(p * Math.PI) * (b.hop ?? 0);
  const resting = b === a || (i === path.length - 2 && p >= 1);
  // spins while it tumbles, settles upright
  const spin = resting ? 0 : (b.x < a.x ? -1 : 1) * p * 360 * (b.hop ? 1 : 0.5);
  const rest = resting ? t - path[path.length - 1].at : 0;
  const glow = resting ? 0.6 + 0.4 * Math.sin(rest * 6) : 0.4;
  const bob = resting ? Math.sin(rest * 3) * 8 : 0;
  return (
    <div style={{position: 'absolute', left: x, top: y + bob, width: 0, height: 0, transform: `scale(${out})`}}>
      <div style={{position: 'absolute', left: -size * 1.1, top: -size * 1.1, width: size * 2.2, height: size * 2.2, borderRadius: '50%', background: `radial-gradient(circle, ${GLOW} 0%, transparent 62%)`, opacity: glow}} />
      <div style={{position: 'absolute', left: -size / 2, top: -size / 2, width: size, height: size, display: 'flex', alignItems: 'center', justifyContent: 'center', transform: `rotate(${spin}deg)`}}>
        <GoldLetter k={k} size={size} style={{textShadow: [...Array.from({length: 12}, (_, n) => `${Math.cos((n / 12) * Math.PI * 2) * 6}px ${Math.sin((n / 12) * Math.PI * 2) * 6}px 0 white`), `0 0 ${size * 0.15}px ${GLOW}`].join(', ')}} />
      </div>
    </div>
  );
};

// ---------------------------------------------------------------- trip across Egypt (map + travelling swirl)

// world px of a place: Giza is (0, 0); 330 px per degree east, 365 px per degree south
const MX = (lon: number) => (lon - 31.13) * 330;
const MY = (lat: number) => (29.98 - lat) * 365;
const M = ([lon, lat]: [number, number]) => `${MX(lon).toFixed(0)},${MY(lat).toFixed(0)}`;
const LAND: [number, number][] = [
  [24.2, 31.6], [25.2, 31.6], [27.2, 31.4], [29.0, 30.95], [29.9, 31.22], [30.4, 31.5], [31.0, 31.6], [31.9, 31.52], [32.3, 31.28], [33.2, 31.12], [34.2, 31.32],
  [34.9, 29.5], [34.6, 28.6], [34.27, 27.75], [33.75, 28.2], [33.2, 28.9], [32.75, 29.6], [32.55, 29.95],
  [32.35, 29.6], [32.7, 28.95], [33.3, 28.1], [33.85, 27.2], [34.3, 26.1], [35.0, 24.9], [35.6, 23.9], [36.0, 22.6], [36.9, 21.6], [37.5, 18.0], [24.2, 18.0],
];
const NILE_PATH: [number, number][] = [
  [32.88, 23.2], [32.9, 24.09], [32.95, 24.6], [32.87, 25.2], [32.62, 25.7], [32.72, 26.15], [32.25, 26.05], [31.7, 26.55], [31.18, 27.18],
  [30.75, 28.1], [31.1, 29.07], [31.22, 30.05], [31.1, 30.25],
];
const DELTA_ARMS: [number, number][][] = [[[31.1, 30.25], [30.75, 30.9], [30.4, 31.45]], [[31.1, 30.25], [31.4, 30.95], [31.82, 31.5]]];
// the trip: from the pyramids, along the Nile, to Aswan
const ROUTE: [number, number][] = [[31.0, 29.95], [31.1, 29.07], [30.75, 28.1], [31.18, 27.18], [31.7, 26.55], [32.25, 26.05], [32.72, 26.15], [32.62, 25.7], [32.87, 25.2], [32.95, 24.6], [32.85, 24.1]];
const ROUTE_PX = ROUTE.map(([lon, lat]) => [MX(lon), MY(lat)] as [number, number]);
const ROUTE_LEN = ROUTE_PX.slice(1).reduce((a, q, i) => a + Math.hypot(q[0] - ROUTE_PX[i][0], q[1] - ROUTE_PX[i][1]), 0);
const routeAt = (p: number): [number, number] => {
  let d = Math.max(0, Math.min(1, p)) * ROUTE_LEN;
  for (let i = 1; i < ROUTE_PX.length; i++) {
    const [ax, ay] = ROUTE_PX[i - 1];
    const [bx, by] = ROUTE_PX[i];
    const l = Math.hypot(bx - ax, by - ay);
    if (d <= l) return [ax + ((bx - ax) * d) / l, ay + ((by - ay) * d) / l];
    d -= l;
  }
  return ROUTE_PX[ROUTE_PX.length - 1];
};

const INK = '#5B4B3A';
// little landmarks, drawn in the app's flat style (each fits a ~120 px box, base at 0,0)
const Mark: React.FC<{kind: string}> = ({kind}) => {
  const st = {stroke: INK, strokeWidth: 4, strokeLinejoin: 'round' as const};
  switch (kind) {
    case 'lighthouse':
      return (
        <g>
          <path d="M-22 0 L-14 -92 L14 -92 L22 0 Z" fill="white" {...st} />
          <path d="M-19.5 -30 L19.5 -30 L17 -52 L-17 -52 Z M-15.5 -72 L15.5 -72 L14.5 -84 L-14.5 -84 Z" fill="#FF7A5C" />
          <rect x={-16} y={-112} width={32} height={20} fill="#FFC845" {...st} />
          <path d="M-20 -112 L0 -130 L20 -112 Z" fill="#FF7A5C" {...st} />
          <path d="M16 -102 L70 -122 L70 -82 Z" fill="#FFF4C2" opacity={0.7} />
        </g>
      );
    case 'tower':
      return (
        <g>
          <path d="M-12 0 L-7 -100 L7 -100 L12 0 Z" fill="#E9D8B4" {...st} />
          <path d="M-16 -100 Q0 -126 16 -100 Z" fill="#6CC24A" {...st} />
          <rect x={-2} y={-138} width={4} height={14} fill={INK} />
          {[-80, -60, -40, -20].map((y) => <line key={y} x1={-9} y1={y} x2={9} y2={y} stroke={INK} strokeWidth={2} opacity={0.5} />)}
        </g>
      );
    case 'pyramids':
      return (
        <g>
          {[[-70, 56], [-28, 80], [22, 50]].map(([ox, w], j) => (
            <g key={j}>
              <polygon points={`${ox},0 ${ox + w / 2},${-w * 0.85} ${ox + w},0`} fill="#FFC845" {...st} />
              <polygon points={`${ox + w / 2},${-w * 0.85} ${ox + w},0 ${ox + w * 0.62},0`} fill="#C99A55" />
            </g>
          ))}
        </g>
      );
    case 'ship':
      return (
        <g>
          <path d="M-50 -20 L50 -20 L38 0 L-38 0 Z" fill="#FF7A5C" {...st} />
          <rect x={-30} y={-46} width={44} height={26} fill="white" {...st} />
          <rect x={18} y={-56} width={14} height={36} fill="#FFC845" {...st} />
          <circle cx={-18} cy={-33} r={4} fill="#4F7C82" />
          <circle cx={0} cy={-33} r={4} fill="#4F7C82" />
        </g>
      );
    case 'wheel':
      return (
        <g>
          <circle cx={0} cy={-46} r={40} fill="none" stroke="#A0704A" strokeWidth={10} />
          {[0, 45, 90, 135].map((a) => (
            <line key={a} x1={-40 * Math.cos((a * Math.PI) / 180)} y1={-46 - 40 * Math.sin((a * Math.PI) / 180)} x2={40 * Math.cos((a * Math.PI) / 180)} y2={-46 + 40 * Math.sin((a * Math.PI) / 180)} stroke="#6E4A2F" strokeWidth={6} />
          ))}
          <circle cx={0} cy={-46} r={10} fill="#6E4A2F" />
          <path d="M-56 0 L56 0" stroke="#6FC3D0" strokeWidth={10} strokeLinecap="round" />
        </g>
      );
    case 'mountain':
      return (
        <g>
          <polygon points="-62,0 -12,-92 38,0" fill="#C27C50" {...st} />
          <polygon points="-2,0 34,-62 70,0" fill="#D5B27A" {...st} />
          <polygon points="-24,-70 -12,-92 0,-70 -8,-66 -14,-74" fill="white" />
        </g>
      );
    case 'fish':
      return (
        <g>
          <ellipse cx={0} cy={-34} rx={36} ry={22} fill="#FFC845" {...st} />
          <path d="M30 -34 L58 -54 L58 -14 Z" fill="#FF7A5C" {...st} />
          <path d="M-8 -54 L-8 -14" stroke="#FF7A5C" strokeWidth={8} />
          <circle cx={-20} cy={-38} r={5} fill={INK} />
          <path d="M-60 0 Q-50 -26 -40 0 M44 0 Q52 -20 60 0" fill="#FF7A5C" stroke={INK} strokeWidth={3} />
        </g>
      );
    case 'balloon':
      return (
        <g>
          <path d="M0 -40 C-50 -60 -46 -132 0 -132 C46 -132 50 -60 0 -40 Z" fill="#FF7A5C" {...st} />
          <path d="M0 -132 C-18 -110 -18 -60 0 -40 C18 -60 18 -110 0 -132" fill="#FFC845" />
          <path d="M-10 -40 L-10 -22 M10 -40 L10 -22" stroke={INK} strokeWidth={3} />
          <rect x={-14} y={-22} width={28} height={20} rx={4} fill="#A0704A" {...st} />
        </g>
      );
    case 'temple':
      return (
        <g>
          <path d="M-62 0 L-56 -86 L-14 -86 L-8 0 Z M8 0 L14 -86 L56 -86 L62 0 Z" fill="#E6C88E" {...st} />
          <rect x={-10} y={-56} width={20} height={56} fill="#C99A55" {...st} />
          {[-46, -32, 24, 38].map((x) => <line key={x} x1={x} y1={-70} x2={x + 6} y2={-24} stroke="#C99A55" strokeWidth={4} />)}
          <path d="M-70 0 L70 0" stroke="#6FC3D0" strokeWidth={10} strokeLinecap="round" />
        </g>
      );
    case 'palms':
      return (
        <g>
          {[-26, 22].map((x, j) => (
            <g key={j} transform={`translate(${x} 0) scale(${j ? 0.8 : 1})`}>
              <path d="M0 0 Q6 -40 0 -80" stroke="#8A6B4E" strokeWidth={9} fill="none" />
              <path d="M0 -80 Q-34 -92 -50 -66 M0 -80 Q34 -92 50 -66 M0 -80 Q-20 -112 -40 -110 M0 -80 Q20 -112 40 -110" stroke="#5E9E45" strokeWidth={12} fill="none" strokeLinecap="round" />
            </g>
          ))}
        </g>
      );
    default:
      return null;
  }
};
const LANDMARKS: {at: [number, number]; kind: string; ar: string; en: string}[] = [
  {at: [29.92, 31.2], kind: 'lighthouse', ar: 'الإسكندرية', en: 'Alexandria'},
  {at: [32.3, 31.2], kind: 'ship', ar: 'بورسعيد', en: 'Port Said'},
  {at: [31.55, 30.15], kind: 'tower', ar: 'القاهرة', en: 'Cairo'},
  {at: [30.6, 29.95], kind: 'pyramids', ar: 'الجيزة', en: 'Giza'},
  {at: [30.2, 29.3], kind: 'wheel', ar: 'الفيوم', en: 'Fayoum'},
  {at: [33.9, 28.75], kind: 'mountain', ar: 'سيناء', en: 'Sinai'},
  {at: [34.35, 27.05], kind: 'fish', ar: 'الغردقة', en: 'Hurghada'},
  {at: [30.3, 25.6], kind: 'palms', ar: 'الوادي الجديد', en: 'New Valley'},
  {at: [33.3, 25.85], kind: 'balloon', ar: 'الأقصر', en: 'Luxor'},
  {at: [32.3, 24.05], kind: 'temple', ar: 'أسوان', en: 'Aswan'},
];

const Travel: React.FC<P<'travel'>> = ({t, fps, at, until, from, to, ease, intro, zoomAt}) => {
  const k = interpolate(t, [at, until], [0, 1], clamp);
  const e = ease === 'in' ? k * k : ease === 'out' ? 1 - (1 - k) * (1 - k) : k;
  const prog = from + (to - from) * e;
  const [vx, vy] = routeAt(prog);
  // the camera keeps the swirl a little above the middle, so you see where it's heading
  const FX = 540;
  const FY = 760;
  const introZ = intro ? interpolate(t - at, [0, 0.55], [2.4, 1], {...clamp, easing: (x) => 1 - Math.pow(1 - x, 3)}) : 1;
  const dive = zoomAt !== undefined ? interpolate(t - zoomAt, [0, 0.6], [1, 2.6], {...clamp, easing: (x) => x * x}) : 1;
  const z = introZ * dive;
  const flash = intro ? interpolate(t - at, [0, 0.35], [1, 0], clamp) : 0;
  const nono = characters.nono?.fall;
  const fofo = characters.fofo?.surprised;
  const spin = prog * 2200;
  return (
    <div style={{position: 'absolute', left: 0, top: 0, width: 1080, height: 1920, overflow: 'hidden', background: '#6FC3D0'}}>
      <div style={{position: 'absolute', left: FX, top: FY, width: 0, height: 0, transform: `scale(${z}) translate(${-vx}px, ${-vy}px)`}}>
        <svg width={10} height={10} style={{position: 'absolute', overflow: 'visible'}}>
          {/* sea waves */}
          {Array.from({length: 120}, (_, i) => {
            const wx = -3000 + (i % 10) * 640 + (Math.floor(i / 10) % 2) * 320 + Math.sin(t * 1.5 + i) * 10;
            const wy = -1200 + Math.floor(i / 10) * 520;
            return <path key={i} d={`M${wx} ${wy} q15 -12 30 0 t30 0`} fill="none" stroke="white" strokeWidth={5} strokeLinecap="round" opacity={0.7} />;
          })}
          {/* land, with a soft shadow edge */}
          <polygon points={LAND.map(M).join(' ')} fill="#D6B072" transform="translate(0 14)" />
          <polygon points={LAND.map(M).join(' ')} fill="#EFDCAE" stroke={INK} strokeWidth={8} strokeLinejoin="round" />
          {/* sand ripples */}
          {Array.from({length: 140}, (_, i) => {
            const rx = MX(25.5 + random(`rx${i}`) * 9);
            const ry = MY(22.6 + random(`ry${i}`) * 8);
            return <path key={i} d={`M${rx} ${ry} q20 -10 40 0`} fill="none" stroke="#D6B072" strokeWidth={5} strokeLinecap="round" />;
          })}
          {/* the green delta and the green strip along the Nile */}
          <polygon points={[[31.1, 30.25], [30.2, 31.45], [30.6, 31.55], [31.4, 31.55], [32.0, 31.45]].map((q) => M(q as [number, number])).join(' ')} fill="#8CC66A" stroke="#6FAE52" strokeWidth={6} strokeLinejoin="round" />
          <polyline points={NILE_PATH.map(M).join(' ')} fill="none" stroke="#8CC66A" strokeWidth={110} strokeLinecap="round" strokeLinejoin="round" />
          <polyline points={NILE_PATH.map(M).join(' ')} fill="none" stroke="#3FA7C0" strokeWidth={28} strokeLinecap="round" strokeLinejoin="round" />
          {DELTA_ARMS.map((arm, i) => <polyline key={i} points={arm.map(M).join(' ')} fill="none" stroke="#3FA7C0" strokeWidth={20} strokeLinecap="round" />)}
          {/* Lake Nasser */}
          <path d={`M${M([32.88, 23.95])} C${M([33.15, 23.5])} ${M([32.6, 23.0])} ${M([32.4, 22.4])} C${M([32.0, 22.1])} ${M([32.5, 21.9])} ${M([32.9, 22.6])} C${M([33.3, 23.1])} ${M([33.2, 23.7])} ${M([32.88, 23.95])}`} fill="#3FA7C0" />
          {/* Fayoum lake */}
          <ellipse cx={MX(30.6)} cy={MY(29.45)} rx={50} ry={20} fill="#3FA7C0" />
          {/* the trail left behind */}
          <polyline points={Array.from({length: 40}, (_, i) => routeAt((prog * i) / 39)).map(([x, y]) => `${x},${y}`).join(' ')} fill="none" stroke="white" strokeWidth={8} strokeDasharray="4 22" strokeLinecap="round" opacity={0.9} />
        </svg>
        {/* landmarks with name tags */}
        {LANDMARKS.map((lm, i) => {
          const x = MX(lm.at[0]);
          const y = MY(lm.at[1]);
          const near = Math.hypot(x - vx, y - vy);
          const pop = 1.35 * (1 + 0.25 * Math.max(0, 1 - near / 400));
          return (
            <div key={i} style={{position: 'absolute', left: x, top: y, width: 0, height: 0, transform: `scale(${pop})`}}>
              <svg width={10} height={10} style={{position: 'absolute', overflow: 'visible'}}>
                <ellipse cx={0} cy={2} rx={58} ry={10} fill="rgba(0,0,0,0.12)" />
                <Mark kind={lm.kind} />
              </svg>
              <div style={{position: 'absolute', left: -110, top: 10, width: 220, textAlign: 'center'}}>
                <div style={{display: 'inline-block', padding: '2px 16px 4px', borderRadius: 22, background: color('cream'), border: `4px solid ${INK}`, whiteSpace: 'nowrap'}}>
                  <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 30, lineHeight: 1.2, color: color('deepTeal')}}>{lm.ar}</div>
                  <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 18, lineHeight: 1, color: color('coral')}}>{lm.en}</div>
                </div>
              </div>
            </div>
          );
        })}
        {/* the swirl with the brothers tumbling inside */}
        <div style={{position: 'absolute', left: vx, top: vy, width: 0, height: 0}}>
          <Vortex kind="vortex" t={t} fps={fps} at={-99} x={0} y={0} size={420} />
          {[nono, fofo].map((pose, i) =>
            pose?.file ? (
              <Img
                key={i}
                src={staticFile(pose.file)}
                style={{
                  position: 'absolute',
                  height: 120,
                  width: (pose.width / pose.height) * 120,
                  left: Math.cos((spin * 0.6 + i * 180) * (Math.PI / 180)) * 58 - ((pose.width / pose.height) * 120) / 2,
                  top: Math.sin((spin * 0.6 + i * 180) * (Math.PI / 180)) * 58 - 60,
                  transform: `rotate(${(i ? -1 : 1) * spin}deg)`,
                }}
              />
            ) : null,
          )}
        </div>
      </div>
      {flash > 0 && <div style={{position: 'absolute', inset: 0, background: 'white', opacity: flash}} />}
    </div>
  );
};

// ---------------------------------------------------------------- layers

const BACK = new Set(['book', 'egypt', 'speed', 'vortex', 'travel']);
const SCREEN = new Set(['compare', 'twoIotas', 'title', 'alarm', 'banner', 'speech']);

// Props behind the characters (`layer="back"`) or in front of them.
export const Props: React.FC<{props?: PropSpec[]; voiceFrom: number; layer: 'back' | 'front' | 'screen'}> = ({props, voiceFrom, layer}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = (frame - voiceFrom) / fps;
  return (
    <>
      {(props ?? [])
        .filter((p) =>
          p.kind === 'shake'
            ? false
            : SCREEN.has(p.kind)
              ? layer === 'screen'
              : layer !== 'screen' && (p.kind === 'statues' ? p.layer !== 'front' : p.kind === 'image' ? p.layer === 'back' : BACK.has(p.kind)) === (layer === 'back'),
        )
        .map((p, i) => {
          const q = {...p, t, fps} as never;
          switch (p.kind) {
            case 'book':
              return <Book key={i} {...(q as P<'book'>)} />;
            case 'egypt':
              return <EgyptMap key={i} {...(q as P<'egypt'>)} />;
            case 'letter':
              return <Letter key={i} {...(q as P<'letter'>)} />;
            case 'slots':
              return <Slots key={i} {...(q as P<'slots'>)} />;
            case 'speed':
              return <Speed key={i} {...(q as P<'speed'>)} />;
            case 'ball':
              return <Ball key={i} {...(q as P<'ball'>)} />;
            case 'rain':
              return <Rain key={i} {...(q as P<'rain'>)} />;
            case 'arrow':
              return <Arrow key={i} {...(q as P<'arrow'>)} />;
            case 'runner':
              return <Runner key={i} {...(q as P<'runner'>)} />;
            case 'statues':
              return <Statues key={i} {...(q as P<'statues'>)} />;
            case 'dizzy':
              return <Dizzy key={i} {...(q as P<'dizzy'>)} />;
            case 'pant':
              return <Pant key={i} {...(q as P<'pant'>)} />;
            case 'compare':
              return <Compare key={i} {...(q as P<'compare'>)} />;
            case 'twoIotas':
              return <TwoIotas key={i} {...(q as P<'twoIotas'>)} />;
            case 'banner':
              return <Banner key={i} {...(q as P<'banner'>)} />;
            case 'confetti':
              return <Confetti key={i} {...(q as P<'confetti'>)} />;
            case 'sand':
              return <Sand key={i} {...(q as P<'sand'>)} />;
            case 'speech':
              return <Speech key={i} {...(q as P<'speech'>)} />;
            case 'sandpile':
              return <SandPile key={i} {...(q as P<'sandpile'>)} />;
            case 'screen':
              return <Screen key={i} {...(q as P<'screen'>)} />;
            case 'title':
              return <Title key={i} {...(q as P<'title'>)} />;
            case 'alarm':
              return <Alarm key={i} {...(q as P<'alarm'>)} />;
            case 'box':
              return <Box key={i} {...(q as P<'box'>)} />;
            case 'image':
              return <Picture key={i} {...(q as P<'image'>)} />;
            case 'vortex':
              return <Vortex key={i} {...(q as P<'vortex'>)} />;
            case 'travel':
              return <Travel key={i} {...(q as P<'travel'>)} />;
            case 'drop':
              return <Drop key={i} {...(q as P<'drop'>)} />;
            case 'bubble':
              return <Bubble key={i} {...(q as P<'bubble'>)} />;
            default:
              return null;
          }
        })}
    </>
  );
};

// Screen shake offset (px) for `shake` props.
export const shakeOffset = (props: PropSpec[] | undefined, t: number): [number, number] => {
  for (const p of props ?? []) {
    if (p.kind !== 'shake') continue;
    const k = t - p.at;
    if (k >= 0 && k < 0.5) {
      const a = 34 * (1 - k / 0.5);
      return [Math.sin(k * 90) * a, Math.cos(k * 70) * a];
    }
  }
  return [0, 0];
};
