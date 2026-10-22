import React from 'react';
import {AbsoluteFill, Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {characters} from '../generated/data';
import {color, FONT_AR, FONT_EN} from '../theme';
import {Background} from './Background';

// Last 2-3 seconds: logo sting + "Follow us!" with both brothers cheering.
export const EndCard: React.FC<{ar: string; en: string}> = ({ar, en}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const logo = spring({frame, fps, config: {damping: 8, stiffness: 150}});
  const text = spring({frame: frame - 12, fps, config: {damping: 11, stiffness: 160}});
  const bros = spring({frame: frame - 6, fps, config: {damping: 12, stiffness: 120}});
  const bounce = (o: number) => Math.abs(Math.sin((frame + o) / 6)) * -30;
  const nono = characters.nono.cheer;
  const fofo = characters.fofo.cheer;
  const h = 560;

  return (
    <AbsoluteFill>
      <Background bg="deepTeal" bg2="slateTeal" seed="end" />
      <Img
        src={staticFile('app/brand/logo.png')}
        style={{position: 'absolute', left: 540 - 270, top: 260, width: 540, height: 540, transform: `scale(${logo}) rotate(${interpolate(logo, [0, 1], [-25, 0])}deg)`}}
      />
      <div style={{position: 'absolute', top: 830, width: '100%', textAlign: 'center', transform: `scale(${text})`}}>
        <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 130, color: color('sunYellow'), lineHeight: 1.1, textShadow: `0 8px 0 ${color('cocoa')}`}}>
          {ar}
        </div>
        <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 80, color: 'white', lineHeight: 1.1}}>{en}</div>
      </div>
      <Img
        src={staticFile(nono.file!)}
        style={{position: 'absolute', left: 30, top: 1880 - h + bounce(0) + (1 - bros) * 700, height: h, width: (nono.width / nono.height) * h}}
      />
      <Img
        src={staticFile(fofo.file!)}
        style={{position: 'absolute', right: 30, top: 1880 - h * 0.9 + bounce(3) + (1 - bros) * 700, height: h * 0.9, width: (fofo.width / fofo.height) * h * 0.9}}
      />
    </AbsoluteFill>
  );
};
