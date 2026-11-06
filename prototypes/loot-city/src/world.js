// PROTOTYPE - NOT FOR PRODUCTION
// City generation: roads, blocks, buildings, props, collisions, loot spawn points.
import * as THREE from 'three';
import { GeoBuilder } from './builder.js';
import { M, nightEmissive } from './materials.js';
import { FACADE_TILE_W, FACADE_TILE_H, rng, signTexture } from './textures.js';
import { lampGeometry, treeGeometries, CarFleet, makeKiosk, makePerson } from './props.js';

export const CELL = 72, ROAD = 16, N = 8, HALF = (CELL * N) / 2; // 288
export const SIDEWALK = 3.2, CURB_H = 0.15;
export const roadLine = (k) => -HALF + k * CELL; // road center
export const blockCenter = (i) => -HALF + i * CELL + CELL / 2;
export const districtOf = (x, z) => (x < 0 ? 0 : 1) + (z < 0 ? 2 : 0);
// 0: Окраина (x<0,z>=0), 1: Центр (x>=0,z>=0), 2: Промзона (x<0,z<0), 3: Холмы (x>=0,z<0)
export const blockDistrict = (i, j) => districtOf(blockCenter(i), blockCenter(j));

export const HOME_BLOCK = [3, 5];
export const MARKET_BLOCK = [3, 4];
// plaza blocks hosting NPCs in other districts (all around the central crossing)
export const PLAZA_BLOCKS = { 1: [4, 4], 2: [3, 3], 3: [4, 3] };

const snap = (v, s) => Math.max(s, Math.round(v / s) * s);

export class World {
  constructor(scene) {
    this.scene = scene;
    this.group = new THREE.Group();
    scene.add(this.group);
    this.boxes = []; // collision AABBs {x0,z0,x1,z1,h}
    this.grid = new Map();
    this.spawns = [[], [], [], []]; // loot spawn points per district
    this.npcSpots = {};
    this.barriers = []; // {mesh, a, b}
    this.lightPools = null;
    this.r = rng(1337);
    this.treeSpots = [];
    this.plazas = {};
  }

  addCollider(x0, z0, x1, z1, h = 10) {
    const b = { x0: Math.min(x0, x1), z0: Math.min(z0, z1), x1: Math.max(x0, x1), z1: Math.max(z0, z1), h };
    this.boxes.push(b);
    const G = 24;
    for (let gx = Math.floor(b.x0 / G); gx <= Math.floor(b.x1 / G); gx++)
      for (let gz = Math.floor(b.z0 / G); gz <= Math.floor(b.z1 / G); gz++) {
        const k = gx + ',' + gz;
        if (!this.grid.has(k)) this.grid.set(k, []);
        this.grid.get(k).push(b);
      }
    return b;
  }
  removeCollider(b) {
    if (!b) return;
    b.x0 = b.x1 = b.z0 = b.z1 = 1e9;
  }
  query(x, z) {
    const G = 24;
    const out = [];
    for (let gx = Math.floor(x / G) - 1; gx <= Math.floor(x / G) + 1; gx++)
      for (let gz = Math.floor(z / G) - 1; gz <= Math.floor(z / G) + 1; gz++) {
        const a = this.grid.get(gx + ',' + gz);
        if (a) for (const b of a) out.push(b);
      }
    return out;
  }

  generate(progress) {
    const B = new GeoBuilder();
    this.B = B;
    progress('Прокладываем дороги');
    this.buildGround();
    this.buildMarkings();
    progress('Строим кварталы');
    for (let i = -3; i < N + 3; i++) {
      for (let j = -3; j < N + 3; j++) {
        const inside = i >= 0 && j >= 0 && i < N && j < N;
        this.buildBlock(i, j, inside);
      }
    }
    progress('Собираем геометрию');
    B.build(M, this.group);
    progress('Фонари и деревья');
    this.buildMarket();
    this.buildLamps();
    this.buildTrees();
    this.buildBarriers();
    this.buildCars();
  }

  buildGround() {
    const g = new THREE.PlaneGeometry(2400, 2400, 1, 1).rotateX(-Math.PI / 2);
    const uv = g.attributes.uv;
    for (let i = 0; i < uv.count; i++) uv.setXY(i, uv.getX(i) * 2400 / 9, uv.getY(i) * 2400 / 9);
    const ground = new THREE.Mesh(g, M.asphalt);
    ground.receiveShadow = true;
    this.group.add(ground);
  }

