// "Grandpa's Pop-up Book" intro (25 s, 60 fps, 9:16 and 16:9).
// A lamp clicks on over Grandpa's book; the cover opens; pages turn through
// paper pop-ups (the Nile, the pyramids, the village with Nono and Fofo); the
// alphabet lifts off the last page into a ring; the logo card folds up and the
// camera drops to eye level; on the hit the logo holds, perfectly still.
// Timeline: ./cues.json. Score: social/tools/synth_intro.py.
import React from 'react';
import {AbsoluteFill, Audio, Img, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {cues, ease, kick, lerp, prog, rnd} from './anim';
import {Book} from './Book';

// Warm lamp light: dark room, a pool of light on the book, dust in the beam.
const Lamp: React.FC<{t: number}> = ({t}) => {
  const {width: W, height: H} = useVideoConfig();
  const m = Math.min(W, H);
  const on0 = cues.lampOn;
  // click on, one flicker, then steady
  const on = t < on0 ? 0 : t < on0 + 0.08 ? 0.8 : t < on0 + 0.16 ? 0.25 : Math.min(1, 0.6 + (t - on0 - 0.16) * 3);
  const room = lerp(0.97, 0.0, on);
  return (
    <>
      <AbsoluteFill
        style={{
          background: `radial-gradient(ellipse ${m * 0.75}px ${m * 0.62}px at 50% ${H > W ? 56 : 54}%, rgba(255,214,140,${0.16 * on}) 0%, rgba(30,15,6,${0.25 + 0.2 * on}) 60%, rgba(8,4,2,0.82) 100%)`,
        }}
      />
      {Array.from({length: 26}, (_, i) => {
        const x = W * (0.25 + rnd(i + 3) * 0.5) + Math.sin(t * 0.5 + i) * m * 0.02;
        const y = (((H * (0.2 + rnd(i + 9) * 0.6) - t * m * (0.006 + rnd(i + 5) * 0.01)) % H) + H) % H;
        const s = m * (0.002 + rnd(i + 7) * 0.003);
        return (
          <div
            key={i}
            style={{position: 'absolute', left: x, top: y, width: s, height: s, borderRadius: s, background: '#FFE7B0', boxShadow: `0 0 ${s * 3}px #FFE7B0`, opacity: on * (0.25 + 0.3 * Math.abs(Math.sin(t * 0.9 + i)))}}
          />
        );
      })}
      <AbsoluteFill style={{background: '#000', opacity: room}} />
    </>
  );
};

// After the hit: the logo alone, still, over the warm study.
const Finale: React.FC<{t: number}> = ({t}) => {
  const {width: W, height: H} = useVideoConfig();
  const S = Math.min(W, H) * 0.84;
  const [s0, s1] = cues.shine;
  const shineP = prog(t, s0, s1);
  return (
    <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 50%, #5a3a22 0%, #24140a 60%, #0c0603 100%)'}}>
      <div style={{position: 'absolute', left: (W - S) / 2, top: (H - S) / 2, width: S, height: S}}>
        <div style={{position: 'absolute', inset: -S * 0.16, borderRadius: '50%', background: 'radial-gradient(circle, rgba(255,214,140,0.55) 0%, transparent 62%)'}} />
        <Img src={staticFile('app/brand/logo.png')} style={{position: 'absolute', inset: 0, width: S, height: S}} />
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
    </AbsoluteFill>
  );
};

export const LogoIntro: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  const flash = Math.max(0.9 * kick(t, cues.drop, 0.55), 0.25 * kick(t, cues.cover[1], 0.3));
  return (
    <AbsoluteFill style={{backgroundColor: '#0c0603', overflow: 'hidden'}}>
      {t < cues.drop ? (
        <>
          <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 40%, #3a2414 0%, #120a06 70%)'}} />
          <Book t={t} />
          <Lamp t={t} />
        </>
      ) : (
        <Finale t={t} />
      )}
      <AbsoluteFill style={{background: '#FFF6E0', opacity: flash}} />
      <Audio src={staticFile('social/music/intro_logo_book.wav')} />
    </AbsoluteFill>
  );
};

export const INTRO_FRAMES = Math.round(cues.duration * cues.fps);
