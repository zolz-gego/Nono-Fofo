// Act 1 close-ups: each one is a tiny part of the logo rebuilt as a vector
// scene in a 100x100 box (cropped to cover the frame). `lt` = seconds since
// the shot started; it keeps running when the shot shrinks onto a block.
import React from 'react';
import {color, FONT_COPTIC} from '../theme';
import {kick, rnd} from './anim';
import {GoldLetter, Palm, Pyramid, Sun} from './Parts';

export type MacroId = 'letter' | 'pyramid' | 'palm' | 'river' | 'book';

const Camera: React.FC<{s: number; x?: number; y?: number; r?: number; children: React.ReactNode}> = ({s, x = 0, y = 0, r = 0, children}) => (
  <g transform={`translate(${50 + x} ${50 + y}) rotate(${r}) scale(${s}) translate(-50 -50)`}>{children}</g>
);

const Twinkle: React.FC<{x: number; y: number; s: number; o: number}> = ({x, y, s, o}) => (
  <path d={`M${x},${y - s} Q${x},${y} ${x + s},${y} Q${x},${y} ${x},${y + s} Q${x},${y} ${x - s},${y} Q${x},${y} ${x},${y - s} Z`} fill="white" opacity={o} />
);

const LetterShot: React.FC<{lt: number; uid: string}> = ({lt, uid}) => {
  const band = -40 + ((lt - 0.55) / 0.7) * 160;
  return (
    <>
      <defs>
        <radialGradient id={`${uid}-bg`} cx="0.5" cy="0.45" r="0.75">
          <stop offset="0" stopColor="#14505C" />
          <stop offset="1" stopColor="#031418" />
        </radialGradient>
        <filter id={`${uid}-bokeh`}>
          <feGaussianBlur stdDeviation={1.6} />
        </filter>
        <mask id={`${uid}-mask`}>
          <text x={50} y={71} textAnchor="middle" fontFamily={FONT_COPTIC} fontSize={64} fill="white">
            a
          </text>
        </mask>
        <linearGradient id={`${uid}-band`} x1="0" y1="0" x2="1" y2="0">
          <stop offset="0" stopColor="white" stopOpacity={0} />
          <stop offset="0.5" stopColor="white" stopOpacity={0.95} />
          <stop offset="1" stopColor="white" stopOpacity={0} />
        </linearGradient>
      </defs>
      <rect width={100} height={100} fill={`url(#${uid}-bg)`} />
      <g filter={`url(#${uid}-bokeh)`}>
        {Array.from({length: 12}, (_, i) => (
          <circle
            key={i}
            cx={rnd(i + 1) * 100 + Math.sin(lt * 0.6 + i) * 2}
            cy={rnd(i + 30) * 100 - lt * 2}
            r={2 + rnd(i + 60) * 5}
            fill={i % 3 ? color('sunYellow') : color('mistBlue')}
            opacity={0.12 + rnd(i + 90) * 0.15}
          />
        ))}
      </g>
      <Camera s={1.0 + lt * 0.07} r={-3 + lt * 2}>
        <g transform="translate(50 50)">
          <GoldLetter ch="a" size={64} uid={`${uid}-a`} glow={Math.min(1, lt / 0.6)} />
        </g>
        <g mask={`url(#${uid}-mask)`}>
          <rect x={band} y={0} width={18} height={100} fill={`url(#${uid}-band)`} transform={`skewX(-20)`} />
        </g>
        <Twinkle x={66} y={34} s={6 * kick(lt, 0.85, 0.5)} o={kick(lt, 0.85, 0.5)} />
      </Camera>
      {Array.from({length: 18}, (_, i) => (
        <circle key={i} cx={(rnd(i + 200) * 100 + lt * (3 + rnd(i) * 4)) % 100} cy={(rnd(i + 300) * 100 - lt * 5 + 100) % 100} r={0.25 + rnd(i + 400) * 0.35} fill="#FFE9A8" opacity={0.6} />
      ))}
    </>
  );
};