  buildMarkings() {
    // dashed center lines and crosswalks via instancing
    const dashes = [], walks = [];
    for (let k = -2; k <= N + 2; k++) {
      const c = roadLine(k);
      for (let s = -HALF - CELL * 2; s < HALF + CELL * 2; s += CELL) {
        // segment between intersections from s+ROAD/2+3 .. s+CELL-ROAD/2-3
        for (let t = s + ROAD / 2 + 4; t < s + CELL - ROAD / 2 - 4; t += 6) {
          dashes.push([c, t + 1.5, 0]); // vertical road (along z) at x=c
          dashes.push([t + 1.5, c, 1]); // horizontal road at z=c
        }
      }
    }
    for (let a = -1; a <= N + 1; a++) for (let b = -1; b <= N + 1; b++) {
      const x = roadLine(a), z = roadLine(b);
      for (let q = -4; q <= 4; q++) {
        walks.push([x + q * 1.0, z + ROAD / 2 - 1.2, 0]);
        walks.push([x + q * 1.0, z - ROAD / 2 + 1.2, 0]);
        walks.push([x + ROAD / 2 - 1.2, z + q * 1.0, 1]);
        walks.push([x - ROAD / 2 + 1.2, z + q * 1.0, 1]);
      }
    }
    const dg = new THREE.PlaneGeometry(0.15, 3).rotateX(-Math.PI / 2);
    const dm = new THREE.InstancedMesh(dg, M.markingYellow, dashes.length);
    const wg = new THREE.PlaneGeometry(0.5, 2.4).rotateX(-Math.PI / 2);
    const wm = new THREE.InstancedMesh(wg, M.marking, walks.length);
    const m4 = new THREE.Matrix4();
    dashes.forEach(([x, z, rot], i) => { m4.makeRotationY(rot ? Math.PI / 2 : 0); m4.setPosition(x, 0.012, z); dm.setMatrixAt(i, m4); });
    walks.forEach(([x, z, rot], i) => { m4.makeRotationY(rot ? Math.PI / 2 : 0); m4.setPosition(x, 0.012, z); wm.setMatrixAt(i, m4); });
    dm.receiveShadow = wm.receiveShadow = true;
    this.group.add(dm, wm);
  }

  building(x0, z0, w, d, h, facade, roofKey = 'roof', collide = true, opts = {}) {
    const B = this.B;
    const x1 = x0 + w, z1 = z0 + d;
    // base floor band (slightly darker concrete plinth)
    B.box(x0 - 0.05, 0, z0 - 0.05, x1 + 0.05, 0.6, z1 + 0.05, { side: 'concrete', tw: 4, th: 4 });
    B.box(x0, 0.6, z0, x1, h, z1, { side: facade, top: roofKey, tw: FACADE_TILE_W, th: FACADE_TILE_H, ts: 6, vBase: 0 });
    if (!opts.noParapet && roofKey === 'roof') {
      // parapet
      const p = 0.35, ph = 0.9;
      B.box(x0 - 0.1, h, z0 - 0.1, x1 + 0.1, h + ph, z0 + p, { side: 'concrete', top: 'concrete', tw: 4, th: 4, ts: 4 });
      B.box(x0 - 0.1, h, z1 - p, x1 + 0.1, h + ph, z1 + 0.1, { side: 'concrete', top: 'concrete', tw: 4, th: 4, ts: 4 });
      B.box(x0 - 0.1, h, z0 + p, x0 + p, h + ph, z1 - p, { side: 'concrete', top: 'concrete', tw: 4, th: 4, ts: 4 });
      B.box(x1 - p, h, z0 + p, x1 + 0.1, h + ph, z1 - p, { side: 'concrete', top: 'concrete', tw: 4, th: 4, ts: 4 });
      // rooftop units
      const n = 1 + Math.floor(this.r() * 3);
      for (let k = 0; k < n; k++) {
        const uw = 1.5 + this.r() * 2.5, ud = 1.5 + this.r() * 2;
        const ux = x0 + 1 + this.r() * Math.max(0.1, w - uw - 2), uz = z0 + 1 + this.r() * Math.max(0.1, d - ud - 2);
        B.box(ux, h, uz, ux + uw, h + 1 + this.r() * 1.5, uz + ud, { side: 'metal', top: 'metal', tw: 2, th: 2, ts: 2 });
      }
    }
    if (collide) this.addCollider(x0 - 0.1, z0 - 0.1, x1 + 0.1, z1 + 0.1, h);
  }

