import {faCheck, faHandPointer, faStar, faXmark} from '@fortawesome/free-solid-svg-icons';
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome';
import React from 'react';
import {AbsoluteFill, Audio, Img, interpolate, random, Sequence, spring, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Background} from '../components/Background';
import {Captions} from '../components/Captions';
import {EndCard} from '../components/EndCard';
import {Sfx} from '../components/Scene';
import {characters, music} from '../generated/data';
import {INTROS} from '../generated/local';
import {color, FONT_AR, FONT_EN, SAFE, W} from '../theme';
import type {Mark, Plan, Rect, TutorialSpec} from './types';

export type TutorialProps = {spec: TutorialSpec; plan: Plan | null; release?: boolean};

// The phone on the stage at rest: the recording's 390×844 CSS px screen scaled up.
const VIEW = {w: 390, h: 844};
const S0 = 1240 / VIEW.h; // stage px per CSS px at zoom 1
const SW = VIEW.w * S0;
const SH = VIEW.h * S0;
const BX = (W - SW) / 2;
const BY = 200;
const BEZEL = 16;
const GOAL = {x: 540, y: 800}; // where a highlighted element is brought to (above the captions)
const CAPTION_TOP = 1480; // about where the caption box starts

// zooms land with a little overshoot (energetic)
const easeBack = (p: number) => {
  const x = Math.min(1, Math.max(0, p));
  const c = 1.9;
  return 1 + (c + 1) * Math.pow(x - 1, 3) + c * Math.pow(x - 1, 2);
};

const ease = (p: number) => {
  const x = Math.min(1, Math.max(0, p));
  return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2;
};

export const Tutorial: React.FC<TutorialProps> = ({spec, plan}) => {
  if (!plan) return null;
  const Intro = plan.intro ? INTROS[spec.intro!]?.component : undefined;
  return (
    <AbsoluteFill style={{backgroundColor: 'black'}}>
      {Intro && (
        <Sequence durationInFrames={plan.intro} name="intro">
          <Intro />
        </Sequence>
      )}
      <Sequence from={plan.intro} name="story">
        <Story spec={spec} plan={plan} />
      </Sequence>
    </AbsoluteFill>
  );
};

const Story: React.FC<{spec: TutorialSpec; plan: Plan}> = ({spec, plan}) => {
  const frame = useCurrentFrame();
  const talking = (f: number) => plan.cues.some((c) => f >= c.from - 4 && f < c.from + c.frames + 4);
  const baseVol = spec.music?.volume ?? 0.1;
  const musicVol = (f: number) =>
    (talking(f) ? baseVol * 0.45 : baseVol) * interpolate(f, [0, 8, plan.total - 20, plan.total], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <AbsoluteFill>
      <Sequence durationInFrames={plan.title + 10} name="title">
        <TitleCard spec={spec} frames={plan.title} />
      </Sequence>
      <Sequence from={plan.title} durationInFrames={plan.screenEnd - plan.title} name="screen" layout="none">
        <AbsoluteFill>
          <Screen spec={spec} plan={plan} offset={plan.title} />
        </AbsoluteFill>
      </Sequence>
      <Sequence from={plan.screenEnd} name="end card">
        <EndCard ar={spec.end.ar} en={spec.end.en} link={spec.end.link} frames={plan.total - plan.screenEnd} />
        <Sfx id="mg_logo_sting" at={0} volume={0.9} />
      </Sequence>
      {plan.pops.map((p, i) => (
        <Sequence key={`pop${i}`} from={p.at} durationInFrames={p.kind === 'stars' ? 40 : 30} name={`pop ${p.kind}`} layout="none">
          <Sticker kind={p.kind} />
        </Sequence>
      ))}
      {frame >= plan.title && frame < plan.screenEnd && (
        <Img src={staticFile('app/brand/logo.png')} style={{position: 'absolute', left: 46, top: 112, width: 108, height: 108, opacity: 0.9}} />
      )}
      {plan.cues.map((c, i) => (
        <React.Fragment key={i}>
          {c.line.voice && (
            <Sequence from={c.from} layout="none" name={`voice ${c.line.id}`}>
              <Audio src={staticFile(c.line.voice)} />
            </Sequence>
          )}
          {c.captions && (
            <Sequence from={c.from - 4} durationInFrames={c.frames + 22} name={`captions ${c.line.id}`}>
              <Captions line={{...c.line, speaker: ''}} voiceFrom={4} voiceFrames={c.frames} />
            </Sequence>
          )}
        </React.Fragment>
      ))}
      <Sfx id="mg_slam" at={6} volume={0.7} />
      <Sfx id="mg_whoosh_in" at={plan.title} volume={0.5} />
      {plan.sfx.map((s, i) => (
        <Sfx key={i} id={s.id} at={s.at} volume={s.volume} />
      ))}
      {spec.music && music[spec.music.track] && <Audio src={staticFile(music[spec.music.track])} volume={musicVol} loop />}
    </AbsoluteFill>
  );
};

