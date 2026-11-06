// PROTOTYPE - NOT FOR PRODUCTION
// First-person controller with AABB collisions, sprint/stamina, vehicles.
import * as THREE from 'three';
import { HALF, districtOf } from './world.js';
import { M } from './materials.js';
import { carGeometries } from './props.js';

export class Player {
  constructor(camera, world) {
    this.cam = camera; this.world = world;
    this.pos = new THREE.Vector3(-36, 0.15, 45);
    this.vel = new THREE.Vector3();
    this.yaw = 0; this.pitch = 0;
    this.keys = {};
    this.stamina = 1;
    this.radius = 0.38;
    this.bob = 0; this.onGround = true; this.vy = 0;
    this.eye = 1.68;
    this.vehicle = null; // id
    this.vehicleSpeed = 1;
    this.blockedMsgT = 0;
    this.stepT = 0;
    this.rig = new THREE.Group(); // vehicle view model
    camera.add(this.rig);
    this.models = {};
    this.speedNow = 0;
  }

  buildVehicleModels() {
    const mk = (fn) => { const g = new THREE.Group(); fn(g); g.visible = false; g.traverse((o) => { if (o.isMesh) { o.castShadow = false; o.receiveShadow = true; } }); this.rig.add(g); return g; };
    const bar = (g, w, mat) => { const b = new THREE.Mesh(new THREE.CylinderGeometry(0.018, 0.018, w, 10).rotateZ(Math.PI / 2), mat); g.add(b); return b; };
    this.models.scooter = mk((g) => {
      bar(g, 0.5, M.darkMetal).position.set(0, -0.35, -0.55);
      const st = new THREE.Mesh(new THREE.CylinderGeometry(0.02, 0.02, 1.0, 10), M.chrome); st.position.set(0, -0.85, -0.6); st.rotation.x = 0.2; g.add(st);
      const deck = new THREE.Mesh(new THREE.BoxGeometry(0.16, 0.04, 0.8), M.darkMetal); deck.position.set(0, -1.55, -0.2); g.add(deck);
      for (const s of [-1, 1]) { const grip = new THREE.Mesh(new THREE.CylinderGeometry(0.025, 0.025, 0.1, 10).rotateZ(Math.PI / 2), M.tire); grip.position.set(s * 0.25, -0.35, -0.55); g.add(grip); }
    });
    this.models.bike = mk((g) => {
      bar(g, 0.62, M.chrome).position.set(0, -0.42, -0.5);
      const st = new THREE.Mesh(new THREE.CylinderGeometry(0.02, 0.02, 0.6, 10), M.chrome); st.position.set(0, -0.7, -0.6); g.add(st);
      const fr = new THREE.Mesh(new THREE.CylinderGeometry(0.025, 0.025, 1.0, 10), new THREE.MeshStandardMaterial({ color: 0x0f5aa8, metalness: 0.6, roughness: 0.3 })); fr.position.set(0, -0.9, -0.2); fr.rotation.x = 1.2; g.add(fr);
      const wheel = new THREE.Mesh(new THREE.TorusGeometry(0.33, 0.025, 8, 32), M.tire); wheel.rotation.y = Math.PI / 2; wheel.position.set(0, -1.32, -0.9); g.add(wheel);
    });
    this.models.moto = mk((g) => {
      bar(g, 0.7, M.chrome).position.set(0, -0.45, -0.55);
      const tank = new THREE.Mesh(new THREE.SphereGeometry(0.22, 20, 14), M.carPaint.clone()); tank.material.color.set(0x111111); tank.scale.set(1, 0.6, 1.6); tank.position.set(0, -0.72, -0.2); g.add(tank);
      const dash = new THREE.Mesh(new THREE.CylinderGeometry(0.07, 0.07, 0.03, 20).rotateX(1.2), new THREE.MeshStandardMaterial({ color: 0x050505, emissive: 0xff5520, emissiveIntensity: 0.6 })); dash.position.set(0, -0.4, -0.65); g.add(dash);
      const head = new THREE.Mesh(new THREE.SphereGeometry(0.11, 16, 12), M.headlight); head.position.set(0, -0.55, -0.85); g.add(head);
    });
    this.models.car = mk((g) => {
      const cg = carGeometries();
      const paint = new THREE.MeshStandardMaterial({ color: 0x8a0c0c, roughness: 0.35, metalness: 0.5 });
      const body = new THREE.Mesh(cg.body, paint);
      body.rotation.y = Math.PI / 2; body.position.set(0, -1.2, 0.4);
      g.add(body);
      const dash = new THREE.Mesh(new THREE.BoxGeometry(1.5, 0.25, 0.4), new THREE.MeshStandardMaterial({ color: 0x151515, roughness: 0.6 })); dash.position.set(0, -0.45, -0.75); g.add(dash);
      const wheel = new THREE.Mesh(new THREE.TorusGeometry(0.17, 0.03, 10, 28), new THREE.MeshStandardMaterial({ color: 0x111111, roughness: 0.4 })); wheel.position.set(-0.38, -0.3, -0.55); wheel.rotation.x = -0.4; g.add(wheel);
      const frameMat = new THREE.MeshStandardMaterial({ color: 0x0a0a0a, roughness: 0.5 });
      for (const s of [-1, 1]) { const p = new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.9, 0.06), frameMat); p.position.set(s * 0.72, 0.0, -0.85); p.rotation.x = -0.5; p.rotation.z = s * 0.1; g.add(p); }
      const roof = new THREE.Mesh(new THREE.BoxGeometry(1.5, 0.05, 1.2), frameMat); roof.position.set(0, 0.38, -0.1); g.add(roof);
    });
  }

  setVehicle(id, speed) {
    for (const k in this.models) this.models[k].visible = false;
    this.vehicle = id; this.vehicleSpeed = id ? speed : 1;
    if (id && this.models[id]) this.models[id].visible = true;
    this.eye = id === 'car' ? 1.15 : id === 'moto' ? 1.5 : 1.68;
  }

  lookDir(out = new THREE.Vector3()) {
    return out.set(-Math.sin(this.yaw) * Math.cos(this.pitch), Math.sin(this.pitch), -Math.cos(this.yaw) * Math.cos(this.pitch));
  }

  onMouse(dx, dy, sens) {
    this.yaw -= dx * sens; this.pitch -= dy * sens;
    this.pitch = Math.max(-1.45, Math.min(1.45, this.pitch));
  }

  collide(nx, nz, y) {
    const r = this.radius + (this.vehicle === 'car' ? 0.6 : 0);
    for (const b of this.world.query(nx, nz)) {
      if (y > b.h) continue;
      const cx = Math.max(b.x0, Math.min(nx, b.x1)), cz = Math.max(b.z0, Math.min(nz, b.z1));
      const dx = nx - cx, dz = nz - cz;
      const d2 = dx * dx + dz * dz;
      if (d2 < r * r) {
        if (d2 > 1e-8) { const d = Math.sqrt(d2); nx = cx + (dx / d) * r; nz = cz + (dz / d) * r; }
        else {
          // inside: push out on smallest axis
          const pl = [nx - b.x0, b.x1 - nx, nz - b.z0, b.z1 - nz];
          const m = Math.min(...pl), i = pl.indexOf(m);
          if (i === 0) nx = b.x0 - r; else if (i === 1) nx = b.x1 + r; else if (i === 2) nz = b.z0 - r; else nz = b.z1 + r;
        }
      }
    }
    // traffic cars
    for (const c of this.world.traffic) {
      if (c.x === undefined) continue;
      const dx = nx - c.x, dz = nz - c.z;
      const along = Math.abs(Math.sin(c.yaw)) > 0.5;
      const hx = along ? 1.0 : 2.3, hz = along ? 2.3 : 1.0;
      if (Math.abs(dx) < hx + r && Math.abs(dz) < hz + r) {
        const px = hx + r - Math.abs(dx), pz = hz + r - Math.abs(dz);
        if (px < pz) nx += Math.sign(dx || 1) * px; else nz += Math.sign(dz || 1) * pz;
      }
    }
    return [nx, nz];
  }

  update(dt, ctx) {
    const k = this.keys;
    const fwd = (k.KeyW || k.ArrowUp ? 1 : 0) - (k.KeyS || k.ArrowDown ? 1 : 0);
    const str = (k.KeyD || k.ArrowRight ? 1 : 0) - (k.KeyA || k.ArrowLeft ? 1 : 0);
    const moving = fwd !== 0 || str !== 0;
    const sprint = (k.ShiftLeft || k.ShiftRight) && moving && this.stamina > 0.02 && !this.vehicle;
    if (sprint) this.stamina = Math.max(0, this.stamina - dt / ctx.staminaMax);
    else this.stamina = Math.min(1, this.stamina + dt * 0.18);
    let speed = 4.2 * ctx.speedMult * (sprint ? 1.75 : 1) * this.vehicleSpeed;
    if (this.vehicle && (k.ShiftLeft || k.ShiftRight)) speed *= 1.3;
    const sy = Math.sin(this.yaw), cy = Math.cos(this.yaw);
    const dir = new THREE.Vector3(-sy * fwd + cy * str, 0, -cy * fwd - sy * str);
    if (dir.lengthSq() > 0) dir.normalize();
    const accel = this.vehicle ? 3 : 10;
    this.vel.x += (dir.x * speed - this.vel.x) * Math.min(1, dt * accel);
    this.vel.z += (dir.z * speed - this.vel.z) * Math.min(1, dt * accel);
    // gravity / jump
    if (k.Space && this.onGround && !this.vehicle) { this.vy = 4.8; this.onGround = false; }
    this.vy -= 15 * dt;
    this.pos.y += this.vy * dt;
    const ground = this.groundHeight(this.pos.x, this.pos.z);
    if (this.pos.y <= ground) { this.pos.y = ground; this.vy = 0; this.onGround = true; }

    // sub-step movement for fast vehicles
    const steps = Math.ceil((Math.hypot(this.vel.x, this.vel.z) * dt) / 0.3) || 1;
    for (let s = 0; s < steps; s++) {
      let nx = this.pos.x + (this.vel.x * dt) / steps, nz = this.pos.z + (this.vel.z * dt) / steps;
      [nx, nz] = this.collide(nx, nz, this.pos.y + 0.3);
      // world bounds
      nx = Math.max(-HALF - 6, Math.min(HALF + 6, nx));
      nz = Math.max(-HALF - 6, Math.min(HALF + 6, nz));
      // locked districts
      const d = districtOf(nx, nz);
      if (!ctx.unlocked[d]) {
        // allow sliding along the boundary
        if (ctx.unlocked[districtOf(nx, this.pos.z)]) nz = this.pos.z;
        else if (ctx.unlocked[districtOf(this.pos.x, nz)]) nx = this.pos.x;
        else { nx = this.pos.x; nz = this.pos.z; }
        if (this.blockedMsgT <= 0) { ctx.onBlocked(d); this.blockedMsgT = 3; }
      }
      this.pos.x = nx; this.pos.z = nz;
    }
    this.blockedMsgT -= dt;
    const hs = Math.hypot(this.vel.x, this.vel.z);
    this.speedNow = hs;
    // head bob & footsteps
    if (this.onGround && hs > 0.5) {
      this.bob += dt * hs * (this.vehicle ? 0.3 : 1.9);
      this.stepT += dt * hs;
      if (!this.vehicle && this.stepT > (sprint ? 2.3 : 1.9)) { this.stepT = 0; ctx.onStep && ctx.onStep(sprint); }
    }
    const bobAmt = this.vehicle ? 0.008 : 0.045;
    const bobY = Math.sin(this.bob * 2) * bobAmt * Math.min(1, hs / 4);
    const bobX = Math.cos(this.bob) * bobAmt * 0.6 * Math.min(1, hs / 4);
    this.cam.position.set(this.pos.x + cy * bobX, this.pos.y + this.eye + bobY, this.pos.z - sy * bobX);
    const strafeTilt = this.vehicle ? -str * 0.04 * Math.min(1, hs / 10) : -str * 0.012;
    this.cam.rotation.set(this.pitch, this.yaw, 0, 'YXZ');
    this.cam.rotation.z = strafeTilt;
    // FOV with speed
    const fov = 72 + Math.min(18, Math.max(0, hs - 5) * 0.7);
    if (Math.abs(this.cam.fov - fov) > 0.05) { this.cam.fov += (fov - this.cam.fov) * Math.min(1, dt * 3); this.cam.updateProjectionMatrix(); }
    // vehicle viewmodel counter-rotates pitch so it stays level-ish
    this.rig.rotation.x = -this.pitch * 0.85;
  }

  groundHeight(x, z) {
    // sidewalks (blocks) are raised by the curb height
    const CELL = 72, R = 8;
    const lx = (((x + HALF) % CELL) + CELL) % CELL, lz = (((z + HALF) % CELL) + CELL) % CELL;
    return lx > R && lx < CELL - R && lz > R && lz < CELL - R ? 0.15 : 0;
  }
}
