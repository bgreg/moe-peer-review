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

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
SKILL="$PLUGIN_ROOT/skills/moe-peer-review/SKILL.md"
AGENTS_DIR="$PLUGIN_ROOT/agents"
HOOKS_DIR="$PLUGIN_ROOT/hooks"

printf "\n=== MOE Plugin Validation ===\n"
printf "Plugin root: %s\n\n" "$PLUGIN_ROOT"

contains() { grep -qi "$1" "$2" 2>/dev/null; }
contains_e() { grep -qiE "$1" "$2" 2>/dev/null; }

printf "Plugin Structure\n"
if [ -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]; then
  pass "plugin.json exists"
else
  fail "plugin.json missing"
fi

if [ -f "$SKILL" ]; then
  pass "SKILL.md exists"
else
  fail "SKILL.md missing"
fi

if [ -f "$HOOKS_DIR/hooks.json" ]; then
  pass "hooks.json exists"
else
  fail "hooks.json missing"
fi

printf "\nTerminology\n"
if grep -qi "orchestrator" "$SKILL" 2>/dev/null; then
  fail "SKILL.md contains 'orchestrator' (should be 'moderator')"
else
  pass "No 'orchestrator' in SKILL.md"
fi

if contains "moderator" "$SKILL"; then
  pass "SKILL.md uses 'moderator'"
else
  fail "SKILL.md missing 'moderator' terminology"
fi

if contains "Dr. Nina Simone-Bennett" "$SKILL"; then
  pass "Moderator persona named in SKILL.md"
else
  fail "Missing moderator persona name"
fi

printf "\nNaming\n"
if contains "ChaoticCarl" "$SKILL"; then
  pass "SKILL.md uses 'ChaoticCarl'"
else
  fail "SKILL.md missing 'ChaoticCarl'"
fi

if contains_e "never (shortened|abbreviated)" "$SKILL"; then
  pass "SKILL.md has abbreviation prevention"
else
  fail "SKILL.md missing abbreviation prevention for ChaoticCarl"
fi

carl_solo=$(grep -vE 'never (be )?(shorten|abbreviat)|is one word' "$SKILL" 2>/dev/null \
  | grep -oE '[A-Za-z]*Carl[A-Za-z]*' 2>/dev/null | grep -cx 'Carl') || true
carl_solo=${carl_solo:-0}
if [ "$carl_solo" -eq 0 ]; then
  pass "No bare 'Carl' without 'Chaotic' prefix in SKILL.md"
else
  fail "Found $carl_solo bare 'Carl' reference(s) in SKILL.md"
  grep -vE 'never (be )?(shorten|abbreviat)|is one word' "$SKILL" \
    | grep -nE '(^|[^A-Za-z])Carl([^A-Za-z]|$)' 2>/dev/null | sed 's/^/          /'
fi

printf "\nRequired Sections\n"
sections=(
  "Review-Only Guardrail"
  "Agent Roster"
  "Dynamic Assignment"
  "Naming Rules"
  "Tool Scope"
  "Live Thread Output"
  "State Management"
  "The Huddle"
  "Reconciliation"
)
for section in "${sections[@]}"; do
  if contains "$section" "$SKILL"; then
    pass "Section: $section"
  else
    fail "Missing section: $section"
  fi
done

printf "\nPhase Structure\n"
phases=(
  "Phase 1: Kick-Off"
  "Interactive Session"
  "The Huddle"
  "Synthesis"
)
for phase in "${phases[@]}"; do
  if contains "$phase" "$SKILL"; then
    pass "Phase: $phase"
  else
    fail "Missing phase: $phase"
  fi
done

if contains "Exchange cap" "$SKILL"; then
  pass "Exchange cap mentioned"
else
  fail "Missing exchange cap"
fi

if contains "Satisfaction" "$SKILL" || contains "satisfied" "$SKILL"; then
  pass "Satisfaction handling documented"
else
  fail "Missing satisfaction handling rule"
fi

printf "\niMessage Format\n"
if contains "Dr. Nina Simone-Bennett\*\* ->" "$SKILL"; then
  pass "Moderator -> Persona format in SKILL.md"
else
  fail "Missing 'Dr. Nina Simone-Bennett -> Persona' format"
fi

if contains "blockquoted" "$SKILL" || contains "blockquote" "$SKILL"; then
  pass "Blockquote instruction present"
else
  fail "Missing blockquote instruction"
fi

if contains_e "interleaved|iMessage" "$SKILL"; then
  pass "Interleaved/iMessage format referenced"
else
  fail "Missing interleaved format reference"
fi

printf "\nReview-Only Guardrail\n"
if contains "STOP" "$SKILL"; then
  pass "STOP directive present"
else
  fail "Missing STOP directive"
fi

if contains "Do not apply" "$SKILL" || contains "never apply" "$SKILL"; then
  pass "Review-only guardrail language"
