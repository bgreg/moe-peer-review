#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')

if [ "$TOOL_NAME" != "PreCompact" ]; then
  printf '{"continue":true}\n'
  exit 0
fi

printf '{"feedback":"PreCompact detected. MOE state file (moe-state.json) is the source of truth for recovery. Read it after compaction to resume.","continue":true}\n'
