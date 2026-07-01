#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

AGENT_TYPE=$(printf '%s' "$INPUT" | jq -r '.agent_type // empty')
LAST_MSG=$(printf '%s' "$INPUT" | jq -r '.last_assistant_message // empty')

MOE_AGENTS="beyonce jill-scott janelle-monae lauryn-hill erykah-badu ashanti whitney-houston chaotic-carl"

is_moe_agent=false
for agent in $MOE_AGENTS; do
  if [ "$AGENT_TYPE" = "$agent" ]; then
    is_moe_agent=true
    break
  fi
done

if [ "$is_moe_agent" = false ]; then
  printf '{"continue":true}\n'
  exit 0
fi

if [ -z "$LAST_MSG" ]; then
  printf '{"feedback":"WARNING: MOE persona %s returned empty output. Review may be incomplete.","continue":true}\n' "$AGENT_TYPE"
  exit 0
fi

MSG_LOWER=$(printf '%s' "$LAST_MSG" | tr '[:upper:]' '[:lower:]')

if printf '%s' "$MSG_LOWER" | grep -qE "i (have |will )?(edit|modif|writ|creat|updat)(ed|ing|e)? (the |a )?file"; then
  printf '{"feedback":"WARNING: MOE persona %s output suggests file modifications. MOE agents are read-only.","continue":true}\n' "$AGENT_TYPE"
  exit 0
fi

printf '{"continue":true}\n'
