import {getAudioDurationInSeconds} from '@remotion/media-utils';
import {staticFile} from 'remotion';
import {INTROS} from './generated/local';
import {END_CARD, END_VOICE_AT, FPS, LEAD, MIN_SCENE, TAIL} from './theme';
import type {Timing, VideoSpec} from './types';

// Scene lengths follow the real voice files (or the estimate until they exist).
export async function computeTiming(spec: VideoSpec): Promise<Timing> {
  const f = (s: number) => Math.round(s * FPS);
  const lead = spec.pace?.lead ?? LEAD;
  const tail = spec.pace?.tail ?? TAIL;
  let from = 0;
  const scenes: Timing['scenes'] = [];
  for (const scene of spec.scenes) {
    const line = scene.line;
    const voiceSec = line ? (line.voice ? await getAudioDurationInSeconds(staticFile(line.voice)) : line.estimate) : 0;
    const keywordEnd = Math.max(0, ...(scene.keywords ?? []).map((k) => k.at + 0.9));
    const sec = Math.max(MIN_SCENE, lead + Math.max(voiceSec, keywordEnd) + tail + (scene.hold ?? 0));
    const duration = f(sec);
    scenes.push({from, duration, voiceFrom: f(lead), voiceFrames: f(voiceSec)});
    from += duration;
  }
  const endFrom = from;
  const endVoice = spec.endCard?.voice ? await getAudioDurationInSeconds(staticFile(spec.endCard.voice)) : 0;
  const endSec = spec.endCard?.duration ?? Math.max(END_CARD, END_VOICE_AT + endVoice + 0.7);
  // scene and end card frames are counted from the end of the intro
  const intro = spec.intro ? (INTROS[spec.intro]?.frames ?? 0) : 0;
  return {fps: FPS, intro, scenes, endFrom, total: intro + endFrom + (spec.endCard ? f(endSec) : 0)};
}
