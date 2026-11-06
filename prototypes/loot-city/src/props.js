// PROTOTYPE - NOT FOR PRODUCTION
// Reusable prop geometries (lamps, trees, cars, people, kiosks).
import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { M } from './materials.js';
import { rng } from './textures.js';

const tmpM = new THREE.Matrix4();

export function lampGeometry() {
  const pole = new THREE.CylinderGeometry(0.07, 0.11, 7, 10).translate(0, 3.5, 0);
  const base = new THREE.CylinderGeometry(0.2, 0.25, 0.5, 10).translate(0, 0.25, 0);
  const arm = new THREE.CylinderGeometry(0.05, 0.05, 1.8, 8).rotateZ(Math.PI / 2).translate(0.85, 6.95, 0);
  const head = new THREE.BoxGeometry(0.75, 0.14, 0.32).translate(1.65, 6.9, 0);
  const g = mergeGeometries([pole, base, arm, head]);
  const bulb = new THREE.BoxGeometry(0.6, 0.04, 0.22).translate(1.65, 6.82, 0);
  return { g, bulb };
}

export function treeGeometries(seed = 1) {
  const r = rng(seed);
  const trunk = new THREE.CylinderGeometry(0.13, 0.22, 3.6, 8, 1).translate(0, 1.8, 0);
  // a couple of branches
  const b1 = new THREE.CylinderGeometry(0.05, 0.09, 1.6, 6).rotateZ(0.7).translate(0.45, 3.4, 0);
  const b2 = new THREE.CylinderGeometry(0.05, 0.09, 1.5, 6).rotateZ(-0.7).rotateY(2).translate(-0.3, 3.3, 0.3);
  const trunkG = mergeGeometries([trunk, b1, b2]);
  const cards = [];
  for (let i = 0; i < 26; i++) {
    const s = 1.4 + r() * 1.2;
    const p = new THREE.PlaneGeometry(s, s);
    p.rotateY(r() * Math.PI);
    p.rotateX((r() - 0.5) * 1.2);
    const a = r() * Math.PI * 2, d = Math.sqrt(r()) * 1.6;
    p.translate(Math.cos(a) * d, 4.2 + (r() - 0.3) * 2.2, Math.sin(a) * d);
    cards.push(p);
  }
  const leavesG = mergeGeometries(cards);
  // normals pointing outward for nicer shading
  const pos = leavesG.attributes.position, nrm = leavesG.attributes.normal;
  for (let i = 0; i < pos.count; i++) {
    const v = new THREE.Vector3(pos.getX(i), pos.getY(i) - 4.4, pos.getZ(i)).normalize();
    nrm.setXYZ(i, v.x, v.y, v.z);
  }
  return { trunkG, leavesG };
}

/** Car body built from an extruded side profile. */
export function carGeometries() {
  const L = 4.4, W = 1.8;
  const s = new THREE.Shape();
  // side profile, x along length (front at +x), y up
  s.moveTo(-2.2, 0.32);
  s.lineTo(2.2, 0.32);
  s.lineTo(2.25, 0.6);
  s.quadraticCurveTo(2.2, 0.85, 1.9, 0.9);
  s.lineTo(0.9, 0.98);
  s.lineTo(0.15, 1.42);
  s.lineTo(-1.05, 1.44);
  s.lineTo(-1.85, 1.0);
  s.quadraticCurveTo(-2.22, 0.95, -2.25, 0.7);
  s.lineTo(-2.2, 0.32);
  const body = new THREE.ExtrudeGeometry(s, { depth: W - 0.2, bevelEnabled: true, bevelThickness: 0.1, bevelSize: 0.08, bevelSegments: 4, curveSegments: 8 });
  body.translate(0, 0, -(W - 0.2) / 2);
  // wheel arches impression: cut not possible; darken underside via separate skirt
  // windows: slightly larger inner greenhouse
  const w = new THREE.Shape();
  w.moveTo(0.82, 1.0); w.lineTo(0.13, 1.4); w.lineTo(-1.0, 1.42); w.lineTo(-1.75, 1.02); w.lineTo(0.82, 1.0);
  const glass = new THREE.ExtrudeGeometry(w, { depth: W - 0.12, bevelEnabled: false });
  glass.translate(0, 0.005, -(W - 0.12) / 2);
  const wheel = new THREE.CylinderGeometry(0.34, 0.34, 0.24, 20).rotateX(Math.PI / 2);
  const rim = new THREE.CylinderGeometry(0.21, 0.21, 0.26, 12).rotateX(Math.PI / 2);
  const wheels = [], rims = [];
  for (const [x, z] of [[1.38, 0.82], [1.38, -0.82], [-1.38, 0.82], [-1.38, -0.82]]) {
    wheels.push(wheel.clone().translate(x, 0.34, z));
    rims.push(rim.clone().translate(x, 0.34, z));
  }
  const head = mergeGeometries([
    new THREE.BoxGeometry(0.06, 0.12, 0.42).translate(2.27, 0.72, 0.58),
    new THREE.BoxGeometry(0.06, 0.12, 0.42).translate(2.27, 0.72, -0.58),
  ]);
  const tail = mergeGeometries([
    new THREE.BoxGeometry(0.06, 0.12, 0.5).translate(-2.28, 0.8, 0.55),
    new THREE.BoxGeometry(0.06, 0.12, 0.5).translate(-2.28, 0.8, -0.55),
  ]);
  const under = new THREE.BoxGeometry(4.0, 0.25, 1.6).translate(0, 0.32, 0);
  return { body, glass, wheels: mergeGeometries(wheels), rims: mergeGeometries(rims), head, tail, under, L, W };
}