else
  fail "Missing review-only guardrail language"
fi

printf "\nState Management\n"
if contains "moe-state.json" "$SKILL"; then
  pass "State file referenced"
else
  fail "Missing state file reference"
fi

if contains "TaskCreate" "$SKILL" || contains "task list" "$SKILL"; then
  pass "Todo list integration"
else
  fail "Missing todo list integration"
fi

if contains "compaction" "$SKILL" || contains "Recovery" "$SKILL"; then
  pass "Compaction recovery instructions"
else
  fail "Missing compaction recovery"
fi

printf "\nSynthesis Structure\n"
synthesis_parts=(
  "Verdict Scoreboard"
  "Production Gates"
  "Compliance Findings"
  "Domain Expert Warnings"
  "User Experience Failures"
  "Key Insight"
  "Action Items"
)
for part in "${synthesis_parts[@]}"; do
  if contains "$part" "$SKILL"; then
    pass "Synthesis: $part"
  else
    fail "Missing synthesis section: $part"
  fi
done

printf "\nSelf-Validation\n"
if contains "validate-moe-transcript" "$SKILL"; then
  pass "Transcript validator referenced"
else
  fail "Missing transcript validator reference"
fi

if contains "Quality Assessment" "$SKILL" || contains "remediation-plan" "$SKILL"; then
  pass "Quality assessment step present"
else
  fail "Missing quality assessment step"
fi

printf "\nAgent Roster\n"
agents=(
  "beyonce:Beyonce Carter"
  "jill-scott:Jill Scott-Williams"
  "janelle-monae:Janelle Monae Robinson"
  "sza:SZA"
  "erykah-badu:Erykah Badu-Johnson"
  "doechii:Doechii"
  "whitney-houston:Whitney Houston-Davis"
  "chaotic-carl:ChaoticCarl"
)
for entry in "${agents[@]}"; do
  file="${entry%%:*}"
  name="${entry#*:}"
  if contains "$name" "$SKILL"; then
    pass "Roster: $name"
  else
    fail "Missing from roster: $name"
  fi
done

printf "\nAgent Files\n"
agent_files=(beyonce jill-scott janelle-monae sza erykah-badu doechii whitney-houston chaotic-carl moe-moderator)
for agent in "${agent_files[@]}"; do
  agent_file="$AGENTS_DIR/$agent.md"
  if [ -f "$agent_file" ]; then
    pass "Agent file exists: $agent.md"
  else
    fail "Agent file missing: $agent.md"
    continue
  fi

  if grep -qi "orchestrator" "$agent_file" 2>/dev/null; then
    fail "Agent $agent.md contains 'orchestrator'"
  else
    pass "Agent $agent.md uses correct terminology"
  fi

  if contains "read-only\|never create\|never edit\|never write\|No file modifications" "$agent_file" || contains_e "read-only|never create|never edit|never write|No file modifications" "$agent_file"; then
    pass "Agent $agent.md has read-only constraint"
  else
    if [ "$agent" = "moe-moderator" ]; then
      pass "Agent moe-moderator.md (moderator can write)"
    else
      fail "Agent $agent.md missing read-only constraint"
    fi
  fi

  if grep -q "^model:" "$agent_file" 2>/dev/null; then
    pass "Agent $agent.md has model in frontmatter"
  else
    fail "Agent $agent.md missing model frontmatter"
  fi

  if grep -q "^color:" "$agent_file" 2>/dev/null; then
    pass "Agent $agent.md has color in frontmatter"
  else
    fail "Agent $agent.md missing color frontmatter"
  fi

  if contains "Huddle" "$agent_file"; then
    pass "Agent $agent.md has Huddle behavior"
  else
    if [ "$agent" = "moe-moderator" ]; then
      pass "Agent moe-moderator.md has Huddle role"
    else
      fail "Agent $agent.md missing Huddle behavior"
    fi
  fi
done

printf "\nHook Files\n"
if [ -f "$HOOKS_DIR/scripts/validate-moe-agent-output.sh" ]; then
  pass "SubagentStop hook script exists"
else
  fail "SubagentStop hook script missing"
fi

if [ -f "$HOOKS_DIR/scripts/save-moe-state.sh" ]; then
  pass "PreCompact hook script exists"
else
  fail "PreCompact hook script missing"
fi

if contains "SubagentStop" "$HOOKS_DIR/hooks.json"; then
  pass "SubagentStop configured in hooks.json"
else
  fail "SubagentStop missing from hooks.json"
fi

if contains "PreCompact" "$HOOKS_DIR/hooks.json"; then
  pass "PreCompact configured in hooks.json"
else
  fail "PreCompact missing from hooks.json"
fi

printf "\n=== Results ===\n"
printf "%d passed, %d failed, %d warnings\n\n" "$PASS" "$FAIL" "$WARN"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
