import {FontAwesomeIcon} from '@fortawesome/react-fontawesome';
import React from 'react';
import {interpolate, random, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {ICONS} from '../icons';
import {color, FONT_AR, FONT_EN} from '../theme';
import type {Keyword} from '../types';

const CARD_W = 430;
const ACCENTS = ['coral', 'leafGreen', 'sunYellow', 'slateTeal'];

// A keyword pops in at the top: icon, the Arabic word, the English word.
export const KeywordCard: React.FC<{kw: Keyword; index: number; count: number; startFrame: number}> = ({kw, index, count, startFrame}) => {
  const frame = useCurrentFrame() - startFrame;
  const {fps} = useVideoConfig();
  if (frame < 0) return null;
  const p = spring({frame, fps, config: {damping: 9, stiffness: 170, mass: 0.7}});
  const left = count === 1 ? 540 - CARD_W / 2 : index % 2 === 0 ? 90 : 1080 - 90 - CARD_W;
  const tilt = (index % 2 === 0 ? -4 : 4) + Math.sin((frame + index * 20) / 14) * 1.5;
  const float = Math.sin((frame + index * 13) / 12) * 8;
  const accent = color(ACCENTS[index % ACCENTS.length]);
  const icon = kw.icon ? ICONS[kw.icon] : undefined;

  return (
    <div style={{position: 'absolute', left, top: 300 + float, width: CARD_W}}>
      {/* burst of little stars */}
      {Array.from({length: 8}, (_, i) => {
        const a = (i / 8) * Math.PI * 2 + random(`${kw.en}-a${i}`);
        const d = interpolate(frame, [0, 14], [40, 260], {extrapolateRight: 'clamp'});
        const o = interpolate(frame, [0, 6, 16], [0, 1, 0], {extrapolateRight: 'clamp'});
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: CARD_W / 2 + Math.cos(a) * d - 12,
              top: 160 + Math.sin(a) * d - 12,
              width: 24,
              height: 24,
              borderRadius: 6,
              background: i % 2 ? color('sunYellow') : 'white',
              transform: `rotate(${frame * 12}deg)`,
              opacity: o,
            }}
          />
        );
      })}
      <div
        style={{
          background: color('cream'),
          border: `7px solid ${color('cocoa')}`,
          borderRadius: 46,
          padding: '22px 20px 18px',
          textAlign: 'center',
          boxShadow: `0 16px 0 ${accent}`,
          transform: `scale(${p}) rotate(${tilt * p}deg)`,
        }}
      >
        {icon && (
          <div
            style={{
              width: 110,
              height: 110,
              margin: '-80px auto 4px',
              borderRadius: 60,
              background: accent,
              border: `7px solid ${color('cocoa')}`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: 'white',
              fontSize: 54,
            }}
          >
            <FontAwesomeIcon icon={icon} />
          </div>
        )}
        <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 96, lineHeight: 1.1, color: color('deepTeal')}}>
          {kw.ar}
        </div>
        <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 58, lineHeight: 1.05, color: accent, textShadow: `0 3px 0 ${color('cocoa')}33`}}>{kw.en}</div>
      </div>
    </div>
  );
};