// ------------------------------------------------------------------ title card

const TitleCard: React.FC<{spec: TutorialSpec; frames: number}> = ({spec}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const logo = spring({frame, fps, config: {damping: 9, stiffness: 140}});
  const slam = interpolate(frame, [6, 11], [3, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const shake = frame >= 11 && frame < 21 ? Math.sin(frame * 2.7) * (21 - frame) * 2.2 : 0;
  const text = frame < 6 ? 0 : slam;
  const bros = spring({frame: frame - 10, fps, config: {damping: 9, stiffness: 160}});
  const bounce = (o: number) => Math.abs(Math.sin((frame + o) / 4.5)) * -42;
  const nono = characters.nono.cheer;
  const fofo = characters.fofo.wave ?? characters.fofo.cheer;
  const h = 470;
  const feet = 1400;
  return (
    <AbsoluteFill>
      <Background bg="coral" bg2="sunYellow" seed={`title-${spec.id}`} />
      <Img src={staticFile('app/brand/logo.png')} style={{position: 'absolute', left: 540 - 130, top: SAFE.top + 30, width: 260, height: 260, transform: `scale(${logo}) rotate(${interpolate(logo, [0, 1], [-20, 0])}deg)`}} />
      <div style={{position: 'absolute', top: SAFE.top + 320, left: SAFE.left, width: SAFE.right - SAFE.left, textAlign: 'center', opacity: frame < 6 ? 0 : 1, transform: `translate(${shake}px, ${shake * 0.6}px) scale(${text}) rotate(${-3 + Math.sin(frame / 6) * 1.5}deg)`}}>
        <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 104, color: color('sunYellow'), lineHeight: 1.15, WebkitTextStroke: `6px ${color('cocoa')}`, paintOrder: 'stroke fill', textShadow: `0 10px 0 ${color('cocoa')}`}}>{spec.title.ar}</div>
        <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 64, color: 'white', lineHeight: 1.15, marginTop: 6, WebkitTextStroke: `4px ${color('cocoa')}`, paintOrder: 'stroke fill'}}>{spec.title.en}</div>
      </div>
      <Img src={staticFile(nono.file!)} style={{position: 'absolute', left: 540 - 20 - (nono.width / nono.height) * h, top: feet - h + bounce(0) + (1 - bros) * 900, height: h}} />
      <Img src={staticFile(fofo.file!)} style={{position: 'absolute', left: 540 + 20, top: feet - h * 0.9 + bounce(4) + (1 - bros) * 900, height: h * 0.9}} />
    </AbsoluteFill>
  );
};

// ------------------------------------------------------------------ the phone

function segAt(plan: Plan, f: number) {
  const segs = plan.segs;
  let lo = 0;
  let hi = segs.length - 1;
  while (lo < hi) {
    const mid = (lo + hi + 1) >> 1;
    if (segs[mid].from <= f) lo = mid;
    else hi = mid - 1;
  }
  return segs[lo];
}

const recTime = (plan: Plan, f: number) => {
  const s = segAt(plan, f);
  if (!s) return 0;
  const p = Math.min(1, Math.max(0, (f - s.from) / s.frames));
  return s.rt0 + (s.rt1 - s.rt0) * p;
};

