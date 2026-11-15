"""Drive `craft-anything-cli mcp` over stdio so browser tools share one session.

Each Craft Anything CLI call starts and closes its own browser, so opening a site and capturing it
must happen inside one MCP session. This script does that.

usage:
  ca_mcp.py signin  <url>                  open a visible window; the person signs in and closes it
  ca_mcp.py capture <url> <new-out-dir>    screenshots at 1440/768/390 plus measured design tokens
  ca_mcp.py score   <orig-dir> <build-dir> compare screenshot-<width>.png pairs (layout + SSIM)
"""
import json
import os
import subprocess
import sys

WIDTHS = (1440, 768, 390)


def session(calls, extra_args=()):
    """Run tool calls in one MCP session; return each call's text result."""
    proc = subprocess.Popen(
        ["craft-anything-cli", "mcp", "--allow-run", "--all-tools", *extra_args],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True,
    )

    def send(msg):
        proc.stdin.write(json.dumps(msg) + "\n")
        proc.stdin.flush()

    def recv(want_id):
        while True:
            line = proc.stdout.readline()
            if not line:
                raise SystemExit("craft-anything-cli mcp exited early; run `craft-anything-cli doctor`")
            msg = json.loads(line)
            if msg.get("id") == want_id:
                return msg

    send({"jsonrpc": "2.0", "id": 0, "method": "initialize", "params": {
        "protocolVersion": "2025-06-18", "capabilities": {},
        "clientInfo": {"name": "craft-clone", "version": "1"}}})
    recv(0)
    send({"jsonrpc": "2.0", "method": "notifications/initialized"})
    results = []
    for i, (name, args) in enumerate(calls, start=1):
        send({"jsonrpc": "2.0", "id": i, "method": "tools/call",
              "params": {"name": name, "arguments": args}})
        res = recv(i)
        if "error" in res:
            results.append(json.dumps(res["error"]))
            continue
        content = res.get("result", {}).get("content", [])
        results.append("".join(c.get("text", "") for c in content))
    proc.stdin.close()
    proc.wait(timeout=60)
    return results


def result_of(text):
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return {"raw": text[:400]}
    return data.get("result", data)


def main(argv):
    if len(argv) < 2:
        raise SystemExit(__doc__)
    cmd = argv[1]
    if cmd == "signin" and len(argv) == 3:
        print("A browser window opens: sign in there, then close it.")
        print(session([("web_site_sign_in", {"url": argv[2]})])[0][:800])
    elif cmd == "capture" and len(argv) == 4:
        out = os.path.abspath(argv[3])
        opened, captured = session([
            ("web_site_open", {"url": argv[2], "width": 1440}),
            ("web_site_capture", {"output_directory": out, "widths": list(WIDTHS)}),
        ])
        print(json.dumps(result_of(opened))[:300])
        print(json.dumps(result_of(captured))[:300])
        print(f"capture written to {out}")
    elif cmd == "score" and len(argv) == 4:
        orig, build = argv[2], argv[3]
        calls, widths = [], []
        for w in WIDTHS:
            a, b = os.path.join(orig, f"screenshot-{w}.png"), os.path.join(build, f"screenshot-{w}.png")
            if os.path.exists(a) and os.path.exists(b):
                widths.append(w)
                calls.append(("web_pixels_compare", {
                    "before": {"path": os.path.abspath(a)}, "after": {"path": os.path.abspath(b)},
                    "common_area": True, "tolerance": 16}))
        if not calls:
            raise SystemExit("no screenshot-<width>.png pairs found in both folders")
        print(f"{'width':>6}  {'layout':>7}  {'perceptual':>10}  {'differ':>7}")
        for w, text in zip(widths, session(calls)):
            r = result_of(text)
            fmt = lambda k: f"{r[k]:.3f}" if isinstance(r.get(k), (int, float)) else "n/a"
            print(f"{w:>6}  {fmt('layout_similarity'):>7}  {fmt('perceptual_similarity'):>10}  {fmt('difference_fraction'):>7}")
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
