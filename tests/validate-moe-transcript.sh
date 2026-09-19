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

phase2_found=false
if contains "Phase 2" || contains "Interactive Session"; then
  phase2_found=true
  pass "Phase 2 (Interactive Session) header present"
else
  if contains "Skipped.*all personas satisfied"; then
    phase2_found=true
    pass "Interactive sessions skipped (early satisfaction)"
  else
    fail "Missing Phase 2 header or skip notice"
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
moderator_arrows=$(grep -cE 'Dr\. Nina Simone-Bennett(\*\*)? ->' "$TRANSCRIPT" 2>/dev/null) || true
moderator_arrows=${moderator_arrows:-0}
if [ "$moderator_arrows" -gt 0 ]; then
  pass "Dr. Nina Simone-Bennett -> Persona format found ($moderator_arrows instances)"
else
  fail "No 'Dr. Nina Simone-Bennett -> Persona' exchanges found (not interleaved)"
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
  "SZA"
  "Erykah Badu-Johnson"
  "Doechii"
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

if contains "Dr. Nina Simone-Bennett"; then
  pass "Moderator appears: Dr. Nina Simone-Bennett"
else
  fail "Missing moderator: Dr. Nina Simone-Bennett"
fi

printf "\nNaming Violations\n"
carl_solo=$(grep -oE '[A-Za-z]*Carl[A-Za-z]*' "$TRANSCRIPT" 2>/dev/null | grep -cx 'Carl') || true
carl_solo=${carl_solo:-0}
if [ "$carl_solo" -eq 0 ]; then
  pass "No bare 'Carl' without 'Chaotic' prefix"
else
  fail "Found $carl_solo bare 'Carl' reference(s) (should be 'ChaoticCarl')"
  grep -nE '(^|[^A-Za-z])Carl([^A-Za-z]|$)' "$TRANSCRIPT" 2>/dev/null | sed 's/^/          /'
fi

if grep -qi "orchestrator" "$TRANSCRIPT" 2>/dev/null; then
  fail "Transcript contains 'orchestrator' (should be 'moderator')"
else
  pass "No 'orchestrator' references"
fi

printf "\nHuddle Integrity\n"
missing_speakers=""
while IFS= read -r who; do
  [ -z "$who" ] && continue
  if ! grep -q "\*\*$who\*\* ->" "$TRANSCRIPT" 2>/dev/null &&
    ! grep -q "\-> \*\*$who\*\*" "$TRANSCRIPT" 2>/dev/null; then
    missing_speakers="$missing_speakers $who;"
  fi
done <<EOF
$(grep -oE '^- [A-Za-z][A-Za-z .-]*: *(participated|[0-9]+ sent)' "$TRANSCRIPT" 2>/dev/null | sed -E 's/^- (.*): *(participated|[0-9]+ sent)/\1/')
EOF
if [ -z "$missing_speakers" ]; then
  pass "Every agent claimed as participating appears in a printed Huddle exchange"
else
  fail "Participation claimed with no printed exchange:$missing_speakers"
fi

stance_satisfied=$(grep -c '^> *I am satisfied' "$TRANSCRIPT" 2>/dev/null) || true
stance_open=$(grep -c '^> *Open items:' "$TRANSCRIPT" 2>/dev/null) || true
stance_total=$((${stance_satisfied:-0} + ${stance_open:-0}))
if [ "$stance_total" -ge 8 ]; then
  pass "Per-agent Phase 2 stances recorded ($stance_satisfied satisfied, $stance_open open-item lists)"
else
  fail "Only $stance_total of 8 explicit Phase 2 stances found; an aggregate count does not satisfy the per-agent rule"
fi

openers=$(grep -oE 'I verified this:|I cannot verify this:|This is incorrect:|I tested this:' "$TRANSCRIPT" 2>/dev/null | wc -l | tr -d ' ')
if [ "${openers:-0}" -ge 8 ]; then
  pass "Literal verification openers present ($openers)"
else
  fail "Only ${openers:-0} literal verification openers found; the moderator is summarizing rather than verifying (SKILL.md Phase 2)"
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
  "Unresolved Disagreements"
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
if grep -q '^\*\*STOP\.\*\*' "$TRANSCRIPT" 2>/dev/null; then
  pass "STOP guardrail block present in transcript"
else
  fail "Missing '**STOP.**' guardrail block in the transcript file (SKILL.md Phase 4)"
fi

printf "\nWorkflow Artifacts\n"
if contains "Exchange counts"; then
  pass "Phase 2 exchange counts recorded"
else
  fail "Missing 'Exchange counts this round' line (SKILL.md Phase 2)"
fi

if contains "Huddle Participation"; then
  pass "Huddle participation checklist present"
else
  fail "Missing Huddle participation checklist (SKILL.md Phase 3)"
fi

if contains "Blocker Re-Test Ledger"; then
  pass "Blocker re-test ledger present"
else
  fail "Missing Blocker Re-Test Ledger (SKILL.md Phase 2)"
fi

if contains "Self-check before The Huddle"; then
  pass "Pre-Huddle moderator self-check present"
else
  fail "Missing 'Self-check before The Huddle' (SKILL.md Phase 2)"
fi

if contains "Consensus Ledger"; then
  pass "Consensus Ledger present"
else
  fail "Missing Consensus Ledger (SKILL.md Phase 2 and Phase 2)"
fi

printf "\nFirst-Person Discipline\n"
third_person=$(grep -cE '^> *(Demanded |Wants to |wants to know|Asked |Reviewed the |Caught the |Confirms |confirms |Noted that )' "$TRANSCRIPT" 2>/dev/null) || true
third_person=${third_person:-0}
if [ "$third_person" -eq 0 ]; then
  pass "No third-person narration markers inside blockquotes"
else
  fail "Found $third_person blockquote line(s) with third-person narration (SKILL.md: first person only)"
  grep -nE '^> *(Demanded |Wants to |wants to know|Asked |Reviewed the |Caught the |Confirms |confirms |Noted that )' "$TRANSCRIPT" 2>/dev/null | sed 's/^/          /'
fi

printf "\nState Management\n"
transcript_dir=$(dirname "$TRANSCRIPT")
STATE="$transcript_dir/moe-state.json"
if [ -f "$STATE" ]; then
  pass "State file exists alongside transcript"
  if grep -q '"synthesis"[^}]*"completed"' "$STATE" 2>/dev/null; then
    if grep -qE '"(kick-off|interactive-session|the-huddle)"[^}]*"(pending|in_progress)"' "$STATE" 2>/dev/null; then
      fail "State file inconsistent: synthesis completed while an earlier phase is pending/in_progress"
    else
      pass "State file phase statuses are internally consistent"
    fi
    if grep -q '"huddle_exchanges": *{ *}' "$STATE" 2>/dev/null; then
      fail "State file: huddle_exchanges is empty after a completed Huddle"
    else
      pass "State file: huddle exchanges recorded"
    fi
  fi
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
