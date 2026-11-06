// PROTOTYPE - NOT FOR PRODUCTION
// Procedural WebAudio: city ambience, rain, footsteps, pickups, cash, engine.
export class Audio {
  constructor() { this.ctx = null; this.vol = 0.8; }
  init() {
    if (this.ctx) return;
    const C = (this.ctx = new (window.AudioContext || window.webkitAudioContext)());
    this.master = C.createGain(); this.master.gain.value = this.vol; this.master.connect(C.destination);
    const len = C.sampleRate * 3;
    const buf = C.createBuffer(1, len, C.sampleRate), d = buf.getChannelData(0);
    let b0 = 0, b1 = 0, b2 = 0;
    for (let i = 0; i < len; i++) { const w = Math.random() * 2 - 1; b0 = 0.99765 * b0 + w * 0.099; b1 = 0.963 * b1 + w * 0.2965; b2 = 0.57 * b2 + w * 1.0526; d[i] = (b0 + b1 + b2 + w * 0.1848) * 0.2; }
    this.noise = buf;
    // city hum
    this.amb = this.loop(0.0, 'lowpass', 500);
    this.rain = this.loop(0.0, 'highpass', 1200);
    this.wind = this.loop(0.0, 'bandpass', 700);
    // engine
    this.eng = C.createOscillator(); this.eng.type = 'sawtooth'; this.eng.frequency.value = 50;
    const ef = C.createBiquadFilter(); ef.type = 'lowpass'; ef.frequency.value = 400;
    this.engGain = C.createGain(); this.engGain.gain.value = 0;
    this.eng.connect(ef); ef.connect(this.engGain); this.engGain.connect(this.master); this.eng.start();
  }
  loop(gain, type, freq) {
    const C = this.ctx;
    const s = C.createBufferSource(); s.buffer = this.noise; s.loop = true;
    const f = C.createBiquadFilter(); f.type = type; f.frequency.value = freq;
    const g = C.createGain(); g.gain.value = gain;
    s.connect(f); f.connect(g); g.connect(this.master); s.start();
    return g;
  }
  setVolume(v) { this.vol = v; if (this.master) this.master.gain.value = v; }
  update(night, rain, speed, vehicle) {
    if (!this.ctx) return;
    const t = this.ctx.currentTime;
    this.amb.gain.setTargetAtTime(0.25 * (1 - night * 0.5), t, 0.5);
    this.rain.gain.setTargetAtTime(rain * 0.35, t, 0.5);
    this.wind.gain.setTargetAtTime(Math.min(0.25, speed * 0.008), t, 0.2);
    const motor = vehicle === 'moto' || vehicle === 'car';
    this.engGain.gain.setTargetAtTime(motor ? 0.05 + Math.min(0.06, speed * 0.002) : 0, t, 0.2);
    this.eng.frequency.setTargetAtTime((vehicle === 'car' ? 38 : 55) + speed * 3.2, t, 0.1);
  }
  blip(freqs, dur = 0.12, type = 'sine', vol = 0.18) {
    if (!this.ctx) return;
    const C = this.ctx, t = C.currentTime;
    freqs.forEach((f, i) => {
      const o = C.createOscillator(); o.type = type; o.frequency.value = f;
      const g = C.createGain(); g.gain.setValueAtTime(0, t + i * dur * 0.6); g.gain.linearRampToValueAtTime(vol, t + i * dur * 0.6 + 0.01); g.gain.exponentialRampToValueAtTime(0.001, t + i * dur * 0.6 + dur * 2);
      o.connect(g); g.connect(this.master); o.start(t + i * dur * 0.6); o.stop(t + i * dur * 0.6 + dur * 2.2);
    });
  }
  thump(freq = 120, vol = 0.12, dur = 0.08) {
    if (!this.ctx) return;
    const C = this.ctx, t = C.currentTime;
    const s = C.createBufferSource(); s.buffer = this.noise;
    const f = C.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = freq * 6;
    const g = C.createGain(); g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.001, t + dur);
    s.connect(f); f.connect(g); g.connect(this.master); s.start(t, Math.random() * 2); s.stop(t + dur + 0.02);
  }
  step(sprint) { this.thump(90 + Math.random() * 40, sprint ? 0.16 : 0.1, 0.09); }
  pickup(r) { const base = [520, 620, 740, 880, 1040][r]; this.blip(r >= 3 ? [base, base * 1.25, base * 1.5, base * 2] : [base, base * 1.5], 0.08, 'triangle', 0.15); }
  cash() { this.blip([1320, 1760], 0.06, 'square', 0.06); this.thump(400, 0.1, 0.15); }
  error() { this.blip([220, 180], 0.1, 'sawtooth', 0.06); }
  event() { this.blip([660, 880, 990, 1320], 0.1, 'triangle', 0.12); }
}
