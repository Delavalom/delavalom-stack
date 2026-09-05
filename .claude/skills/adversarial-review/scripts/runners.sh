#!/usr/bin/env bash
# Probe which external reviewer CLIs can actually complete a call right now.
# Prints one line per runner: <name> <ok|no-auth|missing|timeout> <detail>
#
# This makes a real (tiny) call to each CLI. Do not "optimize" it into a check for
# config files or credential paths: those exist and look valid while the CLI still
# fails to authenticate. A probe that reports a runner it cannot use is worse than
# no probe, because the review silently loses a model family and still claims N.
set -uo pipefail

PROBE_TIMEOUT="${PROBE_TIMEOUT:-45}"

# `timeout` is GNU coreutils and is absent on stock macOS. perl's alarm is everywhere.
run_limited() { perl -e 'alarm shift; exec @ARGV' "$PROBE_TIMEOUT" "$@" 2>&1; }

probe() {
  local name="$1" bin="$2"; shift 2
  command -v "$bin" >/dev/null 2>&1 || { echo "$name missing not-installed"; return; }
  local out rc
  out="$(run_limited "$@")"; rc=$?
  # Collapse to one line: CLIs emit banners and ANSI, which would break the roster table.
  out="$(printf '%s' "$out" | tr -d '\r' | sed $'s/\033\[[0-9;?]*[a-zA-Z]//g' | tr '\n' ' ' | tr -s ' ')"
  if [[ $rc -eq 142 ]]; then echo "$name timeout exceeded-${PROBE_TIMEOUT}s"; return; fi
  case "$out" in
    *PROBE_OK*)                      echo "$name ok live-call" ;;
    *"Auth method"*|*"API key"*|*"api_key"*|*[Uu]nauthorized*|*"not logged in"*|*"log in"*)
                                     echo "$name no-auth ${out:0:90}" ;;
    *)                               echo "$name no-auth unexpected:${out:0:90}" ;;
  esac
}

probe codex  codex        codex exec -s read-only --skip-git-repo-check --ephemeral \
                          "Reply with exactly: PROBE_OK"
probe gemini gemini       gemini --approval-mode plan -p "Reply with exactly: PROBE_OK"
probe cursor cursor-agent cursor-agent -p --output-format text "Reply with exactly: PROBE_OK"
