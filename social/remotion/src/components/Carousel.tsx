import {FontAwesomeIcon} from '@fortawesome/react-fontawesome';
import React from 'react';
import {AbsoluteFill, Img, random, staticFile, useCurrentFrame} from 'remotion';
import {ICONS} from '../icons';
import {color, FONT_AR, FONT_COPTIC, FONT_EN, H, W} from '../theme';
import type {CarouselSpec, CarouselWord} from '../types';

// Instagram / TikTok photo carousel posted after a letter's video, one slide per
// frame (portrait 1080×1920): frame 0 is the letter card, then one slide per word.
// Text stays inside the app's safe area (clear of the TikTok/Reels UI).
export const CAROUSEL_W = W;
export const CAROUSEL_H = H;

const COCOA = color('cocoa');
const GOLD = color('letterGold');
const BG = {cover: 'sunYellow', ar: 'coral', en: 'mistBlue', cop: 'leafGreen'} as const;
const KEYS = 'abjdezqiklmnxoprctvfyw'.split('');
const CARD_X = 110; // card left/right margin
const CARD_TOP = 470;

// The slide background: the group's color, soft rays and faint Coptic letters.
const Backdrop: React.FC<{bg: string; seed: string}> = ({bg, seed}) => {
  const base = color(bg);
  const cx = W / 2;
  const cy = H * 0.45;
  return (
    <AbsoluteFill style={{background: `radial-gradient(circle at 50% 45%, ${base} 0%, ${base} 50%, color-mix(in srgb, ${base} 80%, black) 100%)`}}>
      <svg width={W} height={H} style={{position: 'absolute'}}>
        {Array.from({length: 18}, (_, i) => {
          const a0 = (i / 18) * Math.PI * 2;
          const a1 = a0 + Math.PI / 18;
          const r = 2400;
          return <path key={i} d={`M${cx} ${cy} L${cx + r * Math.cos(a0)} ${cy + r * Math.sin(a0)} L${cx + r * Math.cos(a1)} ${cy + r * Math.sin(a1)} Z`} fill="rgba(255,255,255,0.16)" />;
        })}
      </svg>
      {Array.from({length: 20}, (_, i) => (
        <div
          key={i}
          style={{
            position: 'absolute',
            left: random(`${seed}x${i}`) * (W - 120),
            top: random(`${seed}y${i}`) * (H - 160),
            fontFamily: FONT_COPTIC,
            fontSize: 90 + random(`${seed}s${i}`) * 70,
            color: 'white',
            opacity: 0.18,
            transform: `rotate(${(random(`${seed}r${i}`) - 0.5) * 40}deg)`,
          }}
        >
          {KEYS[Math.floor(random(`${seed}k${i}`) * KEYS.length)]}
        </div>
      ))}
    </AbsoluteFill>
  );
};

// A pill with a cocoa border: Arabic · English (or just one of them).
const Pill: React.FC<{ar?: string; en?: string; bg?: string; fg?: string; size?: number; icon?: string; style?: React.CSSProperties}> = ({ar, en, bg = 'cream', fg = 'deepTeal', size = 44, icon, style}) => (
  <div
    style={{
      display: 'inline-flex',
      alignItems: 'center',
      gap: size * 0.4,
      padding: `${size * 0.18}px ${size * 0.7}px`,
      background: color(bg),
      color: color(fg),
      border: `6px solid ${COCOA}`,
      borderRadius: 999,
      boxShadow: `0 8px 0 ${COCOA}`,
      whiteSpace: 'nowrap',
      ...style,
    }}
  >
    {icon && ICONS[icon] && <FontAwesomeIcon icon={ICONS[icon]} style={{fontSize: size * 0.85}} />}
    {ar && (
      <span dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: size}}>
        {ar}
      </span>
    )}
    {ar && en && <span style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: size * 0.9, opacity: 0.55}}>·</span>}
    {en && <span style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: size * 0.95}}>{en}</span>}
  </div>
);

// Coptic word in gold; the letter being taught is bigger and coral.
const CopticWord: React.FC<{text: string; mark: string; size: number}> = ({text, mark, size}) => (
  <div style={{fontFamily: FONT_COPTIC, fontSize: size, lineHeight: 1.15, color: GOLD, textShadow: `0 6px 0 ${COCOA}`, whiteSpace: 'nowrap'}}>
    {text.split('').map((ch, i) =>
      ch === mark ? (
        <span key={i} style={{color: color('coral'), fontSize: '1.25em', lineHeight: 0.8}}>
          {ch}
        </span>
      ) : (
        ch
      ),
    )}
  </div>
);

const Logo: React.FC = () => <Img src={staticFile('app/brand/logo.png')} style={{position: 'absolute', left: 80, top: 150, height: 130}} />;

// Title on every word slide: the small letter and its sound, e.g. "ⲉ  بينطق ي · says e".
const LetterSound: React.FC<{spec: CarouselSpec}> = ({spec}) => (
  <div style={{position: 'absolute', left: 0, right: 0, top: 310, display: 'flex', justifyContent: 'center'}}>
    <div
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 26,
        padding: '6px 44px 6px 18px',
        background: color('deepTeal'),
        color: color('cream'),
        border: `6px solid ${COCOA}`,
        borderRadius: 999,
        boxShadow: `0 8px 0 ${COCOA}`,
        whiteSpace: 'nowrap',
      }}
    >
      <div
        style={{
          width: 104,
          height: 104,
          borderRadius: 52,
          background: color('cream'),
          border: `5px solid ${COCOA}`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: FONT_COPTIC,
          fontSize: 82,
          lineHeight: 1,
          color: color('coral'),
        }}
      >
        {spec.letter.small}
      </div>
      <span dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 56}}>
        بينطق {spec.sound.ar}
      </span>
      <span style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 50, opacity: 0.55}}>·</span>
      <span style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 54}}>says "{spec.sound.en}"</span>
    </div>
  </div>
);

