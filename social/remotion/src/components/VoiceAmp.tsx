import {useAudioData} from '@remotion/media-utils';
import React, {useMemo} from 'react';
import {staticFile, useCurrentFrame, useVideoConfig} from 'remotion';

type Props = {voice?: string | null; from: number; frames: number; children: (amp: number) => React.ReactNode};

// How loud the line is at the current frame (0..1), for the talking bounce.
export const VoiceAmp: React.FC<Props> = (p) => (p.voice ? <RealAmp {...p} /> : <FakeAmp {...p} />);

const RealAmp: React.FC<Props> = ({voice, from, children}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const audio = useAudioData(staticFile(voice!));
  const env = useMemo(() => {
    if (!audio) return null;
    const data = audio.channelWaveforms[0];
    const per = audio.sampleRate / fps;
    const out: number[] = [];
    for (let i = 0; i * per < data.length; i++) {
      let sum = 0;
      const a = Math.floor(i * per);
      const b = Math.min(data.length, Math.floor((i + 1) * per));
      for (let j = a; j < b; j++) sum += data[j] * data[j];
      out.push(Math.sqrt(sum / Math.max(1, b - a)));
    }
    const peak = Math.max(...out, 1e-6);
    return out.map((v) => Math.min(1, v / (peak * 0.8)));
  }, [audio, fps]);
  const i = frame - from;
  const amp = env && i >= 0 && i < env.length ? (env[i] + (env[i - 1] ?? 0) * 0.6) / 1.6 : 0;
  return <>{children(amp)}</>;
};

// No voice file yet: fake a talking rhythm so the draft still moves.
const FakeAmp: React.FC<Props> = ({from, frames, children}) => {
  const frame = useCurrentFrame();
  const i = frame - from;
  const amp = i >= 0 && i < frames ? 0.35 + 0.35 * Math.abs(Math.sin(i / 2.7)) * Math.abs(Math.sin(i / 7)) : 0;
  return <>{children(amp)}</>;
};
