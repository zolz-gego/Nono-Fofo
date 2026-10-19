// Act 2 (6-16 s): the logo, cut into wooden alphabet blocks, drops onto a
// board row by row (each landing is a note), the camera swings to the front,
// a wave flips every block over to show the picture, the blocks press flat,
// the brothers' faces pop out, and everything shakes before the drop.
import React from 'react';
import {staticFile, useVideoConfig} from 'remotion';
import {color, FONT_COPTIC} from '../theme';
import {COPTIC, clamp, cues, ease, layout, lerp, prog, rnd, springAt} from './anim';
import {Cube, LetterFace} from './Cube';

const TINTS = ['sunYellow', 'coral', 'mistBlue', 'leafGreen', 'cream'];
export const LOGO_SRC = staticFile('app/brand/logo.png');

export const logoSize = (W: number, H: number) => Math.round(Math.min(W, H) * 0.78);

const pop = (t: number, t0: number) => springAt(t, t0, 2.4, 4.5) - springAt(t, t0 + 0.4, 2.0, 5);

export const BlocksAct: React.FC<{t: number}> = ({t}) => {
  const {width: W, height: H} = useVideoConfig();
  const LOGO = logoSize(W, H);
  const n = layout.grid;
  const T = LOGO / n;
  const [w0, w1] = cues.swing;
  const [fl0, fl1] = cues.flatten;
  const [r0, r1] = cues.roll;

  const swing = ease.inOutCubic(prog(t, w0, w1));
  const flat = ease.inOutCubic(prog(t, fl0, fl1));
  const roll = ease.inCubic(prog(t, r0, r1 - 0.05));
  const boardIn = springAt(t, cues.board[0], 1.4, 6);

  const tilt = lerp(52, 0, swing);
  const rz = lerp(-16 + Math.sin(t * 0.6) * 3, 0, swing);
  const scale = lerp(0.9, 1, swing) * (1 - 0.05 * roll);
  const ty = lerp(LOGO * 0.08, 0, swing);
  const gap = 0.1 * (1 - flat) + 0.04 * roll;
  const d = T * lerp(0.92, 0.12, flat);
  const B = LOGO * 1.16;

  return (
    <div style={{position: 'absolute', inset: 0, perspective: 2600}}>
      <div
        style={{
          position: 'absolute',
          left: W / 2,
          top: H / 2,
          transformStyle: 'preserve-3d',
          transform: `translateY(${ty}px) rotateX(${tilt}deg) rotateZ(${rz}deg) scale(${scale})`,
        }}
      >
        {/* the board */}
        <div
          style={{
            position: 'absolute',
            left: -B / 2,
            top: -B / 2,
            width: B,
            height: B,
            borderRadius: B * 0.08,
            boxShadow: `0 0 0 ${B * 0.02}px ${color('boardFrame')}, 0 40px 120px rgba(0,0,0,0.5)`,
            opacity: clamp(boardIn) * (1 - prog(t, w0 + 0.3, w1)),
            transform: `translateZ(${-2 - (1 - boardIn) * 900}px) rotateZ(${(1 - boardIn) * 40}deg)`,
            backgroundImage: `radial-gradient(circle, ${color('studyFloorLine')} 2px, transparent 3px), radial-gradient(circle at 40% 35%, ${color('sand')} 0%, ${color('studyWallShade')} 100%)`,
            backgroundSize: `${T * (1 + gap)}px ${T * (1 + gap)}px, 100% 100%`,
            backgroundPosition: 'center, center',
          }}
        />
        {/* light leaking through the cracks before the drop */}
        <div
          style={{
            position: 'absolute',
            left: -LOGO * 0.52,
            top: -LOGO * 0.52,
            width: LOGO * 1.04,
            height: LOGO * 1.04,
            borderRadius: '50%',
            background: `radial-gradient(circle, #FFF6D0 0%, ${color('sunYellow')} 45%, transparent 70%)`,
            opacity: roll,
            transform: `translateZ(-4px) scale(${1 + roll * 0.15})`,
          }}
        />
        {/* flat copy under the pressed blocks hides hairline seams; dark under the faces that pop out */}
        {t >= fl1 - 0.15 &&
          [...layout.tiles]
            .sort((a, b) => Number(!!b.group) - Number(!!a.group))
            .map(({c, r, group}) => (
              <div
                key={`u${c}-${r}`}
                style={{
                  position: 'absolute',
                  left: (c - (n - 1) / 2) * T * (1 + gap) - T / 2 - 1,
                  top: (r - (n - 1) / 2) * T * (1 + gap) - T / 2 - 1,
                  width: T + 2,
                  height: T + 2,
                  backgroundImage: `url(${LOGO_SRC})`,
                  backgroundSize: `${T * n}px ${T * n}px`,
                  backgroundPosition: `${-c * T + 1}px ${-r * T + 1}px`,
                  filter: group && Math.abs(t - (group === 'nono' ? cues.nonoPop : cues.fofoPop) - 0.35) < 0.4 ? 'brightness(0.3) blur(3px)' : undefined,
                  opacity: prog(t, fl1 - 0.15, fl1) * (1 - roll),
                  transform: 'translateZ(-1px)',
                }}
              />
            ))}
        {layout.tiles.map((tile) => {
          const {c, r, land} = tile;
          const f0 = land - cues.fall;
          if (t < f0) return null;
          const seed = c * 13 + r * 7;
          const p = prog(t, f0, land);
          const after = Math.max(0, t - land);
          let z = 900 * (1 - p * p) + T * 0.35 * Math.exp(-after * 8) * Math.abs(Math.sin(after * 18)) * (p >= 1 ? 1 : 0);
          const tumble = (1 - p) ** 2;
          const rx = (rnd(seed) - 0.5) * 50 * tumble;
          let rzT = (rnd(seed + 1) - 0.5) * 60 * tumble;
          const sq = p >= 1 ? 0.16 * Math.exp(-after * 12) * Math.cos(after * 28) : 0;

          const fl = prog(t, tile.flip, tile.flip + cues.flipDur);
          const ry = 180 + 180 * ease.inOutBack(fl);
          z += T * 0.9 * Math.sin(Math.PI * fl);

          let glow = 0;
          let s = 1;
          if (tile.group) {
            const b = Math.max(0, pop(t, tile.group === 'nono' ? cues.nonoPop : cues.fofoPop));
            z += T * 1.1 * b;
            s += 0.08 * b;
            rzT += 4 * b * Math.sin(t * 22);
            glow = clamp(b);
          }
          z += T * 0.1 * roll * Math.sin(t * 70 + c * 1.7 + r * 2.3);

          const x = (c - (n - 1) / 2) * T * (1 + gap);
          const y = (r - (n - 1) / 2) * T * (1 + gap);
          const tint = color(TINTS[(c + r * 2) % TINTS.length]);
          const ink = (c + r) % 3 === 0 ? 'white' : color('deepTeal');
          const glowColor = tile.group === 'nono' ? color('coral') : color('sunYellow');
          const w = T * 1.004;
          return (
            <React.Fragment key={`${c}-${r}`}>
              {p < 1 && swing < 1 && (
                <div
                  style={{
                    position: 'absolute',
                    left: x - T / 2,
                    top: y - T / 2,
                    width: T,
                    height: T,
                    borderRadius: T * 0.1,
                    background: 'rgba(40,25,10,0.55)',
                    filter: `blur(${lerp(30, 6, p)}px)`,
                    opacity: p * p,
                    transform: `translateZ(1px) scale(${lerp(1.6, 1, p)})`,
                  }}
                />
              )}
              <Cube
                w={w}
                d={d}
                side={`color-mix(in srgb, color-mix(in srgb, ${tint} 68%, black) ${Math.round(100 * (1 - flat))}%, transparent)`}
                transform={`translate3d(${x}px, ${y}px, ${d / 2 + z}px) rotateX(${rx}deg) rotateZ(${rzT}deg) rotateY(${ry}deg) scale3d(${(1 + sq) * s}, ${(1 + sq) * s}, ${1 - sq * 1.5})`}
                faces={{
                  front: (
                    <div
                      style={{
                        width: w,
                        height: w,
                        backgroundImage: `url(${LOGO_SRC})`,
                        backgroundSize: `${T * n}px ${T * n}px`,
                        backgroundPosition: `${-c * T}px ${-r * T}px`,
                        boxShadow: glow > 0.01 ? `inset 0 0 ${T * 0.4 * glow}px ${glowColor}` : undefined,
                      }}
                    />
                  ),
                  back: <LetterFace size={w} bg={tint} ink={ink} letter={COPTIC[(c * 3 + r * 5) % COPTIC.length]} font={FONT_COPTIC} />,
                }}
              />
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
};
