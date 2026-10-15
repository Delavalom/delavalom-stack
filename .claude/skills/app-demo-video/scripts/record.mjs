// Record a real web app as a crisp variable-rate frame sequence via Chrome's screencast API.
// Usage: node record.mjs <scenario.mjs> <name>
// scenario.mjs: export const url = '...'; export async function run(page, h) { await h.moveTo(x, y); await h.click(x, y); await h.type('text'); h.mark('label'); }
// Output: clips/<name>/f00000.jpg ... + clips/<name>/times.json ({ frames: [timestamps], marks })
import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const [, , scenarioPath, name] = process.argv;
if (!scenarioPath || !name) { console.error('usage: node record.mjs <scenario.mjs> <name>'); process.exit(1); }
const sc = await import(path.resolve(scenarioPath));
const viewport = sc.viewport ?? { width: 1280, height: 720 };

// channel:'chrome' uses the installed Chrome; no Playwright browser download needed.
const browser = await chromium.launch({ channel: 'chrome', headless: true });
const ctx = await browser.newContext({ viewport, deviceScaleFactor: sc.scale ?? 1.5, colorScheme: sc.colorScheme ?? 'dark' });

// Headless Chrome draws no cursor: inject a visible one that eases between points.
await ctx.addInitScript(() => {
  const add = () => {
    if (document.getElementById('fakecursor')) return;
    const c = document.createElement('div');
    c.id = 'fakecursor';
    c.style.cssText = 'position:fixed;z-index:2147483647;left:0;top:0;width:22px;height:22px;pointer-events:none;transition:transform .6s cubic-bezier(.22,1,.36,1);transform:translate(-40px,-40px)';
    c.innerHTML = '<svg width="22" height="22" viewBox="0 0 24 24"><path d="M4 2l16 9-7 2-3 7z" fill="#fff" stroke="#000" stroke-width="1.5"/></svg>';
    document.documentElement.appendChild(c);
  };
  document.addEventListener('DOMContentLoaded', add);
});

const page = await ctx.newPage();
const dir = `clips/${name}`;
fs.rmSync(dir, { recursive: true, force: true });
fs.mkdirSync(dir, { recursive: true });

const cdp = await ctx.newCDPSession(page);
const frames = [];
let recording = false;
let t0 = 0;
cdp.on('Page.screencastFrame', async (f) => {
  if (recording) {
    fs.writeFileSync(`${dir}/f${String(frames.length).padStart(5, '0')}.jpg`, Buffer.from(f.data, 'base64'));
    frames.push(f.metadata.timestamp);
  }
  await cdp.send('Page.screencastFrameAck', { sessionId: f.sessionId }).catch(() => {});
});

const marks = {};
const h = {
  wait: (ms) => page.waitForTimeout(ms),
  mark: (k) => { marks[k] = +(Date.now() / 1000 - t0).toFixed(2); },
  moveTo: async (x, y, wait = 650) => {
    await page.evaluate(([x, y]) => { const c = document.getElementById('fakecursor'); if (c) c.style.transform = `translate(${x}px,${y}px)`; }, [x, y]);
    await page.mouse.move(x, y, { steps: 10 });
    await page.waitForTimeout(wait);
  },
  click: async (x, y, wait = 500) => { await h.moveTo(x, y); await page.mouse.click(x, y); await page.waitForTimeout(wait); },
  // Human-ish typing; the screencast only emits frames on paint, so steady typing keeps the frame rate up.
  type: async (text, delay = 65) => { await page.keyboard.type(text, { delay }); },
  scroll: async (dy, steps = 6, gap = 140) => { for (let i = 0; i < steps; i++) { await page.mouse.wheel(0, dy / steps); await page.waitForTimeout(gap); } },
};

await page.goto(sc.url, { waitUntil: 'networkidle' });
await page.waitForTimeout(1000);
await cdp.send('Page.startScreencast', { format: 'jpeg', quality: 92, maxWidth: 1920, maxHeight: 1080, everyNthFrame: 1 });
recording = true;
t0 = Date.now() / 1000;
h.mark('start');
// Screencast frames only arrive when the page repaints; a tiny DOM tick keeps idle stretches from freezing.
const tick = setInterval(() => page.evaluate(() => { document.body.dataset.t = Date.now(); }).catch(() => {}), 33);
await sc.run(page, h);
h.mark('end');
clearInterval(tick);
recording = false;
await cdp.send('Page.stopScreencast');
fs.writeFileSync(`${dir}/times.json`, JSON.stringify({ frames, marks }));
console.log(name, frames.length, 'frames', JSON.stringify(marks));
await browser.close();
