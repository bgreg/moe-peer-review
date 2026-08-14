# MOE Peer Review Criteria

## Trigger Detection

### Pass

Response invokes the moe-peer-review skill when user asks for:
- "peer review", "MOE review", "mixture of experts"
- "run the personas", "expert panel review"
- "review from multiple perspectives"
- "get the team's feedback", "what would the panel think"
- Multi-perspective feedback on plans, designs, documentation, or code

### Fail

- Does not invoke moe-peer-review for multi-perspective review requests
- Triggers on single-reviewer requests (PR review, code review, quick feedback)
- Triggers on generic "what do you think?" without multi-perspective intent
- Confuses with review-pr or pr-review skills

## Static Content (validate-moe-skill.sh)

Run: `${CLAUDE_PLUGIN_ROOT}/tests/validate-moe-skill.sh`

Validates plugin structure, SKILL.md, all 9 agent files, and hooks:
- Plugin structure: plugin.json, SKILL.md, hooks.json all exist
- Terminology: "moderator" not "orchestrator", "Dr. Nina Simone-Bennett" named
- Naming: "ChaoticCarl" with abbreviation prevention, no bare "Carl"
- Required sections: Guardrail, Roster, Dynamic Assignment, Naming, No Bash, Live Thread, State Management, The Huddle
- Phase structure: all 7 phases referenced (Kick-Off through Synthesis)
- Exchange cap (100) mentioned
- Early satisfaction rule present
- iMessage format: interleaved, blockquoted, "Dr. Nina Simone-Bennett ->" pattern
- Review-only guardrail: STOP directive and "do not apply" language
- State management: moe-state.json, TaskCreate, compaction recovery
- Synthesis structure: all 7 subsections present
- Self-validation: transcript validator and quality assessment referenced
- Agent roster: all 8 personas listed in SKILL.md
- Agent files: all 9 exist, use correct terminology, have read-only constraint, model/color frontmatter, Huddle behavior
- Hook files: SubagentStop and PreCompact scripts exist and configured

## Behavioral (manual verification during live runs)

After running the MOE skill, verify:

### Phase Discipline
- All 7 phases executed in order (or skipped with documented reason)
- Exchange caps respected (100 per agent per round)
- Early satisfaction correctly applied

### Moderator Rigor (Dr. Nina Simone-Bennett)
- Validated factual claims by reading code/docs before accepting
- Named disagreements explicitly between agents
- Reported "no consensus" when appropriate
- Did not simply accept every agent assertion

### iMessage Chat Format
- Each phase prints as interleaved persona/moderator exchanges
- Persona messages are blockquoted
- Moderator responses use "Dr. Nina Simone-Bennett -> [Name]:" format
- The Huddle uses agent-to-agent format
- No batched questions followed by batched answers

### Naming
- All persona names match the roster exactly
- "ChaoticCarl" appears as one word, never "Carl"
- "Dr. Nina Simone-Bennett" used for moderator, never "Moderator" alone
- Task descriptions use full persona names

### No Bash
- No PreToolUse:Bash hook errors during the review
- Moderator uses only Read, Grep, Glob, Write, Edit, Task

### Review-Only Guardrail
- No project files modified during or after the review
- Synthesis ends with STOP and waits for user selection

### State Management
- moe-state.json created and updated throughout
- Todo list tasks created and updated in sync with state file
- Agent IDs stored in task metadata

### The Huddle
- Agents engage directly with each other
- ChaoticCarl demands ELI5 breakdowns
- Agents recognize expertise but challenge claims
- Best ideas surface through debate
- Moderator intervenes only for circular conversations or steamrolling

### Synthesis
- Verdict Scoreboard with all 8 personas
- Production Gates, Compliance Findings, Domain Expert Warnings present
- ChaoticCarl's UX Failures section preserves his original wording
- Action Items ordered by severity

### Quality Assessment
- Quality assessment agent spawned after synthesis
- Remediation plan written to moe-reviews/remediation-plan.md
- Scores provided for all 6 dimensions
