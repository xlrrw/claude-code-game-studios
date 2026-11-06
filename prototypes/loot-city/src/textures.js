// PROTOTYPE - NOT FOR PRODUCTION
// Procedural PBR texture generation (no external image assets).
import * as THREE from 'three';

export function rng(seed) {
  let a = seed >>> 0;
  return function () {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Tileable value noise. */
export function makeNoise(seed) {
  const r = rng(seed);
  const P = 512;
  const tab = new Float32Array(P * P);
  for (let i = 0; i < tab.length; i++) tab[i] = r();
  const noise = (x, y, period) => {
    const xi = Math.floor(x), yi = Math.floor(y);
    const xf = x - xi, yf = y - yi;
    const u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf);
    const p = Math.min(period, P);
    const x0 = ((xi % p) + p) % p, x1 = (x0 + 1) % p;
    const y0 = ((yi % p) + p) % p, y1 = (y0 + 1) % p;
    const a = tab[y0 * P + x0], b = tab[y0 * P + x1], c = tab[y1 * P + x0], d = tab[y1 * P + x1];
    return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
  };
  const fbm = (x, y, period, oct = 5) => {
    let s = 0, amp = 0.5, f = 1, n = 0;
    for (let o = 0; o < oct; o++) { s += amp * noise(x * f, y * f, period * f); n += amp; amp *= 0.5; f *= 2; }
    return s / n;
  };
  return { noise, fbm };
}

function canvas(w, h = w) {
  const c = document.createElement('canvas');
  c.width = w; c.height = h;
  return c;
}

let maxAniso = 8;
export function setMaxAnisotropy(a) { maxAniso = a; }

function toTex(c, srgb, repeat = true) {
  const t = new THREE.CanvasTexture(c);
  if (repeat) { t.wrapS = t.wrapT = THREE.RepeatWrapping; }
  t.anisotropy = maxAniso;
  t.colorSpace = srgb ? THREE.SRGBColorSpace : THREE.NoColorSpace;
  t.generateMipmaps = true;
  t.minFilter = THREE.LinearMipmapLinearFilter;
  t.needsUpdate = true;
  return t;
}

/** Builds a normal map canvas from a height Float32Array (tileable). */
function normalFromHeight(h, w, hh, strength) {
  const c = canvas(w, hh);
  const ctx = c.getContext('2d');
  const img = ctx.createImageData(w, hh);
  const d = img.data;
  for (let y = 0; y < hh; y++) {
    for (let x = 0; x < w; x++) {
      const xl = (x - 1 + w) % w, xr = (x + 1) % w, yu = (y - 1 + hh) % hh, yd = (y + 1) % hh;
      const dx = (h[y * w + xr] - h[y * w + xl]) * strength;
      const dy = (h[yd * w + x] - h[yu * w + x]) * strength;
      let nx = -dx, ny = dy, nz = 1;
      const l = Math.hypot(nx, ny, nz); nx /= l; ny /= l; nz /= l;
      const i = (y * w + x) * 4;
      d[i] = (nx * 0.5 + 0.5) * 255; d[i + 1] = (ny * 0.5 + 0.5) * 255; d[i + 2] = (nz * 0.5 + 0.5) * 255; d[i + 3] = 255;
    }
  }
  ctx.putImageData(img, 0, 0);
  return c;
}

/**
 * Generic per-pixel material generator.
 * fn(u,v,x,y) -> {r,g,b, h (height 0..1), rough, metal}
 */
function genMaterial(size, fn, normalStrength = 2, hSize = size) {
  const w = size, h = hSize;
  const cC = canvas(w, h), cR = canvas(w, h);
  const ctxC = cC.getContext('2d'), ctxR = cR.getContext('2d');
  const iC = ctxC.createImageData(w, h), iR = ctxR.createImageData(w, h);
  const H = new Float32Array(w * h);
  const out = { r: 0, g: 0, b: 0, h: 0, rough: 1, metal: 0 };
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      out.metal = 0; out.rough = 1; out.h = 0;
      fn(x / w, y / h, x, y, out);
      const i = (y * w + x) * 4;
      iC.data[i] = out.r; iC.data[i + 1] = out.g; iC.data[i + 2] = out.b; iC.data[i + 3] = 255;
      iR.data[i] = 255; iR.data[i + 1] = out.rough * 255; iR.data[i + 2] = out.metal * 255; iR.data[i + 3] = 255;
      H[y * w + x] = out.h;
    }
  }
  ctxC.putImageData(iC, 0, 0); ctxR.putImageData(iR, 0, 0);
  const cN = normalFromHeight(H, w, h, normalStrength);
  return { map: toTex(cC, true), rm: toTex(cR, false), normal: toTex(cN, false), colorCanvas: cC };
}

