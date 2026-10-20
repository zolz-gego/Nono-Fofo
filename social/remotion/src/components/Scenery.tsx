import {FontAwesomeIcon} from '@fortawesome/react-fontawesome';
import React from 'react';
import {AbsoluteFill, interpolate, random, useCurrentFrame, useVideoConfig} from 'remotion';
import {ICONS} from '../icons';
import {color, FONT_AR, FONT_COPTIC, H, W} from '../theme';

// Themed, moving backgrounds (the `pattern` of a scene). Each one keeps
// moving so the scene never sits still behind the brothers.

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const shade = (c: string, k: number) => `color-mix(in srgb, ${c} ${100 - k}%, black)`;
const tint = (c: string, k: number) => `color-mix(in srgb, ${c} ${100 - k}%, white)`;
const GOLD = color('letterGold');

// ---------------------------------------------------------------- Cairo skyline

const Cairo: React.FC<{base: string; camX: number}> = ({base, camX}) => {
  const f = useCurrentFrame();
  const far = shade(base, 14);
  const near = shade(base, 26);
  // a row of buildings, domes and minarets
  const city = (seed: string, y: number, fill: string, drift: number, par: number) => {
    const parts: React.ReactNode[] = [];
    // buildings are laid out in world space from x = -2400, shifted by the camera (parallax)
    let x = -2400 - camX * par + ((f * drift) % 120);
    let i = 0;
    while (x < W + 120) {
      if (x < -300) {
        x += 70 + random(`${seed}w${i}`) * 110 + 8;
        i++;
        continue;
      }
      const w = 70 + random(`${seed}w${i}`) * 110;
      const h = 120 + random(`${seed}h${i}`) * 220;
      const kind = random(`${seed}k${i}`);
      parts.push(<rect key={`b${i}`} x={x} y={y - h} width={w} height={h + 400} fill={fill} rx={6} />);
      if (kind < 0.3) parts.push(<circle key={`d${i}`} cx={x + w / 2} cy={y - h} r={w * 0.38} fill={fill} />);
      if (kind > 0.75) {
        parts.push(<rect key={`m${i}`} x={x + w / 2 - 12} y={y - h - 170} width={24} height={180} fill={fill} />);
        parts.push(<circle key={`mt${i}`} cx={x + w / 2} cy={y - h - 172} r={20} fill={fill} />);
      }
      for (let r = 0; r < 3; r++)
        for (let c = 0; c < 2; c++)
          if (random(`${seed}win${i}-${r}-${c}`) > 0.45)
            parts.push(<rect key={`w${i}-${r}-${c}`} x={x + 16 + c * (w / 2 - 6)} y={y - h + 30 + r * 52} width={20} height={28} rx={8} fill={color('studyWindow')} opacity={0.5 + 0.4 * Math.sin(f / 9 + i + r)} />);
      x += w + 8;
      i++;
    }
    return parts;
  };
  return (
    <svg width={W} height={H} style={{position: 'absolute'}}>
      {/* sun + clouds */}
      <circle cx={820} cy={330} r={120 + Math.sin(f / 12) * 6} fill={color('sunYellow')} opacity={0.9} />
      {[0, 1, 2].map((i) => {
        const x = ((f * (0.8 + i * 0.4) + i * 420) % (W + 400)) - 300;
        return (
          <g key={i} transform={`translate(${x} ${240 + i * 150})`} opacity={0.85}>
            <ellipse cx={0} cy={0} rx={110} ry={44} fill="white" />
            <ellipse cx={60} cy={-26} rx={70} ry={50} fill="white" />
            <ellipse cx={-50} cy={-14} rx={60} ry={40} fill="white" />
          </g>
        );
      })}
      {/* far pyramids, Cairo Tower */}
      <g transform={`translate(${-camX * 0.15} 0)`}>
        <polygon points="40,1040 210,820 380,1040" fill={far} />
        <polygon points="300,1040 420,880 540,1040" fill={far} />
        <rect x={690} y={640} width={26} height={420} fill={far} />
        <ellipse cx={703} cy={640} rx={44} ry={70} fill={far} />
      </g>
      <g>{city('far', 1080, far, 0.15, 0.35)}</g>
      <g>{city('near', 1230, near, 0.3, 0.7)}</g>
      {/* birds */}
      {[0, 1, 2, 3].map((i) => {
        const x = ((f * 3 + i * 130) % (W + 300)) - 150;
        const y = 520 + i * 40 + Math.sin(f / 8 + i) * 20;
        const wing = Math.sin(f / 3 + i) * 14;
        return <path key={i} d={`M${x - 26} ${y - wing} Q${x - 10} ${y - 8} ${x} ${y} Q${x + 10} ${y - 8} ${x + 26} ${y - wing}`} stroke={shade(base, 45)} strokeWidth={6} fill="none" strokeLinecap="round" />;
      })}
    </svg>
  );
};

