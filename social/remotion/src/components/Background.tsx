import React from 'react';
import {AbsoluteFill, interpolate, random, useCurrentFrame} from 'remotion';
import {color, FONT_COPTIC, H, W} from '../theme';
import {Scenery, SCENERY} from './Scenery';

// Coptic letters (Avva keys) that float around in the background.
const LETTERS = 'abjdezqiklmnxoprctvfyw'.split('');

// camX: camera offset (px) for parallax; from: frame the themed pattern appears.
export const Background: React.FC<{bg: string; bg2?: string; pattern?: string; seed: string; icons?: string[]; camX?: number; from?: number; before?: {pattern: string; icons?: string[]}}> = ({bg, bg2, pattern = 'rays', seed, icons, camX = 0, from = 0, before}) => {
  const frame = useCurrentFrame();
  const base = color(bg);
  const accent = bg2 ? color(bg2) : 'rgba(255,255,255,0.22)';
  const cx = W / 2 - camX * 0.3;
  const cy = H * 0.52;
  const rays = 18;
  return (
    <AbsoluteFill style={{background: `radial-gradient(circle at 50% 50%, ${base} 0%, ${base} 45%, color-mix(in srgb, ${base} 78%, black) 100%)`}}>
      {before && SCENERY.has(before.pattern) && frame < from + 8 && (
        <AbsoluteFill style={{opacity: interpolate(frame, [from, from + 8], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})}}>
          <Scenery pattern={before.pattern} base={base} seed={`${seed}-before`} icons={before.icons} camX={camX} />
        </AbsoluteFill>
      )}
      {SCENERY.has(pattern) && frame >= from && (
        <AbsoluteFill style={{opacity: interpolate(frame, [from, from + 8], [from > 0 ? 0 : 1, 1], {extrapolateRight: 'clamp'})}}>
          <Scenery pattern={pattern} base={base} seed={seed} icons={icons} camX={camX} from={from} />
        </AbsoluteFill>
      )}
      {pattern === 'rays' && (
        <svg width={W} height={H} style={{position: 'absolute', opacity: bg2 ? 0.35 : 1}}>
          <g transform={`rotate(${frame * 0.35} ${cx} ${cy})`}>
            {Array.from({length: rays}, (_, i) => {
              const a0 = (i / rays) * Math.PI * 2;
              const a1 = a0 + Math.PI / rays;
              const r = 2400;
              return (
                <path key={i} d={`M${cx} ${cy} L${cx + r * Math.cos(a0)} ${cy + r * Math.sin(a0)} L${cx + r * Math.cos(a1)} ${cy + r * Math.sin(a1)} Z`} fill={accent} />
              );
            })}
          </g>
        </svg>
      )}
      {pattern === 'dots' &&
        Array.from({length: 26}, (_, i) => {
          const x = (((random(`${seed}-dx${i}`) * W - camX * 0.4) % W) + W) % W;
          const y = (random(`${seed}-dy${i}`) * H - frame * (1 + random(`${seed}-ds${i}`) * 2) + H * 2) % (H + 100) - 50;
          const s = 20 + random(`${seed}-dr${i}`) * 70;
          return <div key={i} style={{position: 'absolute', left: x, top: y, width: s, height: s, borderRadius: s, background: accent, opacity: 0.45}} />;
        })}
      {(pattern === 'letters' || pattern === 'rays') &&
        Array.from({length: 12}, (_, i) => {
          const x = (((random(`${seed}-lx${i}`) * (W - 120) - camX * 0.5) % W) + W) % W;
          const y = (random(`${seed}-ly${i}`) * H - frame * (0.8 + random(`${seed}-lsp${i}`) * 1.4) + H * 2) % (H + 200) - 100;
          const rot = (random(`${seed}-lr${i}`) - 0.5) * 60 + Math.sin(frame / 20 + i) * 8;
          return (
            <div
              key={i}
              style={{
                position: 'absolute',
                left: x,
                top: y,
                fontFamily: FONT_COPTIC,
                fontSize: 90 + random(`${seed}-lsz${i}`) * 90,
                color: 'white',
                opacity: pattern === 'letters' ? 0.35 : 0.22,
                transform: `rotate(${rot}deg)`,
              }}
            >
              {LETTERS[Math.floor(random(`${seed}-lc${i}`) * LETTERS.length)]}
            </div>
          );
        })}
    </AbsoluteFill>
  );
};
