// PROTOTYPE - NOT FOR PRODUCTION
// Physically based sky, sun/moon lighting, day-night cycle, environment reflections, rain.
import * as THREE from 'three';
import { Sky } from 'three/addons/objects/Sky.js';
import { M, nightEmissive, wetMaterials } from './materials.js';

export class Atmosphere {
  constructor(renderer, scene) {
    this.renderer = renderer; this.scene = scene;
    this.sky = new Sky();
    this.sky.scale.setScalar(4500);
    scene.add(this.sky);
    const u = this.sky.material.uniforms;
    u.turbidity.value = 2.8; u.rayleigh.value = 1.3; u.mieCoefficient.value = 0.003; u.mieDirectionalG.value = 0.8;

    this.sun = new THREE.DirectionalLight(0xffffff, 3);
    this.sun.castShadow = true;
    this.sun.shadow.mapSize.set(4096, 4096);
    const S = 85;
    Object.assign(this.sun.shadow.camera, { left: -S, right: S, top: S, bottom: -S, near: 1, far: 600 });
    this.sun.shadow.bias = -0.0004; this.sun.shadow.normalBias = 0.04;
    this.sun.shadow.radius = 2;
    scene.add(this.sun, this.sun.target);
    this.hemi = new THREE.HemisphereLight(0xbfd4ff, 0x4a4036, 0.5);
    scene.add(this.hemi);

    // stars
    const sg = new THREE.BufferGeometry();
    const pts = [];
    for (let i = 0; i < 2500; i++) {
      const v = new THREE.Vector3(Math.random() - 0.5, Math.random() * 0.9 + 0.05, Math.random() - 0.5).normalize().multiplyScalar(3000);
      pts.push(v.x, v.y, v.z);
    }
    sg.setAttribute('position', new THREE.Float32BufferAttribute(pts, 3));
    this.starMat = new THREE.PointsMaterial({ color: 0xffffff, size: 2.2, sizeAttenuation: false, transparent: true, opacity: 0, depthWrite: false, fog: false });
    this.stars = new THREE.Points(sg, this.starMat);
    scene.add(this.stars);
    // moon
    this.moon = new THREE.Mesh(new THREE.SphereGeometry(60, 24, 16), new THREE.MeshBasicMaterial({ color: 0xdfe6ff, fog: false, transparent: true }));
    scene.add(this.moon);

    this.pmrem = new THREE.PMREMGenerator(renderer);
    this.envScene = new THREE.Scene();
    this.envSky = new Sky(); this.envSky.scale.setScalar(1000);
    this.envScene.add(this.envSky);
    // fake city glow + ground bounce in env
    const groundEnv = new THREE.Mesh(new THREE.SphereGeometry(900, 32, 16, 0, Math.PI * 2, Math.PI / 2, Math.PI / 2), new THREE.MeshBasicMaterial({ color: 0x2c2a28, side: THREE.BackSide }));
    this.groundEnv = groundEnv;
    this.envScene.add(groundEnv);
    this.envRT = null;
    this.envTimer = 999;

    scene.fog = new THREE.FogExp2(0xb8c6d6, 0.0014);
    this.fogBase = 0.0014;
    this.night = 0; this.wet = 0; this.rain = 0; this.rainTarget = 0;
    this.sunDir = new THREE.Vector3();
    this._initRain();
  }

  _initRain() {
    const n = 7000;
    const g = new THREE.BufferGeometry();
    const p = new Float32Array(n * 6);
    for (let i = 0; i < n; i++) {
      const x = (Math.random() - 0.5) * 80, y = Math.random() * 40, z = (Math.random() - 0.5) * 80;
      p.set([x, y, z, x + 0.05, y - 0.7, z + 0.02], i * 6);
    }
    g.setAttribute('position', new THREE.BufferAttribute(p, 3));
    this.rainMat = new THREE.LineBasicMaterial({ color: 0xaab6c4, transparent: true, opacity: 0, depthWrite: false });
    this.rainMesh = new THREE.LineSegments(g, this.rainMat);
    this.rainMesh.frustumCulled = false;
    this.scene.add(this.rainMesh);
    this.rainOffset = 0;
  }