// ---------------------------------------------------------------- football pitch (gold lines)

const Field: React.FC<{base: string; from: number}> = ({base, from}) => {
  const f = useCurrentFrame() - from;
  const draw = interpolate(f, [0, 24], [0, 1], clamp);
  const line = {fill: 'none', stroke: GOLD, strokeWidth: 12, strokeLinecap: 'round' as const, pathLength: 1, strokeDasharray: 1, strokeDashoffset: 1 - draw};
  const glow = 0.55 + 0.25 * Math.sin(f / 8);
  return (
    <>
      {Array.from({length: 9}, (_, i) => (
        <div key={i} style={{position: 'absolute', left: 0, top: i * 240 - ((f * 1.5) % 480) + (i % 2) * 0, width: W, height: 240, background: i % 2 ? shade(base, 8) : 'transparent'}} />
      ))}
      <svg width={W} height={H} style={{position: 'absolute', filter: `drop-shadow(0 0 ${14 * glow}px ${color('sunYellow')})`}}>
        <rect x={80} y={190} width={920} height={1540} rx={14} {...line} />
        <line x1={80} y1={960} x2={1000} y2={960} {...line} />
        <circle cx={540} cy={960} r={180} {...line} />
        <rect x={270} y={190} width={540} height={260} {...line} />
        <rect x={400} y={190} width={280} height={110} {...line} />
        <rect x={270} y={1470} width={540} height={260} {...line} />
        <rect x={400} y={1620} width={280} height={110} {...line} />
        <path d="M430 450 A140 140 0 0 0 650 450" {...line} />
        <path d="M430 1470 A140 140 0 0 1 650 1470" {...line} />
        <circle cx={540} cy={960} r={12} fill={GOLD} opacity={draw} />
      </svg>
      {/* sparkles running along the lines */}
      {Array.from({length: 6}, (_, i) => {
        const k = ((f / 60 + i / 6) % 1) * 4920;
        const pt = k < 920 ? [80 + k, 190] : k < 2460 ? [1000, 190 + k - 920] : k < 3380 ? [1000 - (k - 2460), 1730] : [80, 1730 - (k - 3380)];
        return <div key={i} style={{position: 'absolute', left: pt[0] - 14, top: pt[1] - 14, width: 28, height: 28, borderRadius: 14, background: 'white', boxShadow: `0 0 24px ${color('sunYellow')}`, opacity: draw}} />;
      })}
    </>
  );
};

// ---------------------------------------------------------------- doodles: drawings + puzzle pieces

