// PROTOTYPE - NOT FOR PRODUCTION
// Loot item visuals, spawning and pickup detection.
import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/addons/geometries/RoundedBoxGeometry.js';
import { ITEMS, ITEM_BY_ID, RARITY } from './data.js';
import { beamTexture, radialGlow, signTexture } from './textures.js';
import { M } from './materials.js';

const LM = {};
function lootMaterials() {
  if (LM.gold) return LM;
  LM.gold = new THREE.MeshStandardMaterial({ color: 0xffc35a, metalness: 1, roughness: 0.18 });
  LM.silver = new THREE.MeshStandardMaterial({ color: 0xe6e8ee, metalness: 1, roughness: 0.15 });
  LM.bronze = new THREE.MeshStandardMaterial({ color: 0xa8683a, metalness: 1, roughness: 0.35 });
  LM.copper = new THREE.MeshStandardMaterial({ color: 0xd07a4a, metalness: 1, roughness: 0.3 });
  LM.alu = new THREE.MeshStandardMaterial({ color: 0xc8ccd2, metalness: 1, roughness: 0.28 });
  LM.bottle = new THREE.MeshPhysicalMaterial({ color: 0x2f6b3a, roughness: 0.05, metalness: 0, transparent: true, opacity: 0.55, clearcoat: 1 });
  LM.diamond = new THREE.MeshPhysicalMaterial({ color: 0xffffff, roughness: 0, metalness: 0, transmission: 1, thickness: 0.5, ior: 2.42, dispersion: 5, iridescence: 0.3 });
  LM.emerald = new THREE.MeshPhysicalMaterial({ color: 0x18c060, roughness: 0, metalness: 0, transmission: 0.9, thickness: 0.5, ior: 1.58 });
  LM.ruby = new THREE.MeshPhysicalMaterial({ color: 0xd0102a, roughness: 0, transmission: 0.8, thickness: 0.3, ior: 1.76 });
  LM.pearl = new THREE.MeshPhysicalMaterial({ color: 0xf6efe6, roughness: 0.25, sheen: 1, sheenColor: 0xffe8f0, iridescence: 0.6 });
  LM.cardboard = new THREE.MeshStandardMaterial({ color: 0xa47a4c, roughness: 0.95 });
  LM.blackPlastic = new THREE.MeshStandardMaterial({ color: 0x141416, roughness: 0.35 });
  LM.redPlastic = new THREE.MeshStandardMaterial({ color: 0xb01c1c, roughness: 0.4, metalness: 0.2 });
  LM.leather = new THREE.MeshStandardMaterial({ color: 0x4a2a18, roughness: 0.6 });
  LM.screen = new THREE.MeshStandardMaterial({ color: 0x0a0d12, roughness: 0.05, metalness: 0.5, emissive: 0x1a3a5a, emissiveIntensity: 0.3 });
  LM.bag = new THREE.MeshStandardMaterial({ color: 0x18181a, roughness: 0.25, metalness: 0.1 });
  LM.money = new THREE.MeshStandardMaterial({ color: 0x8fb08a, roughness: 0.8 });
  LM.porcelain = new THREE.MeshPhysicalMaterial({ color: 0xf2f4f8, roughness: 0.12, clearcoat: 1 });
  LM.blue = new THREE.MeshStandardMaterial({ color: 0x1f4fa0, roughness: 0.3 });
  LM.wood = M.wood;
  LM.green = new THREE.MeshStandardMaterial({ color: 0x1d5a2a, roughness: 0.5, metalness: 0.3 });
  const c = document.createElement('canvas'); c.width = 256; c.height = 200;
  const x = c.getContext('2d');
  const g = x.createLinearGradient(0, 0, 256, 200); g.addColorStop(0, '#2b4a6f'); g.addColorStop(0.5, '#c7924b'); g.addColorStop(1, '#3d2a1a');
  x.fillStyle = g; x.fillRect(0, 0, 256, 200);
  for (let i = 0; i < 400; i++) { x.fillStyle = `hsla(${30 + Math.random() * 60},50%,${30 + Math.random() * 40}%,0.4)`; x.beginPath(); x.arc(Math.random() * 256, Math.random() * 200, 2 + Math.random() * 10, 0, 7); x.fill(); }
  LM.canvasArt = new THREE.MeshStandardMaterial({ map: new THREE.CanvasTexture(c), roughness: 0.7 });
  LM.canvasArt.map.colorSpace = THREE.SRGBColorSpace;
  return LM;
}