/** Instanced car fleet (parked + moving share it). */
export class CarFleet {
  constructor(scene, count) {
    const g = carGeometries();
    this.count = count;
    const mk = (geo, mat, colors) => {
      const m = new THREE.InstancedMesh(geo, mat, count);
      m.castShadow = true; m.receiveShadow = true;
      m.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
      scene.add(m);
      return m;
    };
    this.body = mk(g.body, M.carPaint);
    this.glass = mk(g.glass, M.glass);
    this.wheels = mk(g.wheels, M.tire);
    this.rims = mk(g.rims, M.rim);
    this.head = mk(g.head, M.headlight);
    this.tail = mk(g.tail, M.taillight);
    this.under = mk(g.under, M.tire);
    this.parts = [this.body, this.glass, this.wheels, this.rims, this.head, this.tail, this.under];
    const palette = [0xf2f2f2, 0x111111, 0x8a8f96, 0x5a0d0d, 0x0e2a55, 0xc8c8c8, 0x23364a, 0x6b6b60, 0xb01818, 0x1e4d2b, 0xd8c8a0, 0x303030];
    const r = rng(9);
    for (let i = 0; i < count; i++) this.body.setColorAt(i, new THREE.Color(palette[Math.floor(r() * palette.length)]));
    this.body.instanceColor.needsUpdate = true;
  }
  set(i, x, z, yaw) {
    tmpM.makeRotationY(yaw); tmpM.setPosition(x, 0, z);
    for (const p of this.parts) p.setMatrixAt(i, tmpM);
  }
  hide(i) { tmpM.makeScale(0, 0, 0); for (const p of this.parts) p.setMatrixAt(i, tmpM); }
  flush() { for (const p of this.parts) { p.instanceMatrix.needsUpdate = true; p.computeBoundingSphere(); } }
  flushFast() { for (const p of this.parts) p.instanceMatrix.needsUpdate = true; }
}

/** Simple humanoid NPC */
export function makePerson(opts = {}) {
  const g = new THREE.Group();
  const shirt = M.cloth.clone(); shirt.color.set(opts.shirt ?? 0x3b5b7a);
  const pants = M.cloth.clone(); pants.color.set(opts.pants ?? 0x2a2a30);
  const skin = M.skin.clone(); skin.color.set(opts.skin ?? 0xd6a184);
  const hair = M.hair.clone(); hair.color.set(opts.hair ?? 0x2a1e16);
  const shoes = new THREE.MeshStandardMaterial({ color: 0x1a1a1a, roughness: 0.5 });
  const add = (geo, mat, x, y, z) => { const m = new THREE.Mesh(geo, mat); m.position.set(x, y, z); m.castShadow = true; m.receiveShadow = true; g.add(m); return m; };
  const legL = add(new THREE.CapsuleGeometry(0.085, 0.75, 4, 10), pants, -0.1, 0.5, 0);
  const legR = add(new THREE.CapsuleGeometry(0.085, 0.75, 4, 10), pants, 0.1, 0.5, 0);
  add(new RoundedBoxGeometry(0.13, 0.08, 0.27, 2, 0.03), shoes, -0.1, 0.04, 0.05);
  add(new RoundedBoxGeometry(0.13, 0.08, 0.27, 2, 0.03), shoes, 0.1, 0.04, 0.05);
  const torso = add(new RoundedBoxGeometry(0.42, 0.62, 0.24, 3, 0.09), shirt, 0, 1.25, 0);
  const hips = add(new RoundedBoxGeometry(0.36, 0.2, 0.22, 2, 0.07), pants, 0, 0.95, 0);
  const armL = new THREE.Group(); armL.position.set(-0.27, 1.5, 0); g.add(armL);
  const armR = new THREE.Group(); armR.position.set(0.27, 1.5, 0); g.add(armR);
  for (const a of [armL, armR]) {
    const up = new THREE.Mesh(new THREE.CapsuleGeometry(0.065, 0.45, 4, 8), shirt); up.position.y = -0.27; up.castShadow = true; a.add(up);
    const hand = new THREE.Mesh(new THREE.SphereGeometry(0.06, 10, 8), skin); hand.position.y = -0.6; hand.castShadow = true; a.add(hand);
  }
  add(new THREE.CylinderGeometry(0.055, 0.06, 0.1, 10), skin, 0, 1.6, 0);
  const head = new THREE.Group(); head.position.set(0, 1.74, 0); g.add(head);
  const skull = new THREE.Mesh(new THREE.SphereGeometry(0.12, 20, 16), skin); skull.scale.set(0.9, 1.1, 1); skull.castShadow = true; head.add(skull);
  const hr = new THREE.Mesh(new THREE.SphereGeometry(0.125, 18, 12, 0, Math.PI * 2, 0, Math.PI * 0.55), hair); hr.scale.set(0.93, 1.05, 1.03); hr.position.y = 0.015; hr.rotation.x = -0.25; head.add(hr);
  const nose = new THREE.Mesh(new THREE.ConeGeometry(0.018, 0.05, 6), skin); nose.rotation.x = Math.PI / 2; nose.position.set(0, -0.005, 0.12); head.add(nose);
  const eyeM = new THREE.MeshStandardMaterial({ color: 0x111111, roughness: 0.1 });
  for (const x of [-0.04, 0.04]) { const e = new THREE.Mesh(new THREE.SphereGeometry(0.013, 8, 6), eyeM); e.position.set(x, 0.025, 0.105); head.add(e); }
  if (opts.hat) {
    const hm = new THREE.MeshStandardMaterial({ color: opts.hat, roughness: 0.8 });
    const cap = new THREE.Mesh(new THREE.CylinderGeometry(0.13, 0.13, 0.08, 16), hm); cap.position.y = 0.1; head.add(cap);
    const brim = new THREE.Mesh(new THREE.CylinderGeometry(0.2, 0.2, 0.015, 16), hm); brim.position.y = 0.065; head.add(brim);
  }
  g.userData = { armL, armR, head, torso, legL, legR, phase: Math.random() * 10 };
  return g;
}

