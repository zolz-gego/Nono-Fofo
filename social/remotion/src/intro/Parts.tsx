// Vector rebuilds of the logo's small details (sharp at any zoom):
// pyramid, palm, sun, glowing Coptic letter. All are SVG <g> groups.
import React from 'react';
import {color, FONT_COPTIC} from '../theme';

// Pyramid with its base centred at (0, 0): 100 wide, 72 tall, gold cap.
export const Pyramid: React.FC<{uid: string}> = ({uid}) => {
  const rows = Array.from({length: 9}, (_, i) => 8 + i * 7.6);
  return (
    <g transform="translate(-50 -72)">
      <defs>
        <linearGradient id={`${uid}-lit`} x1="0" y1="0" x2="0.3" y2="1">
          <stop offset="0" stopColor="#F7E2B0" />
          <stop offset="1" stopColor={color('pyramidDune')} />
        </linearGradient>
        <linearGradient id={`${uid}-shade`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor={color('pyramidShade')} />
          <stop offset="1" stopColor="#A87A3E" />
        </linearGradient>
      </defs>
      <polygon points="50,0 0,72 62,72" fill={`url(#${uid}-lit)`} />
      <polygon points="50,0 62,72 100,72" fill={`url(#${uid}-shade)`} />
      {rows.map((y) => (
        <line key={y} x1={50 - (50 * y) / 72} y1={y} x2={50 + (50 * y) / 72} y2={y} stroke={color('cocoa')} strokeOpacity={0.18} strokeWidth={0.7} />
      ))}
      <polygon points="50,0 45.2,7 51.2,7" fill={color('sunYellow')} />
      <polygon points="50,0 51.2,7 54.8,7" fill={color('letterGold')} />
    </g>
  );
};

// Date palm with its foot at (0, 0), about 100 tall. `sway` in degrees.
export const Palm: React.FC<{sway?: number; t?: number}> = ({sway = 0, t = 0}) => {
  const angles = [-172, -145, -118, -62, -35, -8, -95];
  return (
    <g>
      <path d="M-3.5,0 Q3,-48 -2.5,-86 L2.5,-86 Q9,-48 3.5,0 Z" fill={color('palmTrunk')} />
      {Array.from({length: 11}, (_, i) => {
        const y = -6 - i * 7.4;
        const x = Math.sin((-y / 86) * Math.PI) * 2.6;
        return <path key={i} d={`M${x - 3.4},${y} Q${x},${y + 2.4} ${x + 3.4},${y}`} stroke="#6E553D" strokeWidth={1.1} fill="none" />;
      })}
      <g transform={`translate(0 -86) rotate(${sway})`}>
        {angles.map((a, i) => (
          <g key={i} transform={`rotate(${a + Math.sin(t * 2.4 + i * 1.3) * 3.5})`}>
            <path d="M0,0 Q20,-9 44,7 Q22,1 0,4 Z" fill={i % 2 ? color('palmLeaf') : color('leafGreen')} />
            <path d="M0,1.5 Q22,-4 43,6.5" stroke="#3F7A2F" strokeWidth={0.8} fill="none" />
            {Array.from({length: 7}, (_, k) => {
              const x = 5 + k * 5.4;
              const y = -4 + (k * k) / 6;
              return <path key={k} d={`M${x},${y + 1} l2.4,-4.2`} stroke="#3F7A2F" strokeWidth={0.6} />;
            })}
          </g>
        ))}
        <circle cx={-2.5} cy={3} r={2.6} fill={color('cocoa')} />
        <circle cx={2} cy={4} r={2.6} fill="#7A5A3F" />
        <circle cx={0} cy={1} r={2.4} fill="#6B4E36" />
      </g>
    </g>
  );
};

// Sun at (0, 0) with turning rays.
export const Sun: React.FC<{r: number; spin: number; uid: string}> = ({r, spin, uid}) => (
  <g>
    <defs>
      <radialGradient id={`${uid}-sun`}>
        <stop offset="0" stopColor="#FFF4C2" />
        <stop offset="0.55" stopColor={color('sunYellow')} />
        <stop offset="1" stopColor={color('sunYellow')} stopOpacity={0} />
      </radialGradient>
    </defs>
    <circle r={r * 2.6} fill={`url(#${uid}-sun)`} opacity={0.45} />
    <g transform={`rotate(${spin})`}>
      {Array.from({length: 12}, (_, i) => (
        <rect key={i} x={-r * 0.12} y={-r * 1.75} width={r * 0.24} height={r * 0.5} rx={r * 0.12} fill={color('sunYellow')} transform={`rotate(${i * 30})`} />
      ))}
    </g>
    <circle r={r} fill={`url(#${uid}-sun)`} />
    <circle r={r * 0.82} fill={color('sunYellow')} />
  </g>
);

// Gold Coptic letter centred on (0, 0) with a soft glow.
export const GoldLetter: React.FC<{ch: string; size: number; uid: string; glow?: number}> = ({ch, size, uid, glow = 1}) => (
  <g>
    <defs>
      <linearGradient id={`${uid}-gold`} x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#FFF1B8" />
        <stop offset="0.45" stopColor={color('sunYellow')} />
        <stop offset="1" stopColor={color('letterGold')} />
      </linearGradient>
      <filter id={`${uid}-glow`} x="-1" y="-1" width="3" height="3">
        <feGaussianBlur stdDeviation={size * 0.09} />
      </filter>
    </defs>
    <text textAnchor="middle" y={size * 0.33} fontFamily={FONT_COPTIC} fontSize={size} fill={color('sunYellow')} opacity={0.85 * glow} filter={`url(#${uid}-glow)`}>
      {ch}
    </text>
    <text textAnchor="middle" y={size * 0.33} fontFamily={FONT_COPTIC} fontSize={size} fill={`url(#${uid}-gold)`} stroke="#B07A00" strokeWidth={size * 0.012}>
      {ch}
    </text>
  </g>
);
