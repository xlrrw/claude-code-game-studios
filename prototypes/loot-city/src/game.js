// PROTOTYPE - NOT FOR PRODUCTION
// Game state, economy, NPCs, quests, random events and all UI screens.
import * as THREE from 'three';
import {
  RARITY, CATEGORIES, ITEMS, ITEM_BY_ID, COLLECTIONS, DISTRICTS, UPGRADES, upgradeCost, VEHICLES,
  HOME_STAGES, DECOR, BUSINESSES, businessCost, DAY_LENGTH, START,
} from './data.js';
import { HALF, CELL, N, roadLine, districtOf, CURB_H } from './world.js';
import { animatePerson } from './props.js';
import { makeTreasureChest } from './loot.js';

const SAVE_KEY = 'lootcity_save_v1';
const $ = (id) => document.getElementById(id);
const fmt = (n) => '$' + Math.floor(n).toLocaleString('ru-RU');
const esc = (s) => String(s).replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));

function freshState() {
  return {
    v: 1, money: START.money, earned: 0, inv: [], upg: {}, vehicles: [], vehicle: null,
    unlocked: [true, false, false, false], home: 0, decor: [], biz: {}, col: {}, colDone: [],
    quests: {}, rep: 0, time: 0.36, day: 1, stats: { found: 0, sold: 0, best: 0, legend: 0, events: 0 },
    market: {}, marketDay: 0, last: Date.now(), tutorial: 0, pos: null,
  };
}

const NPCS = [
  { id: 'pawn', name: 'Михалыч', role: 'Скупщик · Ломбард', icon: '💰', d: 0, look: { shirt: 0x6b4a2a, pants: 0x2a2a30, hair: 0x9a9a9a, skin: 0xd8a688 },
    greet: ['Чего притащил? Покажи, оценю по-честному… почти.', 'О, снова ты! Ломбард всегда рад товару.', 'Всё скупаю: от бутылок до бриллиантов.'] },
  { id: 'gear', name: 'Кирилл', role: 'Магазин снаряжения', icon: '🎒', d: 0, look: { shirt: 0x1c5a8a, pants: 0x30302a, hair: 0x3a2a1a, hat: 0x1c3a5a },
    greet: ['Хороший рюкзак — половина успеха, поверь мне.', 'Новинки завезли! Сканер ловит блеск за полквартала.'] },
  { id: 'garage', name: 'Гоша', role: 'Механик · Транспорт', icon: '🛵', d: 0, look: { shirt: 0x2a3a2a, pants: 0x1a2a4a, hair: 0x111111, hat: 0xb03020 },
    greet: ['Пешком далеко не уйдёшь. Глянь мои колёса!', 'Есть самокат, есть мотик… а есть кое-что для серьёзных людей.'] },
  { id: 'broker', name: 'Аркадий', role: 'Брокер · Бизнес', icon: '📈', d: 0, look: { shirt: 0x202838, pants: 0x202838, hair: 0x5a3a1a },
    greet: ['Деньги должны работать, пока ты спишь.', 'Вложись в автомат с газировкой — с этого начинали все магнаты.'] },
  { id: 'mayor', name: 'Пётр Ильич', role: 'Мэрия · Разрешения', icon: '🏛️', d: 0, look: { shirt: 0x3a3a3a, pants: 0x222222, hair: 0xb0b0b0 },
    greet: ['Проход в другие районы — только по пропуску. Порядок есть порядок.', 'Город большой, но не бесплатный.'] },
  { id: 'quest0', name: 'Бабушка Зина', role: 'Заказы Окраины', icon: '👵', d: 0, look: { shirt: 0x8a3a5a, pants: 0x3a2a3a, hair: 0xdddddd },
    greet: ['Внучок, помоги старушке, а я в долгу не останусь!', 'Ох, совсем без тебя никак.'] },
  { id: 'foreman', name: 'Степаныч', role: 'Прораб · Ваш участок', icon: '🏗️', d: 0, look: { shirt: 0xd08a1c, pants: 0x2a3a5a, hair: 0x3a3a3a, hat: 0xf2c230 },
    greet: ['Построим что угодно, были бы деньги.', 'Участок у тебя хороший. Тут бы особнячок…'] },
  { id: 'antiq', name: 'Вера', role: 'Антиквар · Центр', icon: '🏺', d: 1, look: { shirt: 0x5a1c3a, pants: 0x1a1a1a, hair: 0x8a2a1a },
    greet: ['Редкие вещи — моя страсть. Плачу щедрее Михалыча.', 'Есть у меня одна карта… За неё многие бы душу продали.'] },
  { id: 'quest1', name: 'Детектив Лёва', role: 'Заказы Центра', icon: '🕵️', d: 1, look: { shirt: 0x4a4030, pants: 0x2a2a2a, hair: 0x2a1a0a, hat: 0x3a3020 },
    greet: ['Тсс… есть работёнка. Деликатная.', 'Город полон улик. И потерянных ценностей.'] },
  { id: 'scrap', name: 'Толик', role: 'Металлобаза · Промзона', icon: '🔩', d: 2, look: { shirt: 0x4a5a6a, pants: 0x2a3a4a, hair: 0x1a1a1a, hat: 0xf28a1c },
    greet: ['Металл, хлам, железо — беру по лучшей цене!', 'Здесь, в промзоне, своя экономика.'] },
  { id: 'shadow', name: 'Тень', role: 'Чёрный рынок · только ночью', icon: '🌙', d: 2, night: true, look: { shirt: 0x0a0a0a, pants: 0x0a0a0a, hair: 0x050505, hat: 0x0a0a0a, skin: 0xa07a60 },
    greet: ['Вопросов не задаю. Плачу наличными.', 'Ночь — лучшее время для сделок.'] },
  { id: 'jeweler', name: 'Изабелла', role: 'Ювелирный салон · Холмы', icon: '💎', d: 3, look: { shirt: 0xf2f2f2, pants: 0x1a1a2a, hair: 0xe0c070 },
    greet: ['Драгоценности, искусство, антиквариат — только лучшее.', 'В Золотых холмах ценят вкус.'] },
  { id: 'quest3', name: 'Леди Маргарита', role: 'Заказы Холмов', icon: '👒', d: 3, look: { shirt: 0x7a1c2a, pants: 0x1a1a1a, hair: 0x2a1a0a },
    greet: ['Дорогуша, мне нужна помощь в одном изысканном деле.', 'Мой муж снова что-то потерял…'] },
];

// sell multipliers by NPC
function sellMult(npcId, def) {
  switch (npcId) {
    case 'pawn': return 1.0;
    case 'antiq': return def.r >= 2 ? 1.3 : 1.1;
    case 'scrap': return def.cat === 'metal' || def.cat === 'junk' ? 1.5 : 0.9;
    case 'shadow': return 1.4;
    case 'jeweler': return ['jewelry', 'antiques', 'art'].includes(def.cat) ? 1.6 : 0.8;
    default: return 1;
  }
}

export class Game {
  constructor(ctx) {
    Object.assign(this, ctx); // scene, camera, world, loot, player, home, atmo, audio, renderer
    this.s = this.load() || freshState();
    this.effects = []; // {id, name, t}
    this.eventTimer = 70;
    this.modalOpen = false; this.paused = false;
    this.npcs = [];
    this.markers = []; // special event markers {pos, color, t}
    this.passiveAcc = 0;
    this.time = 0;
    this.toastQ = [];
    this.lastPrompt = '';
    this.settings = Object.assign({ quality: 2, sens: 1, vol: 0.7 }, JSON.parse(localStorage.getItem('lootcity_settings') || '{}'));
  }

