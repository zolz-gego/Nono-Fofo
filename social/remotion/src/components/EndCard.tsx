import React from 'react';
import {AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {characters} from '../generated/data';
import {color, END_SETTLE, FONT_AR, FONT_EN, SAFE} from '../theme';
import {Background} from './Background';

// Last seconds: logo sting + "Follow us!" with both brothers cheering.
// Everything stays inside SAFE (clear of the TikTok/Reels buttons and caption,
// and of Instagram's 3:4 grid crop), and the brothers land and stand still
// for the last END_SETTLE seconds so the video never ends mid-jump.
export const EndCard: React.FC<{ar: string; en: string; frames: number}> = ({ar, en, frames}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const logo = spring({frame, fps, config: {damping: 8, stiffness: 150}});
  const text = spring({frame: frame - 12, fps, config: {damping: 11, stiffness: 160}});
  const bros = spring({frame: frame - 6, fps, config: {damping: 12, stiffness: 120}});
  const settle = interpolate(frame, [frames - END_SETTLE * fps - 12, frames - END_SETTLE * fps], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const bounce = (o: number) => Math.abs(Math.sin((frame + o) / 6)) * -30 * settle;
  const nono = characters.nono.cheer;
  const fofo = characters.fofo.cheer;
  const h = 520;
  const feet = SAFE.bottom - 20;

  return (
    <AbsoluteFill>
      <Background bg="deepTeal" bg2="slateTeal" seed="end" />
      <Img
        src={staticFile('app/brand/logo.png')}
        style={{position: 'absolute', left: 540 - 200, top: SAFE.top + 100, width: 400, height: 400, transform: `scale(${logo}) rotate(${interpolate(logo, [0, 1], [-25, 0])}deg)`}}
      />
      <div style={{position: 'absolute', top: SAFE.top + 520, left: SAFE.left, width: SAFE.right - SAFE.left, textAlign: 'center', transform: `scale(${text})`}}>
        <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 118, color: color('sunYellow'), lineHeight: 1.1, textShadow: `0 8px 0 ${color('cocoa')}`}}>
          {ar}
        </div>
        <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 74, color: 'white', lineHeight: 1.1}}>{en}</div>
      </div>
      <Img
        src={staticFile(nono.file!)}
        style={{position: 'absolute', left: SAFE.left + 20, top: feet - h + bounce(0) + (1 - bros) * 900, height: h, width: (nono.width / nono.height) * h}}
      />
      <Img
        src={staticFile(fofo.file!)}
        style={{position: 'absolute', right: 1080 - SAFE.right + 20, top: feet - h * 0.9 + bounce(3) + (1 - bros) * 900, height: h * 0.9, width: (fofo.width / fofo.height) * h * 0.9}}
      />
    </AbsoluteFill>
  );
};
