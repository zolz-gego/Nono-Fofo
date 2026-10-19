// "Logo Blocks" intro: 25.5 s motion-graphics sting built from the app logo.
// Rendered twice (16:9 and 9:16); everything scales with the frame size.
// Timeline: ./cues.json. Score + block layout: social/tools/synth_intro.py.
import React from 'react';
import {AbsoluteFill, Audio, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {color, FONT_COPTIC} from '../theme';
import {COPTIC, cues, kick, prog, rnd} from './anim';
import {BlocksAct} from './BlocksAct';
import {LogoAct} from './LogoAct';
import {MacroAct} from './MacroAct';

const Backdrop: React.FC<{t: number}> = ({t}) => {
  const {width: W, height: H} = useVideoConfig();
  const m = Math.min(W, H);
  const teal = prog(t, 5.9, 6.4);
  const bright = prog(t, cues.drop - 0.05, cues.drop + 0.4);
  const rays = 0.1 * bright + 0.12 * prog(t, cues.final, cues.final + 0.3);
  const cx = W / 2;
  const cy = H / 2;
  return (
    <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 50%, #0b3540 0%, #020c0f 75%)'}}>
      <AbsoluteFill style={{background: `radial-gradient(circle at 50% 50%, ${color('deepTeal')} 0%, #04202a 80%)`, opacity: teal}} />
      <AbsoluteFill style={{background: `radial-gradient(circle at 50% 50%, #1d7486 0%, ${color('deepTeal')} 55%, #052630 100%)`, opacity: bright}} />
      {rays > 0 && (
        <svg width={W} height={H} style={{position: 'absolute', opacity: rays}}>
          <g transform={`rotate(${t * 6} ${cx} ${cy})`}>
            {Array.from({length: 20}, (_, i) => {
              const a0 = (i / 20) * Math.PI * 2;
              const a1 = a0 + Math.PI / 20;
              const r = Math.max(W, H) * 1.2;
              return <path key={i} d={`M${cx} ${cy} L${cx + r * Math.cos(a0)} ${cy + r * Math.sin(a0)} L${cx + r * Math.cos(a1)} ${cy + r * Math.sin(a1)} Z`} fill={color('mistBlue')} />;
            })}
          </g>
        </svg>
      )}
      {Array.from({length: 16}, (_, i) => {
        const size = m * (0.06 + rnd(i + 11) * 0.08);
        const x = rnd(i + 21) * W;
        const y = ((rnd(i + 31) * (H + size * 2) - t * m * (0.02 + rnd(i + 41) * 0.03)) % (H + size * 2) + (H + size * 2)) % (H + size * 2) - size;
        return (
          <div
            key={i}
            style={{
              position: 'absolute',
              left: x,
              top: y,
              fontFamily: FONT_COPTIC,
              fontSize: size,
              color: 'white',
              opacity: 0.05 + 0.05 * teal,
              transform: `rotate(${(rnd(i + 51) - 0.5) * 50 + Math.sin(t * 0.7 + i) * 8}deg)`,
            }}
          >
            {COPTIC[i % COPTIC.length]}
          </div>
        );
      })}
      {Array.from({length: 34}, (_, i) => {
        const x = (rnd(i + 61) * W + t * m * 0.012 * (rnd(i + 71) - 0.3)) % W;
        const y = (((rnd(i + 81) * H - t * m * (0.01 + rnd(i + 91) * 0.02)) % H) + H) % H;
        const s = m * (0.002 + rnd(i + 101) * 0.004);
        return (
          <div
            key={i}
            style={{position: 'absolute', left: x, top: y, width: s, height: s, borderRadius: s, background: '#FFE9A8', boxShadow: `0 0 ${s * 3}px #FFE9A8`, opacity: 0.25 + 0.35 * Math.abs(Math.sin(t * 1.3 + i))}}
          />
        );
      })}
    </AbsoluteFill>
  );
};

const Shockwave: React.FC<{t: number; t0: number; tint: string}> = ({t, t0, tint}) => {
  const {width: W, height: H} = useVideoConfig();
  const p = prog(t, t0, t0 + 0.7);
  if (p <= 0 || p >= 1) return null;
  const r = Math.min(W, H) * 0.1 + Math.max(W, H) * 0.75 * (1 - (1 - p) ** 3);
  return (
    <div
      style={{
        position: 'absolute',
        left: W / 2 - r,
        top: H / 2 - r,
        width: r * 2,
        height: r * 2,
        borderRadius: '50%',
        border: `${Math.max(1, 26 * (1 - p))}px solid ${tint}`,
        opacity: 1 - p,
      }}
    />
  );
};

export const LogoIntro: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps, width: W, height: H} = useVideoConfig();
  const t = frame / fps;
  const m = Math.min(W, H);

  const cuts = cues.macros.slice(1).map((x) => 0.3 * kick(t, x.start, 0.25));
  const flash = Math.max(
    ...cuts,
    0.25 * kick(t, cues.pullback[0], 0.2),
    0.85 * kick(t, cues.impact, 0.4),
    0.9 * kick(t, cues.drop, 0.45),
    0.7 * kick(t, cues.final, 0.5),
    0.25 * kick(t, cues.ring[1], 0.3),
  );
  const roll = prog(t, cues.roll[0], cues.roll[1]);
  const shake =
    m * (0.014 * kick(t, cues.impact, 0.45) + 0.018 * kick(t, cues.drop, 0.5) + 0.014 * kick(t, cues.final, 0.55) + 0.004 * roll * roll + 0.004 * kick(t, cues.flatten[1], 0.2));
  const dx = shake * Math.sin(t * 97);
  const dy = shake * Math.cos(t * 83);

  return (
    <AbsoluteFill style={{backgroundColor: '#020c0f', overflow: 'hidden'}}>
      <Backdrop t={t} />
      <AbsoluteFill style={{transform: `translate(${dx}px, ${dy}px)`}}>
        {t < cues.impact && <MacroAct t={t} />}
        {t >= cues.board[0] && t < cues.drop && <BlocksAct t={t} />}
        {t >= cues.drop && <LogoAct t={t} />}
      </AbsoluteFill>
      <Shockwave t={t} t0={cues.impact} tint="white" />
      <Shockwave t={t} t0={cues.drop} tint={color('sunYellow')} />
      <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 50%, transparent 55%, rgba(0,0,0,0.5) 100%)', pointerEvents: 'none'}} />
      <AbsoluteFill style={{background: '#FFFBF4', opacity: flash}} />
      <AbsoluteFill style={{background: 'black', opacity: 1 - prog(t, 0, 0.35)}} />
      <Audio src={staticFile('social/music/intro_logo_blocks.wav')} />
    </AbsoluteFill>
  );
};

export const INTRO_FRAMES = Math.round(cues.duration * cues.fps);