  // ---------------- persistence ----------------
  load() {
    try { const s = JSON.parse(localStorage.getItem(SAVE_KEY)); if (s && s.v === 1) return Object.assign(freshState(), s); } catch (e) { /* ignore */ }
    return null;
  }
  save() {
    this.s.last = Date.now();
    this.s.pos = [this.player.pos.x, this.player.pos.z, this.player.yaw];
    try { localStorage.setItem(SAVE_KEY, JSON.stringify(this.s)); } catch (e) { /* ignore */ }
  }
  saveSettings() { localStorage.setItem('lootcity_settings', JSON.stringify(this.settings)); }
  reset() { localStorage.removeItem(SAVE_KEY); location.reload(); }

  // ---------------- derived stats ----------------
  lvl(id) { return this.s.upg[id] || 0; }
  get slots() { return START.slots + this.lvl('backpack') * 3 + (this.s.colDone.includes('retro') ? 4 : 0); }
  get used() { return this.s.inv.reduce((a, i) => a + ITEM_BY_ID[i.id].slots, 0); }
  get speedMult() { return 1 + this.lvl('shoes') * 0.08; }
  get detect() { return 45 + this.lvl('detector') * 15; }
  get luck() {
    let l = this.lvl('luck') * 0.3 * (this.s.colDone.includes('jewels') ? 1.25 : 1);
    if (this.hasEffect('rain')) l += 0.5;
    if (this.hasEffect('ticket')) l += 1.5;
    if (this.atmo.night > 0.6) l += 0.3;
    return l;
  }
  get repLevel() { return Math.floor(Math.sqrt(this.s.rep)); }
  get prestige() {
    let p = HOME_STAGES[this.s.home].prestige;
    for (const d of this.s.decor) p += DECOR.find((x) => x.id === d).prestige;
    return p;
  }
  get tradeMult() {
    return (1 + this.lvl('trade') * 0.06) * (this.s.colDone.includes('coins') ? 1.1 : 1) * (1 + this.repLevel * 0.02) * (this.hasEffect('sale') ? 1.5 : 1);
  }
  get passivePerMin() {
    let p = 0;
    for (const b of BUSINESSES) p += (this.s.biz[b.id] || 0) * b.income;
    return p * (this.s.colDone.includes('art') ? 1.5 : 1) * (1 + this.prestige * 0.01);
  }
  marketMult(cat) { return this.s.market[cat] || 1; }
  price(item, npcId) {
    const def = ITEM_BY_ID[item.id];
    return Math.round(item.value * sellMult(npcId, def) * this.tradeMult * this.marketMult(def.cat));
  }
  hasEffect(id) { return this.effects.some((e) => e.id === id); }
  addEffect(id, name, t) { const e = this.effects.find((x) => x.id === id); if (e) e.t = Math.max(e.t, t); else this.effects.push({ id, name, t }); }

  // ---------------- setup ----------------
  start() {
    // NPCs
    const W = this.world;
    const plazaSpot = (d, k) => {
      const L = W.plazas[d];
      const cx = (L.x0 + L.x1) / 2, cz = (L.z0 + L.z1) / 2;
      const spots = [{ x: cx - 9, z: cz, yaw: Math.PI / 2 }, { x: cx + 9, z: cz, yaw: -Math.PI / 2 }];
      return spots[k];
    };
    const spotFor = {
      pawn: W.npcSpots.pawn, gear: W.npcSpots.gear, garage: W.npcSpots.garage, broker: W.npcSpots.broker,
      mayor: W.npcSpots.mayor, quest0: W.npcSpots.quest0, foreman: this.home.foremanSpot,
      antiq: { ...plazaSpot(1, 0), sign: 'АНТИКВАРИАТ', color: 0x5a1c3a }, quest1: { ...plazaSpot(1, 1), sign: 'ДЕТЕКТИВ', color: 0x3a3020 },
      scrap: { ...plazaSpot(2, 0), sign: 'МЕТАЛЛОБАЗА', color: 0x4a5a6a }, shadow: { ...plazaSpot(2, 1), sign: 'ЧЁРНЫЙ РЫНОК', color: 0x111111 },
      jeweler: { ...plazaSpot(3, 0), sign: 'ЮВЕЛИР', color: 0xc0a040 }, quest3: { ...plazaSpot(3, 1), sign: 'ЗАКАЗЫ', color: 0x7a1c2a },
    };
    for (const def of NPCS) {
      const p = W.placeNPC(spotFor[def.id], def.look);
      this.npcs.push({ def, ...p });
    }
    // world state from save
    W.updateBarriers(this.s.unlocked);
    this.home.setStage(this.s.home);
    for (const d of this.s.decor) this.home.addDecor(d);
    this.player.buildVehicleModels();
    if (this.s.vehicle) { const v = VEHICLES.find((x) => x.id === this.s.vehicle); if (v) this.player.setVehicle(v.id, v.speed); }
    if (this.s.pos) { this.player.pos.set(this.s.pos[0], 0, this.s.pos[1]); this.player.yaw = this.s.pos[2]; }
    if (!this.s.marketDay) this.rollMarket();
    // offline income
    const away = Math.min(7200, (Date.now() - this.s.last) / 1000);
    if (this.passivePerMin > 0 && away > 60) {
      const got = Math.round((this.passivePerMin * away) / 60 * 0.5);
      this.s.money += got; this.s.earned += got;
      setTimeout(() => this.toast(`Пока вас не было, бизнес принёс ${fmt(got)}`, '#5ee37a'), 1500);
    }
    this.loot.populate(DISTRICTS, this.s.unlocked, this.luck, 40, this.player.pos);
    this.bindUI();
    if (this.s.tutorial === 0) {
      // a few starter items right on the market square
      const L = this.world.marketLot, cx = (L.x0 + L.x1) / 2, cz = (L.z0 + L.z1) / 2;
      for (const [dx, dz, id] of [[-4, 4, 'bottle'], [5, 2, 'oldphone'], [-9, -4, 'scrap'], [10, 8, 'headphones'], [2, 15, 'can']]) {
        this.loot.spawn(ITEM_BY_ID[id], new THREE.Vector3(cx + dx, CURB_H + 0.02, cz + dz), DISTRICTS[0]);
      }
      setTimeout(() => this.toast('Добро пожаловать в Loot City! Ищите светящиеся предметы и нажимайте E.', '#ffb52e'), 800);
      setTimeout(() => this.toast('Продать находки можно Михалычу в ломбарде на рынке.', '#ffb52e'), 6000);
      this.s.tutorial = 1;
    }
    setInterval(() => this.save(), 15000);
    window.addEventListener('beforeunload', () => this.save());
  }

  rollMarket() {
    for (const c of Object.keys(CATEGORIES)) this.s.market[c] = Math.round((0.75 + Math.random() * 0.6) * 100) / 100;
    this.s.marketDay = this.s.day;
  }