  buildBlock(i, j, inside) {
    const B = this.B, r = this.r;
    const bx0 = roadLine(i) + ROAD / 2, bz0 = roadLine(j) + ROAD / 2;
    const bx1 = roadLine(i + 1) - ROAD / 2, bz1 = roadLine(j + 1) - ROAD / 2;
    const dist = districtOf((bx0 + bx1) / 2, (bz0 + bz1) / 2);
    // sidewalk slab + curb
    B.box(bx0, 0, bz0, bx1, CURB_H, bz1, { side: 'curb', top: 'pavers', tw: 2, th: 2, ts: 1.6 });
    const ix0 = bx0 + SIDEWALK, iz0 = bz0 + SIDEWALK, ix1 = bx1 - SIDEWALK, iz1 = bz1 - SIDEWALK;
    const ground = ['dirt', 'pavers', 'concrete', 'grass'][dist];
    const lotTop = (key) => B.box(ix0, CURB_H, iz0, ix1, CURB_H + 0.02, iz1, { top: key, ts: key === 'pavers' ? 1.6 : 6 });

    if (!inside) {
      // distant skyline (no detail, no collisions)
      lotTop(ground);
      const style = dist === 1 || dist === 3 ? (r() < 0.5 ? 'f_glass' : 'f_darkglass') : r() < 0.5 ? 'f_plaster2' : 'f_brick2';
      const tall = dist === 1 ? 30 + r() * 90 : dist === 3 ? 20 + r() * 60 : 10 + r() * 25;
      const w = snap(30 + r() * 15, 3), d = snap(30 + r() * 15, 3);
      this.building(ix0 + 2, iz0 + 2, w, d, snap(tall, 3.2), style, 'roof', false);
      return;
    }
    const isHome = i === HOME_BLOCK[0] && j === HOME_BLOCK[1];
    const isMarket = i === MARKET_BLOCK[0] && j === MARKET_BLOCK[1];
    if (isHome) { lotTop('grass'); this.homeLot = { x0: ix0, z0: iz0, x1: ix1, z1: iz1 }; this.addSidewalkSpawns(bx0, bz0, bx1, bz1, dist, 4); return; }
    const plazaD = Object.entries(PLAZA_BLOCKS).find(([, b]) => b[0] === i && b[1] === j);
    if (plazaD) {
      lotTop('pavers'); this.plazas[plazaD[0]] = { x0: ix0, z0: iz0, x1: ix1, z1: iz1 };
      this.treeSpots.push([ix0 + 3, iz0 + 3, 1.2], [ix1 - 3, iz0 + 3, 1.2], [ix0 + 3, iz1 - 3, 1.2], [ix1 - 3, iz1 - 3, 1.2]);
      for (let k = 0; k < 4; k++) this.spawns[dist].push(new THREE.Vector3(ix0 + 6 + r() * (ix1 - ix0 - 12), CURB_H, iz0 + 6 + r() * (iz1 - iz0 - 12)));
      this.addSidewalkSpawns(bx0, bz0, bx1, bz1, dist, 3); return;
    }
    if (isMarket) { lotTop('pavers'); this.marketLot = { x0: ix0, z0: iz0, x1: ix1, z1: iz1 }; this.addSidewalkSpawns(bx0, bz0, bx1, bz1, dist, 3); return; }
    lotTop(ground);
    this.addSidewalkSpawns(bx0, bz0, bx1, bz1, dist, 6);
    const W = ix1 - ix0; // 49.6
    if (dist === 0) {
      // 2x2 sub-lots of old houses / garages / empty lots
      for (let a = 0; a < 2; a++) for (let b = 0; b < 2; b++) {
        const sx0 = ix0 + a * W / 2, sz0 = iz0 + b * W / 2, sw = W / 2;
        const roll = r();
        if (roll < 0.62) {
          const w = snap(12 + r() * 9, 3), d = snap(12 + r() * 9, 3);
          const fl = 2 + Math.floor(r() * 4);
          const bx = a === 0 ? sx0 + 0.5 : sx0 + sw - w - 0.5;
          const bz = b === 0 ? sz0 + 0.5 : sz0 + sw - d - 0.5;
          const fac = ['f_brick', 'f_brick2', 'f_plaster', 'f_plaster2'][Math.floor(r() * 4)];
          this.building(bx, bz, w, d, fl * 3.2 + 0.6, fac);
          // spawn in yard behind
          this.spawns[0].push(new THREE.Vector3(a === 0 ? bx + w + 2 : bx - 2, CURB_H, bz + d / 2));
          this.dumpster(a === 0 ? bx + w + 1.5 : bx - 3, b === 0 ? bz + d + 1.5 : bz - 2.5, 0);
        } else if (roll < 0.82) {
          // row of garages
          const gw = 3.6, n = 5;
          for (let k = 0; k < n; k++) {
            const gx = sx0 + 2 + k * gw;
            this.B.box(gx, CURB_H, sz0 + 2, gx + gw - 0.1, 2.8, sz0 + 8, { side: 'f_metal', top: 'roof', tw: 6, th: 6.4, ts: 4 });
          }
          this.addCollider(sx0 + 2, sz0 + 2, sx0 + 2 + n * gw, sz0 + 8, 2.8);
          for (let k = 0; k < 3; k++) this.spawns[0].push(new THREE.Vector3(sx0 + 4 + r() * 14, CURB_H, sz0 + 10 + r() * 10));
        } else {
          // empty lot with junk
          for (let k = 0; k < 4; k++) this.spawns[0].push(new THREE.Vector3(sx0 + 3 + r() * (sw - 6), CURB_H, sz0 + 3 + r() * (sw - 6)));
          this.treeSpots.push([sx0 + sw / 2 + (r() - 0.5) * 8, sz0 + sw / 2 + (r() - 0.5) * 8, 0.8 + r() * 0.5]);
        }
      }
    } else if (dist === 1) {
      const roll = r();
      if (roll < 0.45) {
        const w = snap(30 + r() * 12, 3), d = snap(30 + r() * 12, 3);
        const fl = 10 + Math.floor(r() * 22);
        const x = ix0 + (W - w) / 2, z = iz0 + (W - d) / 2;
        // podium + tower
        this.building(ix0 + 1, iz0 + 1, W - 2, W - 2, 2 * 3.2 + 0.6, 'f_glass', 'roof', true, { noParapet: true });
        this.building(x, z, w, d, fl * 3.2 + 0.6, r() < 0.5 ? 'f_glass' : 'f_darkglass', 'roof', false);
        this.addCollider(x, z, x + w, z + d, fl * 3.2);
      } else {
        for (let a = 0; a < 2; a++) {
          const w = snap(18 + r() * 4, 3), d = snap(36 + r() * 8, 3);
          const fl = 5 + Math.floor(r() * 16);
          const x = a === 0 ? ix0 + 1 : ix1 - w - 1, z = iz0 + (W - d) / 2;
          this.building(x, z, w, d, fl * 3.2 + 0.6, ['f_glass', 'f_darkglass', 'f_plaster'][Math.floor(r() * 3)]);
        }
        // plaza between
        for (let k = 0; k < 4; k++) this.spawns[1].push(new THREE.Vector3(ix0 + W / 2 + (r() - 0.5) * 6, CURB_H, iz0 + 4 + r() * (W - 8)));
        this.treeSpots.push([ix0 + W / 2, iz0 + 6, 1.0], [ix0 + W / 2, iz1 - 6, 1.0]);
      }
    } else if (dist === 2) {
      const roll = r();
      if (roll < 0.6) {
        const w = snap(36 + r() * 8, 3), d = snap(22 + r() * 6, 3);
        const x = ix0 + 1, z = iz0 + 1;
        this.building(x, z, w, d, 9.6 + r() * 3.2, r() < 0.5 ? 'f_metal' : 'f_metal2');
        // container yard
        for (let k = 0; k < 6; k++) {
          const cx = ix0 + 3 + k * 7.5, cz = iz1 - 9;
          const stack = 1 + Math.floor(r() * 3);
          for (let s = 0; s < stack; s++) this.containerAt(cx, cz, s);
          this.addCollider(cx - 1.25, cz - 3.05, cx + 1.25, cz + 3.05, stack * 2.6);
        }
        for (let k = 0; k < 6; k++) this.spawns[2].push(new THREE.Vector3(ix0 + 3 + r() * (W - 6), CURB_H, z + d + 2 + r() * 8));
      } else {
        for (let a = 0; a < 2; a++) {
          const w = snap(20, 3), d = snap(44, 3);
          const x = a === 0 ? ix0 + 1 : ix1 - w - 1;
          this.building(x, iz0 + 2, w, d, 8 + r() * 6, a ? 'f_metal' : 'f_metal2');
        }
        for (let k = 0; k < 5; k++) this.spawns[2].push(new THREE.Vector3(ix0 + W / 2 + (r() - 0.5) * 4, CURB_H, iz0 + 3 + r() * (W - 6)));
        this.dumpster(ix0 + W / 2 - 1, iz0 + 6, 1);
        this.dumpster(ix0 + W / 2 - 1, iz1 - 8, 1);
      }
    } else {
      const roll = r();
      if (roll < 0.25) {
        const w = 27, d = 27, fl = 18 + Math.floor(r() * 20);
        const x = ix0 + (W - w) / 2, z = iz0 + (W - d) / 2;
        this.building(x, z, w, d, fl * 3.2 + 0.6, 'f_darkglass');
        this.treeSpots.push([ix0 + 4, iz0 + 4, 1.2], [ix1 - 4, iz0 + 4, 1.2], [ix0 + 4, iz1 - 4, 1.2], [ix1 - 4, iz1 - 4, 1.2]);
        for (let k = 0; k < 4; k++) this.spawns[3].push(new THREE.Vector3(ix0 + 2 + r() * 6, CURB_H, iz0 + 8 + r() * 30));
      } else {
        // 2 villas with pools and hedges
        for (let a = 0; a < 2; a++) {
          const sx0 = ix0 + a * W / 2, sw = W / 2;
          const w = snap(14 + r() * 4, 3), d = snap(12 + r() * 4, 3);
          const x = sx0 + (sw - w) / 2, z = iz0 + 3;
          this.building(x, z, w, d, 3.2 * (2 + Math.floor(r() * 2)) + 0.6, 'f_villa', 'roof', true);
          // pool
          const px = sx0 + 4, pz = iz0 + d + 7;
          B.box(px - 0.4, CURB_H, pz - 0.4, px + sw - 7.6, CURB_H + 0.3, pz + 6.4, { side: 'pavers', top: 'pavers', tw: 2, th: 2, ts: 2 });
          const water = new THREE.Mesh(new THREE.PlaneGeometry(sw - 8, 6).rotateX(-Math.PI / 2), M.water);
          water.position.set(px + (sw - 8) / 2, CURB_H + 0.33, pz + 3); water.receiveShadow = true;
          this.group.add(water);
          this.addCollider(px - 0.4, pz - 0.4, px + sw - 7.6, pz + 6.4, 0.6);
          // hedge
          B.box(sx0 + 0.3, CURB_H, iz1 - 1.3, sx0 + sw - 0.3, 1.5, iz1 - 0.3, { side: 'grass', top: 'grass', tw: 3, th: 3, ts: 3 });
          this.addCollider(sx0 + 0.3, iz1 - 1.3, sx0 + sw - 0.3, iz1 - 0.3, 1.5);
          this.treeSpots.push([sx0 + 2.5, iz0 + 2.5, 1.1 + r() * 0.3], [sx0 + sw - 2.5, iz1 - 4, 1.1 + r() * 0.3]);
          for (let k = 0; k < 3; k++) this.spawns[3].push(new THREE.Vector3(sx0 + 2 + r() * (sw - 4), CURB_H, pz + 8 + r() * 3));
        }
      }
    }
  }

