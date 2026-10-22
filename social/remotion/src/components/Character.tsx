import React from 'react';
import {Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {characters} from '../generated/data';
import {color} from '../theme';
import type {CharacterSpec} from '../types';

const HEIGHT = 760; // on-screen height of a standing character
const FEET_Y = 1300;
const X = {center: 540, left: 330, right: 750};

// One brother. `amp` (0..1) is how loud he's speaking right now: he bobs,
// squashes and tilts with it, so he looks like he's talking.
export const Character: React.FC<{spec: CharacterSpec; amp: number}> = ({spec, amp}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  let pose = spec.pose;
  let prevPose = pose;
  let swapFrame = -1;
  let fade = false;
  for (const s of spec.swaps ?? []) {
    if (frame >= s.at * fps) {
      prevPose = pose;
      pose = s.pose;
      swapFrame = Math.round(s.at * fps);
      fade = !!s.fade;
    }
  }
  // dissolve: the old pose fades out over the new one
  const fadeK = fade ? Math.min(1, (frame - swapFrame) / (0.45 * fps)) : 1;
  const info = characters[spec.who][pose];
  const height = HEIGHT * (spec.size ?? 1);
  const scale = height / info.height;
  const w = info.width * scale;

  const delay = Math.round((spec.delay ?? 0) * fps);
  if (frame < delay) return null;
  const enter = spec.enter ?? 'left';
  const inP = spring({frame: frame - delay, fps, config: {damping: 13, stiffness: 140, mass: 0.8}});
  let dx = 0;
  let dy = 0;
  let s = 1;
  if (enter === 'left') dx = interpolate(inP, [0, 1], [-1000, 0]);
  if (enter === 'right') dx = interpolate(inP, [0, 1], [1000, 0]);
  if (enter === 'bottom') dy = interpolate(inP, [0, 1], [1100, 0]);
  if (enter === 'pop') s = inP;

  // A little hop each time the pose changes.
  const hop = swapFrame >= 0 && !fade ? Math.sin(Math.min(1, (frame - swapFrame) / 9) * Math.PI) * 50 : 0;
  const swapPop = swapFrame >= 0 && !fade ? spring({frame: frame - swapFrame, fps, config: {damping: 9, stiffness: 220}}) : 1;

  // Repeated jumps (e.g. trying to reach something high).
  let jump = 0;
  for (const j of spec.jumps ?? []) {
    const k = frame / fps - j.at;
    if (k >= 0 && k < (j.until ?? 99) - j.at) jump = Math.max(jump, Math.abs(Math.sin((k / (j.every ?? 0.55)) * Math.PI)) * (j.height ?? 110));
  }

  const breathe = Math.sin(frame / 11) * 0.012;
  const talkY = -amp * 26;
  const sx = 1 + breathe - amp * 0.03;
  const sy = 1 - breathe + amp * 0.05;
  const tilt = Math.sin(frame / 4.5) * amp * 3.5;
  const x = spec.x ?? X[spec.at ?? 'center'];

  // Sideways moves (runs across, runs off, comes back).
  let mx = 0;
  let my = 0;
  let flip = !!spec.flip;
  for (const m of spec.moves ?? []) {
    const a = m.at * fps;
    if (frame < a) break;
    const d = (m.dur ?? 0.4) * fps;
    // a move shorter than a frame is a jump: it applies from its first frame
    const k = d <= 1 ? 1 : Math.min(1, (frame - a) / d);
    const e = k < 1 ? 1 - Math.pow(1 - k, 2.2) : 1;
    mx = mx + (m.to - mx) * e;
    if (m.toY !== undefined) my = my + (m.toY - my) * e;
    if (m.flip !== undefined) flip = m.flip;
  }

  const style: React.CSSProperties = {
    position: 'absolute',
    left: x - w / 2 + dx + mx,
    top: FEET_Y - height + dy + my,
    width: w,
    height,
    transformOrigin: '50% 100%',
    transform: `translateY(${talkY - hop - jump}px) rotate(${tilt}deg) scale(${sx * s * (0.85 + 0.15 * swapPop)}, ${sy * s * (0.85 + 0.15 * swapPop)}) ${flip ? 'scaleX(-1)' : ''}`,
    filter: 'drop-shadow(0 10px 0 rgba(0,0,0,0.08))',
  };
  const prev = characters[spec.who][prevPose];
  if (fadeK < 1 && info.file && prev?.file) {
    const pw = prev.width * (height / prev.height);
    return (
      <>
        <Img src={staticFile(prev.file)} style={{...style, left: (style.left as number) + (w - pw) / 2, width: pw, opacity: 1 - fadeK}} />
        <Img src={staticFile(info.file)} style={{...style, opacity: fadeK}} />
      </>
    );
  }
  return info.file ? (
    <Img src={staticFile(info.file)} style={style} />
  ) : (
    <div style={style}>
      <StatuePlaceholder pose={pose} />
    </div>
  );
};

// Stand-in for a guest whose image isn't made yet (e.g. Ramses before his PNGs
// arrive): a simple sandstone pharaoh statue, drawn on the same 1000×1500 box.
const StatuePlaceholder: React.FC<{pose: string}> = ({pose}) => {
  const stone = color('fortWall');
  const dark = `color-mix(in srgb, ${stone} 70%, black)`;
  const line = color('cocoa');
  const eye = pose === 'look' ? 22 : 0;
  const mouth = pose === 'talk' || pose === 'smile';
  return (
    <svg viewBox="0 0 1000 1500" width="100%" height="100%" style={{overflow: 'visible'}}>
      <g stroke={line} strokeWidth={14} strokeLinejoin="round">
        <rect x={250} y={1340} width={500} height={150} rx={20} fill={dark} />
        <path d="M330 640 L670 640 L720 1340 L280 1340 Z" fill={stone} />
        <path d="M330 900 L670 900 L700 1180 L300 1180 Z" fill="white" opacity={0.5} />
        <path d="M300 640 L230 1000 L290 1010 L350 700" fill={stone} />
        <path d="M700 640 L770 1000 L710 1010 L650 700" fill={stone} />
        <path d="M290 260 Q500 60 710 260 L780 620 L220 620 Z" fill={color('mistBlue')} />
        <ellipse cx={500} cy={380} rx={170} ry={200} fill={stone} />
        <path d="M455 560 L545 560 L530 690 L470 690 Z" fill={dark} />
        <path d="M480 175 q20 -40 40 0 q-20 30 -40 0" fill={color('sunYellow')} />
      </g>
      <ellipse cx={430} cy={360} rx={44} ry={52} fill="white" stroke={line} strokeWidth={10} />
      <ellipse cx={570} cy={360} rx={44} ry={52} fill="white" stroke={line} strokeWidth={10} />
      <circle cx={430 + eye} cy={368} r={20} fill={line} />
      <circle cx={570 + eye} cy={368} r={20} fill={line} />
      <path d="M385 290 L470 300 M530 300 L615 290" stroke={line} strokeWidth={16} strokeLinecap="round" transform={pose === 'demand' ? 'rotate(8 500 295)' : undefined} />
      {mouth ? <ellipse cx={500} cy={480} rx={60} ry={pose === 'talk' ? 40 : 28} fill={line} /> : <path d="M445 470 Q500 505 555 470" fill="none" stroke={line} strokeWidth={12} strokeLinecap="round" />}
      <text x={500} y={1440} textAnchor="middle" fontSize={64} fontFamily="sans-serif" fill="white" opacity={0.85}>
        {pose}
      </text>
    </svg>
  );
};