// "Swipe" hint at the bottom of every slide but the last.
const Swipe: React.FC = () => (
  <div style={{position: 'absolute', left: 0, right: 0, top: 1470, display: 'flex', justifyContent: 'center'}}>
    <Pill ar="اسحب" en="Swipe" icon="arrowRight" size={38} bg="deepTeal" fg="cream" />
  </div>
);

const Card: React.FC<{children: React.ReactNode; height: number; accent: string}> = ({children, height, accent}) => (
  <div
    style={{
      position: 'absolute',
      left: CARD_X,
      right: CARD_X,
      top: CARD_TOP,
      height,
      background: color('cream'),
      border: `8px solid ${COCOA}`,
      borderRadius: 64,
      boxShadow: `0 18px 0 ${color(accent)}`,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      textAlign: 'center',
    }}
  >
    {children}
  </div>
);

// ---------------------------------------------------------------- slide 1: the letter

const LetterTile: React.FC<{k: string; ar: string; en: string}> = ({k, ar, en}) => (
  <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18}}>
    <div
      style={{
        width: 290,
        height: 290,
        borderRadius: 52,
        background: color('deepTeal'),
        border: `8px solid ${COCOA}`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontFamily: FONT_COPTIC,
        fontSize: 220,
        lineHeight: 1,
        color: GOLD,
        textShadow: `0 6px 0 ${COCOA}`,
      }}
    >
      {k}
    </div>
    <Pill ar={ar} en={en} size={38} />
  </div>
);

const LetterSlide: React.FC<{spec: CarouselSpec; last: boolean}> = ({spec, last}) => {
  const {letter, sound} = spec;
  return (
    <AbsoluteFill>
      <Backdrop bg={BG.cover} seed={`${spec.id}-cover`} />
      <Logo />
      <div style={{position: 'absolute', left: 0, right: 0, top: 310, display: 'flex', justifyContent: 'center'}}>
        <Pill ar={`حرف ${letter.name.ar}`} en={`The letter ${letter.name.en}`} size={60} bg="coral" fg="cream" />
      </div>
      <Card height={900} accent="coral">
        <div style={{display: 'flex', gap: 60}}>
          <LetterTile k={letter.capital} ar="كبير" en="Capital" />
          <LetterTile k={letter.small} ar="صغير" en="Small" />
        </div>
        <div style={{display: 'flex', alignItems: 'baseline', gap: 44, marginTop: 50}}>
          <span dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 110, color: color('deepTeal')}}>
            {letter.name.ar}
          </span>
          <span style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 104, color: color('slateTeal')}}>{letter.name.en}</span>
        </div>
        <Pill ar={`بينطق ${sound.ar}`} en={`says "${sound.en}"`} icon="sound" size={50} bg="sunYellow" fg="cocoa" style={{marginTop: 30}} />
      </Card>
      {!last && <Swipe />}
    </AbsoluteFill>
  );
};

// ---------------------------------------------------------------- word slides

const WordSlide: React.FC<{spec: CarouselSpec; word: CarouselWord; index: number; last: boolean}> = ({spec, word, index, last}) => {
  const copticSize = Math.min(230, 1450 / word.coptic.length);
  // the meaning in the other language(s): English for an Arabic word, Arabic for an English one
  const meaning = word.group === 'cop' ? word.meaning : word.group === 'ar' ? {en: word.meaning} : {ar: word.meaning};
  return (
    <AbsoluteFill>
      <Backdrop bg={BG[word.group]} seed={`${spec.id}-${index}`} />
      <Logo />
      <LetterSound spec={spec} />
      <Card height={760} accent="sunYellow">
        <CopticWord text={word.coptic} mark={spec.letter.small} size={copticSize} />
        <div style={{width: 520, height: 8, borderRadius: 4, background: `${COCOA}22`, margin: '26px 0 22px'}} />
        {word.group === 'cop' ? (
          <>
            <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 104, lineHeight: 1.15, color: color('deepTeal')}}>
              {word.ar}
            </div>
            <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 96, lineHeight: 1.1, color: color('slateTeal')}}>{word.en}</div>
          </>
        ) : word.group === 'ar' ? (
          <div dir="rtl" style={{fontFamily: FONT_AR, fontWeight: 800, fontSize: 130, lineHeight: 1.2, color: color('deepTeal')}}>
            {word.word}
          </div>
        ) : (
          <div style={{fontFamily: FONT_EN, fontWeight: 800, fontSize: 124, lineHeight: 1.2, color: color('deepTeal')}}>{word.word}</div>
        )}
        <Pill ar={meaning.ar} en={meaning.en} size={56} bg="coral" fg="cream" style={{marginTop: 34}} />
      </Card>
      {/* the word's emoji, under the card */}
      {word.emoji && (
        <div style={{position: 'absolute', left: 0, right: 0, top: CARD_TOP + 760 + 40, textAlign: 'center', fontSize: 180, lineHeight: 1, filter: 'drop-shadow(0 10px 0 rgba(0,0,0,0.18))'}}>
          {word.emoji}
        </div>
      )}
      {!last && <Swipe />}
    </AbsoluteFill>
  );
};

export const Carousel: React.FC<{spec: CarouselSpec}> = ({spec}) => {
  const frame = useCurrentFrame();
  const last = frame === spec.words.length;
  if (frame === 0) return <LetterSlide spec={spec} last={last} />;
  return <WordSlide spec={spec} word={spec.words[frame - 1]} index={frame} last={last} />;
};