  addSidewalkSpawns(bx0, bz0, bx1, bz1, dist, n) {
    const r = this.r;
    for (let k = 0; k < n; k++) {
      const side = Math.floor(r() * 4), t = 4 + r() * (bx1 - bx0 - 8);
      const o = 1 + r() * (SIDEWALK - 1.5);
      const p = side === 0 ? [bx0 + t, bz0 + o] : side === 1 ? [bx0 + t, bz1 - o] : side === 2 ? [bx0 + o, bz0 + t] : [bx1 - o, bz0 + t];
      this.spawns[dist].push(new THREE.Vector3(p[0], CURB_H, p[1]));
    }
  }

  dumpster(x, z, dist) {
    const g = new THREE.Group();
    const body = new THREE.Mesh(new THREE.BoxGeometry(2.0, 1.2, 1.2), M.dumpster); body.position.y = 0.6 + CURB_H;
    const lid = new THREE.Mesh(new THREE.BoxGeometry(2.05, 0.08, 1.3), M.darkMetal); lid.position.set(0, 1.25 + CURB_H, -0.05); lid.rotation.x = -0.08;
    g.add(body, lid);
    g.position.set(x + 1, 0, z + 0.6);
    g.traverse((o) => { if (o.isMesh) { o.castShadow = o.receiveShadow = true; } });
    this.group.add(g);
    this.addCollider(x, z, x + 2, z + 1.2, 1.3);
    this.spawns[districtOf(x, z)].push(new THREE.Vector3(x + 1, CURB_H, z + 2.2));
  }