const clamp = (v, a = 0, b = 255) => (v < a ? a : v > b ? b : v);

export function asphalt() {
  const N = makeNoise(11);
  const S = 1024;
  return genMaterial(S, (u, v, x, y, o) => {
    const big = N.fbm(u * 8, v * 8, 8, 4);
    const grain = N.noise(u * 400, v * 400, 400);
    const speck = grain > 0.86 ? 40 : grain < 0.08 ? -25 : 0;
    const patch = N.fbm(u * 3 + 7, v * 3, 3, 3);
    const crack = Math.abs(N.fbm(u * 6 + 3, v * 6 + 9, 6, 5) - 0.5) < 0.008 ? -30 : 0;
    let base = 52 + big * 26 + speck + crack + (patch > 0.62 ? -10 : 0);
    o.r = clamp(base); o.g = clamp(base + 1); o.b = clamp(base + 3);
    o.h = grain * 0.6 + big * 0.4 + (crack ? -0.6 : 0);
    o.rough = 0.82 + grain * 0.15 - (patch > 0.62 ? 0.25 : 0);
  }, 3);
}

export function pavers() {
  const N = makeNoise(21);
  const S = 512, tiles = 4;
  const r = rng(5);
  const tint = new Float32Array(tiles * tiles * 2).map(() => r());
  return genMaterial(S, (u, v, x, y, o) => {
    const off = Math.floor(v * tiles) % 2 ? 0.5 / tiles : 0;
    const tu = ((u + off) % 1) * tiles, tv = v * tiles;
    const fu = tu - Math.floor(tu), fv = tv - Math.floor(tv);
    const idx = (Math.floor(tv) * tiles + Math.floor(tu)) % tint.length;
    const edge = Math.min(fu, 1 - fu, fv, 1 - fv);
    const grout = edge < 0.035;
    const n = N.fbm(u * 32, v * 32, 32, 4);
    const t = tint[idx];
    let base = grout ? 95 + n * 20 : 128 + t * 30 + n * 34 - 15;
    o.r = clamp(base + 3); o.g = clamp(base); o.b = clamp(base - 4);
    o.h = grout ? 0 : Math.min(1, edge * 12) * 0.8 + n * 0.2;
    o.rough = grout ? 1 : 0.75 + n * 0.2;
  }, 4);
}

export function grass() {
  const N = makeNoise(31);
  return genMaterial(512, (u, v, x, y, o) => {
    const n = N.fbm(u * 16, v * 16, 16, 5);
    const f = N.noise(u * 256, v * 256, 256);
    const dry = N.fbm(u * 4 + 5, v * 4, 4, 3);
    o.r = clamp(40 + n * 40 + dry * 50 + f * 25);
    o.g = clamp(70 + n * 60 + f * 40 + dry * 20);
    o.b = clamp(22 + n * 20);
    o.h = f * 0.7 + n * 0.3;
    o.rough = 0.95;
  }, 3);
}

