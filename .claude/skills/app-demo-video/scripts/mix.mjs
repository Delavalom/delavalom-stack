// Mix a music bed with timed SFX hits into mix.wav.
// Usage: node mix.mjs <events.json>
// events.json: { "music": "path.mp3", "duration": 55, "musicGainDb": -4, "fadeOut": 2.2,
//                "events": [["keypress-001.wav", 0.30, -20], ["click1.ogg", 22.68, -14]] }   // [file, seconds, gainDb]
// Tip: for typing, emit a key sound every 2-3 characters at the on-screen chars-per-second, not every character.
import fs from 'fs';
import { execSync } from 'child_process';

const cfg = JSON.parse(fs.readFileSync(process.argv[2]));
const D = cfg.duration;
const ev = cfg.events ?? [];
const inputs = [`-i "${cfg.music}"`, ...ev.map((e) => `-i "${e[0]}"`)].join(' ');
const fadeOut = cfg.fadeOut ?? 2;
let f = `[0:a]atrim=0:${D},asetpts=PTS-STARTPTS,volume=${cfg.musicGainDb ?? -4}dB,afade=t=in:d=0.3,afade=t=out:st=${D - fadeOut}:d=${fadeOut},aformat=sample_rates=48000:channel_layouts=stereo[m];`;
ev.forEach((e, i) => {
  const ms = Math.round(e[1] * 1000);
  f += `[${i + 1}:a]aformat=sample_rates=48000:channel_layouts=stereo,volume=${e[2]}dB,adelay=${ms}|${ms}[e${i}];`;
});
f += `[m]${ev.map((_, i) => `[e${i}]`).join('')}amix=inputs=${ev.length + 1}:normalize=0:duration=first,alimiter=limit=0.89[out]`;
execSync(`ffmpeg -y -loglevel error ${inputs} -filter_complex "${f}" -map "[out]" -t ${D} -c:a pcm_s16le mix.wav`, { stdio: 'inherit' });
console.log('mix.wav with', ev.length, 'events');
