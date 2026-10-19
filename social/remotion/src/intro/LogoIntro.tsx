// "Golden Letter Swarm" intro (24 s, 60 fps, 16:9 and 9:16).
// Gold dust gathers into alpha + omega, shatters into a flock that morphs on
// every bar (pyramid, palm, Nile, book, the brothers, their names, a spinning
// ring), then spirals into the logo pixel by pixel and the real logo resolves.
// Timeline: ./cues.json. Score: social/tools/synth_intro.py.
import React from 'react';
import {AbsoluteFill, Audio, Img, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {color, FONT_COPTIC} from '../theme';
import {COPTIC, cues, ease, kick, lerp, prog, rnd} from './anim';
import {Swarm} from './Swarm';

const Backdrop: React.FC<{t: number}> = ({t}) => {
  const {width: W, height: H} = useVideoConfig();
  const m = Math.min(W, H);
  const warm = prog(t, 3.0, 5.0);
  const bright = prog(t, cues.drop - 0.1, cues.drop + 0.5);
  const cx = W / 2;
  const cy = H / 2;
  return (
    <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 50%, #0a2c35 0%, #01080a 78%)'}}>
      <AbsoluteFill style={{background: `radial-gradient(circle at 50% 50%, #12495a 0%, #031820 80%)`, opacity: warm * (1 - bright)}} />
      <AbsoluteFill style={{background: `radial-gradient(circle at 50% 50%, #1d7486 0%, ${color('deepTeal')} 55%, #052630 100%)`, opacity: bright}} />
      {bright > 0 && (
        <svg width={W} height={H} style={{position: 'absolute', opacity: 0.16 * bright}}>
          <g transform={`rotate(${t * 4} ${cx} ${cy})`}>
            {Array.from({length: 20}, (_, i) => {
              const a0 = (i / 20) * Math.PI * 2;
              const a1 = a0 + Math.PI / 20;
              const r = Math.max(W, H) * 1.2;
              return <path key={i} d={`M${cx} ${cy} L${cx + r * Math.cos(a0)} ${cy + r * Math.sin(a0)} L${cx + r * Math.cos(a1)} ${cy + r * Math.sin(a1)} Z`} fill={color('mistBlue')} />;
            })}
          </g>
        </svg>
      )}
      {Array.from({length: 14}, (_, i) => {
        const size = m * (0.06 + rnd(i + 11) * 0.08);
        const x = rnd(i + 21) * W;
        const span = H + size * 2;
        const y = (((rnd(i + 31) * span - t * m * (0.015 + rnd(i + 41) * 0.025)) % span) + span) % span - size;
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
              opacity: 0.025 + 0.025 * warm,
              transform: `rotate(${(rnd(i + 51) - 0.5) * 50}deg)`,
            }}
          >
            {COPTIC[i % COPTIC.length]}
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

export const LogoIntro: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps, width: W, height: H} = useVideoConfig();
  const t = frame / fps;
  const S = Math.min(W, H) * 0.86;

  const [r0, r1] = cues.resolve;
  const logoIn = ease.inOutCubic(prog(t, r0, r1));
  const [sh0, sh1] = cues.shine;
  const shineP = prog(t, sh0, sh1);
  const flash = Math.max(0.35 * kick(t, cues.shatter, 0.3), 0.8 * kick(t, cues.drop, 0.5), 0.15 * kick(t, cues.spinUp[1], 0.3));

  return (
    <AbsoluteFill style={{backgroundColor: '#01080a', overflow: 'hidden'}}>
      <Backdrop t={t} />
      {/* the real logo resolves under the landing particles */}
      {logoIn > 0 && (
        <div style={{position: 'absolute', left: (W - S) / 2, top: (H - S) / 2, width: S, height: S}}>
          <div
            style={{
              position: 'absolute',
              inset: -S * 0.14,
              borderRadius: '50%',
              background: `radial-gradient(circle, ${color('sunYellow')} 0%, transparent 62%)`,
              opacity: 0.25 * logoIn + 0.45 * kick(t, cues.drop, 1.2),
            }}
          />
          <Img src={staticFile('app/brand/logo.png')} style={{position: 'absolute', inset: 0, width: S, height: S, opacity: logoIn}} />
          {shineP > 0 && shineP < 1 && (
            <div style={{position: 'absolute', inset: 0, borderRadius: '50%', overflow: 'hidden', mixBlendMode: 'screen'}}>
              <div
                style={{
                  position: 'absolute',
                  top: -S * 0.5,
                  left: lerp(-S * 1.2, S * 1.2, ease.inOutQuad(shineP)),
                  width: S * 0.35,
                  height: S * 2,
                  transform: 'rotate(20deg)',
                  background: 'linear-gradient(90deg, transparent, rgba(255,255,255,0.55), transparent)',
                }}
              />
            </div>
          )}
        </div>
      )}
      <Swarm t={t} />
      <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 50%, transparent 55%, rgba(0,0,0,0.5) 100%)'}} />
      <AbsoluteFill style={{background: '#FFFBF4', opacity: flash}} />
      <Audio src={staticFile('social/music/intro_logo_swarm.wav')} />
    </AbsoluteFill>
  );
};

export const INTRO_FRAMES = Math.round(cues.duration * cues.fps);
