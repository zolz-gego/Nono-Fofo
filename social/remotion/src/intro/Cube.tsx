import React from 'react';

type Faces = Partial<Record<'front' | 'back' | 'left' | 'right' | 'top' | 'bottom', React.ReactNode>>;

const face = (w: number, h: number, left: number, top: number, transform: string, bg?: string): React.CSSProperties => ({
  position: 'absolute',
  left,
  top,
  width: w,
  height: h,
  transform,
  backfaceVisibility: 'hidden',
  overflow: 'hidden',
  background: bg,
});

// A CSS 3D box centred on its parent's origin. `transform` moves / turns the
// whole box (the parent must use preserve-3d). Sides without content get `side`.
export const Cube: React.FC<{w: number; h?: number; d: number; faces: Faces; side?: string; transform?: string; opacity?: number}> = ({
  w,
  h = w,
  d,
  faces,
  side = '#333',
  transform,
  opacity,
}) => (
  <div style={{position: 'absolute', left: -w / 2, top: -h / 2, width: w, height: h, transformStyle: 'preserve-3d', transform, opacity}}>
    <div style={face(w, h, 0, 0, `translateZ(${d / 2}px)`)}>{faces.front}</div>
    <div style={face(w, h, 0, 0, `rotateY(180deg) translateZ(${d / 2}px)`)}>{faces.back}</div>
    <div style={face(d, h, (w - d) / 2, 0, `rotateY(90deg) translateZ(${w / 2}px)`, side)}>{faces.right}</div>
    <div style={face(d, h, (w - d) / 2, 0, `rotateY(-90deg) translateZ(${w / 2}px)`, side)}>{faces.left}</div>
    <div style={face(w, d, 0, (h - d) / 2, `rotateX(90deg) translateZ(${h / 2}px)`, side)}>{faces.top}</div>
    <div style={face(w, d, 0, (h - d) / 2, `rotateX(-90deg) translateZ(${h / 2}px)`, side)}>{faces.bottom}</div>
  </div>
);

// Wooden alphabet-block face: pastel square, inset border, a big Coptic letter.
export const LetterFace: React.FC<{size: number; bg: string; ink: string; letter: string; font: string}> = ({size, bg, ink, letter, font}) => (
  <div
    style={{
      width: size,
      height: size,
      background: `linear-gradient(135deg, color-mix(in srgb, ${bg} 80%, white) 0%, ${bg} 55%, color-mix(in srgb, ${bg} 85%, black) 100%)`,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      position: 'relative',
    }}
  >
    <div
      style={{
        position: 'absolute',
        inset: size * 0.08,
        borderRadius: size * 0.1,
        border: `${Math.max(2, size * 0.035)}px solid color-mix(in srgb, ${ink} 45%, transparent)`,
      }}
    />
    <span style={{fontFamily: font, fontSize: size * 0.62, color: ink, lineHeight: 1, marginTop: -size * 0.04}}>{letter}</span>
  </div>
);
