// Turn a variable-rate screencast (clips/<name>/) into a constant 30fps clip and a numbered frame sequence.
// Usage: node frames.mjs <name> [fps=30]
// Output: clips/<name>.mp4 (1920x1080) and fr/<name>/0001.jpg ... for a time-driven composition to index into.
import fs from 'fs';
import { execSync } from 'child_process';

const name = process.argv[2];
const fps = Number(process.argv[3] ?? 30);
const dir = `clips/${name}`;
const { frames } = JSON.parse(fs.readFileSync(`${dir}/times.json`));
let list = '';
frames.forEach((_, i) => {
  const d = i < frames.length - 1 ? frames[i + 1] - frames[i] : 0.5;
  list += `file 'f${String(i).padStart(5, '0')}.jpg'\nduration ${d.toFixed(4)}\n`;
});
list += `file 'f${String(frames.length - 1).padStart(5, '0')}.jpg'\n`; // concat demuxer ignores the last duration otherwise
fs.writeFileSync(`${dir}/list.txt`, list);
execSync(`ffmpeg -y -loglevel error -f concat -safe 0 -i ${dir}/list.txt -vf "scale=1920:1080:flags=lanczos,fps=${fps},format=yuv420p" -c:v libx264 -crf 14 -preset slow clips/${name}.mp4`);
fs.rmSync(`fr/${name}`, { recursive: true, force: true });
fs.mkdirSync(`fr/${name}`, { recursive: true });
execSync(`ffmpeg -y -loglevel error -i clips/${name}.mp4 -q:v 2 fr/${name}/%04d.jpg`);
const n = fs.readdirSync(`fr/${name}`).length;
const dur = execSync(`ffprobe -v error -show_entries format=duration -of csv=p=0 clips/${name}.mp4`).toString().trim();
console.log(`${name}: ${dur}s, ${n} frames in fr/${name}/`);
