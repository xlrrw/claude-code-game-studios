// PROTOTYPE - NOT FOR PRODUCTION
// Player home: building stages + decorations on the home lot.
import * as THREE from 'three';
import { GeoBuilder } from './builder.js';
import { M, nightEmissive } from './materials.js';
import { FACADE_TILE_W, FACADE_TILE_H, signTexture } from './textures.js';
import { CURB_H } from './world.js';
import { treeGeometries } from './props.js';

export class Home {
  constructor(world) {
    this.world = world;
    const L = world.homeLot;
    this.L = L;
    this.cx = (L.x0 + L.x1) / 2; this.cz = (L.z0 + L.z1) / 2;
    this.group = new THREE.Group(); world.group.add(this.group);
    this.stageGroup = null; this.stageCollider = [];
    this.decor = {};
    this.decorColliders = {};
    // front of the lot faces -z (towards the market)
    const tex = signTexture('ВАШ УЧАСТОК', '#13361d', '#d8ffd8', 1024, 256, 'Прораб Степаныч строит под ключ');
    const sm = new THREE.MeshStandardMaterial({ map: tex, roughness: 0.6 });
    const sign = new THREE.Mesh(new THREE.PlaneGeometry(3, 0.75), sm);
    sign.position.set(this.cx + 8, CURB_H + 1.9, L.z0 + 1.5);
    sign.rotation.y = Math.PI;
    const post = new THREE.Mesh(new THREE.BoxGeometry(0.1, 1.9, 0.1), M.wood); post.position.set(this.cx + 8, CURB_H + 0.95, L.z0 + 1.52);
    this.group.add(sign, post);
    this.foremanSpot = { x: this.cx - 8, z: L.z0 + 4, yaw: Math.PI, sign: 'СТРОЙКА', color: 0xc77a1c };
  }

  clearStage() {
    if (this.stageGroup) { this.group.remove(this.stageGroup); }
    for (const c of this.stageCollider) this.world.removeCollider(c);
    this.stageCollider = [];
  }

