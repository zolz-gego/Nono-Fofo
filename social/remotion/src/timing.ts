import {getAudioDurationInSeconds} from '@remotion/media-utils';
import {staticFile} from 'remotion';
import {END_CARD, FPS, LEAD, MIN_SCENE, TAIL} from './theme';
import type {Timing, VideoSpec} from './types';

// Scene lengths follow the real voice files (or the estimate until they exist).
export async function computeTiming(spec: VideoSpec): Promise<Timing> {
  const f = (s: number) => Math.round(s * FPS);
  let from = 0;
  const scenes: Timing['scenes'] = [];
  for (const scene of spec.scenes) {
    const line = scene.line;
    const voiceSec = line ? (line.voice ? await getAudioDurationInSeconds(staticFile(line.voice)) : line.estimate) : 0;
    const keywordEnd = Math.max(0, ...(scene.keywords ?? []).map((k) => k.at + 0.9));
    const sec = Math.max(MIN_SCENE, LEAD + Math.max(voiceSec, keywordEnd) + TAIL + (scene.hold ?? 0));
    const duration = f(sec);
    scenes.push({from, duration, voiceFrom: f(LEAD), voiceFrames: f(voiceSec)});
    from += duration;
  }
  const endFrom = from;
  return {fps: FPS, scenes, endFrom, total: endFrom + (spec.endCard ? f(END_CARD) : 0)};
}