export function dirt() {
  const N = makeNoise(41);
  return genMaterial(512, (u, v, x, y, o) => {
    const n = N.fbm(u * 12, v * 12, 12, 5);
    const f = N.noise(u * 300, v * 300, 300);
    const stone = f > 0.9 ? 30 : 0;
    o.r = clamp(95 + n * 50 + stone); o.g = clamp(78 + n * 40 + stone); o.b = clamp(58 + n * 30 + stone);
    o.h = n * 0.6 + f * 0.4;
    o.rough = 0.97;
  }, 4);
}

export function concrete(seed = 51, tone = 1) {
  const N = makeNoise(seed);
  return genMaterial(512, (u, v, x, y, o) => {
    const n = N.fbm(u * 10, v * 10, 10, 5);
    const f = N.noise(u * 256, v * 256, 256);
    const stain = N.fbm(u * 3, v * 3 + 2, 3, 3);
    const b = (120 + n * 50 + f * 18 - (stain > 0.6 ? 30 : 0)) * tone;
    o.r = clamp(b); o.g = clamp(b - 2); o.b = clamp(b - 5);
    o.h = f * 0.5 + n * 0.5;
    o.rough = 0.88 + f * 0.1;
  }, 2);
}

export function bark() {
  const N = makeNoise(61);
  return genMaterial(256, (u, v, x, y, o) => {
    const n = N.fbm(u * 8, v * 1.5, 8, 5);
    const ridge = Math.abs(Math.sin((u * 14 + n * 3) * Math.PI));
    const b = 50 + ridge * 40 + n * 20;
    o.r = clamp(b + 10); o.g = clamp(b - 2); o.b = clamp(b - 14);
    o.h = ridge; o.rough = 0.95;
  }, 5);
}

export function metalPaint(seed = 71) {
  const N = makeNoise(seed);
  return genMaterial(256, (u, v, x, y, o) => {
    const n = N.fbm(u * 6, v * 6, 6, 5);
    const scratch = N.noise(u * 200, v * 4, 200) > 0.93;
    const b = 200 + n * 40 - (scratch ? 60 : 0);
    o.r = o.g = o.b = clamp(b);
    o.h = n * 0.3 + (scratch ? -0.3 : 0);
    o.rough = 0.4 + n * 0.3 + (scratch ? 0.2 : 0); o.metal = 0.6;
  }, 1);
}

export function leafCard() {
  // alpha texture of leaf cluster
  const S = 256;
  const c = canvas(S), ctx = c.getContext('2d');
  const r = rng(77);
  ctx.clearRect(0, 0, S, S);
  for (let i = 0; i < 420; i++) {
    const a = r() * Math.PI * 2, d = Math.sqrt(r()) * S * 0.45;
    const x = S / 2 + Math.cos(a) * d, y = S / 2 + Math.sin(a) * d;
    const g = 70 + r() * 80;
    ctx.fillStyle = `rgb(${(g * 0.55) | 0},${g | 0},${(g * 0.3) | 0})`;
    ctx.save(); ctx.translate(x, y); ctx.rotate(r() * Math.PI * 2);
    ctx.beginPath(); ctx.ellipse(0, 0, 4 + r() * 5, 2 + r() * 2.5, 0, 0, Math.PI * 2); ctx.fill();
    ctx.restore();
  }
  const t = toTex(c, true, false);
  return t;
}

// ---------- Facades ----------
// Tile = 4 window bays (3m each) x 4 floors (3.2m) => 12m x 12.8m
export const FACADE_TILE_W = 12;
export const FACADE_TILE_H = 12.8;

/**
 * style: {wall:[r,g,b], wallVar, brick:boolean, metalPanels, glass:boolean, frame:[r,g,b],
 *  winW (0..1 bay fraction), winH (0..1 floor fraction), glassTint:[r,g,b], lit: prob}
 */