  setStage(s) {
    this.clearStage();
    const g = new THREE.Group(); this.stageGroup = g; this.group.add(g);
    const B = new GeoBuilder();
    const cx = this.cx, cz = this.cz + 4;
    const col = (x0, z0, x1, z1, h) => this.stageCollider.push(this.world.addCollider(x0, z0, x1, z1, h));
    const y0 = CURB_H;
    if (s === 1) {
      const fabric = new THREE.MeshStandardMaterial({ color: 0xd06a1c, roughness: 0.85, side: THREE.DoubleSide });
      const tent = new THREE.Mesh(new THREE.ConeGeometry(1.8, 2.0, 4, 1, true), fabric);
      tent.rotation.y = Math.PI / 4; tent.position.set(cx, y0 + 1.0, cz); tent.castShadow = tent.receiveShadow = true;
      g.add(tent);
      const fire = new THREE.Mesh(new THREE.CylinderGeometry(0.4, 0.5, 0.2, 10), M.concrete); fire.position.set(cx + 3, y0 + 0.1, cz - 2); g.add(fire);
      const flame = new THREE.Mesh(new THREE.ConeGeometry(0.22, 0.6, 8), new THREE.MeshStandardMaterial({ color: 0xff7a20, emissive: 0xff6a10, emissiveIntensity: 3 })); flame.position.set(cx + 3, y0 + 0.5, cz - 2); g.add(flame);
      col(cx - 1.4, cz - 1.4, cx + 1.4, cz + 1.4, 2);
    } else if (s === 2) {
      B.box(cx - 3.5, y0 + 0.5, cz - 1.3, cx + 3.5, y0 + 3.1, cz + 1.3, { side: 'f_metal2', top: 'metal', tw: FACADE_TILE_W / 2, th: FACADE_TILE_H / 2, ts: 3 });
      for (const x of [-2.2, 2.2]) for (const z of [-1.3, 1.3]) { const w = new THREE.Mesh(new THREE.CylinderGeometry(0.4, 0.4, 0.25, 16).rotateX(Math.PI / 2), M.tire); w.position.set(cx + x, y0 + 0.4, cz + z); g.add(w); }
      col(cx - 3.5, cz - 1.4, cx + 3.5, cz + 1.4, 3.1);
    } else if (s === 3) {
      B.box(cx - 5, y0, cz - 4, cx + 5, y0 + 3.8, cz + 4, { side: 'f_brick', tw: FACADE_TILE_W, th: FACADE_TILE_H });
      B.gable(cx - 5, cz - 4, cx + 5, cz + 4, y0 + 3.8, 2.6, 'roofTiles', 'f_brick');
      this.door(g, cx, y0, cz - 4.02);
      col(cx - 5, cz - 4, cx + 5, cz + 4, 6.4);
    } else if (s === 4) {
      B.box(cx - 7, y0, cz - 5, cx + 7, y0 + 6.8, cz + 5, { side: 'f_plaster', tw: FACADE_TILE_W, th: FACADE_TILE_H });
      B.gable(cx - 7, cz - 5, cx + 7, cz + 5, y0 + 6.8, 3.2, 'roofTiles', 'f_plaster');
      // porch
      B.box(cx - 3, y0, cz - 7, cx + 3, y0 + 0.3, cz - 5, { side: 'pavers', top: 'pavers', tw: 2, th: 2, ts: 2 });
      B.box(cx - 3, y0 + 3.2, cz - 7, cx + 3, y0 + 3.45, cz - 5, { side: 'wood', top: 'roofTiles', bottom: 'wood', tw: 2, th: 2, ts: 3 });
      for (const x of [-2.8, 2.8]) { const p = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.12, 2.9, 12), M.curb); p.position.set(cx + x, y0 + 1.75, cz - 6.8); p.castShadow = true; g.add(p); }
      this.door(g, cx, y0 + 0.3, cz - 5.02);
      col(cx - 7, cz - 5, cx + 7, cz + 5, 10);
    } else if (s === 5) {
      B.box(cx - 9, y0, cz - 6, cx + 9, y0 + 10.2, cz + 6, { side: 'f_villa', top: 'roof', tw: FACADE_TILE_W, th: FACADE_TILE_H, ts: 6 });
      B.box(cx - 15, y0, cz - 4, cx - 9, y0 + 6.8, cz + 5, { side: 'f_villa', top: 'roof', tw: FACADE_TILE_W, th: FACADE_TILE_H, ts: 6 });
      B.box(cx + 9, y0, cz - 4, cx + 15, y0 + 6.8, cz + 5, { side: 'f_villa', top: 'roof', tw: FACADE_TILE_W, th: FACADE_TILE_H, ts: 6 });
      B.box(cx - 9.3, y0 + 10.2, cz - 6.3, cx + 9.3, y0 + 10.6, cz + 6.3, { side: 'curb', top: 'roof', tw: 3, th: 3, ts: 6 });
      // portico
      B.box(cx - 4.5, y0, cz - 9, cx + 4.5, y0 + 0.45, cz - 6, { side: 'curb', top: 'pavers', tw: 2, th: 2, ts: 2 });
      B.box(cx - 4.8, y0 + 6.4, cz - 9.3, cx + 4.8, y0 + 7.0, cz - 6, { side: 'curb', top: 'roof', bottom: 'curb', tw: 3, th: 3, ts: 4 });
      for (let k = 0; k < 6; k++) { const p = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.32, 6, 18), M.curb); p.position.set(cx - 4 + k * 1.6, y0 + 3.4, cz - 8.6); p.castShadow = p.receiveShadow = true; g.add(p); }
      this.door(g, cx, y0 + 0.45, cz - 6.02, 1.6);
      col(cx - 15, cz - 6, cx + 15, cz + 6, 11);
    }
    B.build(M, g);
    g.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
  }

  door(g, x, y, z, w = 1.1) {
    const d = new THREE.Mesh(new THREE.BoxGeometry(w, 2.2, 0.08), M.wood); d.position.set(x, y + 1.1, z); g.add(d);
    const knob = new THREE.Mesh(new THREE.SphereGeometry(0.04, 8, 6), M.chrome); knob.position.set(x + w * 0.38, y + 1.05, z - 0.06); g.add(knob);
    const lamp = new THREE.Mesh(new THREE.SphereGeometry(0.1, 12, 8), M.lampBulb); lamp.position.set(x + w * 0.8, y + 2.3, z - 0.1); g.add(lamp);
  }

  addDecor(id) {
    if (this.decor[id]) return;
    const g = new THREE.Group(); this.decor[id] = g; this.group.add(g);
    const L = this.L, y0 = CURB_H;
    const col = (x0, z0, x1, z1, h) => this.world.addCollider(x0, z0, x1, z1, h);
    const add = (m) => { m.castShadow = m.receiveShadow = true; g.add(m); return m; };
    if (id === 'fence') {
      const post = new THREE.BoxGeometry(0.1, 1.2, 0.1), plank = new THREE.BoxGeometry(2.0, 0.12, 0.04);
      const runs = [[L.x0 + 0.5, L.z0 + 0.5, L.x1 - 0.5, L.z0 + 0.5], [L.x0 + 0.5, L.z1 - 0.5, L.x1 - 0.5, L.z1 - 0.5], [L.x0 + 0.5, L.z0 + 0.5, L.x0 + 0.5, L.z1 - 0.5], [L.x1 - 0.5, L.z0 + 0.5, L.x1 - 0.5, L.z1 - 0.5]];
      const posts = [], planks = [];
      runs.forEach(([ax, az, bx, bz], ri) => {
        const len = Math.hypot(bx - ax, bz - az), n = Math.floor(len / 2);
        for (let k = 0; k <= n; k++) {
          const t = k / n, x = ax + (bx - ax) * t, z = az + (bz - az) * t;
          // gate gap in the front fence
          if (ri === 0 && Math.abs(x - (this.cx)) < 3) continue;
          posts.push([x, z, 0]);
          if (k < n && !(ri === 0 && Math.abs(x + (bx - ax) / n / 2 - this.cx) < 3.5)) { planks.push([x + (bx - ax) / n / 2, z + (bz - az) / n / 2, ri >= 2 ? Math.PI / 2 : 0]); }
        }
      });
      const pm = new THREE.InstancedMesh(post, M.wood, posts.length), km = new THREE.InstancedMesh(plank, M.wood, planks.length * 3);
      const m4 = new THREE.Matrix4();
      posts.forEach(([x, z], i) => { m4.makeTranslation(x, y0 + 0.6, z); pm.setMatrixAt(i, m4); });
      planks.forEach(([x, z, r], i) => { for (let h = 0; h < 3; h++) { m4.makeRotationY(r); m4.setPosition(x, y0 + 0.35 + h * 0.3, z); km.setMatrixAt(i * 3 + h, m4); } });
      add(pm); add(km);
    } else if (id === 'lamps') {
      for (const [x, z] of [[this.cx - 3.5, L.z0 + 2], [this.cx + 3.5, L.z0 + 2], [this.cx - 3.5, L.z0 + 10], [this.cx + 3.5, L.z0 + 10]]) {
        add(new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.07, 1.4, 8), M.darkMetal)).position.set(x, y0 + 0.7, z);
        const b = add(new THREE.Mesh(new THREE.SphereGeometry(0.16, 14, 10), M.lampBulb)); b.position.set(x, y0 + 1.5, z);
      }
      // path
      const path = new THREE.Mesh(new THREE.PlaneGeometry(3, 12).rotateX(-Math.PI / 2), M.pavers); path.position.set(this.cx, y0 + 0.03, L.z0 + 6); path.receiveShadow = true; g.add(path);
    } else if (id === 'garden') {
      const { trunkG, leavesG } = treeGeometries(8);
      const spots = [[L.x0 + 4, L.z1 - 5], [L.x0 + 9, L.z1 - 3.5], [L.x1 - 4, L.z1 - 5], [L.x1 - 9, L.z1 - 3.5], [L.x0 + 4, L.z0 + 14], [L.x1 - 4, L.z0 + 14]];
      for (const [x, z] of spots) {
        const t = add(new THREE.Mesh(trunkG, M.bark)); t.position.set(x, y0, z);
        const l = add(new THREE.Mesh(leavesG, M.leaves)); l.position.set(x, y0, z);
        col(x - 0.25, z - 0.25, x + 0.25, z + 0.25, 4);
      }
      const flowers = new THREE.InstancedMesh(new THREE.SphereGeometry(0.08, 6, 4), new THREE.MeshStandardMaterial({ roughness: 0.7 }), 300);
      const m4 = new THREE.Matrix4(), c = new THREE.Color();
      const fc = [0xe83a5a, 0xf2c230, 0xffffff, 0xb24ad8, 0xff7a2a];
      for (let i = 0; i < 300; i++) {
        const side = i % 2 ? 1 : -1;
        m4.makeTranslation(this.cx + side * (2.2 + Math.random() * 1.2), y0 + 0.1 + Math.random() * 0.15, L.z0 + 1.5 + Math.random() * 10);
        flowers.setMatrixAt(i, m4); flowers.setColorAt(i, c.set(fc[i % fc.length]));
      }
      add(flowers);
    } else if (id === 'bench') {
      const x = L.x1 - 8, z = L.z0 + 8;
      for (const [dx, dz] of [[-1.8, -1.8], [1.8, -1.8], [-1.8, 1.8], [1.8, 1.8]]) add(new THREE.Mesh(new THREE.BoxGeometry(0.15, 2.6, 0.15), M.wood)).position.set(x + dx, y0 + 1.3, z + dz);
      const roof = add(new THREE.Mesh(new THREE.ConeGeometry(3.2, 1.4, 4), M.roofTiles)); roof.rotation.y = Math.PI / 4; roof.position.set(x, y0 + 3.3, z);
      const bench = this.world.bench(); bench.position.set(x, y0, z); g.add(bench);
      col(x - 2, z - 2, x + 2, z + 2, 3);
    } else if (id === 'garage') {
      const B = new GeoBuilder();
      const x0 = L.x0 + 2, z0 = L.z0 + 18;
      B.box(x0, y0, z0, x0 + 6.5, y0 + 3.2, z0 + 7, { side: 'f_plaster2', top: 'roof', tw: FACADE_TILE_W, th: FACADE_TILE_H, ts: 4 });
      B.build(M, g);
      const door = add(new THREE.Mesh(new THREE.BoxGeometry(0.08, 2.4, 5), M.metal)); door.position.set(x0 + 6.52, y0 + 1.2, z0 + 3.5);
      col(x0, z0, x0 + 6.5, z0 + 7, 3.2);
    } else if (id === 'pool') {
      const x0 = this.cx - 6, z0 = L.z1 - 13;
      const B = new GeoBuilder();
      B.box(x0 - 0.6, y0, z0 - 0.6, x0 + 12.6, y0 + 0.25, z0 + 5.6, { side: 'pavers', top: 'pavers', tw: 2, th: 2, ts: 2 });
      B.build(M, g);
      const w = add(new THREE.Mesh(new THREE.PlaneGeometry(12, 5).rotateX(-Math.PI / 2), M.water)); w.position.set(x0 + 6, y0 + 0.27, z0 + 2.5);
      for (let k = 0; k < 3; k++) { const l = this.world.bench(); l.position.set(x0 + 2 + k * 4, y0, z0 + 7.5); l.rotation.y = Math.PI / 2; g.add(l); }
      col(x0 - 0.6, z0 - 0.6, x0 + 12.6, z0 + 5.6, 0.4);
    } else if (id === 'fountain') {
      const x = this.cx, z = L.z0 + 13;
      add(new THREE.Mesh(new THREE.CylinderGeometry(2.4, 2.6, 0.5, 36), M.curb)).position.set(x, y0 + 0.25, z);
      add(new THREE.Mesh(new THREE.CylinderGeometry(2.2, 2.2, 0.05, 36), M.water)).position.set(x, y0 + 0.46, z);
      add(new THREE.Mesh(new THREE.CylinderGeometry(0.3, 0.45, 1.8, 16), M.curb)).position.set(x, y0 + 1.1, z);
      add(new THREE.Mesh(new THREE.SphereGeometry(0.5, 20, 14), M.water)).position.set(x, y0 + 2.2, z);
      col(x - 2.5, z - 2.5, x + 2.5, z + 2.5, 1);
    } else if (id === 'statue') {
      const x = L.x1 - 6, z = L.z1 - 18;
      const gold = new THREE.MeshStandardMaterial({ color: 0xffc35a, metalness: 1, roughness: 0.15 });
      add(new THREE.Mesh(new THREE.BoxGeometry(2, 1.2, 2), M.curb)).position.set(x, y0 + 0.6, z);
      add(new THREE.Mesh(new THREE.CapsuleGeometry(0.35, 1.4, 6, 16), gold)).position.set(x, y0 + 2.3, z);
      add(new THREE.Mesh(new THREE.SphereGeometry(0.3, 20, 16), gold)).position.set(x, y0 + 3.4, z);
      const arm = add(new THREE.Mesh(new THREE.CapsuleGeometry(0.1, 0.9, 4, 10), gold)); arm.position.set(x + 0.45, y0 + 3.1, z); arm.rotation.z = -0.6;
      col(x - 1, z - 1, x + 1, z + 1, 4);
    }
  }
}