  containerAt(cx, cz, s) {
    if (!this.containerGeo) {
      this.containerGeo = new THREE.BoxGeometry(2.44, 2.59, 6.06);
      this.containerList = [];
    }
    this.containerList.push([cx, cz, s]);
  }

  buildLamps() {
    const spots = [];
    for (let k = 0; k <= N; k++) {
      const c = roadLine(k);
      for (let s = 0; s < N; s++) {
        const a = roadLine(s) + ROAD / 2 + 6, b = roadLine(s + 1) - ROAD / 2 - 6;
        for (let t = a; t <= b; t += 22) {
          spots.push([c + ROAD / 2 + 0.6, t, Math.PI]); // along vertical road, east side, arm points west
          spots.push([c - ROAD / 2 - 0.6, t + 11, 0]);
          spots.push([t, c + ROAD / 2 + 0.6, Math.PI / 2]);
          spots.push([t + 11, c - ROAD / 2 - 0.6, -Math.PI / 2]);
        }
      }
    }
    const { g, bulb } = lampGeometry();
    const poles = new THREE.InstancedMesh(g, M.darkMetal, spots.length);
    const bulbs = new THREE.InstancedMesh(bulb, M.lampBulb, spots.length);
    const pg = new THREE.PlaneGeometry(9, 9).rotateX(-Math.PI / 2);
    const pools = new THREE.InstancedMesh(pg, M.lightPool, spots.length);
    const m4 = new THREE.Matrix4(), q = new THREE.Quaternion(), s1 = new THREE.Vector3(1, 1, 1);
    spots.forEach(([x, z, yaw], i) => {
      m4.compose(new THREE.Vector3(x, CURB_H, z), q.setFromAxisAngle(new THREE.Vector3(0, 1, 0), yaw), s1);
      poles.setMatrixAt(i, m4); bulbs.setMatrixAt(i, m4);
      const hx = x + Math.cos(yaw) * 1.65, hz = z - Math.sin(yaw) * 1.65;
      m4.makeTranslation(hx, 0.03, hz);
      pools.setMatrixAt(i, m4);
      this.addCollider(x - 0.2, z - 0.2, x + 0.2, z + 0.2, 7);
    });
    poles.castShadow = true; poles.receiveShadow = true;
    this.group.add(poles, bulbs, pools);
    this.lightPools = pools;
    this.lampSpots = spots;
  }

