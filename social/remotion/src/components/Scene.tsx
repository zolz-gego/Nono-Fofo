import React from 'react';
import {AbsoluteFill, Audio, interpolate, Sequence, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {sfx} from '../generated/data';
import {WIPE} from '../theme';
import type {SceneSpec} from '../types';
import {Background} from './Background';
import {Captions} from './Captions';
import {Character} from './Character';
import {KeywordCard} from './KeywordCard';
import {Props, shakeOffset} from './Props';
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
// Camera state at a frame: eased between keyframes (scene seconds).
export function cameraAt(cam: SceneSpec['camera'], sec: number) {
  const c = {x: 0, y: 0, zoom: 1, rot: 0};
  for (const k of cam ?? []) {
    if (sec < k.at) break;
    const d = k.dur ?? 0.6;
    const p = d <= 0 ? 1 : Math.min(1, (sec - k.at) / d);
    const e = p < 0.5 ? 2 * p * p : 1 - Math.pow(-2 * p + 2, 2) / 2;
    c.x += ((k.x ?? c.x) - c.x) * e;
    c.y += ((k.y ?? c.y) - c.y) * e;
    c.zoom += ((k.zoom ?? c.zoom) - c.zoom) * e;
    c.rot += ((k.rot ?? c.rot) - c.rot) * e;
  }
  return c;
}

export const Scene: React.FC<{scene: SceneSpec; index: number; voiceFrom: number; voiceFrames: number; captionSize?: 'normal' | 'large'}> = ({scene, index, voiceFrom, voiceFrames, captionSize}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const sec = (s: number) => Math.round(s * fps);
  const wipe = index === 0 ? 150 : interpolate(frame, [0, WIPE], [0, 150], {extrapolateRight: 'clamp'});
  const whip = scene.transition === 'whip' && index > 0 ? interpolate(frame, [0, WIPE + 2], [1, 0], {extrapolateRight: 'clamp'}) : 0;
  const cam = cameraAt(scene.camera, frame / fps);
  const line = scene.line;
  const chars = scene.characters ?? [];

  const world = `scale(${cam.zoom}) rotate(${cam.rot}deg) translate(${-cam.x}px, ${-cam.y}px)`;
  const [sx, sy] = shakeOffset(scene.props, (frame - voiceFrom) / fps);

  return (
    <AbsoluteFill
      style={
        scene.transition === 'whip' && index > 0
          ? {transform: `translateX(${whip * 1080}px)`, filter: whip > 0.02 ? `blur(${whip * 18}px)` : undefined}
          : scene.transition === 'cut'
            ? {}
            : {clipPath: `circle(${wipe}% at 50% 55%)`}
      }
    >
      <AbsoluteFill style={{transform: `translate(${sx}px, ${sy}px) scale(${sx || sy ? 1.04 : 1})`}}>
        {/* an illustrated backdrop is part of the world (characters stand on its floor), so it moves with the
            camera exactly; patterns only follow with parallax */}
        <AbsoluteFill style={{transform: scene.backdrop ? world : `scale(${1 + (cam.zoom - 1) * 0.5}) rotate(${cam.rot * 0.5}deg)`}}>
          <Background
            bg={scene.bg}
            bg2={scene.bg2}
            pattern={scene.pattern}
            seed={scene.id}
            icons={scene.icons}
            camX={scene.backdrop ? 0 : cam.x}
            from={scene.patternAt !== undefined ? voiceFrom + sec(scene.patternAt) : 0}
            before={scene.before}
            backdrop={scene.backdrop}
          />
        </AbsoluteFill>
        <AbsoluteFill style={{transform: world}}>
          <Props props={scene.props} voiceFrom={voiceFrom} layer="back" />
          <VoiceAmp voice={line?.voice} from={voiceFrom} frames={voiceFrames}>
            {(amp) => chars.map((c, i) => <Character key={i} spec={c} amp={line?.speaker === c.who ? amp : 0} />)}
          </VoiceAmp>
          <Props props={scene.props} voiceFrom={voiceFrom} layer="front" />
        </AbsoluteFill>
      </AbsoluteFill>
      {/* screen props stay put while the camera moves */}
      <Props props={scene.props} voiceFrom={voiceFrom} layer="screen" />
      {(scene.keywords ?? []).map((kw, i) => (
        <KeywordCard key={i} kw={kw} index={i} count={scene.keywords!.length} startFrame={voiceFrom + sec(kw.at)} />
      ))}
      {line && scene.captions !== false && <Captions line={line} voiceFrom={voiceFrom} voiceFrames={voiceFrames} size={captionSize} />}

      {line?.voice && (
        <Sequence from={voiceFrom} layout="none">
          <Audio src={staticFile(line.voice)} />
        </Sequence>
      )}
      {index > 0 && scene.transition !== 'cut' && <Sfx id={scene.transition === 'whip' ? 'mg_whoosh_out' : 'mg_scene_swipe'} at={0} volume={0.8} />}
      {chars.map((c, i) => (c.enter ?? 'left') !== 'none' && <Sfx key={`e${i}`} id={c.enter === 'pop' ? 'mg_boing' : 'mg_whoosh_in'} at={1 + sec(c.delay ?? 0)} volume={0.7} />)}
      {chars.flatMap((c, i) => (c.swaps ?? []).map((s, j) => !s.fade && <Sfx key={`p${i}-${j}`} id="mg_pose_swap" at={sec(s.at)} volume={0.8} />))}
      {(scene.keywords ?? []).map((kw, i) => (
        <Sfx key={`k${i}`} id={i % 2 ? 'mg_keyword_pop_2' : 'mg_keyword_pop'} at={voiceFrom + sec(kw.at)} volume={0.75} />
      ))}
      {(scene.sfx ?? []).map((s, i) => (
        <Sfx key={`x${i}`} id={s.id} at={sec(s.at)} volume={s.volume} />
      ))}
    </AbsoluteFill>
  );
};
