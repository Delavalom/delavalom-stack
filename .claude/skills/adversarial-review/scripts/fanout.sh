#!/usr/bin/env bash
# Run every authenticated external reviewer against one diff, in parallel, then merge.
#
#   fanout.sh <diff-file> <out-dir> [focus]
#
# Prints a roster line per runner and writes <out-dir>/merged.json.
# Exit 0 if at least one reviewer returned a verdict, 4 if none did.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
diff_file="${1:?diff file required}"
out_dir="${2:?out dir required}"
focus="${3:-}"
mkdir -p "$out_dir"

echo "== probing runners =="
roster=()
while read -r name status detail; do
  printf '  %-8s %-8s %s\n' "$name" "$status" "$detail"
  [[ "$status" == "ok" ]] && roster+=("$name")
done < <("${HERE}/runners.sh")

if [[ ${#roster[@]} -eq 0 ]]; then
  echo "no external reviewer is authenticated; fall back to in-harness subagents" >&2
  exit 4
fi

echo "== reviewing with: ${roster[*]} =="
pids=(); names=()
for r in "${roster[@]}"; do
  "${HERE}/review.sh" "$r" "$diff_file" "$out_dir" "$focus" &
  pids+=($!); names+=("$r")
done

# Merge only what THIS run produced. Globbing the directory picks up verdicts left by an
# earlier run against a different diff, and reports them as if this review had found them.
succeeded=()
for i in "${!pids[@]}"; do
  if wait "${pids[$i]}"; then
    succeeded+=("${names[$i]}")
  else
    echo "  ${names[$i]}: no verdict this run (see ${out_dir}/${names[$i]}.log)" >&2
  fi
done

if [[ ${#succeeded[@]} -eq 0 ]]; then
  echo "every selected reviewer failed; no merged verdict written" >&2
  exit 4
fi

python3 - "$out_dir" "${succeeded[@]}" <<'PY'
import json, os, sys

out, runners = sys.argv[1], sys.argv[2:]
merged, sources = [], []
for runner in runners:
    path = os.path.join(out, f"{runner}.json")
    try:
        d = json.load(open(path))
    except Exception as e:
        print(f"  skipping {runner}: {e}", file=sys.stderr)
        continue
    sources.append(runner)
    for kind in ("findings", "no_cope_violations"):
        v = d.get(kind, [])
        if not isinstance(v, list):
            continue
        for item in v:
            if not isinstance(item, dict):   # a str here would crash the assignment below
                continue
            item["_runner"], item["_kind"] = runner, kind
            merged.append(item)

# Group by file and near-adjacent line. Proximity is a HINT, not proof: two reviewers can
# land three lines apart on genuinely different defects. Phase D triage confirms each
# group is one defect before treating agreement as signal.
groups = []
for it in merged:
    for g in groups:
        if (g[0].get("file") == it.get("file")
                and abs((g[0].get("line") or 0) - (it.get("line") or 0)) <= 3
                and g[0]["_kind"] == it["_kind"]):
            g.append(it); break
    else:
        groups.append([it])

rank = {"blocker": 0, "major": 1, "minor": 2}
groups.sort(key=lambda g: (-len({i["_runner"] for i in g}),
                           rank.get(g[0].get("severity", "minor"), 3)))
res = {"sources": sources, "total": len(merged), "groups": [
    {"agreed_by": sorted({i["_runner"] for i in g}), "count": len(g), "items": g} for g in groups]}
json.dump(res, open(os.path.join(out, "merged.json"), "w"), indent=2)

print(f"\n== merged: {len(merged)} raw items -> {len(groups)} distinct, from {sources} ==")
for g in res["groups"]:
    a, i = g["agreed_by"], g["items"][0]
    flag = "LIKELY-CORROBORATED" if len(a) > 1 else "single"
    label = i.get("claim") or i.get("quote", "")
    print(f"  [{flag}:{','.join(a)}] {i.get('file')}:{i.get('line')} "
          f"{i.get('severity', i['_kind'])} — {label[:80]}")
PY