  buildTrees() {
    // sidewalk trees in center & hills
    for (let i = 0; i < N; i++) for (let j = 0; j < N; j++) {
      const d = blockDistrict(i, j);
      if (d === 1 || d === 3 || (d === 0 && this.r() < 0.4)) {
        const bx0 = roadLine(i) + ROAD / 2, bx1 = roadLine(i + 1) - ROAD / 2;
        const bz0 = roadLine(j) + ROAD / 2;
        for (let t = bx0 + 6; t < bx1 - 4; t += 13) this.treeSpots.push([t, bz0 + 1.4, 0.9 + this.r() * 0.3]);
      }
    }
    const { trunkG, leavesG } = treeGeometries(3);
    const n = this.treeSpots.length;
    const trunks = new THREE.InstancedMesh(trunkG, M.bark, n);
    const leaves = new THREE.InstancedMesh(leavesG, M.leaves, n);
    const m4 = new THREE.Matrix4(), q = new THREE.Quaternion();
    const col = new THREE.Color();
    this.treeSpots.forEach(([x, z, s], i) => {
      q.setFromAxisAngle(new THREE.Vector3(0, 1, 0), this.r() * 6.28);
      m4.compose(new THREE.Vector3(x, CURB_H, z), q, new THREE.Vector3(s, s * (0.9 + this.r() * 0.3), s));
      trunks.setMatrixAt(i, m4); leaves.setMatrixAt(i, m4);
      col.setHSL(0.22 + this.r() * 0.08, 0.45, 0.42 + this.r() * 0.15);
      leaves.setColorAt(i, col);
      this.addCollider(x - 0.25, z - 0.25, x + 0.25, z + 0.25, 4);
    });
    trunks.castShadow = leaves.castShadow = true;
    trunks.receiveShadow = leaves.receiveShadow = true;
    this.group.add(trunks, leaves);
    // containers (instanced, colored)
    if (this.containerList) {
      const cm = new THREE.InstancedMesh(this.containerGeo, M.container, this.containerList.length);
      const cols = [0xb5442c, 0x2b5d8c, 0x2d6b3b, 0xc7922e, 0x6b6f73, 0x8c2b2b];
      this.containerList.forEach(([x, z, s], i) => {
        m4.makeRotationY((this.r() - 0.5) * 0.06); m4.setPosition(x, CURB_H + 1.3 + s * 2.6, z);
        cm.setMatrixAt(i, m4); cm.setColorAt(i, col.set(cols[Math.floor(this.r() * cols.length)]));
      });
      cm.castShadow = cm.receiveShadow = true;
      this.group.add(cm);
    }
  }

  /** Concrete jersey barriers on boundary roads; one group per district edge */
  buildBarriers() {
    const geo = new THREE.BoxGeometry(0.6, 1.0, 3.0);
    const top = new THREE.BoxGeometry(0.62, 0.15, 3.02);
    const mkLine = (along, fixed, from, to, a, b) => {
      const pts = [];
      for (let t = from; t < to; t += 3.1) pts.push(t);
      const m = new THREE.InstancedMesh(geo, M.barrier, pts.length);
      const s = new THREE.InstancedMesh(top, M.stripe, pts.length);
      const m4 = new THREE.Matrix4();
      pts.forEach((t, i) => {
        if (along === 'z') { m4.makeTranslation(fixed, 0.5, t); } else { m4.makeRotationY(Math.PI / 2); m4.setPosition(t, 0.5, fixed); }
        m.setMatrixAt(i, m4);
        m4.elements[13] = 1.05; s.setMatrixAt(i, m4);
      });
      m.castShadow = m.receiveShadow = true;
      const grp = new THREE.Group(); grp.add(m, s);
      // warning signs
      const tex = signTexture('ПРОХОД ЗАКРЫТ', '#7a0c0c', '#ffffff', 1024, 256, 'Купите разрешение в мэрии');
      const sm = new THREE.MeshStandardMaterial({ map: tex, emissiveMap: tex, emissive: 0xffffff, emissiveIntensity: 0.3, side: THREE.DoubleSide });
      for (let k = 0; k <= N; k++) {
        const t = roadLine(k);
        if (t <= from + 4 || t >= to - 4) continue;
        const sign = new THREE.Mesh(new THREE.PlaneGeometry(4, 1), sm);
        if (along === 'z') { sign.position.set(fixed, 1.9, t); sign.rotation.y = Math.PI / 2; }
        else { sign.position.set(t, 1.9, fixed); }
        grp.add(sign);
      }
      this.group.add(grp);
      this.barriers.push({ grp, a, b, along, fixed, from, to });
    };
    // vertical boundary x=0: z>0 separates 0|1, z<0 separates 2|3
    mkLine('z', 0, 0, HALF + 8, 0, 1);
    mkLine('z', 0, -HALF - 8, 0, 2, 3);
    mkLine('x', 0, -HALF - 8, 0, 0, 2);
    mkLine('x', 0, 0, HALF + 8, 1, 3);
  }

