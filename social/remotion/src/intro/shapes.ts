// Target shapes for the swarm. Each shape is drawn once into an offscreen
// 1000x1000 canvas ("shape space", centre 500,500), then N points are picked
// from its filled pixels with a seeded PRNG, so every render tab gets exactly
// the same targets. Shapes that need colour (the brothers, the logo) keep the
// pixel colour of each point.
import {rng} from './anim';

export type Shape = {x: Float32Array; y: Float32Array; col?: Uint8ClampedArray};
export type Images = {logo: HTMLImageElement; nono: HTMLImageElement; fofo: HTMLImageElement};

const SIZE = 1000;

function canvas() {
  const c = document.createElement('canvas');
  c.width = SIZE;
  c.height = SIZE;
  const ctx = c.getContext('2d', {willReadFrequently: true})!;
  ctx.fillStyle = 'white';
  ctx.strokeStyle = 'white';
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  return {c, ctx};
}

// Pick n points from pixels with alpha > 128 (weighted evenly over the area).
function sample(ctx: CanvasRenderingContext2D, n: number, seed: number, keepColor = false): Shape {
  const data = ctx.getImageData(0, 0, SIZE, SIZE).data;
  const hits: number[] = [];
  for (let i = 0; i < SIZE * SIZE; i++) if (data[i * 4 + 3] > 128) hits.push(i);
  const r = rng(seed);
  const x = new Float32Array(n);
  const y = new Float32Array(n);
  const col = keepColor ? new Uint8ClampedArray(n * 3) : undefined;
  for (let k = 0; k < n; k++) {
    const p = hits[Math.floor(r() * hits.length)];
    x[k] = (p % SIZE) + r() - 0.5;
    y[k] = Math.floor(p / SIZE) + r() - 0.5;
    if (col) {
      col[k * 3] = data[p * 4];
      col[k * 3 + 1] = data[p * 4 + 1];
      col[k * 3 + 2] = data[p * 4 + 2];
    }
  }
  return {x, y, col};
}

