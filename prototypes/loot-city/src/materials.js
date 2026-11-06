// PROTOTYPE - NOT FOR PRODUCTION
import * as THREE from 'three';
import * as T from './textures.js';

export const M = {};
export const nightEmissive = []; // materials whose emissiveIntensity follows night factor
export const wetMaterials = []; // {mat, dry, wet}

function pbr(tex, extra = {}) {
  const m = new THREE.MeshStandardMaterial({
    map: tex.map, roughnessMap: tex.rm, metalnessMap: tex.rm, normalMap: tex.normal,
    roughness: 1, metalness: 1, ...extra,
  });
  return m;
}

export function buildMaterials(progress) {
  progress('Асфальт и тротуары');
  const asphalt = T.asphalt();
  M.asphalt = pbr(asphalt, { normalScale: new THREE.Vector2(0.6, 0.6) });
  wetMaterials.push({ mat: M.asphalt, dry: 1, wet: 0.28 });
  const pav = T.pavers();
  M.pavers = pbr(pav, { normalScale: new THREE.Vector2(0.8, 0.8) });
  wetMaterials.push({ mat: M.pavers, dry: 1, wet: 0.45 });
  const con = T.concrete(51, 1);
  M.concrete = pbr(con);
  M.curb = pbr(T.concrete(52, 1.25));
  progress('Трава и земля');
  M.grass = pbr(T.grass());
  M.dirt = pbr(T.dirt());
  M.roof = pbr(T.roofTex());
  M.roofTiles = pbr(T.roofTiles());
  M.wood = pbr(T.woodTex());
  M.bark = pbr(T.bark());
  M.metal = pbr(T.metalPaint(71), { color: 0x5b6168 });
  M.darkMetal = new THREE.MeshStandardMaterial({ color: 0x23262a, roughness: 0.45, metalness: 0.8 });
  M.chrome = new THREE.MeshStandardMaterial({ color: 0xdddddd, roughness: 0.12, metalness: 1 });

  const facades = {
    brick: { wall: [150, 72, 52], brick: true, winW: 0.5, winH: 0.5, glassTint: [40, 52, 60], frame: [220, 215, 205], lit: 0.45, mullions: true },
    brick2: { wall: [120, 95, 80], brick: true, winW: 0.46, winH: 0.52, glassTint: [36, 44, 52], frame: [90, 70, 55], lit: 0.4, mullions: true },
    plaster: { wall: [205, 186, 150], winW: 0.48, winH: 0.5, glassTint: [40, 50, 58], frame: [235, 235, 230], lit: 0.45, ledges: true, mullions: true, dirt: 0.9 },
    plaster2: { wall: [170, 180, 175], winW: 0.44, winH: 0.48, glassTint: [36, 46, 52], frame: [200, 200, 195], lit: 0.4, ledges: true, mullions: true, dirt: 1.0 },
    glass: { wall: [50, 55, 60], glass: true, winW: 0.97, winH: 0.84, winTop: 0.08, glassTint: [70, 105, 130], frame: [160, 165, 170], lit: 0.55, metalFrame: true },
    darkglass: { wall: [30, 30, 32], glass: true, winW: 0.96, winH: 0.86, winTop: 0.07, glassTint: [32, 40, 48], frame: [40, 40, 44], lit: 0.5, metalFrame: true, mullions: true },
    metal: { wall: [140, 150, 155], panels: true, winW: 0.3, winH: 0.22, winTop: 0.1, glassTint: [50, 60, 66], frame: [90, 95, 100], lit: 0.15, metalFrame: true },
    metal2: { wall: [80, 110, 130], panels: true, winW: 0.3, winH: 0.22, winTop: 0.1, glassTint: [50, 60, 66], frame: [70, 75, 80], lit: 0.15, metalFrame: true },
    villa: { wall: [238, 234, 226], winW: 0.78, winH: 0.66, winTop: 0.12, glassTint: [60, 80, 95], frame: [40, 40, 42], lit: 0.6, wallVar: 0.08, dirt: 0.2, metalFrame: true },
  };
  let seed = 100;
  for (const [k, st] of Object.entries(facades)) {
    progress('Фасады: ' + k);
    const tx = T.facade(st, seed++);
    const m = pbr(tx, { emissiveMap: tx.emissive, emissive: 0xffffff, emissiveIntensity: 0 });
    M['f_' + k] = m;
    nightEmissive.push({ mat: m, max: 2.2 });
  }

  M.leaves = new THREE.MeshStandardMaterial({ map: T.leafCard(), alphaTest: 0.45, side: THREE.DoubleSide, roughness: 0.85, color: 0xbfd8a0 });
  M.hedge = new THREE.MeshStandardMaterial({ color: 0x2f4a22, roughness: 0.95 });
  M.water = new THREE.MeshPhysicalMaterial({ color: 0x1d7fa8, roughness: 0.03, metalness: 0, transmission: 0, clearcoat: 1, clearcoatRoughness: 0.02, normalMap: asphalt.normal, normalScale: new THREE.Vector2(0.15, 0.15) });
  M.glass = new THREE.MeshPhysicalMaterial({ color: 0x0b0f13, roughness: 0.02, metalness: 0.2, clearcoat: 1, clearcoatRoughness: 0.0, envMapIntensity: 1.4 });
  M.carPaint = new THREE.MeshPhysicalMaterial({ color: 0xffffff, roughness: 0.32, metalness: 0.65, clearcoat: 1, clearcoatRoughness: 0.03 });
  M.tire = new THREE.MeshStandardMaterial({ color: 0x151515, roughness: 0.9 });
  M.rim = new THREE.MeshStandardMaterial({ color: 0xb8bcc0, roughness: 0.25, metalness: 1 });
  M.headlight = new THREE.MeshStandardMaterial({ color: 0xffffff, emissive: 0xfff4dd, emissiveIntensity: 0.2, roughness: 0.1 });
  M.taillight = new THREE.MeshStandardMaterial({ color: 0x550000, emissive: 0xff1010, emissiveIntensity: 0.3, roughness: 0.2 });
  nightEmissive.push({ mat: M.headlight, max: 6, min: 0.2 }, { mat: M.taillight, max: 3, min: 0.3 });
  M.lampBulb = new THREE.MeshStandardMaterial({ color: 0xfff2d0, emissive: 0xffd9a0, emissiveIntensity: 0, roughness: 0.2 });
  nightEmissive.push({ mat: M.lampBulb, max: 12 });
  M.lightPool = new THREE.MeshBasicMaterial({ map: T.radialGlow('#ffd9a8'), transparent: true, opacity: 0, blending: THREE.AdditiveBlending, depthWrite: false, color: 0xffb070, polygonOffset: true, polygonOffsetFactor: -4 });
  M.marking = new THREE.MeshStandardMaterial({ color: 0xd8d8d0, roughness: 0.7, polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -2 });
  M.markingYellow = new THREE.MeshStandardMaterial({ color: 0xd8b030, roughness: 0.7, polygonOffset: true, polygonOffsetFactor: -2, polygonOffsetUnits: -2 });
  M.dumpster = new THREE.MeshStandardMaterial({ color: 0x2c5a34, roughness: 0.6, metalness: 0.5, map: M.metal.map, normalMap: M.metal.normalMap });
  M.container = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.6, metalness: 0.5, normalMap: M.f_metal.normalMap, map: M.metal.map });
  M.barrier = new THREE.MeshStandardMaterial({ map: M.curb.map, normalMap: M.curb.normalMap, roughness: 0.9, color: 0xe8e4dc });
  M.stripe = new THREE.MeshStandardMaterial({ color: 0xd12b1f, roughness: 0.6 });
  M.skin = new THREE.MeshPhysicalMaterial({ color: 0xd6a184, roughness: 0.6, sheen: 0.3, sheenColor: 0xff9a7a });
  M.cloth = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.9 });
  M.hair = new THREE.MeshStandardMaterial({ color: 0x2a1e16, roughness: 0.7 });
  M.awning = new THREE.MeshStandardMaterial({ color: 0xffffff, roughness: 0.85, side: THREE.DoubleSide });
  M.plastic = new THREE.MeshStandardMaterial({ color: 0x777777, roughness: 0.45 });
  return M;
}