const PUZZLE = 'M0 20 H22 a14 14 0 1 1 26 0 H70 V42 a14 14 0 1 0 0 26 V90 H48 a14 14 0 1 1 -26 0 H0 Z';
const DRAWINGS = [
  // sun
  {d: 'M0 0 m-50 0 a50 50 0 1 0 100 0 a50 50 0 1 0 -100 0 M-90 0 h-30 M90 0 h30 M0 -90 v-30 M0 90 v30 M64 64 l20 20 M-64 -64 l-20 -20 M64 -64 l20 -20 M-64 64 l-20 20', x: 180, y: 300, c: 'sunYellow'},
  // house
  {d: 'M-80 40 V-30 L0 -100 L80 -30 V40 Z M-25 40 V0 H25 V40', x: 860, y: 420, c: 'coral'},
  // star
  {d: 'M0 -80 L22 -24 L80 -24 L34 10 L52 70 L0 34 L-52 70 L-34 10 L-80 -24 L-22 -24 Z', x: 170, y: 760, c: 'leafGreen'},
  // heart
  {d: 'M0 60 C-90 0 -70 -70 0 -30 C70 -70 90 0 0 60 Z', x: 900, y: 860, c: 'coral'},
  // spiral
  {d: 'M0 0 a10 10 0 0 1 20 0 a20 20 0 0 1 -40 0 a30 30 0 0 1 60 0 a40 40 0 0 1 -80 0 a50 50 0 0 1 100 0', x: 150, y: 1150, c: 'deepTeal'},
  // zigzag + flower
  {d: 'M-90 0 L-60 -30 L-30 0 L0 -30 L30 0 L60 -30 L90 0 M0 -120 m-20 0 a20 20 0 1 0 40 0 a20 20 0 1 0 -40 0', x: 880, y: 1180, c: 'deepTeal'},
];

const Doodles: React.FC = () => {
  const f = useCurrentFrame();
  const colors = ['coral', 'sunYellow', 'leafGreen', 'deepTeal', 'slateTeal'];
  return (
    <>
      {/* puzzle pieces drifting and turning */}
      {Array.from({length: 9}, (_, i) => {
        const x = random(`px${i}`) * (W - 120);
        const y = ((random(`py${i}`) * H - f * (0.6 + random(`ps${i}`)) + H * 3) % (H + 200)) - 100;
        const rot = random(`pr${i}`) * 360 + f * (random(`pv${i}`) - 0.5) * 2;
        const c = color(colors[i % colors.length]);
        return (
          <svg key={i} width={120} height={120} viewBox="-10 -10 110 110" style={{position: 'absolute', left: x, top: y, transform: `rotate(${rot}deg)`, opacity: 0.55}}>
            <path d={PUZZLE} fill={c} stroke="white" strokeWidth={6} strokeLinejoin="round" />
          </svg>
        );
      })}
      {/* crayon drawings that draw themselves, one after another */}
      <svg width={W} height={H} style={{position: 'absolute'}}>
        {DRAWINGS.map((d, i) => {
          const k = interpolate(f, [i * 7, i * 7 + 26], [0, 1], clamp);
          return (
            <path
              key={i}
              d={d.d}
              transform={`translate(${d.x} ${d.y}) rotate(${Math.sin(f / 20 + i) * 4})`}
              fill="none"
              stroke={color(d.c)}
              strokeWidth={12}
              strokeLinecap="round"
              strokeLinejoin="round"
              pathLength={1}
              strokeDasharray={1}
              strokeDashoffset={1 - k}
              opacity={0.75}
            />
          );
        })}
      </svg>
    </>
  );
};

// ---------------------------------------------------------------- icons that float and light up

const IconsBg: React.FC<{icons: string[]; seed: string; base: string; camX: number}> = ({icons, seed, base, camX}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const n = 14;
  return (
    <>
      {Array.from({length: n}, (_, i) => {
        const icon = ICONS[icons[i % icons.length]];
        if (!icon) return null;
        const col = i % 3;
        const x = ((((60 + ((i * 0.618 + random(`${seed}ix${i}`) * 0.3) % 1) * (W - 200) - camX * (0.4 + col * 0.2)) % (W + 100)) + W + 100) % (W + 100)) - 100;
        const y = ((random(`${seed}iy${i}`) * H - f * (0.9 + random(`${seed}is${i}`) * 1.3) + H * 3) % (H + 240)) - 120;
        const size = 70 + random(`${seed}iz${i}`) * 80 + col * 10;
        const litAt = random(`${seed}il${i}`) * 1.6 * fps;
        const lit = interpolate(f - litAt, [0, 6], [0, 1], clamp);
        const pulse = lit * (1 + 0.08 * Math.sin((f - litAt) / 5));
        const rot = Math.sin(f / 18 + i) * 12;
        return (
          <div key={i} style={{position: 'absolute', left: x, top: y, width: size, height: size, transform: `rotate(${rot}deg) scale(${0.85 + 0.15 * pulse})`}}>
            {lit > 0 && (
              <div style={{position: 'absolute', left: -size * 0.6, top: -size * 0.6, width: size * 2.2, height: size * 2.2, borderRadius: '50%', background: `radial-gradient(circle, ${color('foundGlow')} 0%, transparent 65%)`, opacity: lit * (0.6 + 0.3 * Math.sin((f - litAt) / 6))}} />
            )}
            <div style={{position: 'relative', fontSize: size, lineHeight: 1, color: lit > 0.5 ? color('sunYellow') : tint(base, 35), opacity: 0.45 + 0.5 * lit, filter: lit > 0.5 ? `drop-shadow(0 4px 0 ${shade(base, 30)})` : undefined}}>
              <FontAwesomeIcon icon={icon} />
            </div>
          </div>
        );
      })}
    </>
  );
};