function frameFile(spec: TutorialSpec, t: number) {
  const fr = spec.recording!.frames;
  let lo = 0;
  let hi = fr.length - 1;
  while (lo < hi) {
    const mid = (lo + hi + 1) >> 1;
    if (fr[mid].t <= t) lo = mid;
    else hi = mid - 1;
  }
  return `tutorials/${spec.id}/frames/${fr[lo].file}`;
}

// a mark's box at recording time rt (fish swim on)
const rectAt = (m: Mark, rt: number): Rect => [m.rect[0] + m.speed * (rt - m.tRec), m.rect[1], m.rect[2], m.rect[3]];

type Cam = {z: number; tx: number; ty: number};
const REST: Cam = {z: 1, tx: 0, ty: 0};

function camFor(m: Mark | null, rt: number): Cam {
  if (!m) return REST;
  const [x, y, w, h] = rectAt(m, rt);
  const z = Math.max(1, Math.min(m.zoom, 860 / (w * S0), 760 / (h * S0)));
  let tx = GOAL.x - BX - z * S0 * (x + w / 2);
  let ty = GOAL.y - BY - z * S0 * (y + h / 2);
  // once the phone is wider/taller than the frame, never show past its edges
  if (z * SW > W) tx = Math.min(-BX + BEZEL * z, Math.max(W - BX - z * SW - BEZEL * z, tx));
  // (the phone's bottom may rise to the captions, so low targets still reach GOAL)
  if (z * SH > 1920) ty = Math.min(-BY, Math.max(CAPTION_TOP - BY - z * SH, ty));
  return {z, tx, ty};
}

const lerpCam = (a: Cam, b: Cam, p: number): Cam => ({z: a.z + (b.z - a.z) * p, tx: a.tx + (b.tx - a.tx) * p, ty: a.ty + (b.ty - a.ty) * p});

// camera keyframes: zoom to each mark when it starts, back out after it
// (unless the next one follows right away)
function cameraAt(plan: Plan, f: number, rt: number): Cam {
  const keys: {f: number; m: Mark | null; dur: number}[] = [];
  plan.marks.forEach((m, i) => {
    keys.push({f: m.from, m, dur: m.big ? 12 : 9});
    const next = plan.marks[i + 1];
    if (!next || next.from - m.until > 18) keys.push({f: m.until + 4, m: null, dur: 11});
  });
  let i = -1;
  for (let k = 0; k < keys.length && keys[k].f <= f; k++) i = k;
  if (i < 0) return REST;
  const cur = camFor(keys[i].m, rt);
  const prev = camFor(keys[i - 1]?.m ?? null, rt);
  const p = (f - keys[i].f) / keys[i].dur;
  return lerpCam(prev, cur, keys[i].m ? easeBack(p) : ease(p));
}

