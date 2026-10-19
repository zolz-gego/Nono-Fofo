// Grandpa's pop-up book in CSS 3D. The world plane is the desk; the camera
// looks down at it (rotateX tilt) and lowers to eye level for the finale.
// Spine at x = 0; units: u = pageW / 100 (spreads are 200u x 130u).
import React from 'react';
import {Img, staticFile, useVideoConfig} from 'remotion';
import {characters} from '../generated/data';
import {color, FONT_COPTIC} from '../theme';
import {clamp, COPTIC, cues, ease, lerp, prog} from './anim';
import {CoverArt, PIECE_BOX, PieceArt, SpreadArt} from './PaperArt';

type Piece = (typeof cues.spreads)[number]['pieces'][number];

const PAPER_EDGE = 'drop-shadow(1.6px 0 0 #fffaf0) drop-shadow(-1.6px 0 0 #fffaf0) drop-shadow(0 1.6px 0 #fffaf0) drop-shadow(0 -1.6px 0 #fffaf0)';
// the logo card floats up out of the book after it unfolds; the ring circles its centre
const CARD_FLOAT = 22;
const CARD_CENTER = CARD_FLOAT + 46;
// pop-ups stand taller than their page footprint, like a real pop-up book
const POP_SCALE = 1.45;
const LETTERS = COPTIC.concat(['w', 'S', 'F', 'h', 'j', 'G', 'T']).slice(0, 28);

export const bookSize = (W: number, H: number) => {
  const pageW = Math.min(W, H) * 0.44;
  return {pageW, u: pageW / 100, pageH: pageW * 1.3};
};

// Pop up with a little overshoot (paper springing open).
const popUp = (t: number, at: number) => {
  const x = t - at;
  if (x <= 0) return 0;
  return 1 - Math.exp(-6.5 * x) * Math.cos(2 * Math.PI * 1.5 * x);
};

const turnState = (t: number) => {
  const done = cues.turns.filter(([, b]) => t >= b).length;
  const active = cues.turns.findIndex(([a, b]) => t >= a && t < b);
  return {done, active, p: active >= 0 ? prog(t, cues.turns[active][0], cues.turns[active][1]) : 0};
};

export const camera = (t: number, W: number, H: number) => {
  const {pageW, u} = bookSize(W, H);
  const [c0, c1] = cues.cover;
  const [e0, e1] = cues.eyeLevel;
  const open = ease.inOutCubic(prog(t, c0, c1));
  const eye = ease.inOutCubic(prog(t, e0, e1));
  let tilt = lerp(lerp(52, 44, prog(t, 0, c1)), 86, eye);
  let zoom = lerp(0.92, 1.0, ease.outCubic(prog(t, 0, c1))) + 0.05 * prog(t, c1, e0);
  zoom = lerp(zoom, 1.55, eye);
  const baseTy = H * (H > W ? 0.13 : 0.1);
  const cardLift = CARD_CENTER * u * Math.sin((tilt * Math.PI) / 180) * zoom;
  const ty = lerp(baseTy, cardLift, eye);
  const tx = lerp(-pageW / 2, 0, open) * zoom;
  tilt = Math.min(tilt, 86);
  return {tilt, zoom, tx, ty};
};

const PieceView: React.FC<{p: Piece; t: number; up: number; u: number; seed: number}> = ({p, t, up, u, seed}) => {
  let x = p.x;
  if ('sail' in p && p.sail) x = lerp(p.x, p.sail[2], ease.inOutQuad(prog(t, p.sail[0], p.sail[1])));
  const isKid = p.kind === 'nono' || p.kind === 'fofo';
  const pose = isKid ? characters[p.kind].wave : null;
  const box = PIECE_BOX[p.kind];
  const h = p.h * u * POP_SCALE;
  const w = pose ? (pose.width / pose.height) * h : (box[2] / box[3]) * h;
  const px = x * u;
  const py = p.y * u;
  const lean = -68 * up;
  const wobble = isKid && up > 0.9 ? Math.sin((t - p.at) * 7) * 5 * Math.exp(-(t - p.at - 0.5) * 0.4) : 0;
  const bob = p.kind === 'felucca' ? Math.sin(t * 3) * 2 : 0;
  const rise = p.kind === 'sun' ? -h * 0.55 * ease.outCubic(prog(t, p.at + 0.2, p.at + 1.2)) : 0;
  const art = pose ? (
    <Img src={staticFile(pose.file)} style={{width: w, height: h, display: 'block'}} />
  ) : (
    <PieceArt kind={p.kind} t={t} seed={seed} />
  );
  return (
    <>
      {/* cast shadow lying on the page, away from the lamp */}
      <div
        style={{
          position: 'absolute',
          left: px - w / 2,
          top: py - h,
          width: w,
          height: h,
          transformOrigin: '50% 100%',
          transform: `translateZ(0.6px) skewX(-24deg) scaleY(${0.5 * up})`,
          filter: 'brightness(0) blur(5px)',
          opacity: 0.28 * clamp(up),
        }}
      >
        {art}
      </div>
      <div
        style={{
          position: 'absolute',
          left: px - w / 2,
          top: py - h,
          width: w,
          height: h,
          transformOrigin: '50% 100%',
          transform: `translateZ(1px) rotateX(${lean}deg) rotateZ(${wobble}deg) translateY(${rise - bob}px)`,
          filter: PAPER_EDGE,
        }}
      >
        {art}
      </div>
    </>
  );
};