  // ---------------- main update ----------------
  update(dt) {
    this.time += dt;
    const s = this.s;
    // clock
    s.time += dt / DAY_LENGTH;
    if (s.time >= 1) { s.time -= 1; s.day++; this.rollMarket(); this.toast(`Наступил день ${s.day}. Цены на рынке изменились.`, '#4aa8ff'); }
    // passive income
    const ppm = this.passivePerMin;
    if (ppm > 0) {
      this.passiveAcc += (ppm * dt) / 60;
      if (this.passiveAcc >= 1) { const w = Math.floor(this.passiveAcc); s.money += w; s.earned += w; this.passiveAcc -= w; }
    }
    // effects
    for (const e of this.effects) e.t -= dt;
    const expired = this.effects.filter((e) => e.t <= 0);
    for (const e of expired) { if (e.id === 'rain') this.atmo.rainTarget = 0; this.toast(`Событие закончилось: ${e.name}`, '#9aa6b2'); }
    this.effects = this.effects.filter((e) => e.t > 0);
    for (const m of this.markers) m.t -= dt;
    this.markers = this.markers.filter((m) => m.t > 0 && this.loot.items.includes(m.item));
    // special loot expiry
    for (const it of [...this.loot.items]) if (it.special && it.expire !== undefined) { it.expire -= dt; if (it.expire <= 0) this.loot.remove(it); }
    // random events
    this.eventTimer -= dt;
    if (this.eventTimer <= 0) { this.eventTimer = 110 + Math.random() * 110; this.randomEvent(); }
    // respawn loot
    this.loot.timer += dt;
    if (this.loot.timer > 6) { this.loot.timer = 0; this.loot.populate(DISTRICTS, s.unlocked, this.luck, 40, this.player.pos); }
    // NPCs
    const night = this.atmo.night > 0.5;
    for (const n of this.npcs) {
      const show = !n.def.night || night;
      n.person.visible = show;
      if (show && n.person.position.distanceTo(this.camera.position) < 60) animatePerson(n.person, this.time, n === this.talking);
    }
    this.updatePrompt();
    this.updateHUD();
  }

  nearNPC() {
    const p = this.player.pos;
    let best = null, bd = 3.6;
    for (const n of this.npcs) {
      if (n.def.night && this.atmo.night <= 0.5) continue;
      const d = Math.hypot(p.x - n.ix, p.z - n.iz);
      if (d < bd) { bd = d; best = n; }
    }
    return best;
  }

  updatePrompt() {
    const dir = this.player.lookDir();
    const it = this.modalOpen ? null : this.loot.pick(this.camera.position, dir, this.player.vehicle === 'car' ? 4.5 : 3.2);
    this.focusItem = it;
    const npc = this.modalOpen || it ? null : this.nearNPC();
    this.focusNPC = npc;
    let html = '';
    if (it) {
      const r = RARITY[it.def.r];
      html = it.chest
        ? `<div class="name" style="color:${r.color}">Сундук с сокровищами</div><div><kbd>E</kbd> Открыть</div>`
        : `<div class="name" style="color:${r.color}">${esc(it.def.name)}</div><div style="color:${r.color}">${r.name} · ~${fmt(it.value)} · ${it.def.slots} ${it.def.slots > 1 ? 'места' : 'место'}</div><div><kbd>E</kbd> Подобрать</div>`;
    } else if (npc) {
      html = `<div class="name">${npc.def.icon} ${esc(npc.def.name)}</div><div class="muted">${esc(npc.def.role)}</div><div><kbd>E</kbd> Поговорить</div>`;
    }
    if (html !== this.lastPrompt) { $('prompt').innerHTML = html; this.lastPrompt = html; }
  }

