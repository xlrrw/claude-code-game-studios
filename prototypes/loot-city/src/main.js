// PROTOTYPE - NOT FOR PRODUCTION
// Bootstrap: renderer, post-processing, loading, main loop.
import * as THREE from 'three';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
import { SMAAPass } from 'three/addons/postprocessing/SMAAPass.js';
import { ShaderPass } from 'three/addons/postprocessing/ShaderPass.js';
import { N8AOPass } from 'n8ao';
import { buildMaterials } from './materials.js';
import { setMaxAnisotropy } from './textures.js';
import { World } from './world.js';
import { Atmosphere } from './sky.js';
import { LootManager } from './loot.js';
import { Player } from './player.js';
import { Home } from './home.js';
import { Audio } from './audio.js';
import { Game } from './game.js';
import { DISTRICTS } from './data.js';

const $ = (id) => document.getElementById(id);
const nextFrame = () => new Promise((r) => requestAnimationFrame(() => setTimeout(r, 0)));

// Film look: vignette, subtle grain, slight color grading (applied after tone mapping)
const GradeShader = {
  uniforms: { tDiffuse: { value: null }, time: { value: 0 }, vignette: { value: 0.32 }, grain: { value: 0.025 }, night: { value: 0 } },
  vertexShader: 'varying vec2 vUv; void main(){ vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position,1.0); }',
  fragmentShader: `uniform sampler2D tDiffuse; uniform float time, vignette, grain, night; varying vec2 vUv;
    float h(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453); }
    void main(){
      vec4 c = texture2D(tDiffuse, vUv);
      vec3 col = c.rgb;
      // gentle S-curve + split toning (warm highlights, cool shadows)
      col = mix(col, col*col*(3.0-2.0*col), 0.22);
      float l = dot(col, vec3(0.299,0.587,0.114));
      col += (vec3(1.02,1.0,0.96)-1.0) * l + (vec3(0.97,0.99,1.04)-1.0) * (1.0-l) * (0.6 + night*0.6);
      col = mix(vec3(l), col, 1.08);
      vec2 d = vUv - 0.5;
      col *= 1.0 - vignette * dot(d,d) * 2.2;
      col += (h(vUv * 1000.0 + time) - 0.5) * grain;
      gl_FragColor = vec4(col, c.a);
    }`,
};

