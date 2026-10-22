import {FontAwesomeIcon} from '@fortawesome/react-fontawesome';
import React from 'react';
import {Img, interpolate, random, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {images} from '../generated/data';
import {ICONS} from '../icons';
import {color, FONT_AR, FONT_COPTIC, FONT_EN} from '../theme';
import type {PropSpec} from '../types';
import {Alarm, Box, Bubble, Screen, Title} from './TeaserProps';

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

const Book: React.FC<P<'book'>> = ({t, fps, x = 540, y = 860, size = 1, openAt, burstAt, letterInAt, letterFrom = [540, 420], letter = 'A', found, only}) => {
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

  return (
    <div style={{position: 'absolute', left: x, top: y, width: 0, height: 0}}>
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
                  // page letters vanish when they burst out; one comes back with letterIn
                  const back = side === 1 && i === 4 && li >= 0.55;
                  // letters found earlier sit big on the page already
                  const had = side === 0 && i === 4 && !!found;
                  const gone = burst && !back && !had;
                  // only: a clean page with just the letters found so far
                  if (only && !back && !had) return <div key={i} />;
                  return (
                    <GoldLetter
                      key={i}
                      k={back ? letter : had ? found! : key}
                      size={(back || had ? 110 : 70) * size}
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

// ---------------------------------------------------------------- layers

const BACK = new Set(['book', 'egypt', 'speed']);
const SCREEN = new Set(['compare', 'title', 'alarm']);

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
              : layer !== 'screen' && (p.kind === 'statues' ? p.layer !== 'front' : BACK.has(p.kind)) === (layer === 'back'),
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
            case 'confetti':
              return <Confetti key={i} {...(q as P<'confetti'>)} />;
            case 'screen':
              return <Screen key={i} {...(q as P<'screen'>)} />;
            case 'title':
              return <Title key={i} {...(q as P<'title'>)} />;
            case 'alarm':
              return <Alarm key={i} {...(q as P<'alarm'>)} />;
            case 'box':
              return <Box key={i} {...(q as P<'box'>)} />;
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
