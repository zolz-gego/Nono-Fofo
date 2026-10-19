import React from 'react';
import {AbsoluteFill, Audio, interpolate, Sequence, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {sfx} from '../generated/data';
import {WIPE} from '../theme';
import type {SceneSpec} from '../types';
import {Background} from './Background';
import {Captions} from './Captions';
import {Character} from './Character';
import {KeywordCard} from './KeywordCard';
import {VoiceAmp} from './VoiceAmp';

export const Sfx: React.FC<{id: string; at: number; volume?: number}> = ({id, at, volume = 1}) =>
  sfx[id] ? (
    <Sequence from={at} layout="none">
      <Audio src={staticFile(sfx[id])} volume={volume} />
    </Sequence>
  ) : null;

// One scene: background, brother(s), captions, keyword pops and their sounds.
// Entrances, pose swaps, keywords and the wipe-in get their sound automatically;
// `sfx` in video.json adds more.
export const Scene: React.FC<{scene: SceneSpec; index: number; voiceFrom: number; voiceFrames: number}> = ({scene, index, voiceFrom, voiceFrames}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const sec = (s: number) => Math.round(s * fps);
  const wipe = index === 0 ? 150 : interpolate(frame, [0, WIPE], [0, 150], {extrapolateRight: 'clamp'});
  const line = scene.line;
  const chars = scene.characters ?? [];

  return (
    <AbsoluteFill style={{clipPath: `circle(${wipe}% at 50% 55%)`}}>
      <Background bg={scene.bg} bg2={scene.bg2} pattern={scene.pattern} seed={scene.id} />
      <VoiceAmp voice={line?.voice} from={voiceFrom} frames={voiceFrames}>
        {(amp) => chars.map((c, i) => <Character key={i} spec={c} amp={line?.speaker === c.who ? amp : 0} />)}
      </VoiceAmp>
      {(scene.keywords ?? []).map((kw, i) => (
        <KeywordCard key={i} kw={kw} index={i} count={scene.keywords!.length} startFrame={voiceFrom + sec(kw.at)} />
      ))}
      {line && <Captions line={line} voiceFrom={voiceFrom} voiceFrames={voiceFrames} />}

      {line?.voice && (
        <Sequence from={voiceFrom} layout="none">
          <Audio src={staticFile(line.voice)} />
        </Sequence>
      )}
      {index > 0 && <Sfx id="mg_scene_swipe" at={0} volume={0.8} />}
      {chars.map((c, i) => (c.enter ?? 'left') !== 'none' && <Sfx key={`e${i}`} id={c.enter === 'pop' ? 'mg_boing' : 'mg_whoosh_in'} at={1} volume={0.7} />)}
      {chars.flatMap((c, i) => (c.swaps ?? []).map((s, j) => <Sfx key={`p${i}-${j}`} id="mg_pose_swap" at={sec(s.at)} volume={0.8} />))}
      {(scene.keywords ?? []).map((kw, i) => (
        <Sfx key={`k${i}`} id={i % 2 ? 'mg_keyword_pop_2' : 'mg_keyword_pop'} at={voiceFrom + sec(kw.at)} volume={0.75} />
      ))}
      {(scene.sfx ?? []).map((s, i) => (
        <Sfx key={`x${i}`} id={s.id} at={sec(s.at)} volume={s.volume} />
      ))}
    </AbsoluteFill>
  );
};