const Page: React.FC<{id: string; side: 0 | 1; W: number; H: number; uid: string; inked?: number}> = ({id, side, W, H, uid, inked}) => {
  const {pageW, pageH} = bookSize(W, H);
  return (
    <div style={{width: pageW, height: pageH, overflow: 'hidden', position: 'relative'}}>
      <div style={{position: 'absolute', left: -side * pageW, top: 0, width: pageW * 2, height: pageH}}>
        <SpreadArt id={id} uid={uid} inked={inked} />
      </div>
    </div>
  );
};

export const Book: React.FC<{t: number}> = ({t}) => {
  const {width: W, height: H} = useVideoConfig();
  const {pageW, pageH, u} = bookSize(W, H);
  const cam = camera(t, W, H);
  const [c0, c1] = cues.cover;
  const ids = cues.spreads.map((s) => s.id);
  const ts = turnState(t);
  const shown = ts.done; // spread on the pages (left page is this one unless a turn is landing)
  const opening = prog(t, c0, c1);
  const coverOpen = t >= c1;

  const inked = 1 - prog(t, cues.lettersLift[0], cues.lettersLift[0] + 0.5);
  const leftId = ids[Math.min(shown, ids.length - 1)];
  const rightId = ids[Math.min(ts.active >= 0 ? ts.active + 1 : shown, ids.length - 1)];
  const board = (extra: React.CSSProperties) => ({
    position: 'absolute' as const,
    background: 'linear-gradient(135deg, #8E3B26, #4A1A10)',
    borderRadius: 6,
    boxShadow: '0 30px 80px rgba(0,0,0,0.6)',
    ...extra,
  });
  const pageStyle = (x: number): React.CSSProperties => ({
    position: 'absolute',
    left: x,
    top: -pageH / 2,
    width: pageW,
    height: pageH,
    transform: 'translateZ(2px)',
    boxShadow: '0 3px 0 #E4D3AE, 0 6px 0 #D2BD92, 0 8px 0 #BFA77A',
  });

  // which spread's pieces are standing, and how far up
  const pieces: {p: Piece; up: number; seed: number}[] = [];
  cues.spreads.forEach((s, si) => {
    const turnOut = cues.turns[si];
    const fold = turnOut ? 1 - ease.inCubic(prog(t, turnOut[0], turnOut[0] + 0.35)) : 1;
    const live = si === shown || si === ts.active;
    if (!live) return;
    s.pieces.forEach((p, k) => {
      const up = popUp(t, p.at) * fold;
      if (up > 0.001) pieces.push({p, up, seed: si * 10 + k});
    });
  });
  // back to front so nearer pieces cover farther ones
  pieces.sort((a, b) => a.p.y - b.p.y);

  // the turning sheet (cover first, then pages)
  let sheet: React.ReactNode = null;
  const sheetT = !coverOpen ? ease.inOutCubic(opening) : ts.active >= 0 ? ease.inOutCubic(ts.p) : -1;
  if (sheetT >= 0) {
    const front = !coverOpen ? <CoverArt uid="cover-f" /> : <Page id={ids[ts.active]} side={1} W={W} H={H} uid={`sf${ts.active}`} />;
    const back = !coverOpen ? (
      <Page id={ids[0]} side={0} W={W} H={H} uid="cover-b" />
    ) : (
      <Page id={ids[ts.active + 1]} side={0} W={W} H={H} uid={`sb${ts.active}`} />
    );
    const shade = Math.sin(Math.PI * sheetT) * 0.35;
    sheet = (
      <div
        style={{
          position: 'absolute',
          left: 0,
          top: -pageH / 2,
          width: pageW,
          height: pageH,
          transformOrigin: '0 50%',
          transformStyle: 'preserve-3d',
          transform: `translateZ(${4 + Math.sin(Math.PI * sheetT) * 6}px) rotateY(${-180 * sheetT}deg)`,
        }}
      >
        <div style={{position: 'absolute', inset: 0, backfaceVisibility: 'hidden'}}>
          {front}
          <div style={{position: 'absolute', inset: 0, background: `linear-gradient(90deg, rgba(0,0,0,${shade}), transparent 60%)`}} />
        </div>
        <div style={{position: 'absolute', inset: 0, backfaceVisibility: 'hidden', transform: 'rotateY(180deg)'}}>
          {back}
          <div style={{position: 'absolute', inset: 0, background: `linear-gradient(270deg, rgba(0,0,0,${shade}), transparent 60%)`}} />
        </div>
      </div>
    );
  }

  // the alphabet lifts off the last page and circles the logo card
  const lastTurn = cues.turns[cues.turns.length - 1];
  const [l0, l1] = cues.lettersLift;
  const tiltR = (cam.tilt * Math.PI) / 180;
  const letters =
    t >= lastTurn[0] && t < cues.drop + 0.05
      ? LETTERS.map((ch, i) => {
          const page = i < 14 ? 0 : 1;
          if (page === 0 && t < lastTurn[1]) return null;
          const k = i % 14;
          const sx = (18 + page * 100 + (k % 4) * 21 - 100) * u;
          const sy = (26 + Math.floor(k / 4) * 26 - 70) * u;
          const d0 = l0 + (i / 28) * 0.6;
          if (t < l0) return null;
          const lift = ease.outCubic(prog(t, d0, d0 + 0.6));
          const fly = ease.inOutCubic(prog(t, l0 + 0.9, l1));
          const a = (i / 28) * Math.PI * 2 + (t - l0) * 1.4;
          const R = 57 * u;
          const cz = CARD_CENTER * u;
          const rx = R * Math.cos(a);
          const ry = R * Math.sin(a);
          const ringX = rx;
          const ringY = ry * Math.cos(tiltR);
          const ringZ = cz - ry * Math.sin(tiltR);
          const x = lerp(sx, ringX, fly);
          const y = lerp(sy, ringY, fly);
          const z = lerp(1 + lift * 26 * u, ringZ, fly);
          const gold = clamp(lift * 1.5);
          return (
            <div
              key={i}
              style={{
                position: 'absolute',
                left: x - 10 * u,
                top: y - 10 * u,
                width: 20 * u,
                height: 20 * u,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontFamily: FONT_COPTIC,
                fontSize: 15 * u * (1 + gold * 0.25),
                color: gold > 0.5 ? color('sunYellow') : color('cocoa'),
                textShadow: gold > 0.1 ? `0 0 ${8 * gold}px ${color('sunYellow')}, 0 0 ${20 * gold}px rgba(255,200,69,${0.6 * gold})` : undefined,
                transform: `translateZ(${z}px) rotateX(${-cam.tilt * lift}deg)`,
              }}
            >
              {ch}
            </div>
          );
        })
      : null;

  // the logo card folds up at the spine
  const [k0] = cues.card;
  const cardUp = popUp(t, k0);
  const cardW = 92 * u;

  return (
    <div style={{position: 'absolute', inset: 0, perspective: Math.max(W, H) * 1.1, overflow: 'hidden'}}>
      <div
        style={{
          position: 'absolute',
          left: W / 2 + cam.tx,
          top: H / 2 + cam.ty,
          transformStyle: 'preserve-3d',
          transform: `rotateX(${cam.tilt}deg) scale(${cam.zoom})`,
        }}
      >
        {/* desk */}
        <div
          style={{
            position: 'absolute',
            left: -9000,
            top: -9000,
            width: 18000,
            height: 18000,
            transform: 'translateZ(-6px)',
            background: `repeating-linear-gradient(92deg, rgba(0,0,0,0.07) 0 3px, transparent 3px 46px, rgba(255,255,255,0.03) 46px 50px, transparent 50px 120px), linear-gradient(180deg, ${color('studyShelf')}, ${color('monasteryWoodDark')})`,
          }}
        />
        {/* boards: back cover always, the opened front cover on the left */}
        <div style={board({left: -6, top: -pageH / 2 - 8, width: pageW + 14, height: pageH + 16})} />
        {coverOpen && <div style={board({left: -pageW - 8, top: -pageH / 2 - 8, width: pageW + 14, height: pageH + 16})} />}
        {/* pages */}
        {coverOpen && (
          <div style={pageStyle(-pageW)}>
            <Page id={leftId} side={0} W={W} H={H} uid={`l-${leftId}`} inked={inked} />
          </div>
        )}
        <div style={pageStyle(0)}>
          <Page id={rightId} side={1} W={W} H={H} uid={`r-${rightId}`} inked={inked} />
        </div>
        {/* spine shadow */}
        {coverOpen && <div style={{position: 'absolute', left: -12, top: -pageH / 2, width: 24, height: pageH, transform: 'translateZ(2.5px)', background: 'linear-gradient(90deg, transparent, rgba(60,30,10,0.25), transparent)'}} />}
        {sheet}
        {pieces.map(({p, up, seed}) => (
          <PieceView key={seed} p={p} t={t} up={up} u={u} seed={seed} />
        ))}
        {cardUp > 0 && (
          <div
            style={{
              position: 'absolute',
              left: -cardW / 2,
              top: -cardW,
              width: cardW,
              height: cardW,
              transformOrigin: '50% 100%',
              transform: `translateZ(${3 + CARD_FLOAT * u * ease.inOutCubic(prog(t, k0 + 0.3, cues.eyeLevel[1]))}px) rotateX(${-90 * clamp(cardUp, 0, 1.08)}deg)`,
              filter: PAPER_EDGE,
            }}
          >
            <Img src={staticFile('app/brand/logo.png')} style={{width: cardW, height: cardW, display: 'block'}} />
          </div>
        )}
        {letters}
      </div>
    </div>
  );
};
