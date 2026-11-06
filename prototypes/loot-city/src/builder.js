// PROTOTYPE - NOT FOR PRODUCTION
// Accumulates world-space quads per material key, then emits merged meshes.
import * as THREE from 'three';

export class GeoBuilder {
  constructor() { this.buckets = new Map(); }
  _b(key) {
    let b = this.buckets.get(key);
    if (!b) { b = { p: [], n: [], uv: [], idx: [], c: 0 }; this.buckets.set(key, b); }
    return b;
  }
  /** quad from 4 corners (counter-clockwise when viewed from the front) */
  quad(key, a, b, c, d, uva, uvb, uvc, uvd) {
    const B = this._b(key);
    const e1 = new THREE.Vector3().subVectors(b, a), e2 = new THREE.Vector3().subVectors(d, a);
    const n = new THREE.Vector3().crossVectors(e1, e2).normalize();
    for (const [v, uv] of [[a, uva], [b, uvb], [c, uvc], [d, uvd]]) {
      B.p.push(v.x, v.y, v.z); B.n.push(n.x, n.y, n.z); B.uv.push(uv[0], uv[1]);
    }
    const s = B.c;
    B.idx.push(s, s + 1, s + 2, s, s + 2, s + 3);
    B.c += 4;
  }
  /**
   * Axis-aligned box. opts: {side, top, bottom, tw, th, ts (top uv scale), u0 (uv offset)}
   * Side UVs are world scaled: u = along/tw, v = (y - y0Base)/th
   */
  box(x0, y0, z0, x1, y1, z1, opts) {
    const V = (x, y, z) => new THREE.Vector3(x, y, z);
    const tw = opts.tw ?? 1, th = opts.th ?? 1, ts = opts.ts ?? 1;
    const vb = opts.vBase ?? y0;
    const side = opts.side;
    const v0 = (y0 - vb) / th, v1 = (y1 - vb) / th;
    const W = x1 - x0, D = z1 - z0;
    if (side) {
      // front (+z)
      this.quad(side, V(x0, y0, z1), V(x1, y0, z1), V(x1, y1, z1), V(x0, y1, z1), [0, v0], [W / tw, v0], [W / tw, v1], [0, v1]);
      // back (-z)
      this.quad(side, V(x1, y0, z0), V(x0, y0, z0), V(x0, y1, z0), V(x1, y1, z0), [0, v0], [W / tw, v0], [W / tw, v1], [0, v1]);
      // right (+x)
      this.quad(side, V(x1, y0, z1), V(x1, y0, z0), V(x1, y1, z0), V(x1, y1, z1), [0, v0], [D / tw, v0], [D / tw, v1], [0, v1]);
      // left (-x)
      this.quad(side, V(x0, y0, z0), V(x0, y0, z1), V(x0, y1, z1), V(x0, y1, z0), [0, v0], [D / tw, v0], [D / tw, v1], [0, v1]);
    }
    if (opts.top) {
      this.quad(opts.top, V(x0, y1, z1), V(x1, y1, z1), V(x1, y1, z0), V(x0, y1, z0),
        [x0 / ts, z1 / ts], [x1 / ts, z1 / ts], [x1 / ts, z0 / ts], [x0 / ts, z0 / ts]);
    }
    if (opts.bottom) {
      this.quad(opts.bottom, V(x0, y0, z0), V(x1, y0, z0), V(x1, y0, z1), V(x0, y0, z1),
        [0, 0], [1, 0], [1, 1], [0, 1]);
    }
  }
  /** Gable roof prism along X (ridge parallel to X) */
  gable(x0, z0, x1, z1, y, h, key, endKey, ts = 4) {
    const V = (x, yy, z) => new THREE.Vector3(x, yy, z);
    const zm = (z0 + z1) / 2;
    const slope = Math.hypot(h, (z1 - z0) / 2);
    const o = 0.5; // overhang
    const X0 = x0 - o, X1 = x1 + o, Z0 = z0 - o, Z1 = z1 + o;
    const hh = h + o * h / ((z1 - z0) / 2);
    const yb = y + h - hh;
    this.quad(key, V(X0, yb, Z1), V(X1, yb, Z1), V(X1, y + h, zm), V(X0, y + h, zm), [0, 0], [(X1 - X0) / ts, 0], [(X1 - X0) / ts, slope / ts], [0, slope / ts]);
    this.quad(key, V(X1, yb, Z0), V(X0, yb, Z0), V(X0, y + h, zm), V(X1, y + h, zm), [0, 0], [(X1 - X0) / ts, 0], [(X1 - X0) / ts, slope / ts], [0, slope / ts]);
    // gable ends (triangles as degenerate quads)
    const D = z1 - z0;
    this.quad(endKey, V(x1, y, z1), V(x1, y, z0), V(x1, y + h, zm), V(x1, y + h, zm), [0, 0], [D / 3, 0], [D / 6, h / 3.2], [D / 6, h / 3.2]);
    this.quad(endKey, V(x0, y, z0), V(x0, y, z1), V(x0, y + h, zm), V(x0, y + h, zm), [0, 0], [D / 3, 0], [D / 6, h / 3.2], [D / 6, h / 3.2]);
  }
  build(materials, group, { castShadow = true, receiveShadow = true } = {}) {
    const meshes = {};
    for (const [key, B] of this.buckets) {
      const g = new THREE.BufferGeometry();
      g.setAttribute('position', new THREE.Float32BufferAttribute(B.p, 3));
      g.setAttribute('normal', new THREE.Float32BufferAttribute(B.n, 3));
      g.setAttribute('uv', new THREE.Float32BufferAttribute(B.uv, 2));
      g.setIndex(B.idx);
      g.computeBoundingSphere();
      const mat = materials[key];
      if (!mat) { console.warn('no material', key); continue; }
      const m = new THREE.Mesh(g, mat);
      m.castShadow = castShadow; m.receiveShadow = receiveShadow;
      m.matrixAutoUpdate = false; m.updateMatrix();
      group.add(m);
      meshes[key] = m;
    }
    return meshes;
  }
}