const Screen: React.FC<{spec: TutorialSpec; plan: Plan; offset: number}> = ({spec, plan, offset}) => {
  const local = useCurrentFrame();
  const f = local + offset; // story frame
  const rec = spec.recording;
  const rt = recTime(plan, f);
  const cam = cameraAt(plan, f, rt);
  const m = plan.marks.find((k) => f >= k.from && f <= k.until + 8) ?? null;
  const k = m ? Math.min(ease((f - m.from) / 8), 1 - ease((f - m.until) / 6)) : 0;
  const src = rec ? staticFile(frameFile(spec, rt)) : null;

  // the highlighted box in content px (padding around the element)
  let box: [number, number, number, number] | null = null;
  if (m) {
    const [x, y, w, h] = rectAt(m, rt);
    const pad = m.round ? 0 : 8;
    box = [(x - pad) * S0, (y - pad) * S0, (w + 2 * pad) * S0, (h + 2 * pad) * S0];
  }
  const radius = 26;
  const clip = box && (m!.round ? `ellipse(${box[2] / 2}px ${box[3] / 2}px at ${box[0] + box[2] / 2}px ${box[1] + box[3] / 2}px)` : `inset(${box[1]}px ${SW - box[0] - box[2]}px ${SH - box[1] - box[3]}px ${box[0]}px round ${radius}px)`);
  const blur = m ? (m.big ? 7 : 3.5) * k : 0;
  const dim = m ? (m.big ? 0.5 : 0.3) * k : 0;
  const pulse = 1 + 0.04 * Math.sin(f / 3);
  // every tap kicks the camera a little; a wrong catch shakes it
  const tapM = plan.marks.find((k) => k.kind !== 'show' && k.kind !== 'type' && f >= k.at && f < k.at + 12);
  const kick = tapM ? 1 + 0.045 * Math.sin(((f - tapM.at) / 12) * Math.PI) : 1;
  const wrong = plan.pops.find((p) => p.kind === 'wrong' && f >= p.at && f < p.at + 14);
  const shake = wrong ? Math.sin((f - wrong.at) * 2.6) * (14 - (f - wrong.at)) * 2.4 : 0;

  const img = (style: React.CSSProperties) => (src ? <Img src={src} style={{position: 'absolute', left: 0, top: 0, width: SW, height: SH, ...style}} /> : <div style={{position: 'absolute', inset: 0, background: color('cream'), ...style}} />);

  return (
    <AbsoluteFill>
      <Background bg="sunYellow" bg2="coral" seed={`screen-${spec.id}`} />
      <div style={{position: 'absolute', inset: 0, transformOrigin: `${GOAL.x}px ${GOAL.y}px`, transform: `translateX(${shake}px) scale(${kick})`}}>
      <div style={{position: 'absolute', left: BX, top: BY, width: SW, height: SH, transformOrigin: '0 0', transform: `translate(${cam.tx}px, ${cam.ty}px) scale(${cam.z})`}}>
        {/* bezel */}
        <div style={{position: 'absolute', left: -BEZEL, top: -BEZEL, width: SW + 2 * BEZEL, height: SH + 2 * BEZEL, borderRadius: 74, background: color('cocoa'), boxShadow: '0 30px 60px rgba(0,0,0,0.35)'}} />
        <div style={{position: 'absolute', left: 0, top: 0, width: SW, height: SH, borderRadius: 58, overflow: 'hidden', background: 'white'}}>
          {k > 0.001 ? (
            <>
              {img({filter: `blur(${blur}px) brightness(${1 - dim})`, transform: 'scale(1.01)'})}
              {img({clipPath: clip!})}
            </>
          ) : (
            img({})
          )}
          {box && k > 0.001 && (
            <div
              style={{
                position: 'absolute',
                left: box[0],
                top: box[1],
                width: box[2],
                height: box[3],
                borderRadius: m!.round ? '50%' : radius,
                border: `${7 / cam.z}px solid ${color('sunYellow')}`,
                boxShadow: `0 0 ${30 / cam.z}px ${10 / cam.z}px rgba(255, 196, 60, ${0.75 * k}), inset 0 0 ${16 / cam.z}px rgba(255, 196, 60, ${0.5 * k})`,
                opacity: k,
                transform: `scale(${interpolate(k, [0, 1], [1.25, 1]) * pulse})`,
              }}
            />
          )}
        </div>
      </div>
      </div>
      {m && <Finger m={m} f={f} rt={rt} cam={cam} />}
    </AbsoluteFill>
  );
};

