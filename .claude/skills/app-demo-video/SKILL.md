---
name: app-demo-video
description: Record a real web app (prod URL or local dev) as crisp 1080p footage and cut it into a polished demo or launch video with camera push-ins, captions, mock "before" scenes, synced key and click sounds, and music. Use when someone asks to screen-record their app, make a demo, walkthrough, or launch video of a product they built, or show the app working on video. Pairs with /brag or /brag-slim (story and share copy), /hyperframes (composition), /motion-design (timing), and /media-use (assets).
---

# App demo video

Real footage of the product beats any mock. This skill gets that footage cleanly and edits it into a time-driven composition you can scrub, spot-check and render frame-exact.

Scripts live in `<skill-dir>/scripts/`. Copy them into a `work/` folder next to the deliverables and run them from there. They need Node 22+, `playwright` (`npm i playwright`, no browser download: they use the installed Chrome via `channel: 'chrome'`) and ffmpeg.

## Pipeline

| Step | Script | Output |
|---|---|---|
| 1. Scout | Claude in Chrome, or Playwright screenshots | coordinates, real copy, what's worth showing |
| 2. Record | `node record.mjs scenario.mjs <name>` | `clips/<name>/f*.jpg` + `times.json` |
| 3. Normalize | `node frames.mjs <name>` | `clips/<name>.mp4` + `fr/<name>/0001.jpg…` at 30fps |
| 4. Compose | `video.html` with `window.render(t)` | one HTML file, every scene a pure function of `t` |
| 5. Check | `node capture.mjs video.html stills 0,4.5,12,…` | stills to inspect before the full render |
| 6. Render | `node capture.mjs video.html all <seconds>` | `out/00000.jpg…` |
| 7. Sound | `node mix.mjs events.json` | `mix.wav` |
| 8. Encode | ffmpeg (below) | final mp4 |

### 1. Scout before recording

Open the app, try the exact flow, and write down pixel coordinates at the recording viewport (1280×720 by default; frames come out at 1920×1080 because of the 1.5× device scale). Pick inputs that return impressive, honest results. Run the real API or MCP tool for any data you show (e.g. a recommendation call) and use its actual output.

### 2. Record with the screencast API

Use `record.mjs`, not the Claude in Chrome extension's GIF recorder (low quality, GIF-only) and not Playwright's `recordVideo` (soft, low bitrate). It drives headless Chrome, captures `Page.screencastFrame` JPEGs with timestamps, and injects a visible cursor that eases between points, since headless Chrome draws none. A scenario is a small module: see `scenario.example.mjs`. Keep each clip to one idea (search, open detail, run a flow) and 8 to 15 seconds long. Hold 1 to 1.5 seconds after every state change so the edit has room to breathe.

### 3. Normalize

Screencast frames arrive only when the page repaints, at uneven times. `frames.mjs` retimes them with ffmpeg's concat demuxer into a constant 30fps clip, then dumps a numbered frame sequence for the composition to index into.

### 4. Compose as a pure function of time

Build one `video.html` (1920×1080) that exposes `window.render(t)` and `window.ready()`. Each scene owns a time window. Inside it, derive everything from `t`: opacity, transforms, typed text (`text.slice(0, (t - start) * cps)`), counters, and which footage frame to show (`fr/<name>/${frame}.jpg` where `frame = floor((t - start) * 30) + 1`). No CSS transitions, timers or `requestAnimationFrame`. That makes any frame reproducible, so spot checks are honest.

What made the ToolDB launch video work:
- **Story:** hook (the pain, typed as a prompt), problem cards, the "before" (a mock of the old tool, e.g. a Notion table that finds nothing), the reveal (logo plus one real number), real footage, the killer feature, then an outro with the URL. Fit it in 45 to 60 seconds.
- **Camera on footage:** slow push-ins (`scale` 1 to 1.14 with ease-in-out over about 1.5s) toward whatever the viewer should read, then release. Never cut mid-type.
- **Captions** over footage instead of voiceover: one short line at a time, about 0.3 seconds per word on screen.
- **Mock scenes** (a terminal, the old tool) built in HTML with real names and data. Say in the report that they're mocks.
- **Motion:** one signature ease (ease-out-quart for entrances), staggers under 500ms, crossfades of 0.3 to 0.35 seconds between scenes. Follow /motion-design.

### 5–6. Check, then render

Render stills at each scene's midpoint and at every transition, then look at them before rendering all frames. `capture.mjs` waits for every `<img>` to decode before each screenshot; skipping that causes blank flashes on footage frames.

### 7. Sound

Music from /brag's bundled tracks or /media-use, at about -4 dB. Add key taps every 2 to 3 characters while text types, a click on each click, and a soft whoosh on each reveal, all from the same timeline numbers the composition uses. Keep SFX between -14 and -22 dB.

### 8. Encode

```bash
ffmpeg -y -framerate 30 -i out/%05d.jpg -i mix.wav \
  -af "volume=3.5dB,alimiter=limit=0.95" \
  -c:v libx264 -crf 16 -preset slow -pix_fmt yuv420p -movflags +faststart \
  -c:a aac -b:a 192k -shortest ../demo.mp4
```

Aim for about -14 LUFS for social (`ffmpeg -i demo.mp4 -af ebur128 -f null -`). For a poster frame shown as the thumbnail, copy the best still over `out/00000.jpg` before encoding.

## Honesty rules

- Show only sources, numbers and features that exist in the code or the live app. If the brief claims something the code doesn't do, leave it out and tell the user.
- If you show a curated subset of real output (one pick per row, say), tell the user in the report.
- Report how the footage was recorded: headless Chrome via Playwright, not a screen recording of the user's desktop.
