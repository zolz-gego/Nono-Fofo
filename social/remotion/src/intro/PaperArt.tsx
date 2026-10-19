// Printed paper art for Grandpa's pop-up book: the page spreads (drawn across
// both pages in a 200x130 box and clipped per page), the leather cover, and
// the pop-up pieces (each drawn with its foot at 0,0 in its own viewBox).
import React from 'react';
import {color, FONT_COPTIC} from '../theme';
import {COPTIC, rnd} from './anim';
import {Palm, Pyramid, Sun} from './Parts';

const INK = color('cocoa');

const TextLines: React.FC<{x: number; y: number; w: number; rows: number; seed: number}> = ({x, y, w, rows, seed}) => (
  <g opacity={0.22}>
    {Array.from({length: rows}, (_, i) => {
      let cx = x;
      const out: React.ReactNode[] = [];
      for (let k = 0; cx < x + w - 4; k++) {
        const len = 3 + rnd(seed + i * 13 + k) * 7;
        if (cx + len > x + w) break;
        out.push(<rect key={k} x={cx} y={y + i * 4.2} width={len} height={1.3} rx={0.6} fill={INK} />);
        cx += len + 1.6;
      }
      return <g key={i}>{out}</g>;
    })}
  </g>
);

// Paper grain + gutter shade shared by every spread.
const Paper: React.FC<{uid: string}> = ({uid}) => (
  <>
    <defs>
      <filter id={`${uid}-grain`}>
        <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves={2} seed={4} />
        <feColorMatrix values="0 0 0 0 0.35  0 0 0 0 0.27  0 0 0 0 0.18  0 0 0 0.10 0" />
      </filter>
      <linearGradient id={`${uid}-gutter`} x1="0" x2="1">
        <stop offset="0.38" stopColor="#000" stopOpacity={0} />
        <stop offset="0.5" stopColor="#3a2412" stopOpacity={0.32} />
        <stop offset="0.62" stopColor="#000" stopOpacity={0} />
      </linearGradient>
      <linearGradient id={`${uid}-edge`} x1="0" x2="1">
        <stop offset="0" stopColor="#3a2412" stopOpacity={0.18} />
        <stop offset="0.06" stopColor="#000" stopOpacity={0} />
        <stop offset="0.94" stopColor="#000" stopOpacity={0} />
        <stop offset="1" stopColor="#3a2412" stopOpacity={0.18} />
      </linearGradient>
    </defs>
  </>
);

const PaperTop: React.FC<{uid: string}> = ({uid}) => (
  <>
    <rect width={200} height={130} filter={`url(#${uid}-grain)`} />
    <rect width={200} height={130} fill={`url(#${uid}-gutter)`} />
    <rect width={200} height={130} fill={`url(#${uid}-edge)`} />
  </>
);

const Corners: React.FC = () => (
  <g fill="none" stroke={color('letterGold')} strokeWidth={0.7} opacity={0.75}>
    <rect x={5} y={5} width={90} height={120} rx={2} />
    <rect x={105} y={5} width={90} height={120} rx={2} />
  </g>
);