const PyramidShot: React.FC<{lt: number; uid: string}> = ({lt, uid}) => (
  <>
    <defs>
      <linearGradient id={`${uid}-sky`} x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor={color('pyramidSkyTop')} />
        <stop offset="1" stopColor={color('skyBottom')} />
      </linearGradient>
    </defs>
    <rect width={100} height={100} fill={`url(#${uid}-sky)`} />
    <Camera s={1.25 - lt * 0.08} y={10 - lt * 9}>
      <g transform="translate(80 18)">
        <Sun r={7} spin={lt * 25} uid={`${uid}-s`} />
      </g>
      {[0, 1].map((i) => {
        const x = 18 + i * 9 + lt * 6;
        const y = 22 + i * 4 + Math.sin(lt * 3 + i) * 1;
        const f = Math.sin(lt * 14 + i * 2) * 1.6;
        return <path key={i} d={`M${x - 3},${y - f} Q${x - 1.5},${y - 1} ${x},${y} Q${x + 1.5},${y - 1} ${x + 3},${y - f}`} stroke={color('cocoa')} strokeWidth={0.6} fill="none" />;
      })}
      <g transform="translate(46 112) scale(1.25)">
        <Pyramid uid={`${uid}-p`} />
      </g>
      <path d="M-10,100 Q25,86 55,96 T120,92 L120,120 L-10,120 Z" fill={color('pyramidDune')} />
      <path d="M-10,108 Q30,96 70,104 T120,100 L120,120 L-10,120 Z" fill={color('pyramidDuneDark')} />
    </Camera>
  </>
);

const PalmShot: React.FC<{lt: number; uid: string}> = ({lt, uid}) => (
  <>
    <defs>
      <linearGradient id={`${uid}-sky`} x1="0" y1="0" x2="0.4" y2="1">
        <stop offset="0" stopColor="#FFE1A0" />
        <stop offset="0.5" stopColor={color('skyTop')} />
        <stop offset="1" stopColor={color('skyBottom')} />
      </linearGradient>
      <filter id={`${uid}-far`}>
        <feGaussianBlur stdDeviation={1.2} />
      </filter>
    </defs>
    <rect width={100} height={100} fill={`url(#${uid}-sky)`} />
    <Camera s={1.15} x={6 - lt * 10}>
      <circle cx={84} cy={12} r={16} fill={color('sunYellow')} opacity={0.35} />
      <circle cx={84} cy={12} r={8} fill="#FFF1B8" opacity={0.9} />
      <g filter={`url(#${uid}-far)`} opacity={0.55} transform="translate(82 104) scale(0.55)">
        <Palm sway={Math.sin(lt * 1.8 + 1) * 3} t={lt + 2} />
      </g>
      <g transform="translate(36 112) scale(0.95)">
        <Palm sway={Math.sin(lt * 1.8) * 4} t={lt} />
      </g>
      <path d="M-10,104 Q40,92 120,100 L120,120 L-10,120 Z" fill={color('farBank')} />
    </Camera>
  </>
);

const RiverShot: React.FC<{lt: number; uid: string}> = ({lt, uid}) => (
  <>
    <defs>
      <linearGradient id={`${uid}-water`} x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor={color('waterTop')} />
        <stop offset="1" stopColor={color('seaNear')} />
      </linearGradient>
    </defs>
    <rect width={100} height={100} fill={`url(#${uid}-water)`} />
    <Camera s={1.2} r={-18}>
      {Array.from({length: 16}, (_, i) => {
        const y = -5 + i * 7.5;
        const off = ((lt * (10 + (i % 3) * 3) + i * 9) % 20) - 20;
        let d = `M${-30 + off},${y}`;
        for (let k = 0; k < 9; k++) d += ` q5,${k % 2 ? 2 : -2} 10,0 t10,0`;
        return <path key={i} d={d} stroke="white" strokeOpacity={0.18 + (i % 4) * 0.08} strokeWidth={0.6 + (i % 3) * 0.4} fill="none" strokeLinecap="round" />;
      })}
      {Array.from({length: 9}, (_, i) => {
        const tw = Math.max(0, Math.sin(lt * 5 + i * 2.1));
        return <Twinkle key={i} x={rnd(i + 7) * 100} y={rnd(i + 17) * 100} s={2.4 * tw} o={tw} />;
      })}
      <g transform={`translate(${30 + lt * 14} ${58 - lt * 3}) rotate(${lt * 20})`}>
        <ellipse rx={5} ry={3.6} fill={color('leafGreen')} />
        <path d="M0,0 L5,-1" stroke={color('palmLeaf')} strokeWidth={0.6} />
      </g>
      {Array.from({length: 8}, (_, i) => (
        <path
          key={i}
          d={`M${-6 + i * 2.2},120 Q${-4 + i * 2.2 + Math.sin(lt * 2 + i) * 2},${80 - i * 3} ${-2 + i * 2.6 + Math.sin(lt * 2 + i) * 3},${66 - (i % 3) * 6}`}
          stroke={i % 2 ? color('reed') : color('palmLeaf')}
          strokeWidth={1.2}
          fill="none"
          strokeLinecap="round"
        />
      ))}
    </Camera>
  </>
);