export function facade(style, seed) {
  const W = 1024, H = 1024;
  const N = makeNoise(seed);
  const r = rng(seed * 7 + 3);
  const cC = canvas(W, H), cR = canvas(W, H), cE = canvas(W, H);
  const ctxC = cC.getContext('2d'), ctxR = cR.getContext('2d'), ctxE = cE.getContext('2d');
  const iC = ctxC.createImageData(W, H), iR = ctxR.createImageData(W, H), iE = ctxE.createImageData(W, H);
  const Hh = new Float32Array(W * H);
  const bays = 4, floors = 4;
  const bw = W / bays, fh = H / floors;
  // per-window state
  const lit = [], tint = [], blind = [];
  for (let i = 0; i < bays * floors; i++) {
    lit.push(r() < style.lit ? 0.5 + r() * 0.5 : 0);
    const warm = r();
    tint.push(warm < 0.7 ? [255, 190 + r() * 40, 120 + r() * 50] : warm < 0.9 ? [230, 235, 255] : [255, 230, 190]);
    blind.push(r() < 0.22 ? 0.15 + r() * 0.5 : 0);
  }
  const [wr, wg, wb] = style.wall;
  const [gr, gg, gb] = style.glassTint;
  const [fr, fg, fb] = style.frame;
  for (let y = 0; y < H; y++) {
    const fy = (y % fh) / fh;
    const floor = floors - 1 - Math.floor(y / fh);
    for (let x = 0; x < W; x++) {
      const fx = (x % bw) / bw;
      const bay = Math.floor(x / bw);
      const wi = floor * bays + bay;
      const i = (y * W + x) * 4;
      const n = N.fbm(x / W * 12, y / H * 12, 12, 4);
      const f = N.noise(x / W * 300, y / H * 300, 300);
      // window rect (upper part of floor, image y goes down: fy 0 = top of floor)
      const x0 = (1 - style.winW) / 2, x1 = 1 - x0;
      const y0 = style.winTop ?? 0.18, y1 = y0 + style.winH;
      const inWin = fx > x0 && fx < x1 && fy > y0 && fy < y1;
      const fw = 0.018;
      const inFrame = fx > x0 - fw && fx < x1 + fw && fy > y0 - fw * 1.2 && fy < y1 + fw * 1.2 && !inWin;
      let R, G, B, h, rough, metal = 0, er = 0, eg = 0, eb = 0;
      if (inWin) {
        // mullion
        const mull = style.mullions && Math.abs(fx - 0.5) < 0.008;
        const ly = (fy - y0) / style.winH;
        const blindCover = blind[wi] > 0 && ly < blind[wi];
        if (mull) { R = fr; G = fg; B = fb; h = 0.6; rough = 0.4; metal = 0.6; }
        else if (blindCover) {
          const slat = (Math.floor(ly * 60) % 2) ? 0.9 : 1;
          R = 120 * slat; G = 116 * slat; B = 106 * slat; h = 0.2; rough = 0.8;
          if (lit[wi]) { er = tint[wi][0] * 0.35 * lit[wi]; eg = tint[wi][1] * 0.35 * lit[wi]; eb = tint[wi][2] * 0.35 * lit[wi]; }
        } else {
          const grad = 0.85 + ly * 0.3 + n * 0.1;
          R = gr * grad; G = gg * grad; B = gb * grad; h = 0.0; rough = 0.04 + f * 0.04; metal = 0.85;
          if (lit[wi]) {
            const inner = 0.6 + 0.4 * Math.sin(fx * 3.1) * (0.6 + 0.4 * n);
            er = tint[wi][0] * lit[wi] * inner; eg = tint[wi][1] * lit[wi] * inner; eb = tint[wi][2] * lit[wi] * inner;
          }
        }
      } else if (inFrame) {
        R = fr; G = fg; B = fb; h = 0.75; rough = 0.45; metal = style.metalFrame ? 0.7 : 0;
      } else if (style.glass) {
        // spandrel panels between glass bands
        const band = fy < 0.06 || fy > 0.94;
        R = (band ? 60 : 40) + n * 15; G = R + 4; B = R + 10; h = band ? 0.8 : 0.5; rough = 0.3; metal = 0.6;
      } else if (style.brick) {
        const bh = fh / 18, bwid = bw / 7;
        const row = Math.floor(y / bh);
        const off = (row % 2) * bwid * 0.5;
        const bx = ((x + off) % bwid) / bwid, by = (y % bh) / bh;
        const mortar = bx < 0.06 || by < 0.12;
        const bid = (row * 131 + Math.floor((x + off) / bwid) * 71) % 97 / 97;
        if (mortar) { R = 150 + n * 20; G = 142 + n * 20; B = 130 + n * 20; h = 0.2; rough = 1; }
        else {
          const v = 0.8 + bid * 0.35 + f * 0.1;
          R = wr * v; G = wg * v; B = wb * v; h = 0.7 + f * 0.2; rough = 0.9;
        }
        // grime streaks under windows
        const streak = fx > x0 && fx < x1 && fy > y1 ? (1 - (fy - y1) * 2) * 0.25 * N.noise(fx * 40, 0, 40) : 0;
        R *= 1 - streak; G *= 1 - streak; B *= 1 - streak;
      } else if (style.panels) {
        const pw = bw / 2;
        const seam = (x % pw) < 3 || (y % fh) < 3;
        const rib = Math.sin(x / W * Math.PI * 2 * 160) * 0.5 + 0.5;
        const v = 0.85 + n * 0.25 + rib * 0.08;
        R = wr * v; G = wg * v; B = wb * v; h = seam ? 0 : 0.4 + rib * 0.4; rough = 0.55 + n * 0.3; metal = 0.5;
        const rust = N.fbm(x / W * 8 + 3, y / H * 8, 8, 4);
        if (rust > 0.62) { R = R * 0.6 + 110 * 0.4; G = G * 0.6 + 60 * 0.4; B = B * 0.6 + 30 * 0.4; rough = 0.95; metal = 0.1; }
      } else {
        // plaster
        const v = 0.9 + n * (style.wallVar ?? 0.2) + f * 0.05;
        R = wr * v; G = wg * v; B = wb * v; h = 0.5 + f * 0.3 + n * 0.2; rough = 0.92;
        const ledge = fy > 0.94; // floor ledge
        if (style.ledges && ledge) { R *= 0.92; G *= 0.92; B *= 0.92; h = 0.9; }
        const dirtv = N.fbm(x / W * 4, y / H * 2 + 5, 4, 3);
        const d = Math.max(0, dirtv - 0.6) * (style.dirt ?? 0.6) * 0.6;
        R *= 1 - d; G *= 1 - d; B *= 1 - d * 1.1;
      }
      iC.data[i] = clamp(R); iC.data[i + 1] = clamp(G); iC.data[i + 2] = clamp(B); iC.data[i + 3] = 255;
      iR.data[i] = 255; iR.data[i + 1] = clamp(rough * 255); iR.data[i + 2] = clamp(metal * 255); iR.data[i + 3] = 255;
      iE.data[i] = clamp(er); iE.data[i + 1] = clamp(eg); iE.data[i + 2] = clamp(eb); iE.data[i + 3] = 255;
      Hh[y * W + x] = h;
    }
  }
  ctxC.putImageData(iC, 0, 0); ctxR.putImageData(iR, 0, 0); ctxE.putImageData(iE, 0, 0);
  const cN = normalFromHeight(Hh, W, H, 3);
  return { map: toTex(cC, true), rm: toTex(cR, false), normal: toTex(cN, false), emissive: toTex(cE, true) };
}