export const SpreadArt: React.FC<{id: string; uid: string; inked?: number}> = ({id, uid, inked = 1}) => (
  <svg viewBox="0 0 200 130" width="100%" height="100%" preserveAspectRatio="none" style={{display: 'block'}}>
    <Paper uid={uid} />
    <rect width={200} height={130} fill={color('cream')} />
    <rect width={200} height={130} fill="#F4E7CC" opacity={0.55} />
    {id === 'nile' && (
      <>
        <path d="M0,58 C40,40 70,80 100,62 S160,40 200,60 L200,82 C160,64 130,96 100,84 S40,62 0,80 Z" fill={color('waterTop')} opacity={0.85} />
        {Array.from({length: 10}, (_, i) => (
          <path key={i} d={`M${8 + i * 19},${66 + (i % 2) * 6} q3,-2 6,0 t6,0`} stroke="white" strokeWidth={0.8} fill="none" opacity={0.8} />
        ))}
        <path d="M0,58 C40,40 70,80 100,62 S160,40 200,60" stroke={color('palmLeaf')} strokeWidth={2.2} fill="none" opacity={0.6} />
        <path d="M0,80 C40,62 70,96 100,84 S160,64 200,82" stroke={color('palmLeaf')} strokeWidth={2.2} fill="none" opacity={0.6} />
        <TextLines x={12} y={14} w={74} rows={5} seed={1} />
        <TextLines x={112} y={14} w={74} rows={5} seed={2} />
        <TextLines x={12} y={100} w={74} rows={4} seed={3} />
        <TextLines x={112} y={100} w={74} rows={4} seed={4} />
      </>
    )}
    {id === 'pyramids' && (
      <>
        <rect width={200} height={44} fill={color('pyramidSkyTop')} opacity={0.35} />
        <path d="M0,44 Q50,34 100,44 T200,42 L200,130 L0,130 Z" fill={color('pyramidDune')} opacity={0.55} />
        <path d="M0,78 Q60,66 120,80 T200,76" stroke={color('pyramidDuneDark')} strokeWidth={1.2} fill="none" opacity={0.6} />
        <path d="M0,100 Q70,90 140,102 T200,98" stroke={color('pyramidDuneDark')} strokeWidth={1.2} fill="none" opacity={0.6} />
        <TextLines x={14} y={108} w={70} rows={3} seed={5} />
        <TextLines x={114} y={108} w={70} rows={3} seed={6} />
      </>
    )}
    {id === 'village' && (
      <>
        {Array.from({length: 9}, (_, i) => (
          <rect key={i} x={0} y={30 + i * 9} width={200} height={4.5} fill={i % 2 ? color('villageField') : color('villageFieldRow')} opacity={0.35} />
        ))}
        <path d="M60,130 C80,100 120,90 110,30" stroke={color('villagePath')} strokeWidth={9} fill="none" opacity={0.85} />
        <path d="M0,24 C60,30 140,18 200,26" stroke={color('villageCanal')} strokeWidth={3} fill="none" opacity={0.7} />
        <TextLines x={14} y={8} w={70} rows={3} seed={7} />
        <TextLines x={114} y={8} w={70} rows={3} seed={8} />
      </>
    )}
    {id === 'letters' && (
      <>
        <Corners />
        {COPTIC.concat(['w', 'S', 'F', 'h', 'j', 'G', 'T']).slice(0, 28).map((ch, i) => {
          const page = i < 14 ? 0 : 1;
          const k = i % 14;
          const x = 18 + page * 100 + (k % 4) * 21;
          const y = 26 + Math.floor(k / 4) * 26;
          return (
            <text key={i} x={x} y={y} fontFamily={FONT_COPTIC} fontSize={15} fill={INK} textAnchor="middle" opacity={0.9 * inked}>
              {ch}
            </text>
          );
        })}
      </>
    )}
    <PaperTop uid={uid} />
  </svg>
);

export const CoverArt: React.FC<{uid: string}> = ({uid}) => (
  <svg viewBox="0 0 100 130" width="100%" height="100%" preserveAspectRatio="none" style={{display: 'block'}}>
    <defs>
      <radialGradient id={`${uid}-leather`} cx="0.4" cy="0.35" r="0.9">
        <stop offset="0" stopColor="#9E4A33" />
        <stop offset="1" stopColor="#5A2216" />
      </radialGradient>
      <filter id={`${uid}-tex`}>
        <feTurbulence type="fractalNoise" baseFrequency="1.6" numOctaves={2} seed={9} />
        <feColorMatrix values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.25 0" />
      </filter>
      <linearGradient id={`${uid}-gold`} x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#FFF1B8" />
        <stop offset="0.5" stopColor={color('sunYellow')} />
        <stop offset="1" stopColor={color('letterGold')} />
      </linearGradient>
    </defs>
    <rect width={100} height={130} fill={`url(#${uid}-leather)`} />
    <rect width={100} height={130} filter={`url(#${uid}-tex)`} />
    <rect x={7} y={7} width={86} height={116} rx={3} fill="none" stroke={`url(#${uid}-gold)`} strokeWidth={1.2} />
    <rect x={10} y={10} width={80} height={110} rx={2} fill="none" stroke={`url(#${uid}-gold)`} strokeWidth={0.5} />
    {[[10, 10], [90, 10], [10, 120], [90, 120]].map(([x, y], i) => (
      <circle key={i} cx={x} cy={y} r={2.2} fill={`url(#${uid}-gold)`} />
    ))}
    <text x={36} y={76} textAnchor="middle" fontFamily={FONT_COPTIC} fontSize={34} fill={`url(#${uid}-gold)`} stroke="#7A4E00" strokeWidth={0.4}>
      a
    </text>
    <text x={64} y={76} textAnchor="middle" fontFamily={FONT_COPTIC} fontSize={34} fill={`url(#${uid}-gold)`} stroke="#7A4E00" strokeWidth={0.4}>
      w
    </text>
    <rect x={0} y={0} width={4} height={130} fill="#3A140C" opacity={0.6} />
  </svg>
);

// ---------------------------------------------------------------- pop-up pieces