function mesh(geo, mat, x = 0, y = 0, z = 0) {
  const m = new THREE.Mesh(geo, mat); m.position.set(x, y, z); m.castShadow = true; m.receiveShadow = true; return m;
}

export function makeItemMesh(def) {
  const L = lootMaterials();
  const g = new THREE.Group();
  const metal = def.mat === 'gold' ? L.gold : def.mat === 'silver' ? L.silver : L.gold;
  switch (def.shape) {
    case 'bottle': {
      const pts = [];
      for (let i = 0; i <= 12; i++) { const t = i / 12; const r = t < 0.6 ? 0.045 : t < 0.8 ? 0.045 - (t - 0.6) * 0.15 : 0.015; pts.push(new THREE.Vector2(r, t * 0.3)); }
      const b = mesh(new THREE.LatheGeometry(pts, 18), L.bottle); b.rotation.z = Math.PI / 2; b.position.y = 0.045; g.add(b); break;
    }
    case 'can': { const c = mesh(new THREE.CylinderGeometry(0.033, 0.033, 0.12, 20), L.alu, 0, 0.033); c.rotation.z = Math.PI / 2; c.scale.y = 0.85; g.add(c); break; }
    case 'box': { g.add(mesh(new RoundedBoxGeometry(0.5, 0.35, 0.4, 2, 0.02), L.cardboard, 0, 0.175)); const f = mesh(new THREE.BoxGeometry(0.25, 0.02, 0.4), L.cardboard, 0.12, 0.36); f.rotation.z = -0.5; g.add(f); break; }
    case 'coil': { const t = mesh(new THREE.TorusGeometry(0.14, 0.03, 10, 32), L.copper, 0, 0.03); t.rotation.x = Math.PI / 2; g.add(t); const t2 = t.clone(); t2.scale.setScalar(0.8); t2.position.y = 0.07; g.add(t2); break; }
    case 'phone': g.add(mesh(new RoundedBoxGeometry(0.08, 0.012, 0.16, 2, 0.006), L.blackPlastic, 0, 0.006)); g.add(mesh(new THREE.PlaneGeometry(0.07, 0.14).rotateX(-Math.PI / 2), L.screen, 0, 0.0125)); break;
    case 'bag': { const s = mesh(new THREE.SphereGeometry(0.28, 16, 12), L.bag, 0, 0.22); s.scale.set(1, 0.8, 0.9); g.add(s); g.add(mesh(new THREE.ConeGeometry(0.06, 0.15, 8), L.bag, 0, 0.47)); break; }
    case 'tire': { const t = mesh(new THREE.TorusGeometry(0.3, 0.11, 12, 32), M.tire, 0, 0.11); t.rotation.x = Math.PI / 2; g.add(t); break; }
    case 'headphones': { const a = mesh(new THREE.TorusGeometry(0.09, 0.012, 8, 24, Math.PI), L.blackPlastic, 0, 0.03); a.rotation.x = -Math.PI / 2; g.add(a); g.add(mesh(new THREE.CylinderGeometry(0.045, 0.045, 0.03, 16), L.blackPlastic, 0.09, 0.03)); g.add(mesh(new THREE.CylinderGeometry(0.045, 0.045, 0.03, 16), L.blackPlastic, -0.09, 0.03)); break; }
    case 'toolbox': g.add(mesh(new RoundedBoxGeometry(0.5, 0.22, 0.22, 2, 0.02), L.redPlastic, 0, 0.11)); g.add(mesh(new THREE.TorusGeometry(0.08, 0.012, 6, 16, Math.PI), M.darkMetal, 0, 0.22)); break;
    case 'wallet': g.add(mesh(new RoundedBoxGeometry(0.11, 0.025, 0.09, 2, 0.01), L.leather, 0, 0.012)); break;
    case 'radio': g.add(mesh(new RoundedBoxGeometry(0.25, 0.15, 0.07, 2, 0.015), def.id === 'r_cassette' ? L.alu : L.leather, 0, 0.075)); g.add(mesh(new THREE.CylinderGeometry(0.045, 0.045, 0.01, 20).rotateX(Math.PI / 2), M.darkMetal, -0.05, 0.075, 0.036)); break;
    case 'spoon': { const s = mesh(new THREE.BoxGeometry(0.15, 0.005, 0.015), L.silver, 0, 0.005); g.add(s); const b = mesh(new THREE.SphereGeometry(0.025, 12, 8), L.silver, 0.09, 0.008); b.scale.set(1.3, 0.3, 1); g.add(b); break; }
    case 'laptop': { g.add(mesh(new RoundedBoxGeometry(0.34, 0.02, 0.24, 2, 0.008), L.alu, 0, 0.01)); const lid = new THREE.Group(); lid.position.set(0, 0.02, -0.12); lid.rotation.x = -1.9; lid.add(mesh(new RoundedBoxGeometry(0.34, 0.012, 0.24, 2, 0.005), L.alu, 0, 0, 0.12)); lid.add(mesh(new THREE.PlaneGeometry(0.31, 0.2).rotateX(-Math.PI / 2), L.screen, 0, -0.007, 0.12)); lid.children[1].rotation.x = Math.PI / 2; g.add(lid); break; }
    case 'gpu': g.add(mesh(new THREE.BoxGeometry(0.28, 0.04, 0.11), L.blackPlastic, 0, 0.02)); for (const x of [-0.07, 0.07]) g.add(mesh(new THREE.CylinderGeometry(0.04, 0.04, 0.01, 18), M.darkMetal, x, 0.045)); break;
    case 'cash': for (let i = 0; i < 3; i++) { const b = mesh(new THREE.BoxGeometry(0.16, 0.02, 0.07), L.money, (i - 1) * 0.01, 0.01 + i * 0.02); b.rotation.y = i * 0.2; g.add(b); } break;
    case 'bar': { const b = mesh(new THREE.CylinderGeometry(0.06, 0.08, 0.05, 4, 1), def.mat === 'silver' ? L.silver : L.gold, 0, 0.025); b.rotation.y = Math.PI / 4; b.scale.set(1.6, 1, 0.8); g.add(b); break; }
    case 'watch': { const t = mesh(new THREE.TorusGeometry(0.04, 0.01, 8, 24), L.gold, 0, 0.01); t.rotation.x = Math.PI / 2; g.add(t); g.add(mesh(new THREE.CylinderGeometry(0.025, 0.025, 0.012, 24), L.gold, 0, 0.02, 0.04)); break; }
    case 'case': g.add(mesh(new RoundedBoxGeometry(0.46, 0.12, 0.34, 2, 0.02), L.alu, 0, 0.06)); g.add(mesh(new THREE.TorusGeometry(0.05, 0.01, 6, 16, Math.PI), M.darkMetal, 0, 0.06, 0.17)); break;
    case 'gem': { const m = def.mat === 'emerald' ? L.emerald : L.diamond; const o = mesh(new THREE.OctahedronGeometry(0.05, 0), m, 0, 0.05); o.scale.y = 1.25; g.add(o); break; }
    case 'egg': { const e = mesh(new THREE.SphereGeometry(0.07, 24, 18), L.gold, 0, 0.09); e.scale.y = 1.3; g.add(e); g.add(mesh(new THREE.TorusGeometry(0.07, 0.008, 8, 32), L.ruby, 0, 0.09)); g.children[1].rotation.x = Math.PI / 2; g.add(mesh(new THREE.CylinderGeometry(0.03, 0.05, 0.03, 16), L.gold, 0, 0.015)); break; }
    case 'coin': { const c = mesh(new THREE.CylinderGeometry(0.02, 0.02, 0.004, 24), metal, 0, 0.004); g.add(c); const c2 = c.clone(); c2.position.set(0.03, 0.004, 0.01); g.add(c2); break; }
    case 'camera': g.add(mesh(new RoundedBoxGeometry(0.14, 0.08, 0.06, 2, 0.01), L.blackPlastic, 0, 0.04)); g.add(mesh(new THREE.CylinderGeometry(0.03, 0.035, 0.05, 20).rotateX(Math.PI / 2), L.alu, 0, 0.04, 0.05)); break;
    case 'record': { g.add(mesh(new THREE.CylinderGeometry(0.15, 0.15, 0.004, 40), L.blackPlastic, 0, 0.003)); g.add(mesh(new THREE.CylinderGeometry(0.05, 0.05, 0.005, 24), L.redPlastic, 0, 0.004)); break; }
    case 'console': g.add(mesh(new RoundedBoxGeometry(0.09, 0.02, 0.15, 2, 0.008), new THREE.MeshStandardMaterial({ color: 0xb8b4a8, roughness: 0.5 }), 0, 0.01)); g.add(mesh(new THREE.PlaneGeometry(0.06, 0.05).rotateX(-Math.PI / 2), L.screen, 0, 0.021, -0.03)); break;
    case 'rotary': g.add(mesh(new RoundedBoxGeometry(0.22, 0.12, 0.2, 3, 0.04), L.blackPlastic, 0, 0.06)); g.add(mesh(new THREE.CylinderGeometry(0.05, 0.05, 0.01, 24).rotateX(-0.6), L.alu, 0, 0.12, 0.03)); g.add(mesh(new THREE.CapsuleGeometry(0.025, 0.18, 4, 8).rotateZ(Math.PI / 2), L.blackPlastic, 0, 0.15, -0.04)); break;
    case 'ring': { const t = mesh(new THREE.TorusGeometry(0.018, 0.004, 8, 24), L.gold, 0, 0.018); g.add(t); g.add(mesh(new THREE.OctahedronGeometry(0.008), L.ruby, 0, 0.038)); break; }
    case 'necklace': { for (let i = 0; i < 24; i++) { const a = i / 24 * Math.PI * 2; g.add(mesh(new THREE.SphereGeometry(0.01, 10, 8), L.pearl, Math.cos(a) * 0.08, 0.01, Math.sin(a) * 0.1)); } break; }
    case 'frame': { g.add(mesh(new THREE.BoxGeometry(0.7, 0.55, 0.05), L.gold, 0, 0.275)); g.add(mesh(new THREE.PlaneGeometry(0.6, 0.45), L.canvasArt, 0, 0.275, 0.026)); g.rotation.x = -0.25; break; }
    case 'statue': { g.add(mesh(new THREE.BoxGeometry(0.14, 0.05, 0.14), L.bronze, 0, 0.025)); const b = mesh(new THREE.CapsuleGeometry(0.04, 0.16, 4, 10), L.bronze, 0, 0.17); g.add(b); g.add(mesh(new THREE.SphereGeometry(0.035, 14, 10), L.bronze, 0, 0.32)); break; }
    case 'vase': { const pts = []; for (let i = 0; i <= 16; i++) { const t = i / 16; pts.push(new THREE.Vector2(0.03 + Math.sin(t * Math.PI) * 0.1 + (t > 0.85 ? (t - 0.85) * 0.3 : 0), t * 0.4)); } g.add(mesh(new THREE.LatheGeometry(pts, 24), L.porcelain)); g.add(mesh(new THREE.TorusGeometry(0.13, 0.006, 6, 32).rotateX(Math.PI / 2), L.blue, 0, 0.2)); break; }
    case 'chest': g.add(mesh(new RoundedBoxGeometry(0.2, 0.12, 0.14, 2, 0.01), L.wood, 0, 0.06)); g.add(mesh(new THREE.BoxGeometry(0.21, 0.015, 0.145), L.gold, 0, 0.1)); break;
    default: g.add(mesh(new THREE.BoxGeometry(0.2, 0.2, 0.2), L.cardboard, 0, 0.1));
  }
  return g;
}