// ---------------------------------------------------------------- Grandpa's study

const Study: React.FC<{camX: number}> = ({camX}) => {
  const f = useCurrentFrame();
  const books = ['coral', 'deepTeal', 'leafGreen', 'sunYellow', 'slateTeal', 'monasteryRug', 'mistBlue'];
  return (
    <>
      <AbsoluteFill style={{background: `linear-gradient(${color('studyWall')}, ${color('studyWallShade')})`}} />
      <AbsoluteFill style={{transform: `translateX(${-camX * 0.6}px)`}}>
      {/* mashrabiya window with light beams */}
      <div style={{position: 'absolute', left: 90, top: 200, width: 300, height: 420, borderRadius: '150px 150px 12px 12px', background: color('studyWindow'), border: `16px solid ${color('studyMashrabiya')}`, overflow: 'hidden'}}>
        <svg width={300} height={420} style={{position: 'absolute'}}>
          {Array.from({length: 8}, (_, i) => <line key={`v${i}`} x1={i * 40} y1={0} x2={i * 40} y2={420} stroke={color('studyMashrabiya')} strokeWidth={8} />)}
          {Array.from({length: 11}, (_, i) => <line key={`h${i}`} x1={0} y1={i * 40} x2={300} y2={i * 40} stroke={color('studyMashrabiya')} strokeWidth={8} />)}
          {Array.from({length: 40}, (_, i) => <circle key={`c${i}`} cx={(i % 8) * 40 + 20} cy={Math.floor(i / 8) * 80 + 20} r={9} fill={color('studyMashrabiya')} />)}
        </svg>
      </div>
      <div style={{position: 'absolute', left: 120, top: 560, width: 900, height: 900, background: `linear-gradient(160deg, ${color('studyLight')}, transparent 70%)`, clipPath: 'polygon(0 0, 30% 0, 100% 100%, 40% 100%)', opacity: 0.8 + 0.2 * Math.sin(f / 15)}} />
      {/* bookshelf */}
      <div style={{position: 'absolute', right: 60, top: 180, width: 420, height: 700, background: color('studyShelf'), borderRadius: 12, padding: 18}}>
        {[0, 1, 2].map((r) => (
          <div key={r} style={{display: 'flex', alignItems: 'flex-end', gap: 6, height: 200, borderBottom: `16px solid ${shade(color('studyShelf'), 25)}`, marginBottom: 14, padding: '0 8px'}}>
            {Array.from({length: 8}, (_, i) => (
              <div key={i} style={{width: 34 + random(`bw${r}${i}`) * 14, height: 120 + random(`bh${r}${i}`) * 60, background: color(books[(r * 3 + i) % books.length]), borderRadius: 4, transform: `rotate(${i === 6 ? 12 : 0}deg)`, transformOrigin: 'bottom', boxShadow: 'inset -6px 0 0 rgba(0,0,0,0.12)'}} />
            ))}
          </div>
        ))}
      </div>
      {/* floor + rug */}
      <div style={{position: 'absolute', left: -1500, top: 1180, width: W + 3000, height: H - 1180, background: color('studyFloor')}} />
      {Array.from({length: 6}, (_, i) => <div key={i} style={{position: 'absolute', left: -1500, top: 1230 + i * 110, width: W + 3000, height: 6, background: color('studyFloorLine')}} />)}
      {/* a second window and a hanging lamp further left, for camera pans */}
      <div style={{position: 'absolute', left: -560, top: 220, width: 260, height: 380, borderRadius: '130px 130px 12px 12px', background: color('studyWindow'), border: `16px solid ${color('studyMashrabiya')}`}} />
      <div style={{position: 'absolute', left: -220, top: 0, width: 8, height: 300, background: color('cocoa')}} />
      <div style={{position: 'absolute', left: -280, top: 290, width: 130, height: 80, borderRadius: '65px 65px 10px 10px', background: color('monasteryBrass'), boxShadow: `0 40px 80px ${color('studyWindow')}`}} />
      <div style={{position: 'absolute', left: 120, top: 1250, width: 840, height: 120, borderRadius: '50%', background: color('monasteryRug'), border: `12px solid ${color('monasteryRugBorder')}`, boxShadow: `inset 0 0 0 14px ${color('studyArmchair')}`}} />
      {/* dust in the light */}
      {Array.from({length: 22}, (_, i) => {
        const x = 200 + random(`dx${i}`) * 700 + Math.sin(f / 30 + i) * 30;
        const y = 600 + ((random(`dy${i}`) * 800 - f * 0.6 + 1600) % 800);
        return <div key={i} style={{position: 'absolute', left: x, top: y, width: 10, height: 10, borderRadius: 5, background: 'white', opacity: 0.35 + 0.3 * Math.sin(f / 7 + i)}} />;
      })}
      </AbsoluteFill>
    </>
  );
};