const Felucca: React.FC = () => (
  <g>
    <path d="M-44,-14 L44,-14 Q36,0 22,2 L-26,2 Q-40,-2 -44,-14 Z" fill={color('monasteryWood')} stroke={color('monasteryWoodDark')} strokeWidth={1.5} />
    <rect x={-44} y={-16} width={88} height={3} fill={color('monasteryWoodDark')} />
    <rect x={-1.5} y={-96} width={3} height={82} fill={color('monasteryWoodDark')} />
    <path d="M0,-96 L40,-18 L-6,-22 Z" fill={color('cream')} stroke="#CDBA94" strokeWidth={1} />
    <path d="M2,-80 L30,-26" stroke={color('coral')} strokeWidth={3} opacity={0.8} />
    <path d="M-4,-90 Q-30,-60 -36,-20" stroke={color('monasteryWoodDark')} strokeWidth={1.2} fill="none" />
  </g>
);

const Papyrus: React.FC<{t: number}> = ({t}) => (
  <g>
    {[-14, -5, 4, 13].map((x, i) => {
      const top = -60 - (i % 2) * 22;
      const sway = Math.sin(t * 2.2 + i) * 3;
      return (
        <g key={i}>
          <path d={`M${x * 0.3},0 Q${x * 0.6},${top / 2} ${x + sway},${top}`} stroke={color('reed')} strokeWidth={2.2} fill="none" />
          <path d={`M${x + sway},${top} l-11,-14 q11,-6 22,0 Z`} fill={color('leafGreen')} />
          {Array.from({length: 5}, (_, k) => (
            <path key={k} d={`M${x + sway},${top} l${-10 + k * 5},-13`} stroke={color('palmLeaf')} strokeWidth={0.8} />
          ))}
        </g>
      );
    })}
  </g>
);

const House: React.FC = () => (
  <g>
    <rect x={-42} y={-52} width={84} height={52} fill={color('villagePath')} stroke={color('villagePathEdge')} strokeWidth={2} />
    <path d="M-20,-52 A20,20 0 0 1 20,-52 Z" fill={color('roofStraw')} stroke={color('villagePathEdge')} strokeWidth={2} />
    <rect x={-10} y={-30} width={20} height={30} rx={10} fill={color('houseDoor')} />
    <rect x={-34} y={-42} width={14} height={12} rx={2} fill={color('houseWindow')} />
    <rect x={20} y={-42} width={14} height={12} rx={2} fill={color('houseWindow')} />
    <rect x={-42} y={-56} width={84} height={5} fill={color('villagePathEdge')} />
  </g>
);

const Tower: React.FC = () => (
  <g>
    <path d="M-22,0 L-14,-80 Q0,-98 14,-80 L22,0 Z" fill={color('pigeonTower')} stroke={color('villagePathEdge')} strokeWidth={2} />
    {Array.from({length: 4}, (_, r) =>
      Array.from({length: 3}, (_, c) => <circle key={`${r}-${c}`} cx={-8 + c * 8} cy={-66 + r * 14} r={2.4} fill={color('cocoa')} opacity={0.75} />),
    )}
    <rect x={-5} y={-14} width={10} height={14} rx={5} fill={color('houseDoor')} />
  </g>
);

const SunTab: React.FC<{t: number}> = ({t}) => (
  <g>
    <rect x={-2.5} y={0} width={5} height={60} fill="#E9D7B0" stroke="#CDBA94" strokeWidth={0.8} />
    <Sun r={14} spin={t * 30} uid="pop-sun" />
  </g>
);

// viewBox per piece kind ("minX minY w h", foot at 0,0)
export const PIECE_BOX: Record<string, [number, number, number, number]> = {
  palm: [-50, -112, 100, 115],
  pyramid: [-55, -76, 110, 79],
  papyrus: [-32, -100, 64, 102],
  felucca: [-50, -100, 100, 104],
  house: [-50, -80, 100, 82],
  tower: [-30, -100, 60, 102],
  sun: [-40, -40, 80, 100],
};

export const PieceArt: React.FC<{kind: string; t: number; seed: number}> = ({kind, t, seed}) => {
  const b = PIECE_BOX[kind];
  return (
    <svg viewBox={b.join(' ')} width="100%" height="100%" style={{display: 'block', overflow: 'visible'}}>
      {kind === 'palm' && <Palm sway={Math.sin(t * 2.2 + seed) * 3} t={t + seed} />}
      {kind === 'pyramid' && <Pyramid uid={`pyr-${seed}`} />}
      {kind === 'papyrus' && <Papyrus t={t + seed} />}
      {kind === 'felucca' && <Felucca />}
      {kind === 'house' && <House />}
      {kind === 'tower' && <Tower />}
      {kind === 'sun' && <SunTab t={t} />}
    </svg>
  );
};