// The cartoon finger: slides in to the element, presses it, a ripple spreads.
const Finger: React.FC<{m: Mark; f: number; rt: number; cam: Cam}> = ({m, f, rt, cam}) => {
  if (!m.finger) return null;
  const [x, y, w, h] = rectAt(m, rt);
  const px = BX + cam.tx + cam.z * S0 * (x + w / 2);
  const py = BY + cam.ty + cam.z * S0 * (y + h / 2);
  const inP = ease((f - m.from - 2) / 12);
  const out = ease((f - m.until - 2) / 8);
  const press = m.kind === 'show' ? 0 : interpolate(f, [m.at - 4, m.at, m.at + 5], [0, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const point = m.kind === 'show' ? Math.sin(Math.max(0, f - m.from - 14) / 4) * 0.5 + 0.5 : 0;
  const size = 132;
  // the fingertip sits about here inside the icon
  const tipX = size * 0.36;
  const tipY = size * 0.04;
  const ox = (1 - inP) * 180 + out * 140;
  const oy = (1 - inP) * 260 + out * 200 + point * 14;
  const ripple = f >= m.at && m.kind !== 'show' ? (f - m.at) / 16 : -1;
  return (
    <>
      {ripple >= 0 && ripple <= 1 && (
        <div style={{position: 'absolute', left: px - 120 * ripple, top: py - 120 * ripple, width: 240 * ripple, height: 240 * ripple, borderRadius: '50%', border: `8px solid rgba(255,255,255,${1 - ripple})`, boxShadow: `0 0 20px rgba(255,196,60,${0.8 * (1 - ripple)})`}} />
      )}
      <div
        style={{
          position: 'absolute',
          left: px - tipX + ox,
          top: py - tipY + oy,
          width: size,
          height: size,
          opacity: inP * (1 - out),
          transformOrigin: `${tipX}px ${tipY}px`,
          transform: `scale(${1 - press * 0.16}) rotate(${-12 + press * 4}deg)`,
          filter: `drop-shadow(4px 0 0 ${color('cocoa')}) drop-shadow(-4px 0 0 ${color('cocoa')}) drop-shadow(0 4px 0 ${color('cocoa')}) drop-shadow(0 -4px 0 ${color('cocoa')}) drop-shadow(0 14px 10px rgba(0,0,0,0.35))`,
        }}
      >
        <FontAwesomeIcon icon={faHandPointer} style={{width: size, height: size, color: 'white'}} />
      </div>
    </>
  );
};

// A sticker pops over the phone after a catch: صح! (green), غلط! (coral, shakes), or a star burst for the result.
const STICKERS = {
  ok: {icon: faCheck, ar: 'صح!', en: 'Right!', bg: 'leafGreen'},
  wrong: {icon: faXmark, ar: 'غلط!', en: 'Wrong!', bg: 'coral'},
  stars: {icon: faStar, ar: 'برافو!', en: 'Bravo!', bg: 'sunYellow'},
} as const;

const Sticker: React.FC<{kind: 'ok' | 'wrong' | 'stars'}> = ({kind}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const st = STICKERS[kind];
  const len = kind === 'stars' ? 40 : 30;
  const p = spring({frame, fps, config: {damping: 8, stiffness: 220, mass: 0.6}});
  const out = interpolate(frame, [len - 7, len], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const wobble = kind === 'wrong' ? Math.sin(frame * 1.6) * Math.max(0, 12 - frame) * 1.4 : Math.sin(frame / 3) * 3;
  const cx = 540;
  const cy = kind === 'stars' ? 360 : 420;
  const textColor = kind === 'stars' ? color('cocoa') : 'white';
  return (
    <>
      {Array.from({length: 12}, (_, i) => {
        const a = (i / 12) * Math.PI * 2 + random(`${kind}-${i}`) * 0.5;
        const d = interpolate(frame, [0, 16], [60, kind === 'stars' ? 520 : 330], {extrapolateRight: 'clamp'});
        const o = interpolate(frame, [0, 4, 18], [0, 1, 0], {extrapolateRight: 'clamp'});
        const c = ['sunYellow', 'coral', 'leafGreen', 'white'][i % 4];
        return <FontAwesomeIcon key={i} icon={faStar} style={{position: 'absolute', left: cx + Math.cos(a) * d - 18, top: cy + Math.sin(a) * d - 18, width: 36, height: 36, color: color(c), opacity: o}} />;
      })}
      <div
        style={{
          position: 'absolute',
          left: cx - 230,
          top: cy - 95,
          width: 460,
          height: 190,
          borderRadius: 95,
          background: color(st.bg),
          border: `8px solid ${color('cocoa')}`,
          boxShadow: `0 12px 0 ${color('cocoa')}`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 26,
          opacity: out,
          transform: `scale(${p * (0.85 + 0.15 * out)}) rotate(${(kind === 'wrong' ? 6 : -6) + wobble}deg)`,
        }}
      >
        <FontAwesomeIcon icon={st.icon} style={{width: 92, height: 92, color: textColor}} />
        <div style={{textAlign: 'center', lineHeight: 1}}>
          <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 92, color: textColor}}>{st.ar}</div>
          <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 40, color: textColor, marginTop: 4}}>{st.en}</div>
        </div>
      </div>
    </>
  );
};