async function boot() {
  const canvas = $('game');
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: false, powerPreference: 'high-performance', stencil: false });
  renderer.setSize(innerWidth, innerHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 0.6;
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  setMaxAnisotropy(Math.min(16, renderer.capabilities.getMaxAnisotropy()));

  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(72, innerWidth / innerHeight, 0.05, 5000);
  scene.add(camera);

  const steps = 18; let step = 0;
  const progress = async (msg) => {
    step++;
    $('loadbar').style.width = Math.min(100, (step / steps) * 100) + '%';
    $('loadmsg').textContent = msg + '…';
    await nextFrame();
  };
  // material generation is synchronous; give the UI a frame between chunks
  const msgs = [];
  const syncProgress = (m) => msgs.push(m);
  await progress('Генерация текстур');
  buildMaterials((m) => { syncProgress(m); });
  await progress('Текстуры готовы');
  const world = new World(scene);
  world.generate((m) => syncProgress(m));
  await progress('Город построен');
  const atmo = new Atmosphere(renderer, scene);
  const loot = new LootManager(scene, world);
  const player = new Player(camera, world);
  const home = new Home(world);
  const audio = new Audio();
  await progress('Жители просыпаются');

  // ---- post-processing ----
  let composer, aoPass, bloom, grade, smaa;
  const buildComposer = (q) => {
    const pr = [0.75, 1, Math.min(devicePixelRatio, 1.5), Math.min(devicePixelRatio, 2)][q];
    renderer.setPixelRatio(pr);
    renderer.setSize(innerWidth, innerHeight);
    const sm = [1024, 2048, 4096, 4096][q];
    if (atmo.sun.shadow.mapSize.x !== sm) { atmo.sun.shadow.mapSize.set(sm, sm); atmo.sun.shadow.map?.dispose(); atmo.sun.shadow.map = null; }
    renderer.shadowMap.type = q === 0 ? THREE.PCFShadowMap : THREE.PCFSoftShadowMap;
    composer = new EffectComposer(renderer, new THREE.WebGLRenderTarget(innerWidth * pr, innerHeight * pr, { type: THREE.HalfFloatType, samples: 0 }));
    composer.setPixelRatio(pr); composer.setSize(innerWidth, innerHeight);
    if (q >= 1) {
      aoPass = new N8AOPass(scene, camera, innerWidth, innerHeight);
      Object.assign(aoPass.configuration, { aoRadius: 2.2, distanceFalloff: 1.2, intensity: 3.2, gammaCorrection: false, halfRes: q < 3, denoiseSamples: q >= 2 ? 8 : 4 });
      aoPass.setQualityMode(['Performance', 'Low', 'Medium', 'High'][q]);
      composer.addPass(aoPass);
    } else {
      aoPass = null;
      composer.addPass(new RenderPass(scene, camera));
    }
    bloom = new UnrealBloomPass(new THREE.Vector2(innerWidth, innerHeight), 0.35, 0.6, 0.92);
    if (q >= 1) composer.addPass(bloom);
    composer.addPass(new OutputPass());
    grade = new ShaderPass(GradeShader);
    composer.addPass(grade);
    if (q >= 1) { smaa = new SMAAPass(innerWidth * pr, innerHeight * pr); composer.addPass(smaa); }
  };

  const game = new Game({ scene, camera, world, loot, player, home, atmo, audio, renderer });
  game.applyQuality = (q) => buildComposer(q);
  buildComposer(game.settings.quality);
  audio.vol = game.settings.vol;
  game.start();
  // warm-up: compile shaders and build env map before showing
  atmo.update(0.016, game.s.time, player.pos);
  player.update(0.001, ctxFor(game));
  renderer.compile(scene, camera);
  await progress('Готово');

  $('loading').classList.add('hidden');
  $('start').classList.remove('hidden');
  $('playbtn').onclick = () => {
    $('start').classList.add('hidden'); $('hud').classList.remove('hidden');
    audio.init(); audio.setVolume(game.settings.vol);
    game.started = true;
    game.requestLock();
  };
  $('resetbtn').onclick = () => { if (confirm('Удалить сохранение и начать заново?')) game.reset(); };

  addEventListener('resize', () => {
    camera.aspect = innerWidth / innerHeight; camera.updateProjectionMatrix();
    renderer.setSize(innerWidth, innerHeight); composer.setSize(innerWidth, innerHeight);
  });

  const clock = new THREE.Clock();
  let fpsAcc = 0, fpsN = 0;
  function loop() {
    requestAnimationFrame(loop);
    const dt = Math.min(0.05, clock.getDelta());
    const active = game.started && !game.paused && !game.modalOpen;
    if (active) { player.update(dt, ctxFor(game)); }
    if (game.started && !game.paused) game.update(active ? dt : dt * 0.25);
    world.updateTraffic(game.paused ? 0 : dt, player.pos);
    atmo.update(dt, game.s.time, player.pos);
    loot.update(dt, camera.position, game.detect, game.time);
    audio.update(atmo.night, atmo.rain, player.speedNow, player.vehicle);
    // wet look on lamp light pools, AO tone at night
    if (aoPass) aoPass.configuration.intensity = 3.2 * (1 - atmo.night * 0.5);
    bloom.threshold = THREE.MathUtils.lerp(9, 1.2, atmo.night);
    bloom.strength = THREE.MathUtils.lerp(0.12, 0.5, atmo.night);
    grade.uniforms.time.value = game.time % 100;
    grade.uniforms.night.value = atmo.night;
    composer.render(dt);
    fpsAcc += dt; fpsN++;
    if (fpsAcc > 1) { $('fps').textContent = `${Math.round(fpsN / fpsAcc)} FPS`; fpsAcc = 0; fpsN = 0; }
  }
  loop();
  window.__game = game;
}

function ctxFor(game) {
  return {
    speedMult: game.speedMult,
    staminaMax: 4 * (1 + game.lvl('stamina') * 0.3),
    unlocked: game.s.unlocked,
    onBlocked: (d) => game.toast(`🔒 Район «${DISTRICTS[d].name}» закрыт. Пропуск — в мэрии у Петра Ильича (${'$' + DISTRICTS[d].cost.toLocaleString('ru-RU')}).`, '#ff5a5a'),
    onStep: (sp) => game.audio.step(sp),
  };
}

boot().catch((e) => {
  console.error(e);
  $('loadmsg').textContent = 'Ошибка запуска: ' + e.message;
});