  updateBarriers(unlocked) {
    for (const b of this.barriers) b.grp.visible = !(unlocked[b.a] && unlocked[b.b]);
  }

  buildCars() {
    // parked cars along curbs + moving traffic
    this.parked = [];
    for (let k = 0; k <= N; k++) {
      const c = roadLine(k);
      for (let s = 0; s < N; s++) {
        const a = roadLine(s) + ROAD / 2 + 8, b = roadLine(s + 1) - ROAD / 2 - 8;
        for (let t = a; t < b; t += 7) {
          if (this.r() < 0.22) this.parked.push([c + 6.3, t, Math.PI / 2]);
          if (this.r() < 0.22) this.parked.push([c - 6.3, t, -Math.PI / 2]);
          if (this.r() < 0.22) this.parked.push([t, c + 6.3, Math.PI]);
          if (this.r() < 0.22) this.parked.push([t, c - 6.3, 0]);
        }
      }
    }
    this.trafficCount = 26;
    this.fleet = new CarFleet(this.group, this.parked.length + this.trafficCount);
    this.parked.forEach(([x, z, yaw], i) => {
      this.fleet.set(i, x, z, yaw);
      const along = Math.abs(Math.sin(yaw)) > 0.5; // car oriented along z
      if (along) this.addCollider(x - 1.0, z - 2.3, x + 1.0, z + 2.3, 1.5);
      else this.addCollider(x - 2.3, z - 1.0, x + 2.3, z + 1.0, 1.5);
    });
    // traffic agents on lanes, each confined to a quadrant (never crosses district barriers)
    this.traffic = [];
    for (let t = 0; t < this.trafficCount; t++) {
      const q = t % 4;
      const sx = q === 0 || q === 2 ? -1 : 1, sz = q >= 2 ? -1 : 1;
      const lines = sx < 0 ? [0, 1, 2, 3] : [5, 6, 7, 8];
      const linesZ = sz < 0 ? [0, 1, 2, 3] : [5, 6, 7, 8];
      const horiz = this.r() < 0.5;
      const pool = horiz ? linesZ : lines;
      const line = pool[Math.floor(this.r() * 4)];
      const lo = (horiz ? sx : sz) < 0 ? -HALF - 30 : 12, hi = (horiz ? sx : sz) < 0 ? -12 : HALF + 30;
      this.traffic.push({ sx, sz, horiz, line, dir: this.r() < 0.5 ? 1 : -1, pos: lo + this.r() * (hi - lo), speed: 9 + this.r() * 5, cur: 0, idx: this.parked.length + t });
    }
    this.fleet.flush();
  }

  _range(c) {
    const s = c.horiz ? c.sx : c.sz;
    return s < 0 ? [-HALF - 30, -12] : [12, HALF + 30];
  }

  updateTraffic(dt, player) {
    for (const c of this.traffic) {
      const base = roadLine(c.line);
      let x = c.horiz ? c.pos : base - 2.3 * c.dir, z = c.horiz ? base + 2.3 * c.dir : c.pos;
      const ax = c.horiz ? x + c.dir * 6 : x, az = c.horiz ? z : z + c.dir * 6;
      const dp = Math.hypot(player.x - ax, player.z - az);
      const target = dp < 5.5 ? 0 : c.speed;
      c.cur += (target - c.cur) * Math.min(1, dt * (target < c.cur ? 5 : 0.8));
      const prev = c.pos;
      c.pos += c.dir * c.cur * dt;
      const [lo, hi] = this._range(c);
      if (c.pos > hi) { c.pos = hi; c.dir = -1; }
      if (c.pos < lo) { c.pos = lo; c.dir = 1; }
      const k0 = Math.floor((prev + HALF) / CELL), k1 = Math.floor((c.pos + HALF) / CELL);
      if (k0 !== k1) {
        const kk = c.dir > 0 ? k1 : k0;
        const otherSign = c.horiz ? c.sx : c.sz; // crossing road kk lies on travel axis
        const valid = kk >= 0 && kk <= N && kk !== N / 2 && (otherSign < 0 ? kk < N / 2 : kk > N / 2);
        if (valid && this.r() < 0.4) {
          const oldBase = roadLine(c.line);
          c.horiz = !c.horiz; c.line = kk; c.pos = oldBase;
          c.dir = this.r() < 0.5 ? 1 : -1;
          const [lo2, hi2] = this._range(c);
          if (c.pos + c.dir * 20 > hi2) c.dir = -1;
          if (c.pos + c.dir * 20 < lo2) c.dir = 1;
        }
      }
      const b2 = roadLine(c.line);
      x = c.horiz ? c.pos : b2 - 2.3 * c.dir; z = c.horiz ? b2 + 2.3 * c.dir : c.pos;
      const yaw = c.horiz ? (c.dir > 0 ? 0 : Math.PI) : (c.dir > 0 ? -Math.PI / 2 : Math.PI / 2);
      this.fleet.set(c.idx, x, z, yaw);
      c.x = x; c.z = z; c.yaw = yaw;
    }
    this.fleet.flushFast();
  }