// ---------------------------------------------------------------- sea waves

const Waves: React.FC<{base: string}> = ({base}) => {
  const f = useCurrentFrame();
  return (
    <svg width={W} height={H} style={{position: 'absolute'}}>
      {Array.from({length: 12}, (_, r) => {
        const y = 120 + r * 160;
        const off = ((f * (2 + (r % 3))) % 200) - 200;
        let d = `M${off} ${y}`;
        for (let x = off; x < W + 200; x += 100) d += ` q25 ${r % 2 ? -22 : 22} 50 0 q25 ${r % 2 ? 22 : -22} 50 0`;
        return <path key={r} d={d} stroke={tint(base, 55)} strokeWidth={9} fill="none" strokeLinecap="round" opacity={0.7} />;
      })}
      {/* a little felucca sailing by */}
      <g transform={`translate(${((f * 2.4) % (W + 300)) - 150} ${1470 + Math.sin(f / 10) * 8})`}>
        <path d="M-70 0 H70 L50 30 H-50 Z" fill={color('monasteryWood')} />
        <path d="M0 -10 V-150 L70 -20 Z" fill="white" stroke={color('cocoa')} strokeWidth={5} />
      </g>
    </svg>
  );
};

// ---------------------------------------------------------------- desert with dunes

const Desert: React.FC = () => {
  const f = useCurrentFrame();
  const dune = (y: number, amp: number, c: string, speed: number, k: number) => {
    const off = -((f * speed) % 600);
    let d = `M${off} ${y}`;
    for (let x = off; x < W + 600; x += 300) d += ` q75 ${-amp} 150 0 q75 ${amp * 0.6} 150 0`;
    return <path key={k} d={`${d} V${H} H${off} Z`} fill={c} />;
  };
  return (
    <>
      <AbsoluteFill style={{background: `linear-gradient(${color('pyramidSkyTop')}, ${color('skyBottom')} 60%)`}} />
      <svg width={W} height={H} style={{position: 'absolute'}}>
        <circle cx={840} cy={300} r={110} fill={color('sunYellow')} />
        <circle cx={840} cy={300} r={150 + Math.sin(f / 10) * 10} fill={color('sunGlow')} />
        {dune(1000, 90, color('pyramidDune'), 0.4, 0)}
        {dune(1150, 70, color('pyramidDuneDark'), 0.8, 1)}
        {dune(1300, 60, color('monasteryDesert'), 1.3, 2)}
        {/* palm */}
        <g transform="translate(150 1060)">
          <path d="M0 0 Q-10 -120 10 -240" stroke={color('palmTrunk')} strokeWidth={22} fill="none" strokeLinecap="round" />
          {[-60, -20, 20, 60, 100].map((a, i) => (
            <path key={i} d="M10 -240 q60 -30 120 20" stroke={color('palmLeaf')} strokeWidth={20} fill="none" strokeLinecap="round" transform={`rotate(${a + Math.sin(f / 12 + i) * 4} 10 -240)`} />
          ))}
        </g>
      </svg>
    </>
  );
};