/** Big treasure chest used by events */
export function makeTreasureChest() {
  const g = new THREE.Group();
  const L = lootMaterials();
  g.add(mesh(new RoundedBoxGeometry(0.9, 0.5, 0.6, 2, 0.03), L.wood, 0, 0.25));
  const lid = mesh(new THREE.CylinderGeometry(0.3, 0.3, 0.9, 16, 1, false, 0, Math.PI).rotateZ(Math.PI / 2), L.wood, 0, 0.5); lid.rotation.x = Math.PI / 2; g.add(lid);
  for (const x of [-0.35, 0.35]) g.add(mesh(new THREE.BoxGeometry(0.06, 0.82, 0.62), L.gold, x, 0.41));
  return g;
}

export class LootManager {
  constructor(scene, world) {
    this.scene = scene; this.world = world;
    this.items = []; // {id, def, value, rarity, group, pos, district, special}
    this.beamTex = beamTexture();
    this.glowTex = radialGlow();
    this.beamGeo = new THREE.CylinderGeometry(0.025, 0.07, 3.2, 10, 1, true).translate(0, 1.6, 0);
    this.glowGeo = new THREE.PlaneGeometry(1.4, 1.4).rotateX(-Math.PI / 2);
    this.beamMats = RARITY.map((r) => new THREE.MeshBasicMaterial({ map: this.beamTex, color: r.hex, transparent: true, opacity: r.beam, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide, fog: false }));
    this.glowMats = RARITY.map((r) => new THREE.MeshBasicMaterial({ map: this.glowTex, color: r.hex, transparent: true, opacity: 0.6, blending: THREE.AdditiveBlending, depthWrite: false }));
    this.nextId = 1;
    this.timer = 0;
  }