  buildMarket() {
    // NPC kiosks in market block
    const L = this.marketLot;
    const cx = (L.x0 + L.x1) / 2, cz = (L.z0 + L.z1) / 2;
    this.npcSpots = {
      pawn: { x: cx - 14, z: cz - 14, yaw: 0, sign: 'ЛОМБАРД', color: 0x8a1c1c },
      gear: { x: cx, z: cz - 14, yaw: 0, sign: 'СНАРЯЖЕНИЕ', color: 0x1c5a8a },
      garage: { x: cx + 14, z: cz - 14, yaw: 0, sign: 'ТРАНСПОРТ', color: 0x333333 },
      broker: { x: cx - 14, z: cz + 12, yaw: Math.PI, sign: 'БИЗНЕС', color: 0x1c6a3a },
      mayor: { x: cx, z: cz + 12, yaw: Math.PI, sign: 'МЭРИЯ', color: 0x5a4a1c },
      quest0: { x: cx + 14, z: cz + 12, yaw: Math.PI, sign: 'ЗАКАЗЫ', color: 0x6a2c6a },
    };
    // fountain in the middle of the market
    const base = new THREE.Mesh(new THREE.CylinderGeometry(4, 4.2, 0.6, 40), M.curb); base.position.set(cx, CURB_H + 0.3, cz);
    const water = new THREE.Mesh(new THREE.CylinderGeometry(3.7, 3.7, 0.05, 40), M.water); water.position.set(cx, CURB_H + 0.55, cz);
    const col = new THREE.Mesh(new THREE.CylinderGeometry(0.4, 0.6, 2.2, 16), M.curb); col.position.set(cx, CURB_H + 1.4, cz);
    const bowl = new THREE.Mesh(new THREE.CylinderGeometry(1.5, 0.5, 0.4, 32), M.curb); bowl.position.set(cx, CURB_H + 2.6, cz);
    for (const m of [base, water, col, bowl]) { m.castShadow = m.receiveShadow = true; this.group.add(m); }
    this.addCollider(cx - 4, cz - 4, cx + 4, cz + 4, 1);
    // benches
    for (const [bx, bz, yaw] of [[cx - 7, cz, Math.PI / 2], [cx + 7, cz, -Math.PI / 2]]) {
      const b = this.bench(); b.position.set(bx, CURB_H, bz); b.rotation.y = yaw; this.group.add(b);
      this.addCollider(bx - 0.5, bz - 1, bx + 0.5, bz + 1, 0.8);
    }
    this.treeSpots.push([L.x0 + 3, L.z0 + 3, 1.2], [L.x1 - 3, L.z0 + 3, 1.2], [L.x0 + 3, L.z1 - 3, 1.2], [L.x1 - 3, L.z1 - 3, 1.2]);
  }

  bench() {
    const g = new THREE.Group();
    for (let k = 0; k < 4; k++) { const s = new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.04, 1.8), M.wood); s.position.set(-0.2 + k * 0.12, 0.45, 0); g.add(s); }
    for (let k = 0; k < 2; k++) { const s = new THREE.Mesh(new THREE.BoxGeometry(0.04, 0.1, 1.8), M.wood); s.position.set(0.25, 0.65 + k * 0.14, 0); g.add(s); }
    for (const z of [-0.8, 0.8]) { const l = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.45, 0.06), M.darkMetal); l.position.set(0, 0.22, z); g.add(l); }
    g.traverse((o) => { if (o.isMesh) o.castShadow = o.receiveShadow = true; });
    return g;
  }

  /** Place a kiosk + NPC at a spot (also used for remote districts). */
  placeNPC(spot, personOpts) {
    const k = makeKiosk(signTexture(spot.sign, '#111', '#ffe08a'), spot.color);
    k.position.set(spot.x, CURB_H, spot.z); k.rotation.y = spot.yaw;
    this.group.add(k);
    nightEmissive.push({ mat: k.userData.signMat, max: 2.5, min: 0.25 });
    const p = makePerson(personOpts);
    const off = new THREE.Vector3(0, 0, -0.9).applyAxisAngle(new THREE.Vector3(0, 1, 0), spot.yaw);
    p.position.set(spot.x + off.x, CURB_H, spot.z + off.z); p.rotation.y = spot.yaw;
    this.group.add(p);
    const c = Math.cos(spot.yaw), s = Math.sin(spot.yaw);
    // collider covering kiosk footprint (rotations are multiples of 90°)
    const hw = Math.abs(c) > 0.5 ? 1.8 : 1.8, hd = 1.8;
    this.addCollider(spot.x - hw, spot.z - hd, spot.x + hw, spot.z + hd, 3);
    void s;
    // interaction point in front of the counter
    const front = new THREE.Vector3(0, 0, 1.9).applyAxisAngle(new THREE.Vector3(0, 1, 0), spot.yaw);
    return { person: p, kiosk: k, ix: spot.x + front.x, iz: spot.z + front.z };
  }
}