// ---------------------------------------------------------------- chalkboard

const Board: React.FC = () => {
  const f = useCurrentFrame();
  const chalk = ['a', 'b', 'j', 'd', 'e', 'w', 'A', 'W'];
  return (
    <>
      <AbsoluteFill style={{background: color('boardFrame')}} />
      <div style={{position: 'absolute', left: 30, top: 30, right: 30, bottom: 30, borderRadius: 24, background: `radial-gradient(circle at 50% 40%, ${color('board')}, ${color('boardDark')})`, boxShadow: `inset 0 0 0 10px ${color('boardFrameDark')}`}} />
      {/* faint chalk letters and doodles, slowly written */}
      {chalk.map((k, i) => {
        const x = 80 + random(`cx${i}`) * 820;
        const y = 120 + random(`cy${i}`) * 1500;
        const o = interpolate(f, [i * 5, i * 5 + 12], [0, 0.16], clamp);
        return <div key={i} style={{position: 'absolute', left: x, top: y, fontFamily: FONT_COPTIC, fontSize: 130 + random(`cs${i}`) * 80, color: color('demoChalk'), opacity: o, transform: `rotate(${(random(`cr${i}`) - 0.5) * 30}deg)`}}>{k}</div>;
      })}
      <svg width={W} height={H} style={{position: 'absolute', opacity: 0.18}}>
        <path d="M120 1500 q80 -60 160 0 t160 0" stroke="white" strokeWidth={8} fill="none" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - interpolate(f, [10, 40], [0, 1], clamp)} />
        <path d="M800 900 l40 -80 l40 80 z" stroke="white" strokeWidth={8} fill="none" pathLength={1} strokeDasharray={1} strokeDashoffset={1 - interpolate(f, [20, 45], [0, 1], clamp)} />
      </svg>
      {/* chalk dust */}
      {Array.from({length: 14}, (_, i) => {
        const x = random(`bdx${i}`) * W;
        const y = (random(`bdy${i}`) * H + f * (0.5 + random(`bds${i}`))) % H;
        return <div key={i} style={{position: 'absolute', left: x, top: y, width: 8, height: 8, borderRadius: 4, background: 'white', opacity: 0.2}} />;
      })}
    </>
  );
};

// ---------------------------------------------------------------- notebook grid

const Grid: React.FC = () => {
  const f = useCurrentFrame();
  const nums = ['١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', '1', '2', '3', '4', '5'];
  return (
    <>
      <AbsoluteFill style={{background: color('cream')}} />
      <svg width={W} height={H} style={{position: 'absolute'}}>
        {Array.from({length: 30}, (_, i) => <line key={`h${i}`} x1={0} y1={i * 66} x2={W} y2={i * 66} stroke={color('mistBlue')} strokeWidth={3} />)}
        {Array.from({length: 18}, (_, i) => <line key={`v${i}`} x1={i * 66} y1={0} x2={i * 66} y2={H} stroke={color('mistBlue')} strokeWidth={3} opacity={0.6} />)}
        <line x1={120} y1={0} x2={120} y2={H} stroke={color('coral')} strokeWidth={5} />
      </svg>
      {nums.map((n, i) => {
        const x = 150 + random(`nx${i}`) * 820;
        const y = ((random(`ny${i}`) * H - f * (0.5 + random(`ns${i}`) * 0.8) + H * 3) % (H + 200)) - 100;
        return (
          <div key={i} style={{position: 'absolute', left: x, top: y, fontFamily: FONT_AR, fontWeight: 800, fontSize: 90 + random(`nz${i}`) * 60, color: color(['coral', 'deepTeal', 'leafGreen', 'sunYellow'][i % 4]), opacity: 0.3, transform: `rotate(${Math.sin(f / 15 + i) * 12}deg)`}}>
            {n}
          </div>
        );
      })}
    </>
  );
};

