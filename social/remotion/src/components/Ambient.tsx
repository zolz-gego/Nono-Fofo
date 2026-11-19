import React from 'react';
import {random} from 'remotion';
import {color} from '../theme';

// Living scenery drawn over an illustrated backdrop, in world px (it pans and
// zooms with the camera). `clock` is the story frame, so birds, clouds and
// boats carry on smoothly from one scene to the next instead of restarting.

const FPS = 30;
// the backdrop is mirrored on both sides (Background.tsx), so the world runs
// from about -1700 to 2800 px; things that cross the screen wrap over this span
const X0 = -500;
const SPAN = 3300;
const wrap = (x: number) => ((((x - X0) % SPAN) + SPAN) % SPAN) + X0;

// open water on aswan-nile (world px), plus the same spots in the mirrored copy
const WATER: [number, number][] = [
  [-50, 819], [118, 735], [230, 893], [456, 763], [737, 819], [990, 763], [1216, 803], [709, 566], [1188, 594], [906, 285], [560, 900], [1060, 880],
];
// the felucca's lane (world px): open water between Philae's rocks and the far bank
const FEL_X0 = 470;
const FEL_RUN = 760;
const FEL_PERIOD = 80; // seconds there and back
const SPARKLES = [...WATER, ...WATER.map(([x, y]) => [2600 - x, y] as [number, number])];

const Bird: React.FC<{t: number; i: number}> = ({t, i}) => {
  const speed = 70 + random(`bs${i}`) * 50;
  const x = wrap(-400 + random(`bx${i}`) * SPAN + t * speed);
  const y = 60 + random(`by${i}`) * 260 + Math.sin(t * 0.8 + i) * 25;
  const flap = Math.sin(t * (7 + random(`bf${i}`) * 3) + i * 2);
  const s = 0.8 + random(`bz${i}`) * 0.6;
  const k = 14 * flap;
  return (
    <svg width={80} height={60} style={{position: 'absolute', left: x - 40, top: y - 30, overflow: 'visible', transform: `scale(${s})`}}>
      <path d={`M6 ${30 - k} Q22 ${18 - k * 0.4} 40 30 Q58 ${18 - k * 0.4} 74 ${30 - k}`} fill="none" stroke={color('cocoa')} strokeWidth={6} strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
};

const Cloud: React.FC<{t: number; i: number}> = ({t, i}) => {
  const x = wrap(random(`cx${i}`) * SPAN + t * (9 + i * 4));
  const y = -40 + random(`cy${i}`) * 110;
  const s = 0.7 + random(`cs${i}`) * 0.6;
  return (
    <svg width={340} height={150} style={{position: 'absolute', left: x - 170, top: y - 75, overflow: 'visible', transform: `scale(${s})`, opacity: 0.92}}>
      <g fill="white">
        <ellipse cx={170} cy={100} rx={150} ry={42} />
        <circle cx={115} cy={80} r={52} />
        <circle cx={185} cy={62} r={66} />
        <circle cx={250} cy={88} r={42} />
      </g>
    </svg>
  );
};

// a little felucca: brown hull, tall white triangle sail, sways on the water
const Felucca: React.FC<{x: number; y: number; h: number; t: number; flip?: boolean}> = ({x, y, h, t, flip}) => {
  const rock = Math.sin(t * 1.6) * 3;
  const bob = Math.sin(t * 2.1) * 4;
  return (
    <svg width={h} height={h} viewBox="0 0 100 100" style={{position: 'absolute', left: x - h / 2, top: y - h + bob, overflow: 'visible', transform: `rotate(${rock}deg) ${flip ? 'scaleX(-1)' : ''}`, transformOrigin: '50% 90%'}}>
      <path d="M48 6 L48 82" stroke={color('cocoa')} strokeWidth={3} />
      <path d="M50 8 L86 78 L50 78 Z" fill="white" stroke={color('cocoa')} strokeWidth={2.5} strokeLinejoin="round" />
      <path d="M45 18 L22 76 L45 76 Z" fill="#F4F1E6" stroke={color('cocoa')} strokeWidth={2.5} strokeLinejoin="round" />
      <path d="M10 82 L92 82 Q86 96 70 96 L28 96 Q14 96 10 82 Z" fill="#9A5B34" stroke={color('cocoa')} strokeWidth={2.5} strokeLinejoin="round" />
      <path d="M14 86 L88 86" stroke="#C98B5A" strokeWidth={3} />
      {/* wake */}
      <path d={`M0 99 Q12 ${95 + bob * 0.3} 24 99`} fill="none" stroke="white" strokeWidth={3} strokeLinecap="round" opacity={0.8} />
    </svg>
  );
};

export const NileLife: React.FC<{clock: number}> = ({clock}) => {
  const t = clock / FPS;
  return (
    <div style={{position: 'absolute', left: 0, top: 0, width: 0, height: 0}}>
      {/* water sparkles: little white wave lines that glint and drift with the current */}
      {SPARKLES.map(([x, y], i) => {
        const ph = (t * 0.5 + random(`w${i}`)) % 1;
        const o = Math.sin(ph * Math.PI);
        const dx = ph * 40;
        return (
          <svg key={`w${i}`} width={120} height={30} style={{position: 'absolute', left: x - 60 + dx, top: y - 15, overflow: 'visible', opacity: 0.85 * o}}>
            <path d="M5 18 Q20 6 35 18 T65 18 T95 18" fill="none" stroke="white" strokeWidth={5} strokeLinecap="round" />
          </svg>
        );
      })}
      {/* one felucca sails slowly back and forth in a clear lane of the river (in front of the painted
          boats, behind the bank), so it never crosses Philae, the other boats or the sand */}
      <Felucca x={FEL_X0 + FEL_RUN * (0.5 - 0.5 * Math.cos((t * 2 * Math.PI) / FEL_PERIOD))} y={845} h={115} t={t} flip={Math.sin((t * 2 * Math.PI) / FEL_PERIOD) < 0} />
      {Array.from({length: 4}, (_, i) => (
        <Cloud key={`c${i}`} t={t} i={i} />
      ))}
      {Array.from({length: 6}, (_, i) => (
        <Bird key={`b${i}`} t={t} i={i} />
      ))}
    </div>
  );
};