export function animatePerson(p, t, talking) {
  const u = p.userData;
  const ph = t + u.phase;
  u.torso.scale.y = 1 + Math.sin(ph * 1.8) * 0.012;
  u.head.rotation.y = Math.sin(ph * 0.4) * 0.5 + (talking ? Math.sin(ph * 3) * 0.05 : 0);
  u.head.rotation.x = Math.sin(ph * 0.7) * 0.05;
  u.armL.rotation.x = Math.sin(ph * 0.9) * 0.05 + (talking ? Math.sin(ph * 4) * 0.25 - 0.3 : 0);
  u.armR.rotation.x = Math.sin(ph * 0.9 + 1) * 0.05;
  u.armL.rotation.z = -0.08; u.armR.rotation.z = 0.08;
}

/** Market kiosk with awning and sign */
export function makeKiosk(signTex, awningColor = 0xb8322a) {
  const g = new THREE.Group();
  const aw = M.awning.clone(); aw.color.set(awningColor);
  const wall = new THREE.Mesh(new THREE.BoxGeometry(3.2, 1.1, 1.2), M.wood); wall.position.set(0, 0.55, 0); g.add(wall);
  const counter = new THREE.Mesh(new THREE.BoxGeometry(3.4, 0.08, 1.4), M.darkMetal); counter.position.set(0, 1.12, 0); g.add(counter);
  const back = new THREE.Mesh(new THREE.BoxGeometry(3.2, 2.8, 0.15), M.wood); back.position.set(0, 1.4, -1.6); g.add(back);
  for (const x of [-1.55, 1.55]) {
    const p = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.05, 2.9, 8), M.darkMetal); p.position.set(x, 1.45, 0.6); g.add(p);
    const p2 = p.clone(); p2.position.z = -1.6; g.add(p2);
  }
  const awn = new THREE.Mesh(new THREE.PlaneGeometry(3.6, 2.8, 1, 6), aw);
  awn.rotation.x = -Math.PI / 2 + 0.25; awn.position.set(0, 2.95, -0.45); g.add(awn);
  // wavy awning edge
  const pos = awn.geometry.attributes.position;
  for (let i = 0; i < pos.count; i++) pos.setZ(i, Math.sin(pos.getY(i) * 3) * 0.04);
  awn.geometry.computeVertexNormals();
  const signMat = new THREE.MeshStandardMaterial({ map: signTex, emissiveMap: signTex, emissive: 0xffffff, emissiveIntensity: 0.25, roughness: 0.5 });
  const sign = new THREE.Mesh(new THREE.PlaneGeometry(3.2, 0.8), signMat); sign.position.set(0, 3.3, 0.85); sign.rotation.x = -0.08; g.add(sign);
  g.userData.signMat = signMat;
  g.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
  return g;
}