  rollItem(district, luck, extraRarity = 0) {
    // rarity weights shift with district & luck
    const boost = district.rarityBoost + luck + extraRarity;
    const w = [100, 38 + boost * 10, 9 + boost * 6, 1.6 + boost * 2.2, 0.18 + boost * 0.55];
    if (district.id === 0) w[4] *= 0.5;
    const total = w.reduce((a, b) => a + b, 0);
    let x = Math.random() * total, rar = 0;
    for (let i = 0; i < w.length; i++) { if (x < w[i]) { rar = i; break; } x -= w[i]; }
    const pool = ITEMS.filter((it) => it.r === rar);
    const def = pool[Math.floor(Math.random() * pool.length)];
    return def;
  }

  spawn(def, pos, district, special = false) {
    const g = new THREE.Group();
    const m = makeItemMesh(def);
    m.rotation.y = Math.random() * Math.PI * 2;
    g.add(m);
    const beam = new THREE.Mesh(this.beamGeo, this.beamMats[def.r]);
    const glow = new THREE.Mesh(this.glowGeo, this.glowMats[def.r]);
    glow.position.y = 0.02;
    g.add(beam, glow);
    g.position.copy(pos);
    this.scene.add(g);
    const value = Math.round(def.v * district.lootMult ** 0.35 * (0.8 + Math.random() * 0.4));
    const it = { uid: this.nextId++, def, value, group: g, beam, glow, pos: g.position, district: district.id, special, t: Math.random() * 10 };
    this.items.push(it);
    return it;
  }

