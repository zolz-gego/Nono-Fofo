import React from 'react';
import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {CAPTION_BOTTOM, color, FONT_AR, FONT_EN, H, SAFE} from '../theme';
import type {Line} from '../types';

// Start time (s from voice start) of each Arabic word: given in video.json,
// or spread over the line by word length.
function wordStarts(line: Line, words: string[], voiceSec: number): number[] {
  if (line.words?.length === words.length) return line.words;
  const weights = words.map((w) => w.replace(/[^\p{L}]/gu, '').length + 1);
  const total = weights.reduce((a, b) => a + b, 0);
  let acc = 0;
  return weights.map((w) => {
    const t = (acc / total) * voiceSec;
    acc += w;
    return t;
  });
}

// Arabic line (word by word) with the English subtitle under it.
export const Captions: React.FC<{line: Line; voiceFrom: number; voiceFrames: number}> = ({line, voiceFrom, voiceFrames}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = (frame - voiceFrom) / fps;
  const words = line.ar.split(/\s+/).filter(Boolean);
  const starts = wordStarts(line, words, voiceFrames / fps);
  const current = starts.findLastIndex((s) => t >= s);
  const inP = spring({frame: frame - voiceFrom + 4, fps, config: {damping: 14, stiffness: 180}});

  return (
    <div
      style={{
        position: 'absolute',
        left: SAFE.left,
        width: SAFE.right - SAFE.left,
        bottom: H - CAPTION_BOTTOM, // anchored at the bottom so long lines grow upwards
        padding: '22px 34px 26px',
        borderRadius: 44,
        background: `color-mix(in srgb, ${color('deepTeal')} 88%, transparent)`,
        border: `6px solid ${color('cream')}`,
        boxShadow: '0 14px 0 rgba(0,0,0,0.12)',
        textAlign: 'center',
        transform: `translateY(${interpolate(inP, [0, 1], [60, 0])}px) scale(${interpolate(inP, [0, 1], [0.8, 1])})`,
        opacity: inP,
      }}
    >
      <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 76, lineHeight: 1.25, display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: '0 18px'}}>
        {words.map((w, i) => {
          const on = i === current;
          const said = i <= current;
          const pop = on ? spring({frame: frame - voiceFrom - Math.round(starts[i] * fps), fps, config: {damping: 10, stiffness: 260}}) : 0;
          return (
            <span
              key={i}
              style={{
                color: on ? color('sunYellow') : 'white',
                opacity: said ? 1 : 0.55,
                display: 'inline-block',
                transform: `scale(${1 + pop * 0.12}) translateY(${-pop * 6}px)`,
              }}
            >
              {w}
            </span>
          );
        })}
      </div>
      <div style={{fontFamily: FONT_EN, fontWeight: 700, fontSize: 50, lineHeight: 1.15, color: color('mistBlue'), marginTop: 6}}>{line.en}</div>
    </div>
  );
};
