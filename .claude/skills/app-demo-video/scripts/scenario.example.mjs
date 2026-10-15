// Example scenario for record.mjs: search, then open a result.
export const url = 'https://example.com/';
export const viewport = { width: 1280, height: 720 }; // recorded at 1.5x => 1920x1080 frames

export async function run(page, h) {
  await h.wait(800);
  await h.click(640, 300);          // focus the search box
  h.mark('type');
  await h.type('self-hosted product analytics');
  await h.wait(1200);               // let live suggestions settle on screen
  await h.moveTo(560, 420, 900);
  h.mark('open');
  await h.click(560, 420, 1500);    // open a result
  await h.scroll(360);
  await h.wait(1200);
}