// ---------------------------------------------------------------- running track

const Track: React.FC<{base: string; camX: number}> = ({base, camX}) => {
  const f = useCurrentFrame();
  return (
    <>
      <AbsoluteFill style={{background: `linear-gradient(${tint(color('mistBlue'), 20)} 0 38%, ${base} 38%)`}} />
      {/* stands with a crowd of dots */}
      {Array.from({length: 4}, (_, r) => (
        <div key={r} style={{position: 'absolute', left: 0, top: 260 + r * 90, width: W, height: 90, background: r % 2 ? color('slateTeal') : color('deepTeal')}}>
          {Array.from({length: 18}, (_, i) => (
            <div key={i} style={{position: 'absolute', left: ((((i * 62 + (r % 2) * 30 - camX * 0.5) % (W + 62)) + W + 62) % (W + 62)) - 40, top: 18 + Math.abs(Math.sin(f / 4 + i + r)) * -14, width: 34, height: 34, borderRadius: 17, background: color(['coral', 'sunYellow', 'cream', 'leafGreen'][(i + r) % 4])}} />
          ))}
        </div>
      ))}
      {/* lane lines rushing past */}
      {[800, 1000, 1200, 1400, 1600].map((y, i) => (
        <div key={i} style={{position: 'absolute', left: 0, top: y, width: W, height: 12, background: 'white', opacity: 0.85}} />
      ))}
      {Array.from({length: 8}, (_, i) => (
        <div key={i} style={{position: 'absolute', left: ((i * 260 - f * 28 - camX * 1.2) % (W + 260) + W + 260) % (W + 260) - 130, top: 890 + (i % 4) * 200, width: 120, height: 14, borderRadius: 7, background: 'white', opacity: 0.5}} />
      ))}
    </>
  );
};

// ---------------------------------------------------------------- footprints trail

const Trail: React.FC<{base: string}> = ({base}) => {
  const f = useCurrentFrame();
  const icon = ICONS.shoes;
  return (
    <>
      {Array.from({length: 18}, (_, i) => {
        const p = i / 17;
        const x = 80 + p * 900;
        const y = 1250 - p * 950 + Math.sin(p * 9) * 90;
        const at = i * 3;
        const o = interpolate(f - at, [0, 4, 40, 60], [0, 1, 1, 0.35], clamp);
        return (
          <div key={i} style={{position: 'absolute', left: x, top: y, fontSize: 70, color: tint(base, 45), opacity: o, transform: `rotate(${-60 + Math.cos(p * 9) * 25}deg) scale(${interpolate(f - at, [0, 5], [1.6, 1], clamp)})`}}>
            {icon && <FontAwesomeIcon icon={icon} />}
          </div>
        );
      })}
    </>
  );
};

export const SCENERY = new Set(['cairo', 'field', 'doodles', 'icons', 'study', 'waves', 'desert', 'board', 'grid', 'track', 'trail']);

export const Scenery: React.FC<{pattern: string; base: string; seed: string; icons?: string[]; camX?: number; from?: number}> = ({pattern, base, seed, icons, camX = 0, from = 0}) => {
  switch (pattern) {
    case 'cairo':
      return <Cairo base={base} camX={camX} />;
    case 'field':
      return <Field base={base} from={from} />;
    case 'doodles':
      return <Doodles />;
    case 'icons':
      return <IconsBg icons={icons ?? ['star']} seed={seed} base={base} camX={camX} />;
    case 'study':
      return <Study camX={camX} />;
    case 'waves':
      return <Waves base={base} />;
    case 'desert':
      return <Desert />;
    case 'board':
      return <Board />;
    case 'grid':
      return <Grid />;
    case 'track':
      return <Track base={base} camX={camX} />;
    case 'trail':
      return <Trail base={base} />;
    default:
      return null;
  }
};