export function roofTex() {
  const N = makeNoise(81);
  return genMaterial(512, (u, v, x, y, o) => {
    const n = N.fbm(u * 10, v * 10, 10, 5);
    const g = N.noise(u * 350, v * 350, 350);
    const b = 70 + n * 40 + g * 30;
    o.r = clamp(b); o.g = clamp(b); o.b = clamp(b + 2);
    o.h = g; o.rough = 0.9;
  }, 3);
}

export function roofTiles() {
  const N = makeNoise(91);
  return genMaterial(512, (u, v, x, y, o) => {
    const rows = 16, cols = 10;
    const row = Math.floor(v * rows);
    const off = row % 2 ? 0.5 / cols : 0;
    const fu = ((u + off) * cols) % 1, fv = (v * rows) % 1;
    const n = N.fbm(u * 20, v * 20, 20, 4);
    const shade = 0.75 + fv * 0.35;
    const edge = fu < 0.04 || fu > 0.96;
    o.r = clamp((150 + n * 40) * shade * (edge ? 0.7 : 1));
    o.g = clamp((62 + n * 20) * shade * (edge ? 0.7 : 1));
    o.b = clamp((45 + n * 15) * shade * (edge ? 0.7 : 1));
    o.h = fv * (edge ? 0.3 : 1); o.rough = 0.7;
  }, 4);
}