  remove(it) {
    this.scene.remove(it.group);
    it.group.traverse((o) => { if (o.geometry && o.geometry !== this.beamGeo && o.geometry !== this.glowGeo) o.geometry.dispose(); });
    this.items.splice(this.items.indexOf(it), 1);
  }

  countIn(d) { let n = 0; for (const it of this.items) if (it.district === d && !it.special) n++; return n; }

  populate(districts, unlocked, luck, cap, playerPos) {
    for (const d of districts) {
      const target = cap * (d.id === 0 ? 1 : 0.9);
      let n = this.countIn(d.id), guard = 0;
      while (n < target && guard++ < 200) {
        const sp = this.world.spawns[d.id];
        const p = sp[Math.floor(Math.random() * sp.length)];
        if (playerPos && p.distanceTo(playerPos) < 25 && unlocked[d.id]) continue;
        if (this.items.some((it) => it.pos.distanceToSquared(p) < 2)) continue;
        const pos = p.clone().add(new THREE.Vector3((Math.random() - 0.5) * 1.5, 0.0, (Math.random() - 0.5) * 1.5));
        this.spawn(this.rollItem(d, luck), pos, d);
        n++;
      }
    }
  }

  update(dt, cam, detectRadius, time) {
    for (const it of this.items) {
      const d = it.pos.distanceTo(cam);
      const vis = d < detectRadius || it.special;
      it.beam.visible = vis;
      const f = 1 - THREE.MathUtils.smoothstep(d, detectRadius * 0.6, detectRadius);
      it.beam.scale.set(1, it.special ? 3 : 1 + it.def.r * 0.4, 1);
      it.glow.material.opacity = 0.55;
      it.glow.scale.setScalar(0.8 + Math.sin(time * 3 + it.t) * 0.12);
      it.group.visible = d < 220 || it.special;
      void f;
    }
  }

  /** item the camera is looking at within range */
  pick(camPos, camDir, range = 3.2) {
    let best = null, bestScore = 0.86;
    for (const it of this.items) {
      const to = new THREE.Vector3().subVectors(it.pos, camPos);
      to.y += 0.15;
      const d = to.length();
      if (d > range) continue;
      const dot = to.normalize().dot(camDir);
      const score = dot + (range - d) * 0.02;
      if (dot > 0.82 && score > bestScore) { best = it; bestScore = score; }
    }
    return best;
  }
}

export { ITEM_BY_ID, signTexture };