const draw: Record<string, (ctx: CanvasRenderingContext2D, img: Images, font: string) => void> = {
  alphaOmega(ctx, _img, font) {
    ctx.font = `440px ${font}`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('a', 330, 500);
    ctx.fillText('w', 680, 500);
  },
  pyramid(ctx) {
    ctx.beginPath();
    ctx.moveTo(470, 300);
    ctx.lineTo(170, 760);
    ctx.lineTo(770, 760);
    ctx.closePath();
    ctx.fill();
    // stone courses carved out
    ctx.globalCompositeOperation = 'destination-out';
    ctx.lineWidth = 9;
    for (let y = 390; y < 760; y += 62) {
      ctx.beginPath();
      ctx.moveTo(100, y);
      ctx.lineTo(900, y);
      ctx.stroke();
    }
    ctx.beginPath();
    ctx.moveTo(470, 300);
    ctx.lineTo(540, 760);
    ctx.stroke();
    ctx.globalCompositeOperation = 'source-over';
    // sun and ground
    ctx.beginPath();
    ctx.arc(760, 270, 80, 0, Math.PI * 2);
    ctx.fill();
    ctx.lineWidth = 16;
    for (let i = 0; i < 12; i++) {
      const a = (i / 12) * Math.PI * 2;
      ctx.beginPath();
      ctx.moveTo(760 + Math.cos(a) * 110, 270 + Math.sin(a) * 110);
      ctx.lineTo(760 + Math.cos(a) * 150, 270 + Math.sin(a) * 150);
      ctx.stroke();
    }
    ctx.fillRect(90, 785, 820, 18);
  },
  palm(ctx) {
    ctx.lineWidth = 46;
    ctx.beginPath();
    ctx.moveTo(540, 860);
    ctx.quadraticCurveTo(600, 600, 500, 360);
    ctx.stroke();
    const fronds: [number, number, number, number][] = [
      [300, 330, 170, 470],
      [330, 230, 200, 260],
      [450, 170, 420, 120],
      [580, 190, 660, 170],
      [680, 260, 820, 300],
      [690, 360, 800, 480],
      [380, 420, 300, 560],
    ];
    for (const [cx, cy, ex, ey] of fronds) {
      for (let w = 36; w > 0; w -= 12) {
        ctx.lineWidth = w;
        ctx.beginPath();
        ctx.moveTo(500, 350);
        ctx.quadraticCurveTo(cx, cy, ex + (36 - w) * 0.8 * Math.sign(ex - 500), ey + (36 - w) * 0.6);
        ctx.stroke();
      }
    }
    for (const [dx, dy] of [[-28, 22], [20, 30], [-4, 44]]) {
      ctx.beginPath();
      ctx.arc(500 + dx, 360 + dy, 24, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.fillRect(330, 860, 360, 16);
  },
  nile(ctx) {
    ctx.lineWidth = 92;
    ctx.beginPath();
    ctx.moveTo(560, 80);
    ctx.bezierCurveTo(330, 180, 300, 330, 520, 420);
    ctx.bezierCurveTo(740, 510, 720, 660, 470, 720);
    ctx.bezierCurveTo(300, 760, 330, 860, 470, 930);
    ctx.stroke();
    // ripples carved out
    ctx.globalCompositeOperation = 'destination-out';
    ctx.lineWidth = 7;
    for (let k = 0; k < 9; k++) {
      ctx.beginPath();
      ctx.moveTo(380 + (k % 3) * 60, 110 + k * 92);
      ctx.quadraticCurveTo(410 + (k % 3) * 60, 98 + k * 92, 440 + (k % 3) * 60, 110 + k * 92);
      ctx.stroke();
    }
    ctx.globalCompositeOperation = 'source-over';
  },
  book(ctx) {
    const page = (dir: number) => {
      ctx.beginPath();
      ctx.moveTo(500, 400);
      ctx.bezierCurveTo(500 + dir * 120, 330, 500 + dir * 300, 330, 500 + dir * 400, 370);
      ctx.lineTo(500 + dir * 400, 720);
      ctx.bezierCurveTo(500 + dir * 300, 680, 500 + dir * 120, 690, 500, 760);
      ctx.closePath();
      ctx.fill();
    };
    page(-1);
    page(1);
    ctx.globalCompositeOperation = 'destination-out';
    ctx.lineWidth = 10;
    ctx.beginPath();
    ctx.moveTo(500, 395);
    ctx.lineTo(500, 765);
    ctx.stroke();
    ctx.lineWidth = 7;
    for (const dir of [-1, 1]) {
      for (let k = 0; k < 6; k++) {
        const y = 440 + k * 46;
        ctx.beginPath();
        ctx.moveTo(500 + dir * 70, y + 4);
        ctx.quadraticCurveTo(500 + dir * 200, y - 22, 500 + dir * 340, y - 4);
        ctx.stroke();
      }
    }
    ctx.globalCompositeOperation = 'source-over';
    // cover under the pages
    ctx.beginPath();
    ctx.moveTo(90, 735);
    ctx.quadraticCurveTo(300, 700, 500, 790);
    ctx.quadraticCurveTo(700, 700, 910, 735);
    ctx.lineTo(910, 760);
    ctx.quadraticCurveTo(700, 730, 500, 815);
    ctx.quadraticCurveTo(300, 730, 90, 760);
    ctx.closePath();
    ctx.fill();
  },
  brothers(ctx, img) {
    const h1 = 760;
    const w1 = (img.nono.width / img.nono.height) * h1;
    ctx.drawImage(img.nono, 470 - w1, 880 - h1, w1, h1);
    const h2 = 600;
    const w2 = (img.fofo.width / img.fofo.height) * h2;
    ctx.drawImage(img.fofo, 530, 880 - h2, w2, h2);
  },
  names(ctx, _img, font) {
    ctx.font = `300px ${font}`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('nono', 500, 330);
    ctx.fillText('fofo', 500, 670);
  },
  logo(ctx, img) {
    ctx.drawImage(img.logo, 0, 0, SIZE, SIZE);
  },
};

export const COLORED = new Set(['brothers', 'logo']);

export function buildShapes(n: number, img: Images, font: string): Record<string, Shape> {
  const out: Record<string, Shape> = {};
  Object.entries(draw).forEach(([name, fn], i) => {
    const {ctx} = canvas();
    fn(ctx, img, font);
    out[name] = sample(ctx, n, 1000 + i * 77, COLORED.has(name));
  });
  return out;
}
