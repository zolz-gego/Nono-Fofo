import React from 'react';
import {AbsoluteFill, Audio, Img, interpolate, Sequence, staticFile, useCurrentFrame} from 'remotion';
import {EndCard} from './components/EndCard';
import {Scene, Sfx} from './components/Scene';
import {music} from './generated/data';
import {WIPE} from './theme';
import type {Timing, VideoSpec} from './types';

export type VideoProps = {spec: VideoSpec; timing: Timing | null};

export const Video: React.FC<VideoProps> = ({spec, timing}) => {
  const frame = useCurrentFrame();
  if (!timing) return null;

  // Background music sits low and dips further while someone talks.
  const talking = (f: number) =>
    timing.scenes.some((s) => f >= s.from + s.voiceFrom - 4 && f < s.from + s.voiceFrom + s.voiceFrames + 4);
  const baseVol = spec.music?.volume ?? 0.16;
  const musicVol = (f: number) =>
    (talking(f) ? baseVol * 0.55 : baseVol) *
    interpolate(f, [0, 8, timing.total - 20, timing.total], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

  return (
    <AbsoluteFill style={{backgroundColor: 'black'}}>
      {spec.scenes.map((scene, i) => {
        const t = timing.scenes[i];
        const last = i === spec.scenes.length - 1 && !spec.endCard;
        return (
          <Sequence key={scene.id} from={t.from} durationInFrames={t.duration + (last ? 0 : WIPE)} name={scene.id}>
            <Scene scene={scene} index={i} voiceFrom={t.voiceFrom} voiceFrames={t.voiceFrames} />
          </Sequence>
        );
      })}
      {spec.endCard && (
        <Sequence from={timing.endFrom} name="end card">
          <EndCard ar={spec.endCard.ar} en={spec.endCard.en} />
          <Sfx id="mg_logo_sting" at={0} volume={0.9} />
        </Sequence>
      )}
      {/* small logo watermark, hidden on the end card */}
      {frame < timing.endFrom && (
        <Img src={staticFile('app/brand/logo.png')} style={{position: 'absolute', left: 46, top: 112, width: 108, height: 108, opacity: 0.9}} />
      )}
      {spec.music && music[spec.music.track] && <Audio src={staticFile(music[spec.music.track])} volume={musicVol} loop />}
    </AbsoluteFill>
  );
};
