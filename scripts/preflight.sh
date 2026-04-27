#!/usr/bin/env bash
# Flower preflight: parse-check + GUT unit tests + both autobots.
# Non-zero exit on regression. ~30–60s on a warm cache.
#
# Usage: ./scripts/preflight.sh
#
# Run before committing GDScript changes. Catches:
#   - Parse errors (load_and_apply / class_name resolution / missing types)
#   - Unit test failures
#   - E2E autobot regressions (existing 10/10 single-player happy path)
#   - Multiplayer playthrough autobot regressions (1P 14/14, 2P 16/16)

set -e
cd "$(dirname "$0")/.."

GUT_LOG="$(mktemp -t flower-gut.XXXXXX.log)"
AUTO1_LOG="$(mktemp -t flower-auto1.XXXXXX.log)"
AUTOP1_LOG="$(mktemp -t flower-autop1.XXXXXX.log)"
AUTOP2_LOG="$(mktemp -t flower-autop2.XXXXXX.log)"
trap 'rm -f "$GUT_LOG" "$AUTO1_LOG" "$AUTOP1_LOG" "$AUTOP2_LOG"' EXIT

step() { printf "\n\033[1;36m▶ %s\033[0m\n" "$*"; }
ok()   { printf "  \033[1;32m✓ %s\033[0m\n" "$*"; }
fail() { printf "  \033[1;31m✗ %s\033[0m\n" "$*"; exit 1; }

step "1/4  parse-check (godot --headless --quit)"
godot --headless --quit > /dev/null 2>&1 || fail "parse-check failed (run godot --headless --quit to see errors)"
ok "parse-check clean"

step "2/4  unit tests (GUT)"
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit > "$GUT_LOG" 2>&1 || true
if grep -q "All tests passed" "$GUT_LOG"; then
    ok "$(grep -oE '[0-9]+/[0-9]+ passed' "$GUT_LOG" | tail -1) (see $GUT_LOG)"
else
    cat "$GUT_LOG" | tail -40
    fail "GUT failures (full log: $GUT_LOG)"
fi

step "3/4  e2e autobot (single-player happy path)"
godot --headless --script res://scripts/e2e/autobot_runner.gd > "$AUTO1_LOG" 2>&1 || true
if grep -q "10 / 10 checks passed" "$AUTO1_LOG"; then
    ok "10/10 checks passed"
else
    grep -E "PASS|FAIL|checks passed" "$AUTO1_LOG" | tail -15
    fail "autobot regressed (full log: $AUTO1_LOG)"
fi

step "4/4  e2e autobot_play (boss-kill, 1P + 2P)"
godot --headless --script res://scripts/e2e/autobot_play_runner.gd -- --players=1 > "$AUTOP1_LOG" 2>&1 || true
if grep -q "14 / 14 checks passed" "$AUTOP1_LOG"; then
    ok "1P 14/14"
else
    grep -E "PASS|FAIL|checks passed" "$AUTOP1_LOG" | tail -20
    fail "autobot_play 1P regressed (full log: $AUTOP1_LOG)"
fi

godot --headless --script res://scripts/e2e/autobot_play_runner.gd -- --players=2 > "$AUTOP2_LOG" 2>&1 || true
if grep -q "16 / 16 checks passed" "$AUTOP2_LOG"; then
    ok "2P 16/16"
else
    grep -E "PASS|FAIL|checks passed" "$AUTOP2_LOG" | tail -20
    fail "autobot_play 2P regressed (full log: $AUTOP2_LOG)"
fi

printf "\n\033[1;32m✅ preflight green — safe to commit\033[0m\n"