export function woodTex() {
  const N = makeNoise(101);
  return genMaterial(512, (u, v, x, y, o) => {
    const n = N.fbm(u * 2, v * 20, 2, 5);
    const ring = Math.sin((v * 30 + n * 6) * Math.PI) * 0.5 + 0.5;
    const plank = (u * 6) % 1 < 0.015;
    const b = 0.75 + ring * 0.25;
    o.r = clamp(150 * b * (plank ? 0.5 : 1)); o.g = clamp(100 * b * (plank ? 0.5 : 1)); o.b = clamp(62 * b * (plank ? 0.5 : 1));
    o.h = plank ? 0 : ring * 0.4 + 0.6; o.rough = 0.65;
  }, 2);
}

/** Text sign texture. */
export function signTexture(text, bg = '#1a1a1a', fg = '#ffd166', w = 1024, h = 256, sub = '') {
  const c = canvas(w, h), ctx = c.getContext('2d');
  const g = ctx.createLinearGradient(0, 0, 0, h);
  g.addColorStop(0, bg); g.addColorStop(1, '#000');
  ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
  ctx.strokeStyle = fg; ctx.lineWidth = 8; ctx.strokeRect(10, 10, w - 20, h - 20);
  ctx.fillStyle = fg;
  ctx.font = `bold ${sub ? h * 0.42 : h * 0.55}px "Segoe UI", Arial, sans-serif`;
  ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
  ctx.shadowColor = fg; ctx.shadowBlur = 18;
  ctx.fillText(text, w / 2, sub ? h * 0.42 : h / 2);
  if (sub) { ctx.font = `${h * 0.18}px "Segoe UI", Arial`; ctx.fillText(sub, w / 2, h * 0.78); }
  const t = toTex(c, true, false);
  return t;
}

export function radialGlow(color = '#ffffff') {
  const S = 128, c = canvas(S), ctx = c.getContext('2d');
  const g = ctx.createRadialGradient(S / 2, S / 2, 0, S / 2, S / 2, S / 2);
  g.addColorStop(0, color); g.addColorStop(0.4, 'rgba(255,255,255,0.35)'); g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g; ctx.fillRect(0, 0, S, S);
  return toTex(c, true, false);
}

export function beamTexture() {
  const c = canvas(16, 256), ctx = c.getContext('2d');
  const g = ctx.createLinearGradient(0, 256, 0, 0);
  g.addColorStop(0, 'rgba(255,255,255,1)'); g.addColorStop(0.3, 'rgba(255,255,255,0.5)'); g.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = g; ctx.fillRect(0, 0, 16, 256);
  return toTex(c, true, false);
}

export function roadMarkTexture() {
  const c = canvas(64, 64), ctx = c.getContext('2d');
  ctx.fillStyle = '#ddd'; ctx.fillRect(0, 0, 64, 64);
  const t = toTex(c, true);
  return t;
}
