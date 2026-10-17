#!/usr/bin/env bash
# Copy edits from the live ~/.claude/skills back into this repo's vendored skills.
# ~/.claude/skills is where skills get edited; install.sh goes the other way.
# Only skills already vendored here are refreshed. Submodules are skipped.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIVE="${HOME}/.claude/skills"

for dir in "${REPO}"/.claude/skills/*/; do
    name="$(basename "$dir")"
    [[ -e "${dir}.git" ]] && continue
    if [[ ! -d "${LIVE}/${name}" ]]; then
        echo "not installed, skipped: ${name}"
        continue
    fi
    rsync -a --delete --exclude '.git' --exclude '.DS_Store' --exclude '__pycache__' \
        --exclude 'node_modules' --exclude '/assets/music/*.mp3' "${LIVE}/${name}/" "$dir"
done

git -C "$REPO" status --short .claude/skills
