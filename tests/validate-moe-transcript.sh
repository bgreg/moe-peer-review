#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() {
  printf "  PASS  %s\n" "$1"
  PASS=$((PASS + 1))
}
fail() {
  printf "  FAIL  %s\n" "$1"
  FAIL=$((FAIL + 1))
}
warn() {
  printf "  WARN  %s\n" "$1"
  WARN=$((WARN + 1))
}

if [ $# -lt 1 ]; then
  printf "Usage: %s <path-to-moe-transcript.md>\n" "$0"
  printf "  Diagnostic check on an MOE review transcript.\n"
  printf "  Reports findings only. A failure is a signal that the model's execution\n"
  printf "  or the plugin's guidance needs tuning -- it is NOT an instruction to edit\n"
  printf "  the transcript to make checks pass.\n"
  exit 1
fi

TRANSCRIPT="$1"

printf "\n=== MOE Transcript Diagnostic ===\n"
printf "Findings only. Failures indicate model/plugin tuning is needed, not transcript edits.\n"
printf "File: %s\n\n" "$TRANSCRIPT"

if [ ! -f "$TRANSCRIPT" ]; then
  fail "Transcript file not found"
  printf "\n%d passed, %d failed, %d warnings\n" "$PASS" "$FAIL" "$WARN"
  exit 1
fi

contains() { grep -qi "$1" "$TRANSCRIPT" 2>/dev/null; }
count_matches() {
  local c
  c=$(grep -ci "$1" "$TRANSCRIPT" 2>/dev/null) || true
  printf '%s' "${c:-0}"
}

printf "Phase Structure\n"
if contains "Phase 1"; then
  pass "Phase 1 (Kick-Off) header present"
else
  fail "Missing Phase 1 header"
fi

if contains "Phase 2"; then
  pass "Phase 2 (Clarifying Questions) header present"
else
  fail "Missing Phase 2 header"
fi

phase3_found=false
if contains "Phase 3" || contains "Interactive Session"; then
  phase3_found=true
  pass "Phase 3+ (Interactive Session) header present"
else
  if contains "Skipped.*all personas satisfied"; then
    phase3_found=true
    pass "Interactive sessions skipped (early satisfaction)"
  else
    fail "Missing Phase 3+ header or skip notice"
  fi
fi

if contains "Huddle"; then
  pass "The Huddle header present"
else
  fail "Missing The Huddle header"
fi

if contains "Synthesis"; then
  pass "Synthesis header present"
else
  fail "Missing Synthesis header"
fi

printf "\niMessage Chat Format\n"
moderator_arrows=$(count_matches "Dr. Dara Mitchell ->")
if [ "$moderator_arrows" -gt 0 ]; then
  pass "Dr. Dara Mitchell -> Persona format found ($moderator_arrows instances)"
else
  fail "No 'Dr. Dara Mitchell -> Persona' exchanges found (not interleaved)"
fi

agent_arrows=$(grep -c '\*\*.*-> \*\*' "$TRANSCRIPT" 2>/dev/null) || true
agent_arrows=${agent_arrows:-0}
if [ "$agent_arrows" -gt 0 ]; then
  pass "Agent-to-agent exchanges found ($agent_arrows instances)"
else
  fail "No agent-to-agent exchanges found (Huddle missing or misformatted)"
fi

blockquotes=$(count_matches "^>")
if [ "$blockquotes" -gt 0 ]; then
  pass "Blockquoted responses found ($blockquotes lines)"
else
  fail "No blockquoted responses found"
fi

printf "\nPersona Names\n"
personas=(
  "Beyonce Carter"
  "Jill Scott-Williams"
  "Janelle Monae Robinson"
  "Lauryn Hill-Washington"
  "Erykah Badu-Johnson"
  "Ashanti Douglas"
  "Whitney Houston-Davis"
  "ChaoticCarl"
)
for name in "${personas[@]}"; do
  if contains "$name"; then
    pass "Persona appears: $name"
  else
    fail "Missing persona: $name"
  fi
done

if contains "Dr. Dara Mitchell"; then
  pass "Moderator appears: Dr. Dara Mitchell"
else
  fail "Missing moderator: Dr. Dara Mitchell"
fi

printf "\nNaming Violations\n"
carl_bare=$(grep -cP '(?<![A-Za-z])Carl(?![A-Za-z])' "$TRANSCRIPT" 2>/dev/null) || true
carl_chaotic=$(grep -c 'ChaoticCarl' "$TRANSCRIPT" 2>/dev/null) || true
carl_bare=${carl_bare:-0}
carl_chaotic=${carl_chaotic:-0}
carl_solo=$((carl_bare - carl_chaotic))
if [ "$carl_solo" -le 0 ]; then
  pass "No bare 'Carl' without 'Chaotic' prefix"
else
  fail "Found $carl_solo bare 'Carl' references (should be 'ChaoticCarl')"
fi

if grep -qi "orchestrator" "$TRANSCRIPT" 2>/dev/null; then
  fail "Transcript contains 'orchestrator' (should be 'moderator')"
else
  pass "No 'orchestrator' references"
fi

printf "\nSynthesis Structure\n"
synthesis_parts=(
  "Verdict Scoreboard"
  "Production Gates"
  "Compliance Findings"
  "Domain Expert Warnings"
  "User Experience Failures"
  "Mandatory Production Standards"
  "Improvements"
  "Key Insight"
  "Action Items"
)
for part in "${synthesis_parts[@]}"; do
  if contains "$part"; then
    pass "Synthesis: $part"
  else
    fail "Missing synthesis section: $part"
  fi
done

printf "\nReview-Only Guardrail\n"
if contains "STOP"; then
  pass "STOP directive present in synthesis"
else
  fail "Missing STOP directive in synthesis (required guardrail)"
fi

printf "\nState Management\n"
transcript_dir=$(dirname "$TRANSCRIPT")
if [ -f "$transcript_dir/moe-state.json" ]; then
  pass "State file exists alongside transcript"
else
  warn "No moe-state.json found alongside transcript"
fi

printf "\n=== Results ===\n"
printf "%d passed, %d failed, %d warnings\n" "$PASS" "$FAIL" "$WARN"

if [ "$FAIL" -gt 0 ]; then
  printf "\nFailures above are a tuning signal. Do NOT edit the transcript to clear them:\n"
  printf "the transcript is a faithful record. Trace each failure to its cause (model\n"
  printf "execution vs. plugin guidance) and feed it into the remediation plan.\n\n"
  exit 1
fi
printf "\n"
