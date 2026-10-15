// Render a time-driven HTML composition (window.render(t), optional window.ready()) to frames.
// Usage: node capture.mjs <video.html> stills 0,4.5,12   -> stills/t0.00.jpg ...
//        node capture.mjs <video.html> all <seconds>     -> out/00000.jpg ... at 30fps
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const [, , html, mode, arg] = process.argv;
const FPS = 30;
const browser = await chromium.launch({ channel: 'chrome', headless: true });
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
await page.goto('file://' + path.resolve(html));
await page.evaluate(() => window.ready?.());
await page.waitForTimeout(500);

const shot = async (t, file) => {
  await page.evaluate((t) => window.render(t), t);
  // Frame-sequence <img> swaps must finish decoding before the screenshot, or frames flash blank.
  await page.evaluate(async () => { await Promise.all([...document.images].filter((i) => i.src).map((i) => i.decode().catch(() => {}))); });
  await page.screenshot({ path: file, type: 'jpeg', quality: 95 });
};

if (mode === 'stills') {
  fs.mkdirSync('stills', { recursive: true });
  for (const t of arg.split(',').map(Number)) await shot(t, `stills/t${t.toFixed(2)}.jpg`);
} else {
  const n = Math.round(Number(arg) * FPS);
  fs.mkdirSync('out', { recursive: true });
  for (let i = 0; i < n; i++) {
    await shot(i / FPS, `out/${String(i).padStart(5, '0')}.jpg`);
    if (i % 150 === 0) console.log(`${i}/${n}`);
  }
}
await browser.close();