const BookShot: React.FC<{lt: number; uid: string}> = ({lt, uid}) => {
  const letters = ['p', 'a', 'r', 'q', 'e', 'n', 'o', 's'];
  return (
    <>
      <defs>
        <linearGradient id={`${uid}-page`} x1="0" y1="0" x2="1" y2="0">
          <stop offset="0" stopColor="#D9C29A" />
          <stop offset="0.18" stopColor={color('cream')} />
          <stop offset="1" stopColor="#F6EAD2" />
        </linearGradient>
        <linearGradient id={`${uid}-curl`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="white" />
          <stop offset="1" stopColor="#CDB58C" />
        </linearGradient>
        <filter id={`${uid}-glow`}>
          <feGaussianBlur stdDeviation={1.4} />
        </filter>
      </defs>
      <rect width={100} height={100} fill={`url(#${uid}-page)`} />
      <Camera s={1.1 + lt * 0.2} r={-6}>
        {Array.from({length: 11}, (_, i) => (
          <g key={i}>
            {Array.from({length: 5}, (_, k) => (
              <rect key={k} x={12 + k * 17 + rnd(i * 9 + k) * 3} y={8 + i * 8.5} width={8 + rnd(i * 5 + k) * 7} height={1.6} rx={0.8} fill={color('cocoa')} opacity={0.16} />
            ))}
          </g>
        ))}
        {letters.map((ch, i) => {
          const rise = Math.max(0, lt - i * 0.05) * 1.6;
          const x = 14 + i * 10;
          const y = 62 - rise * 28 - Math.sin(i) * 3;
          const gold = Math.min(1, rise * 2);
          return (
            <g key={i} transform={`translate(${x} ${y}) rotate(${Math.sin(i * 1.7) * 18 * gold})`}>
              <text textAnchor="middle" fontFamily={FONT_COPTIC} fontSize={11} fill={color('sunYellow')} filter={`url(#${uid}-glow)`} opacity={gold}>
                {ch}
              </text>
              <text textAnchor="middle" fontFamily={FONT_COPTIC} fontSize={11} fill={gold > 0.5 ? color('letterGold') : color('cocoa')}>
                {ch}
              </text>
            </g>
          );
        })}
      </Camera>
      <path d={`M100,${78 - lt * 30} L100,100 L${78 - lt * 30},100 Z`} fill={`url(#${uid}-curl)`} />
    </>
  );
};

export const MacroScene: React.FC<{id: MacroId; lt: number; uid: string; punch?: number}> = ({id, lt, uid, punch = 0}) => {
  const Shot = {letter: LetterShot, pyramid: PyramidShot, palm: PalmShot, river: RiverShot, book: BookShot}[id];
  return (
    <svg viewBox="0 0 100 100" width="100%" height="100%" preserveAspectRatio="xMidYMid slice" style={{display: 'block'}}>
      <g transform={`translate(50 50) scale(${1 + 0.08 * punch}) translate(-50 -50)`}>
        <Shot lt={lt} uid={uid} />
      </g>
    </svg>
  );
};