  updateHUD() {
    const s = this.s;
    $('money').textContent = fmt(s.money);
    const ppm = this.passivePerMin;
    $('income').textContent = ppm > 0 ? `+${fmt(ppm)}/мин` : '';
    $('bag').textContent = `${this.used}/${this.slots}`;
    $('bagpill').style.borderColor = this.used >= this.slots ? 'rgba(255,90,90,0.7)' : '';
    const d = districtOf(this.player.pos.x, this.player.pos.z);
    $('dist').textContent = DISTRICTS[d].name;
    $('distpill').style.color = DISTRICTS[d].color;
    const h = Math.floor(s.time * 24), m = Math.floor((s.time * 24 - h) * 60);
    const icon = this.atmo.night > 0.5 ? '🌙' : this.atmo.rain > 0.3 ? '🌧️' : '☀️';
    $('clock').textContent = `${icon} День ${s.day} · ${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
    $('stam').firstElementChild.style.width = (this.player.stamina * 100).toFixed(0) + '%';
    $('stam').style.opacity = this.player.stamina < 0.99 ? 1 : 0;
    const eh = this.effects.map((e) => `<span class="eff">${esc(e.name)} · ${Math.ceil(e.t)}с</span>`).join('');
    if (eh !== this._eh) { $('effects').innerHTML = eh; this._eh = eh; }
    this.drawMinimap();
  }

  // ---------------- minimap ----------------
  drawMinimap(big = null) {
    const c = big || $('minimap');
    const g = c.getContext('2d');
    const W = c.width, H = c.height;
    const p = this.player.pos;
    const scale = big ? W / (HALF * 2 + 40) : W / 260; // px per meter
    const cx = big ? 0 : p.x, cz = big ? 0 : p.z;
    const toS = (x, z) => [W / 2 + (x - cx) * scale, H / 2 + (z - cz) * scale];
    g.save();
    g.clearRect(0, 0, W, H);
    if (!big) { g.beginPath(); g.arc(W / 2, H / 2, W / 2, 0, Math.PI * 2); g.clip(); }
    g.fillStyle = '#0d1116'; g.fillRect(0, 0, W, H);
    // districts
    for (const d of DISTRICTS) {
      const x0 = d.id % 2 === 0 ? -HALF : 0, z0 = d.id >= 2 ? -HALF : 0;
      const [sx, sz] = toS(x0, z0);
      g.fillStyle = this.s.unlocked[d.id] ? d.color + '22' : 'rgba(255,40,40,0.10)';
      g.fillRect(sx, sz, HALF * scale, HALF * scale);
      if (big) { g.fillStyle = this.s.unlocked[d.id] ? d.color : '#ff6a6a'; g.font = 'bold 26px Segoe UI'; g.textAlign = 'center'; const [tx, tz] = toS(x0 + HALF / 2, z0 + HALF / 2 - 20); g.fillText(d.name + (this.s.unlocked[d.id] ? '' : ' 🔒'), tx, tz); }
    }
    // blocks
    g.fillStyle = 'rgba(255,255,255,0.10)';
    for (let i = 0; i < N; i++) for (let j = 0; j < N; j++) {
      const [sx, sz] = toS(roadLine(i) + 8, roadLine(j) + 8);
      g.fillRect(sx, sz, (CELL - 16) * scale, (CELL - 16) * scale);
    }
    // home
    const hl = this.world.homeLot;
    const [hx, hz] = toS((hl.x0 + hl.x1) / 2, (hl.z0 + hl.z1) / 2);
    g.fillStyle = '#5ee37a'; g.font = `${big ? 30 : 26}px Segoe UI`; g.textAlign = 'center'; g.textBaseline = 'middle';
    g.fillText('🏠', hx, hz);
    // npcs
    for (const n of this.npcs) {
      if (n.def.night && this.atmo.night <= 0.5) continue;
      const [sx, sz] = toS(n.ix, n.iz);
      g.font = `${big ? 22 : 18}px Segoe UI`;
      g.fillText(n.def.icon, sx, sz);
    }
    // loot
    for (const it of this.loot.items) {
      const d = it.pos.distanceTo(p);
      if (d > this.detect && !it.special) continue;
      const [sx, sz] = toS(it.pos.x, it.pos.z);
      g.fillStyle = RARITY[it.def.r].color;
      g.beginPath(); g.arc(sx, sz, it.special ? 7 : 4, 0, Math.PI * 2); g.fill();
      if (it.special) { g.strokeStyle = '#fff'; g.lineWidth = 2; g.stroke(); }
    }
    // player
    const [px, pz] = toS(p.x, p.z);
    g.translate(px, pz); g.rotate(-this.player.yaw);
    g.fillStyle = '#ffffff'; g.beginPath(); g.moveTo(0, -12); g.lineTo(8, 9); g.lineTo(0, 4); g.lineTo(-8, 9); g.closePath(); g.fill();
    g.restore();
    if (!big) { g.fillStyle = 'rgba(255,255,255,0.8)'; g.font = 'bold 22px Segoe UI'; g.textAlign = 'center'; g.fillText('С', W / 2, 26); }
  }

  // ---------------- interactions ----------------
  interact() {
    if (this.modalOpen) return;
    const it = this.focusItem;
    if (it) return this.pickup(it);
    const npc = this.focusNPC;
    if (npc) return this.openNPC(npc);
  }

  pickup(it) {
    const s = this.s;
    if (it.chest) {
      // treasure chest: gives several valuable items or their cash value
      let got = 0, cash = 0;
      for (let k = 0; k < 3; k++) {
        const def = this.loot.rollItem(DISTRICTS[it.district], this.luck, 2.5);
        const value = Math.round(def.v * (0.9 + Math.random() * 0.3));
        if (this.used + def.slots <= this.slots) { s.inv.push({ id: def.id, value }); got++; } else cash += value;
      }
      if (cash) { s.money += cash; s.earned += cash; }
      this.loot.remove(it);
      this.audio.pickup(4); this.audio.cash();
      this.toast(`Сундук открыт! ${got} предм. в рюкзак${cash ? `, ${fmt(cash)} наличными` : ''}`, '#ffb52e');
      return;
    }
    if (this.used + it.def.slots > this.slots) { this.audio.error(); this.toast('Рюкзак полон! Продайте вещи или купите рюкзак побольше.', '#ff5a5a'); return; }
    s.inv.push({ id: it.def.id, value: it.value });
    s.stats.found++;
    if (it.def.r === 4) s.stats.legend++;
    this.loot.remove(it);
    this.audio.pickup(it.def.r);
    const r = RARITY[it.def.r];
    this.toast(`<span class="rar" style="color:${r.color}"></span>${esc(it.def.name)} <span class="muted">· ${r.name} · ~${fmt(it.value)}</span>`, r.color);
    if (it.def.col && !(s.col[it.def.col] || []).includes(it.def.id)) this.toast('Этот предмет нужен для коллекции! Откройте телефон [Tab].', '#b26bff');
    // quest progress: pick in district
    for (const q of Object.values(s.quests)) if (q && q.type === 'pick' && districtOf(it.pos.x, it.pos.z) === q.d) q.prog = Math.min(q.n, (q.prog || 0) + 1);
  }

  randomEvent() {
    const s = this.s;
    const open = DISTRICTS.filter((d) => s.unlocked[d.id]);
    const d = open[Math.floor(Math.random() * open.length)];
    const evs = ['truck', 'sale', 'rain', 'courier', 'goldrush', 'treasure'];
    const ev = evs[Math.floor(Math.random() * evs.length)];
    s.stats.events++;
    this.audio.event();
    const sp = this.world.spawns[d.id];
    const at = sp[Math.floor(Math.random() * sp.length)];
    if (ev === 'truck') {
      for (let k = 0; k < 8; k++) {
        const pos = at.clone().add(new THREE.Vector3((Math.random() - 0.5) * 8, 0, (Math.random() - 0.5) * 8));
        pos.y = this.player.groundHeight(pos.x, pos.z);
        const it = this.loot.spawn(this.loot.rollItem(d, this.luck, 0.5), pos, d, true); it.expire = 150;
        this.markers.push({ item: it, t: 150 });
      }
      this.banner('🚚 Грузовик потерял груз!', `Ценные вещи рассыпались в районе «${d.name}». Отмечено на карте — 2.5 минуты!`);
    } else if (ev === 'sale') {
      this.addEffect('sale', 'Скупщики +50%', 120);
      this.banner('💸 Ажиотаж на рынке!', 'Все скупщики платят на 50% больше — 2 минуты.');
    } else if (ev === 'rain') {
      this.atmo.rainTarget = 1; this.addEffect('rain', 'Дождь: редкость ↑', 160);
      this.banner('🌧️ Начинается ливень', 'В дождь люди теряют больше ценностей. Шанс редких находок повышен.');
    } else if (ev === 'courier') {
      const def = this.loot.rollItem(d, this.luck, 4);
      const pos = at.clone(); pos.y = this.player.groundHeight(pos.x, pos.z);
      const it = this.loot.spawn(def.r < 3 ? ITEMS.filter((x) => x.r === 3)[Math.floor(Math.random() * 3)] : def, pos, d, true); it.expire = 150;
      this.markers.push({ item: it, t: 150 });
      this.banner('📦 Курьер потерял посылку', `Что-то очень ценное лежит в районе «${d.name}». Отмечено на карте!`);
    } else if (ev === 'goldrush') {
      this.addEffect('ticket', 'Золотая лихорадка', 75);
      this.banner('✨ Золотая лихорадка!', 'Следующие 75 секунд шанс эпических и легендарных находок резко выше.');
      // refresh some loot nearby
      this.loot.populate(DISTRICTS, s.unlocked, this.luck, 30, null);
    } else if (ev === 'treasure') {
      this.spawnChest(d, at);
      this.banner('🗺️ Слухи о кладе', `Говорят, в районе «${d.name}» кто-то зарыл сундук. Отмечено на карте!`);
    }
  }

  spawnChest(d, at) {
    const pos = at.clone(); pos.y = this.player.groundHeight(pos.x, pos.z);
    const it = this.loot.spawn(ITEM_BY_ID.faberge, pos, d, true);
    it.group.children[0].clear?.();
    it.group.remove(it.group.children[0]);
    it.group.add(makeTreasureChest());
    it.chest = true; it.expire = 240;
    this.markers.push({ item: it, t: 240 });
    return it;
  }

  // ---------------- toasts & banners ----------------
  toast(html, color = '#ffb52e') {
    const el = document.createElement('div');
    el.className = 'toast'; el.style.borderLeftColor = color; el.innerHTML = html;
    $('toasts').appendChild(el);
    while ($('toasts').children.length > 5) $('toasts').firstElementChild.remove();
    setTimeout(() => { el.style.transition = 'opacity .5s'; el.style.opacity = 0; setTimeout(() => el.remove(), 500); }, 5200);
  }
  banner(t, sub) {
    const b = $('banner');
    b.querySelector('.t').textContent = t; b.querySelector('.s').textContent = sub;
    b.classList.remove('hidden');
    clearTimeout(this._bt); this._bt = setTimeout(() => b.classList.add('hidden'), 7000);
  }

  // ---------------- modal framework ----------------
  openModal(render) {
    this.modalOpen = true;
    this.renderModal = render;
    $('modal').classList.remove('hidden');
    document.exitPointerLock?.();
    this.rerender();
  }
  rerender() { if (this.renderModal) { $('mcard').innerHTML = this.renderModal(); this.wire(); } }
  closeModal() {
    this.modalOpen = false; this.renderModal = null; this.talking = null;
    $('modal').classList.add('hidden');
    this.requestLock();
  }
  wire() {
    $('mcard').querySelectorAll('[data-a]').forEach((el) => {
      el.addEventListener('click', (e) => { e.stopPropagation(); this.action(el.dataset.a, el.dataset.v); });
    });
  }
  head(icon, title, sub) {
    return `<div class="mhead"><div class="av">${icon}</div><div><h3>${esc(title)}</h3><div class="sub">${sub}</div></div>
      <div class="x" style="text-align:right"><div class="price" style="font-size:20px">${fmt(this.s.money)}</div><div class="muted" style="font-size:12px">🎒 ${this.used}/${this.slots}</div></div>
      <button data-a="close" style="margin-left:10px">✕</button></div>`;
  }
  tabs(list, cur) { return `<div class="tabs">${list.map(([id, n]) => `<button data-a="tab" data-v="${id}" class="${id === cur ? 'on' : ''}">${n}</button>`).join('')}</div>`; }

  openNPC(npc) {
    this.talking = npc;
    const def = npc.def;
    const greet = def.greet[Math.floor(Math.random() * def.greet.length)];
    const tabs = [];
    if (['pawn', 'antiq', 'scrap', 'shadow', 'jeweler'].includes(def.id)) tabs.push(['sell', 'Продать']);
    if (def.id === 'gear') tabs.push(['upg', 'Улучшения']);
    if (def.id === 'garage') tabs.push(['veh', 'Транспорт']);
    if (def.id === 'broker') tabs.push(['biz', 'Бизнес']);
    if (def.id === 'mayor') tabs.push(['perm', 'Разрешения']);
    if (def.id === 'foreman') tabs.push(['build', 'Строительство'], ['decor', 'Благоустройство']);
    if (def.id === 'antiq') tabs.push(['maps', 'Карты кладов']);
    if (def.id === 'shadow') tabs.push(['black', 'Особый товар']);
    if (def.id.startsWith('quest') || def.id === 'scrap') tabs.push(['quest', 'Задание']);
    this.npcTab = tabs[0][0];
    this.openModal(() => {
      let body = `<div class="say">«${esc(greet)}»</div>`;
      body += this.npcBody(def, this.npcTab);
      return this.head(def.icon, def.name, esc(def.role)) + (tabs.length > 1 ? this.tabs(tabs, this.npcTab) : '') + `<div class="mbody">${body}</div>`;
    });
  }

  npcBody(def, tab) {
    const s = this.s;
    if (tab === 'sell') {
      if (!s.inv.length) return '<div class="muted">Рюкзак пуст. Возвращайтесь с добычей!</div>';
      let total = 0;
      const rows = s.inv.map((it, i) => {
        const d = ITEM_BY_ID[it.id], r = RARITY[d.r];
        const p = this.price(it, def.id); total += p;
        const mm = this.marketMult(d.cat);
        const trend = mm > 1.05 ? `<span style="color:var(--good)">▲${Math.round((mm - 1) * 100)}%</span>` : mm < 0.95 ? `<span style="color:var(--bad)">▼${Math.round((1 - mm) * 100)}%</span>` : '';
        const colNeed = d.col && !(s.col[d.col] || []).includes(d.id);
        return `<div class="row"><span class="rar" style="color:${r.color}"></span><div class="grow"><div class="t">${esc(d.name)}</div><div class="d">${r.name} · ${CATEGORIES[d.cat]} ${trend}${colNeed ? ' · <span style="color:#b26bff">нужен для коллекции</span>' : ''}</div></div>
          <div class="price">${fmt(p)}</div><button data-a="sell" data-v="${i}">Продать</button></div>`;
      }).join('');
      return `<div class="foot" style="padding:0 0 14px;border:none"><div class="grow muted">Множитель торговли: ×${this.tradeMult.toFixed(2)}${this.hasEffect('sale') ? ' (ажиотаж!)' : ''}</div><button class="primary" data-a="sellall">Продать всё (кроме коллекционных) за ${fmt(s.inv.reduce((a, it) => a + (ITEM_BY_ID[it.id].col && !(s.col[ITEM_BY_ID[it.id].col] || []).includes(it.id) ? 0 : this.price(it, def.id)), 0))}</button></div>${rows}`;
    }
    if (tab === 'upg') {
      return UPGRADES.map((u) => {
        const l = this.lvl(u.id), max = l >= u.max, c = upgradeCost(u, l);
        const pips = Array.from({ length: u.max }, (_, k) => `<i class="${k < l ? 'f' : ''}"></i>`).join('');
        return `<div class="row"><div class="grow"><div class="t">${u.name}<span class="lvl">${pips}</span></div><div class="d">${u.desc}</div></div>
          ${max ? '<div class="muted">Максимум</div>' : `<div class="price">${fmt(c)}</div><button data-a="upg" data-v="${u.id}" ${s.money < c ? 'disabled' : ''}>Купить</button>`}</div>`;
      }).join('');
    }
    if (tab === 'veh') {
      return VEHICLES.map((v) => {
        const own = s.vehicles.includes(v.id);
        return `<div class="row"><div class="grow"><div class="t">${v.name}</div><div class="d">${v.desc} Скорость ×${v.speed}</div></div>
          ${own ? `<button data-a="ride" data-v="${v.id}">${s.vehicle === v.id ? 'Слезть' : 'Ехать'}</button>` : `<div class="price">${fmt(v.cost)}</div><button data-a="veh" data-v="${v.id}" ${s.money < v.cost ? 'disabled' : ''}>Купить</button>`}</div>`;
      }).join('') + '<div class="muted" style="margin-top:8px">Клавиша <kbd>V</kbd> — сесть на лучший транспорт или слезть.</div>';
    }
    if (tab === 'biz') {
      return `<div class="muted" style="margin-bottom:10px">Доход сейчас: <b style="color:var(--good)">${fmt(this.passivePerMin)}/мин</b> (бонус престижа дома +${this.prestige}%). Пока вы оффлайн, бизнес работает вполсилы (до 2 часов).</div>` +
        BUSINESSES.map((b) => {
          const own = s.biz[b.id] || 0, c = businessCost(b, own), max = own >= b.max;
          return `<div class="row"><div class="grow"><div class="t">${b.name} <span class="muted">×${own}/${b.max}</span></div><div class="d">+${fmt(b.income)}/мин за каждый</div></div>
            ${max ? '<div class="muted">Максимум</div>' : `<div class="price">${fmt(c)}</div><button data-a="biz" data-v="${b.id}" ${s.money < c ? 'disabled' : ''}>Купить</button>`}</div>`;
        }).join('');
    }
    if (tab === 'perm') {
      return DISTRICTS.map((d) => {
        const own = s.unlocked[d.id];
        return `<div class="row"><div class="grow"><div class="t" style="color:${d.color}">${d.name}</div><div class="d">${d.desc} Ценность находок ×${d.lootMult}</div></div>
          ${own ? '<div style="color:var(--good)">Открыт</div>' : `<div class="price">${fmt(d.cost)}</div><button data-a="perm" data-v="${d.id}" ${s.money < d.cost ? 'disabled' : ''}>Купить пропуск</button>`}</div>`;
      }).join('');
    }
    if (tab === 'build') {
      return HOME_STAGES.map((h, i) => {
        if (i === 0) return '';
        const done = s.home >= i, next = s.home === i - 1;
        return `<div class="row"><div class="grow"><div class="t">${h.name}</div><div class="d">Престиж +${h.prestige}</div></div>
          ${done ? '<div style="color:var(--good)">Построено</div>' : next ? `<div class="price">${fmt(h.cost)}</div><button data-a="build" data-v="${i}" ${s.money < h.cost ? 'disabled' : ''}>Построить</button>` : '<div class="muted">Сначала предыдущий этап</div>'}</div>`;
      }).join('');
    }
    if (tab === 'decor') {
      return DECOR.map((d) => {
        const own = s.decor.includes(d.id), ok = s.home >= d.needStage;
        return `<div class="row"><div class="grow"><div class="t">${d.name}</div><div class="d">Престиж +${d.prestige} · требуется: ${HOME_STAGES[d.needStage].name}</div></div>
          ${own ? '<div style="color:var(--good)">Есть</div>' : !ok ? '<div class="muted">Недоступно</div>' : `<div class="price">${fmt(d.cost)}</div><button data-a="decor" data-v="${d.id}" ${s.money < d.cost ? 'disabled' : ''}>Купить</button>`}</div>`;
      }).join('');
    }
    if (tab === 'maps') {
      const c = 1500 + s.day * 100;
      return `<div class="row"><div class="grow"><div class="t">Карта клада</div><div class="d">Отмечает сундук с тремя ценными находками в одном из открытых районов.</div></div><div class="price">${fmt(c)}</div><button data-a="map" data-v="${c}" ${s.money < c ? 'disabled' : ''}>Купить</button></div>`;
    }
    if (tab === 'black') {
      return `<div class="row"><div class="grow"><div class="t">Счастливый билет</div><div class="d">3 минуты сильно повышенной удачи.</div></div><div class="price">${fmt(2500)}</div><button data-a="ticket" ${s.money < 2500 ? 'disabled' : ''}>Купить</button></div>`;
    }
    if (tab === 'quest') return this.questBody(def);
    return '';
  }

  // ---------------- quests ----------------
  questDistrict(def) { return def.d; }
  newQuest(def) {
    const d = def.d;
    const r = Math.random();
    const scale = [1, 3, 8, 20][d];
    if (r < 0.3) {
      const cats = [['junk', 'metal', 'electronics'], ['electronics', 'cash', 'metal'], ['metal', 'junk', 'electronics'], ['jewelry', 'antiques', 'art']][d];
      const cat = cats[Math.floor(Math.random() * cats.length)];
      const n = 2 + Math.floor(Math.random() * 2);
      return { type: 'cat', cat, n, reward: Math.round((60 + Math.random() * 40) * n * scale), text: `Принеси ${n} предм. категории «${CATEGORIES[cat]}».` };
    }
    if (r < 0.55) {
      const rar = Math.min(4, 1 + d + (Math.random() < 0.3 ? 1 : 0));
      return { type: 'rar', rar, reward: Math.round([0, 150, 600, 2500, 9000][rar] * (1 + d * 0.3)), text: `Принеси любой предмет редкости «${RARITY[rar].name}» или выше.` };
    }
    if (r < 0.8) {
      const n = 4 + Math.floor(Math.random() * 5);
      return { type: 'pick', d, n, prog: 0, reward: Math.round(40 * n * scale), text: `Подбери ${n} предметов в районе «${DISTRICTS[d].name}».` };
    }
    const amt = Math.round((300 + Math.random() * 500) * scale / 50) * 50;
    return { type: 'earn', amt, prog: 0, reward: Math.round(amt * 0.4), text: `Заработай ${fmt(amt)} на продажах.` };
  }
  questReady(q) {
    const inv = this.s.inv;
    if (q.type === 'cat') return inv.filter((i) => ITEM_BY_ID[i.id].cat === q.cat && !ITEM_BY_ID[i.id].col).length >= q.n;
    if (q.type === 'rar') return inv.some((i) => ITEM_BY_ID[i.id].r >= q.rar);
    if (q.type === 'pick') return q.prog >= q.n;
    if (q.type === 'earn') return q.prog >= q.amt;
    return false;
  }
  questProgressText(q) {
    const inv = this.s.inv;
    if (q.type === 'cat') return `${Math.min(q.n, inv.filter((i) => ITEM_BY_ID[i.id].cat === q.cat && !ITEM_BY_ID[i.id].col).length)}/${q.n} в рюкзаке`;
    if (q.type === 'rar') return this.questReady(q) ? 'Есть в рюкзаке' : 'Нет в рюкзаке';
    if (q.type === 'pick') return `${q.prog}/${q.n}`;
    if (q.type === 'earn') return `${fmt(q.prog)} / ${fmt(q.amt)}`;
    return '';
  }
  questBody(def) {
    const s = this.s;
    let q = s.quests[def.id];
    if (!q) { q = s.quests[def.id] = this.newQuest(def); }
    const ready = this.questReady(q);
    return `<div class="col"><h4>📜 ${esc(q.text)}</h4><div class="muted">Прогресс: ${this.questProgressText(q)}</div>
      <div style="margin-top:10px;display:flex;gap:10px;align-items:center"><div class="grow">Награда: <span class="price">${fmt(q.reward)}</span> + репутация</div>
      <button class="primary" data-a="qdone" ${ready ? '' : 'disabled'}>Сдать задание</button><button data-a="qskip">Другое задание</button></div></div>
      <div class="muted">Репутация: ${s.rep} (уровень ${this.repLevel}, +${this.repLevel * 2}% к ценам продажи)</div>`;
  }
  completeQuest(def) {
    const s = this.s, q = s.quests[def.id];
    if (!q || !this.questReady(q)) return;
    if (q.type === 'cat') {
      let n = q.n;
      s.inv = s.inv.filter((i) => { if (n > 0 && ITEM_BY_ID[i.id].cat === q.cat && !ITEM_BY_ID[i.id].col) { n--; return false; } return true; });
    } else if (q.type === 'rar') {
      // hand over the cheapest qualifying item
      const c = s.inv.filter((i) => ITEM_BY_ID[i.id].r >= q.rar).sort((a, b) => a.value - b.value)[0];
      s.inv.splice(s.inv.indexOf(c), 1);
    }
    s.money += q.reward; s.earned += q.reward; s.rep += 1 + def.d;
    this.audio.cash();
    this.toast(`Задание выполнено! +${fmt(q.reward)}`, '#5ee37a');
    s.quests[def.id] = null;
  }

  // ---------------- actions ----------------
  action(a, v) {
    const s = this.s, npc = this.talking;
    const pay = (c) => { if (s.money < c) { this.audio.error(); return false; } s.money -= c; this.audio.cash(); return true; };
    switch (a) {
      case 'close': return this.closeModal();
      case 'tab': this.npcTab = v; this.phoneTab = v; break;
      case 'sell': { const it = s.inv[+v]; if (!it) break; const p = this.price(it, npc.def.id); this.sold(p); s.inv.splice(+v, 1); this.audio.cash(); break; }
      case 'sellall': {
        let tot = 0;
        s.inv = s.inv.filter((it) => { const d = ITEM_BY_ID[it.id]; if (d.col && !(s.col[d.col] || []).includes(d.id)) return true; tot += this.price(it, npc.def.id); return false; });
        if (tot) { this.sold(tot); this.audio.cash(); this.toast(`Продано на ${fmt(tot)}`, '#5ee37a'); }
        break;
      }
      case 'upg': { const u = UPGRADES.find((x) => x.id === v); const l = this.lvl(v); if (l < u.max && pay(upgradeCost(u, l))) { s.upg[v] = l + 1; this.toast(`${u.name}: уровень ${l + 1}`, '#4aa8ff'); } break; }
      case 'veh': { const vv = VEHICLES.find((x) => x.id === v); if (pay(vv.cost)) { s.vehicles.push(v); this.toast(`Куплен транспорт: ${vv.name}! Нажмите V.`, '#4aa8ff'); this.ride(v); } break; }
      case 'ride': this.ride(s.vehicle === v ? null : v); break;
      case 'biz': { const b = BUSINESSES.find((x) => x.id === v); const own = s.biz[v] || 0; if (own < b.max && pay(businessCost(b, own))) { s.biz[v] = own + 1; this.toast(`Куплено: ${b.name}`, '#5ee37a'); } break; }
      case 'perm': { const d = DISTRICTS[+v]; if (!s.unlocked[d.id] && pay(d.cost)) { s.unlocked[d.id] = true; this.world.updateBarriers(s.unlocked); this.banner(`🔓 Открыт район «${d.name}»`, d.desc); this.loot.populate(DISTRICTS, s.unlocked, this.luck, 40, this.player.pos); } break; }
      case 'build': { const i = +v; if (s.home === i - 1 && pay(HOME_STAGES[i].cost)) { s.home = i; this.home.setStage(i); this.banner('🏗️ Стройка завершена!', `Ваш новый дом: ${HOME_STAGES[i].name}`); } break; }
      case 'decor': { const d = DECOR.find((x) => x.id === v); if (!s.decor.includes(v) && pay(d.cost)) { s.decor.push(v); this.home.addDecor(v); this.toast(`Установлено: ${d.name}`, '#5ee37a'); } break; }
      case 'map': { if (pay(+v)) { const open = DISTRICTS.filter((d) => s.unlocked[d.id]); const d = open[Math.floor(Math.random() * open.length)]; const sp = this.world.spawns[d.id]; this.spawnChest(d, sp[Math.floor(Math.random() * sp.length)]); this.toast(`Клад отмечен на карте в районе «${d.name}»!`, '#ffb52e'); } break; }
      case 'ticket': if (pay(2500)) { this.addEffect('ticket', 'Счастливый билет', 180); } break;
      case 'qdone': this.completeQuest(npc.def); break;
      case 'qskip': s.quests[npc.def.id] = this.newQuest(npc.def); break;
      case 'drop': { const it = s.inv[+v]; if (!it) break; s.inv.splice(+v, 1); const def = ITEM_BY_ID[it.id]; const p = this.player.pos.clone(); const dir = this.player.lookDir(); p.x += dir.x * 1.2; p.z += dir.z * 1.2; p.y = this.player.groundHeight(p.x, p.z); const li = this.loot.spawn(def, p, DISTRICTS[districtOf(p.x, p.z)]); li.value = it.value; break; }
      case 'collect': {
        const it = s.inv[+v]; if (!it) break; const def = ITEM_BY_ID[it.id];
        const arr = (s.col[def.col] = s.col[def.col] || []);
        if (!arr.includes(def.id)) { arr.push(def.id); s.inv.splice(+v, 1); this.audio.pickup(3); this.checkCollections(); }
        break;
      }
      case 'taxi': if (pay(50)) { const hl = this.world.homeLot; this.player.pos.set((hl.x0 + hl.x1) / 2 - 3, CURB_H, hl.z0 - 4); this.closeModal(); this.toast('Такси доставило вас домой.', '#ffb52e'); return; } break;
      case 'quality': this.settings.quality = +v; this.saveSettings(); this.applyQuality(+v); break;
    }
    this.rerender();
  }

  sold(p) {
    const s = this.s;
    s.money += p; s.earned += p; s.stats.sold++; s.stats.best = Math.max(s.stats.best, p);
    for (const q of Object.values(s.quests)) if (q && q.type === 'earn') q.prog = Math.min(q.amt, (q.prog || 0) + p);
    this.save();
  }

  ride(v) {
    const s = this.s;
    if (v && !s.vehicles.includes(v)) return;
    s.vehicle = v;
    const vv = VEHICLES.find((x) => x.id === v);
    this.player.setVehicle(v, vv ? vv.speed : 1);
  }
  toggleVehicle() {
    const s = this.s;
    if (s.vehicle) return this.ride(null);
    const best = [...VEHICLES].reverse().find((v) => s.vehicles.includes(v.id));
    if (best) this.ride(best.id); else this.toast('У вас пока нет транспорта. Загляните к механику Гоше.', '#9aa6b2');
  }

  checkCollections() {
    const s = this.s;
    for (const c of COLLECTIONS) {
      if (s.colDone.includes(c.id)) continue;
      const need = ITEMS.filter((i) => i.col === c.id).map((i) => i.id);
      if (need.every((id) => (s.col[c.id] || []).includes(id))) {
        s.colDone.push(c.id); s.money += c.reward; s.earned += c.reward;
        this.audio.event();
        this.banner(`🏆 Коллекция «${c.name}» собрана!`, `Награда ${fmt(c.reward)} и бонус: ${c.bonusText}`);
      }
    }
  }

  // ---------------- phone ----------------
  openPhone(tab = 'inv') {
    if (this.modalOpen) { this.closeModal(); return; }
    this.phoneTab = tab;
    const tabs = [['inv', '🎒 Рюкзак'], ['col', '🏆 Коллекции'], ['quests', '📜 Задания'], ['market', '📊 Рынок'], ['map', '🗺️ Карта'], ['stats', '📈 Статистика']];
    this.openModal(() => {
      const body = this.phoneBody(this.phoneTab);
      return this.head('📱', 'Телефон', `День ${this.s.day} · Репутация ${this.s.rep}`) + this.tabs(tabs, this.phoneTab) + `<div class="mbody">${body}</div>`;
    });
    if (tab === 'map') setTimeout(() => this.drawBig(), 0);
  }
  drawBig() { const c = document.getElementById('bigmap'); if (c) this.drawMinimap(c); }

  phoneBody(tab) {
    const s = this.s;
    if (tab === 'inv') {
      const rows = s.inv.map((it, i) => {
        const d = ITEM_BY_ID[it.id], r = RARITY[d.r];
        const colNeed = d.col && !(s.col[d.col] || []).includes(d.id);
        return `<div class="row"><span class="rar" style="color:${r.color}"></span><div class="grow"><div class="t">${esc(d.name)}</div><div class="d">${r.name} · ${CATEGORIES[d.cat]} · ${d.slots} мест · оценка ~${fmt(it.value)}</div></div>
          ${colNeed ? `<button class="primary" data-a="collect" data-v="${i}">В коллекцию</button>` : ''}<button data-a="drop" data-v="${i}">Выбросить</button></div>`;
      }).join('') || '<div class="muted">Рюкзак пуст.</div>';
      return `<div class="foot" style="padding:0 0 14px;border:none"><div class="grow muted">Занято ${this.used} из ${this.slots} мест</div><button data-a="taxi">🚕 Такси домой ($50)</button></div>${rows}`;
    }
    if (tab === 'col') {
      return COLLECTIONS.map((c) => {
        const items = ITEMS.filter((i) => i.col === c.id);
        const have = s.col[c.id] || [];
        const done = s.colDone.includes(c.id);
        return `<div class="col"><h4>${done ? '✅' : '🏆'} ${c.name} <span class="muted">${have.length}/${items.length}</span></h4><div class="muted" style="font-size:13px">Бонус: ${c.bonusText} · награда ${fmt(c.reward)}</div>
          <div class="slots">${items.map((i) => `<span class="slot ${have.includes(i.id) ? 'have' : ''}" style="${have.includes(i.id) ? '' : `color:${RARITY[i.r].color}`}">${have.includes(i.id) ? '✓ ' : ''}${esc(i.name)}</span>`).join('')}</div></div>`;
      }).join('') + '<div class="muted">Подобранные коллекционные предметы можно поместить в коллекцию через вкладку «Рюкзак».</div>';
    }
    if (tab === 'quests') {
      const list = NPCS.filter((n) => n.id.startsWith('quest') || n.id === 'scrap');
      return list.map((n) => {
        const q = s.quests[n.id];
        const locked = !s.unlocked[n.d];
        return `<div class="row"><div class="av" style="font-size:24px">${n.icon}</div><div class="grow"><div class="t">${n.name} <span class="muted">· ${DISTRICTS[n.d].name}</span></div>
          <div class="d">${locked ? 'Район закрыт' : q ? `${esc(q.text)} — ${this.questProgressText(q)}${this.questReady(q) ? ' <b style="color:var(--good)">Готово к сдаче!</b>' : ''}` : 'Зайдите за новым заданием'}</div></div>${q ? `<div class="price">${fmt(q.reward)}</div>` : ''}</div>`;
      }).join('');
    }
    if (tab === 'market') {
      return '<div class="muted" style="margin-bottom:10px">Цены меняются каждый игровой день. Продавайте, когда категория в плюсе.</div>' + Object.entries(CATEGORIES).map(([k, n]) => {
        const m = this.marketMult(k);
        const col = m > 1.05 ? 'var(--good)' : m < 0.95 ? 'var(--bad)' : 'var(--txt)';
        return `<div class="row"><div class="grow t">${n}</div><div style="color:${col};font-weight:700">×${m.toFixed(2)}</div><div class="prog" style="width:200px"><div style="width:${Math.min(100, m / 1.4 * 100)}%;background:${col}"></div></div></div>`;
      }).join('') + `<div class="col" style="margin-top:14px"><h4>Лучшие покупатели</h4><div class="muted" style="font-size:13px;line-height:1.6">
        💰 Михалыч (Окраина) — всё по базовой цене<br>🏺 Вера (Центр) — +10%, редкие и выше +30%<br>🔩 Толик (Промзона) — металл и хлам +50%<br>🌙 Тень (Промзона, ночью) — всё +40%<br>💎 Изабелла (Холмы) — драгоценности, антиквариат, искусство +60%</div></div>`;
    }
    if (tab === 'map') return '<canvas id="bigmap" width="1000" height="1000"></canvas>';
    if (tab === 'stats') {
      const st = s.stats;
      const rows = [['Всего заработано', fmt(s.earned)], ['Найдено предметов', st.found], ['Продано предметов', st.sold], ['Самая дорогая сделка', fmt(st.best)], ['Легендарных находок', st.legend], ['Событий в городе', st.events], ['Дом', HOME_STAGES[s.home].name], ['Престиж', this.prestige], ['Пассивный доход', fmt(this.passivePerMin) + '/мин'], ['Открыто районов', s.unlocked.filter(Boolean).length + '/4'], ['Коллекций собрано', s.colDone.length + '/' + COLLECTIONS.length]];
      const king = s.home === 5 && s.colDone.length === COLLECTIONS.length && s.unlocked.every(Boolean);
      return (king ? '<div class="say">👑 Вы — Король Loot City! Все районы, все коллекции и особняк. Легенда улиц.</div>' : '<div class="say">Цель: открыть все районы, собрать все коллекции и построить особняк — стать Королём города.</div>') +
        rows.map(([a, b]) => `<div class="row"><div class="grow">${a}</div><div class="t">${b}</div></div>`).join('');
    }
    return '';
  }

  // ---------------- input/UI binding ----------------
  bindUI() {
    const canvas = this.renderer.domElement;
    $('modal').addEventListener('click', (e) => { if (e.target.id === 'modal') this.closeModal(); });
    document.addEventListener('keydown', (e) => {
      if (e.code === 'Tab') { e.preventDefault(); if (!this.paused) this.openPhone('inv'); return; }
      if (e.code === 'KeyM' && !this.paused) { if (this.modalOpen && this.phoneTab === 'map') this.closeModal(); else { if (this.modalOpen) this.closeModal(); this.openPhone('map'); } return; }
      if (e.code === 'Escape') { if (this.modalOpen) { this.closeModal(); } return; }
      if (this.modalOpen || this.paused) return;
      this.player.keys[e.code] = true;
      if (e.code === 'KeyE') this.interact();
      if (e.code === 'KeyV') this.toggleVehicle();
    });
    document.addEventListener('keyup', (e) => { this.player.keys[e.code] = false; });
    document.addEventListener('mousemove', (e) => {
      if (document.pointerLockElement === canvas) this.player.onMouse(e.movementX, e.movementY, 0.0022 * this.settings.sens);
    });
    canvas.addEventListener('click', () => { if (!this.modalOpen) this.requestLock(); });
    document.addEventListener('pointerlockchange', () => {
      const locked = document.pointerLockElement === canvas;
      if (!locked && !this.modalOpen && this.started) this.setPaused(true);
      if (locked) this.setPaused(false);
    });
    $('resume').onclick = () => this.requestLock();
    $('savebtn').onclick = () => { this.save(); this.toast('Игра сохранена', '#5ee37a'); };
    $('fsbtn').onclick = () => { if (document.fullscreenElement) document.exitFullscreen(); else document.documentElement.requestFullscreen(); };
    $('quality').value = this.settings.quality;
    $('quality').onchange = (e) => { this.settings.quality = +e.target.value; this.saveSettings(); this.applyQuality(+e.target.value); };
    $('sens').value = this.settings.sens; $('sens').oninput = (e) => { this.settings.sens = +e.target.value; this.saveSettings(); };
    $('vol').value = this.settings.vol; $('vol').oninput = (e) => { this.settings.vol = +e.target.value; this.audio.setVolume(this.settings.vol); this.saveSettings(); };
  }
  setPaused(p) {
    this.paused = p;
    $('paused').classList.toggle('hidden', !p);
    for (const k in this.player.keys) this.player.keys[k] = false;
  }
  requestLock() {
    const c = this.renderer.domElement;
    try { const r = c.requestPointerLock(); if (r && r.catch) r.catch(() => {}); } catch (e) { /* ignore */ }
  }
}
