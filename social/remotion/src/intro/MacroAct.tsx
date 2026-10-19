// Act 1 (0-6 s): full-frame close-ups cut on the beat, then the camera pulls
// back to show each close-up was the face of a block floating in space, and
// the blocks shoot off into the dark.
import React from 'react';
import {useVideoConfig} from 'remotion';
import {color, FONT_COPTIC} from '../theme';
import {COPTIC, cues, ease, kick, lerp, prog, rnd} from './anim';
import {Cube, LetterFace} from './Cube';
import {MacroScene, type MacroId} from './Macro';

const SLOT: Record<MacroId, number> = {letter: -2, pyramid: -1, book: 0, palm: 1, river: 2};
const TINTS = ['sunYellow', 'coral', 'mistBlue', 'leafGreen', 'cream'];

export const MacroAct: React.FC<{t: number}> = ({t}) => {
  const {width: W, height: H} = useVideoConfig();
  const M = Math.max(W, H);
  const [p0, p1] = cues.pullback;
  const [s0, s1] = cues.scatter;

  if (t < p0) {
    const m = [...cues.macros].reverse().find((x) => t >= x.start) ?? cues.macros[0];
    return (
      <div style={{position: 'absolute', left: (W - M) / 2, top: (H - M) / 2, width: M, height: M}}>
        <MacroScene id={m.id as MacroId} lt={t - m.start} uid={`full-${m.id}`} punch={m.start > 0 ? kick(t, m.start, 0.3) : 0} />
      </div>
    );
  }

  const C = Math.min(W, H) * 0.3;
  const p = ease.outExpo(prog(t, p0, p1));
  const s = ease.inCubic(prog(t, s0, s1));
  const k = lerp((M / C) * 1.04, 1, p);

  return (
    <div style={{position: 'absolute', inset: 0, perspective: 3200}}>
      <div
        style={{
          position: 'absolute',
          left: W / 2,
          top: H / 2,
          transformStyle: 'preserve-3d',
          transform: `scale(${k}) rotateX(${lerp(0, 10, p)}deg) rotateY(${lerp(0, -16, p) + t * 3}deg)`,
        }}
      >
        {cues.macros.map((m, i) => {
          const slot = SLOT[m.id as MacroId];
          const spin = p * (slot * 14 + Math.sin(t * 2.2 + slot) * 10);
          const x = slot * C * 1.5 * (1 + s * 1.6);
          const y = Math.sin(t * 2 + slot) * C * 0.08 * p + (rnd(i + 4) - 0.5) * C * 3 * s;
          const z = -Math.abs(slot) * C * 0.45 * p - 4200 * s;
          const tint = color(TINTS[i]);
          const letter = (n: number) => <LetterFace size={C} bg={tint} ink={color('deepTeal')} letter={COPTIC[(i * 4 + n) % COPTIC.length]} font={FONT_COPTIC} />;
          return (
            <div key={m.id} style={{position: 'absolute', transformStyle: 'preserve-3d', transform: `translate3d(${x}px, ${y}px, ${z}px)`}}>
              <Cube
                w={C}
                d={C}
                side={`color-mix(in srgb, ${tint} 72%, black)`}
                transform={`rotateY(${spin + s * 220 * (slot >= 0 ? 1 : -1)}deg) rotateX(${spin * 0.4 + s * 160}deg)`}
                opacity={1 - prog(t, s1 - 0.12, s1)}
                faces={{
                  front: <MacroScene id={m.id as MacroId} lt={t - m.start} uid={`cube-${m.id}`} />,
                  back: letter(0),
                  left: letter(1),
                  right: letter(2),
                  top: letter(3),
                  bottom: letter(5),
                }}
              />
            </div>
          );
        })}
      </div>
    </div>
  );
};
