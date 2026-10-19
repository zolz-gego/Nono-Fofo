import React from 'react';
import {Img, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {characters} from '../generated/data';
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
  let swapFrame = -1;
  for (const s of spec.swaps ?? []) {
    if (frame >= s.at * fps) {
      pose = s.pose;
      swapFrame = Math.round(s.at * fps);
    }
  }
  const info = characters[spec.who][pose];
  const scale = HEIGHT / info.height;
  const w = info.width * scale;

  const enter = spec.enter ?? 'left';
  const inP = spring({frame, fps, config: {damping: 13, stiffness: 140, mass: 0.8}});
  let dx = 0;
  let dy = 0;
  let s = 1;
  if (enter === 'left') dx = interpolate(inP, [0, 1], [-1000, 0]);
  if (enter === 'right') dx = interpolate(inP, [0, 1], [1000, 0]);
  if (enter === 'bottom') dy = interpolate(inP, [0, 1], [1100, 0]);
  if (enter === 'pop') s = inP;

  // A little hop each time the pose changes.
  const hop = swapFrame >= 0 ? Math.sin(Math.min(1, (frame - swapFrame) / 9) * Math.PI) * 50 : 0;
  const swapPop = swapFrame >= 0 ? spring({frame: frame - swapFrame, fps, config: {damping: 9, stiffness: 220}}) : 1;

  const breathe = Math.sin(frame / 11) * 0.012;
  const talkY = -amp * 26;
  const sx = 1 + breathe - amp * 0.03;
  const sy = 1 - breathe + amp * 0.05;
  const tilt = Math.sin(frame / 4.5) * amp * 3.5;
  const x = X[spec.at ?? 'center'];

  return (
    <>
      <Img
        src={staticFile(info.file)}
        style={{
          position: 'absolute',
          left: x - w / 2 + dx,
          top: FEET_Y - HEIGHT + dy,
          width: w,
          height: HEIGHT,
          transformOrigin: '50% 100%',
          transform: `translateY(${talkY - hop}px) rotate(${tilt}deg) scale(${sx * s * (0.85 + 0.15 * swapPop)}, ${sy * s * (0.85 + 0.15 * swapPop)}) ${spec.flip ? 'scaleX(-1)' : ''}`,
          filter: 'drop-shadow(0 10px 0 rgba(0,0,0,0.08))',
        }}
      />
    </>
  );
};
