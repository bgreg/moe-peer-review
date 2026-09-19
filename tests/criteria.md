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
- Required sections: Guardrail, Roster, Dynamic Assignment, Naming, Tool Scope, Live Thread, State Management, The Huddle
- Phase structure: all 4 phases referenced (Kick-Off, Interactive Session, The Huddle, Synthesis)
- Exchange cap mentioned
- Satisfaction handling rule present
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

### Observer and Moderator Split
- The main session spawns Dr. Nina Simone-Bennett as a `moe-moderator` agent and prints what she sends
- The main session makes no review decisions and does not verify, seed, nudge, or call time
- The moderator spawns the eight personas herself and records their IDs in moe-state.json

### Phase Discipline
- All 4 phases executed in order (Kick-Off, Interactive Session, The Huddle, Synthesis)
- Exchange caps respected (3 per agent in Phase 2, 4 messages sent per agent in The Huddle)
- Exchange-count line printed at the end of Phase 2
- Every persona received the moderator's opening verification and a response in Phase 2 (3N blocks for N personas)
- Blocker Re-Test Ledger present, with a row for every Blocker reaching Synthesis

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

### Tool Scope
- Moderator has full tool access and writes only to the review output directory
- Persona Bash commands are read-only inspection only (git log/diff/show, grep, rg, find, cat, wc, ls)

### Review-Only Guardrail
- No project files modified during or after the review
- Synthesis ends with STOP and waits for user selection

### State Management
- moe-state.json created and updated throughout
- Todo list tasks created and updated in sync with state file when TaskCreate is available to the moderator
- Agent IDs stored in task metadata

### The Huddle
- Every persona receives the full Findings Board (all eight Phase 2 stances, verbatim) and the peer roster
- Personas choose whom to engage and message each other directly with SendMessage
- The moderator is not in the message path; she checks participation, nudges anyone at zero once with no content, and calls time after at most two rounds
- ChaoticCarl reads the board and picks like everyone else; the participation check confirms he was answered
- SENT/RECEIVED logs collected from every persona and cross-checked pairwise before the transcript is printed
- Best ideas surface through debate

### Synthesis
- Verdict Scoreboard with all 8 personas
- Production Gates, Compliance Findings, Domain Expert Warnings present
- ChaoticCarl's UX Failures section preserves his original wording
- Action Items ordered by severity

### Quality Assessment
- Quality assessment agent spawned after synthesis
- Plugin improvement suggestions written to moe-reviews/plugin-improvements.md
- Scores provided for all 6 dimensions