  /** dayT in [0,1): 0 = midnight, 0.5 = noon */
  update(dt, dayT, focus) {
    const ang = (dayT - 0.25) * Math.PI * 2;
    const elev = Math.sin(ang); // -1..1
    const az = dayT * Math.PI * 2 + 0.6;
    const el = elev * 0.78;
    this.sunDir.set(Math.cos(az) * Math.cos(el), Math.sin(el), Math.sin(az) * Math.cos(el)).normalize();
    const u = this.sky.material.uniforms;
    u.sunPosition.value.copy(this.sunDir);
    const day = THREE.MathUtils.smoothstep(elev, -0.08, 0.22);
    this.night = 1 - THREE.MathUtils.smoothstep(elev, -0.18, 0.05);
    const golden = THREE.MathUtils.smoothstep(elev, -0.05, 0.08) * (1 - THREE.MathUtils.smoothstep(elev, 0.1, 0.35));
    // rain
    this.rain += (this.rainTarget - this.rain) * Math.min(1, dt * 0.3);
    this.wet += ((this.rain > 0.2 ? 1 : 0) - this.wet) * Math.min(1, dt * (this.rain > 0.2 ? 0.08 : 0.02));
    u.turbidity.value = 2.8 + this.rain * 14;
    u.rayleigh.value = 1.3 + this.rain * 2 + golden * 0.8;

    const lightDir = elev > -0.05 ? this.sunDir : this.moonDir(az, elev);
    this.sun.position.copy(focus).addScaledVector(lightDir, 250);
    // snap target to shadow texel grid to avoid shimmering
    const tex = (85 * 2) / this.sun.shadow.mapSize.x;
    this.sun.target.position.set(Math.round(focus.x / tex) * tex, 0, Math.round(focus.z / tex) * tex);
    this.sun.position.sub(focus).add(this.sun.target.position);
    const sunCol = new THREE.Color().setHSL(0.09 + day * 0.04, 0.9 - day * 0.55, 0.55 + day * 0.3);
    if (elev > -0.05) {
      this.sun.color.copy(sunCol);
      this.sun.intensity = (0.2 + 4.6 * day) * (1 - this.rain * 0.8);
    } else {
      this.sun.color.set(0x9fb4ff);
      this.sun.intensity = 0.35 * (1 - this.rain * 0.7);
    }
    this.hemi.intensity = 0.08 + 0.22 * day * (1 + this.rain * 0.8);
    this.hemi.color.setHSL(0.6, 0.5, 0.6 + day * 0.15);

    this.starMat.opacity = this.night * (1 - this.rain);
    this.stars.position.copy(focus);
    const md = this.moonDir(az, elev);
    this.moon.position.copy(focus).addScaledVector(md, 2800);
    this.moon.material.opacity = this.night * (1 - this.rain * 0.9);

    // fog colour follows horizon
    const fogDay = new THREE.Color(0x9fb6cf).lerp(new THREE.Color(0xd8a87c), golden * 0.7);
    const fogNight = new THREE.Color(0x0c1018);
    const fogC = fogNight.clone().lerp(fogDay, day).lerp(new THREE.Color(0x6c747e).multiplyScalar(0.3 + day * 0.7), this.rain * 0.8);
    this.scene.fog.color.copy(fogC);
    this.scene.fog.density = this.fogBase * (1 + this.rain * 1.8 + this.night * 0.3);

    // emissive (windows, lamps)
    for (const e of nightEmissive) e.mat.emissiveIntensity = (e.min ?? 0) + (e.max - (e.min ?? 0)) * this.night;
    M.lightPool.opacity = this.night * 0.55;
    // wet surfaces
    for (const w of wetMaterials) {
      w.mat.roughness = THREE.MathUtils.lerp(w.dry, w.wet, this.wet);
      w.mat.color.setScalar(1 - this.wet * 0.35);
    }
    this.renderer.toneMappingExposure = 0.55 + 0.25 * this.night * 0 + (this.night * 0.35);

    // rain particles follow camera
    this.rainMat.opacity = this.rain * 0.45;
    this.rainMesh.visible = this.rain > 0.01;
    if (this.rainMesh.visible) {
      this.rainOffset = (this.rainOffset + dt * 22) % 40;
      this.rainMesh.position.set(focus.x, focus.y - 10 - this.rainOffset + 20, focus.z);
    }

    // refresh environment map periodically
    this.envTimer += dt;
    if (this.envTimer > 3) {
      this.envTimer = 0;
      const eu = this.envSky.material.uniforms;
      for (const k of ['turbidity', 'rayleigh', 'mieCoefficient', 'mieDirectionalG']) eu[k].value = u[k].value;
      eu.sunPosition.value.copy(this.sunDir);
      this.groundEnv.material.color.setRGB(0.12, 0.11, 0.1).multiplyScalar(0.2 + day);
      if (this.envRT) this.envRT.dispose();
      this.envRT = this.pmrem.fromScene(this.envScene, 0, 1, 2000);
      this.scene.environment = this.envRT.texture;
      this.scene.environmentIntensity = 0.1 + 0.42 * day * (1 + this.rain) + this.night * 0.1;
    }
  }

  moonDir(az, elev) {
    return new THREE.Vector3(-Math.cos(az) * 0.8, Math.max(0.35, -elev * 0.9), -Math.sin(az) * 0.8).normalize();
  }
}
