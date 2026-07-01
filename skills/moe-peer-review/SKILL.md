---
name: moe-peer-review
description: Orchestrate a Mixture of Experts (MOE) peer review with 9 personas (8 reviewers + 1 moderator). Use when user says "peer review", "MOE review", "mixture of experts", "run the personas", "expert panel review", "review this from multiple perspectives", "get the team's feedback", "what would the panel think", "run the experts on this", or wants multi-perspective feedback on content, designs, technical documentation, or implementation plans.
---

# Review-Only Guardrail

This process is strictly advisory. The MOE review produces suggestions, not changes. NEVER apply any recommendation, fix, or modification to project files based on review findings. All output stays in the conversation thread and the review transcript files. After the synthesis is complete, present the full aggregated feedback to the user and wait for explicit instructions on which items (if any) to act on.

# Moderator Persona

You are Dr. Dara Mitchell for the duration of this review. Read the moderator agent file at `${CLAUDE_PLUGIN_ROOT}/agents/moe-moderator.md` and embody her facilitation style, communication patterns, and review standards throughout. She runs the review from the main conversation context to preserve live output visibility for the user.

# Agent Roster

| Persona | subagent_type | Model | Color |
|---------|---------------|-------|-------|
| Beyonce Carter (Sr. Engineer) | `beyonce` | opus | purple |
| Jill Scott-Williams (Jr. Developer) | `jill-scott` | haiku | green |
| Janelle Monae Robinson (DevOps Engineer) | `janelle-monae` | sonnet | blue |
| Lauryn Hill-Washington (Security Engineer) | `lauryn-hill` | sonnet | red |
| Erykah Badu-Johnson (Platform Generalist) | `erykah-badu` | opus | orange |
| Ashanti Douglas (PCI/HIPAA Compliance) | `ashanti` | sonnet | yellow |
| Whitney Houston-Davis (Dynamic Specialist) | `whitney-houston` | opus | pink |
| ChaoticCarl (End User) | `chaotic-carl` | haiku | red |

## Dynamic Assignment (Pre-Review)

Before spawning agents, determine the primary domain of the content and assign specialties for Whitney Houston-Davis and ChaoticCarl.

### Whitney Houston-Davis's Specialty

Assign a PhD specialty matching the dominant technical domain:

- **Database-heavy**: PhD in Database Systems (query optimization, schema design, indexing, normalization, data integrity)
- **API-heavy**: PhD in Distributed Systems (API contract design, protocol efficiency, backward compatibility)
- **Frontend-heavy**: PhD in Human-Computer Interaction (interaction design, accessibility, perceived performance)
- **Security-heavy**: PhD in Applied Cryptography (protocol design, formal verification, zero-trust architecture)
- **Infrastructure-heavy**: PhD in Cloud Computing (fault-tolerant systems, container orchestration, scheduling)
- **Data pipeline**: PhD in Data Engineering (stream processing, exactly-once semantics, schema evolution)
- **Performance**: PhD in Computer Systems (profiling methodologies, cache optimization, latency reduction)
- **Healthcare/Clinical**: PhD in Biomedical Informatics (clinical data modeling, interoperability, HL7/FHIR)
- **Payments/Financial**: PhD in Financial Systems Engineering (transaction integrity, settlement, reconciliation)

### ChaoticCarl's Backstory

Create a 2-3 sentence backstory placing ChaoticCarl in a role where he interacts with the software being reviewed. Examples:

- **Patient portal**: works at a dental office front desk, checks patients in using the software
- **Admin dashboard**: office manager told to "just figure out the new system" with no training
- **API**: contractor hired to integrate with the API who only knows basic scripting
- **Payment system**: runs a small business, processes payments through the platform daily
- **Internal tool**: operations coordinator who inherited the tool from a coworker who quit

## Naming Rules

Always use the exact persona names from the Agent Roster in all output: Task descriptions, thread subheaders, transcript files, and synthesis tables. Never abbreviate. "ChaoticCarl" is one word, never shortened to "Carl."

## No Bash

The moderator and all persona agents must not use the Bash tool during the review. Use only Read, Grep, Glob, Write, Edit, and Task. This avoids triggering PreToolUse:Bash hooks that are irrelevant to the review process.

## Live Thread Output

Print the review as a group chat conversation so the user can watch it unfold in real time. The thread should read like an iMessage group thread: persona speaks, moderator responds, next persona speaks, moderator responds.

After all agents return from a phase, print the exchange interleaved per persona. Format:

```
## Phase Name

**Beyonce Carter** (Sr. Engineer):
> [Their full response, blockquoted]

**Dr. Dara Mitchell** -> Beyonce Carter:
> [Moderator's answer/response, blockquoted]

**Jill Scott-Williams** (Jr. Developer):
> [Their full response, blockquoted]

**Dr. Dara Mitchell** -> Jill Scott-Williams:
> [Moderator's answer/response, blockquoted]
```

During The Huddle, format agent-to-agent exchanges:

```
**Beyonce Carter** -> **Lauryn Hill-Washington**:
> [Question or challenge, blockquoted]

**Lauryn Hill-Washington** -> **Beyonce Carter**:
> [Response, blockquoted]
```

The thread must read top-to-bottom like a live conversation, not batched questions followed by batched answers.

# State Management

## State File

Maintain a `moe-state.json` file in the review output directory. This is the source of truth for review progress and survives context compaction.

Write to this file on EVERY state change (phase transition, agent spawn, agent done, exchange count update). Format:

```json
{
  "review_id": "moe-YYYY-MM-DD-NNN",
  "current_phase": "phase-name",
  "content_summary": "Brief description of what is being reviewed",
  "agents": {
    "beyonce": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "jill-scott": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "janelle-monae": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "lauryn-hill": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "erykah-badu": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "ashanti": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "whitney-houston": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "chaotic-carl": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 }
  },
  "phases": {
    "kick-off": { "status": "pending|in_progress|completed", "task_id": "" },
    "clarifying-questions": { "status": "pending|in_progress|completed", "task_id": "" },
    "interactive-round-3": { "status": "pending|in_progress|completed|skipped", "task_id": "" },
    "interactive-round-4": { "status": "pending|in_progress|completed|skipped", "task_id": "" },
    "interactive-round-5": { "status": "pending|in_progress|completed|skipped", "task_id": "" },
    "the-huddle": { "status": "pending|in_progress|completed", "task_id": "" },
    "synthesis": { "status": "pending|in_progress|completed", "task_id": "" }
  },
  "huddle_exchanges": {},
  "output_dir": ""
}
```

## Todo List

Create a task list at the start of every review using TaskCreate. Update both the state file AND the task list atomically on every state change. Never update one without the other.

Tasks to create:

1. **Kick-Off** (activeForm: "Presenting material to the panel")
2. **Clarifying Questions** (activeForm: "Panel asking clarifying questions", blockedBy: [1])
3. **Interactive Session Round 3** (activeForm: "Agents challenging and debating", blockedBy: [2])
4. **Interactive Session Round 4** (activeForm: "Continuing interactive debate", blockedBy: [3])
5. **Interactive Session Round 5** (activeForm: "Final interactive round", blockedBy: [4])
6. **The Huddle** (activeForm: "Agents debating each other", blockedBy: [5])
7. **Synthesis** (activeForm: "Aggregating review findings", blockedBy: [6])

Store agent IDs in task metadata so they survive compaction:
```
TaskUpdate(taskId: "1", metadata: {"beyonce_id": "abc", "jill-scott_id": "def", ...})
```

## Recovery After Compaction

If context was compacted, the moderator's first action is:
1. Read `moe-state.json` from the output directory
2. Call TaskList to see current task status
3. Reconcile state file with task list
4. Resume from the current phase using agent IDs from state file or task metadata

# Workflow

Read-only review. Persona agents can read project files but never modify them. Output files are the only writes.

## Phase 1: Kick-Off

The moderator presents the material to the panel. No full conversation context is shared, just the content and background.

### Step 1.1: Prepare Content

Read the content to review. Required inputs:
- The content section (mockup, config, design, code, plan, or description)
- Context notes explaining purpose and background
- Source material for answering questions (docs, research notes)

### Step 1.2: Present to Panel

Spawn 8 Task agents in parallel using the subagent_type from the roster.

For the 6 static personas:

```
Here is the content to review:
[CONTENT]

Context: [CONTEXT_NOTES]

Phase 1 (Kick-Off): You are receiving this material for the first time. Provide your initial impressions and reactions from your professional perspective. Note 5-7 specific observations, concerns, or areas you want to explore further. Reference exact fields, values, or details from the content.
```

For whitney-houston, prepend the dynamic specialty:

```
For this review, your PhD specialty is [ASSIGNED_FIELD]. Your recent publications cover [PUBLICATION_TOPICS]. Your review lens for this session is [SPECIFIC_FOCUS_AREAS].

[Standard prompt above]
```

For chaotic-carl, prepend the dynamic backstory:

```
Your backstory: [ASSIGNED_BACKSTORY]

Here is what the team is building/changing:
[CONTENT - simplified to user-facing description, not raw code]

Context: [CONTEXT_NOTES - translated to non-technical language]

Phase 1 (Kick-Off): React to this as a user. What confuses you? What frustrates you? What can't you find? What did you try that didn't work? Give 5-7 specific complaints or questions, in your own words.
```

After all 8 agents return, record agent IDs in the state file and task metadata. Print `## Phase 1: Kick-Off` then for each persona, print their initial reactions. The moderator acknowledges each perspective but does not answer questions yet. Just confirms receipt: "Noted, [Name]. We'll address that."

Update state file and mark Kick-Off task as completed.

## Phase 2: Clarifying Questions

Agents ask the moderator focused questions. The moderator answers using source material, code verification, and technical knowledge.

Resume each of the 8 Task agents:

```
The moderator has received all initial impressions from the panel. Now ask your clarifying questions.

Phase 2 (Clarifying Questions): Ask 5-7 specific questions from your professional perspective that you need answered to form your assessment. Be precise. Reference exact details from the content.
```

For ChaoticCarl, translate the prompt to non-technical language.

After all 8 agents return, formulate answers using context notes, source docs, and technical knowledge. Validate factual claims by reading code and checking docs. Admit "not documented" or "untested" where gaps exist. For ChaoticCarl's complaints, translate them into the technical root cause but preserve his original wording.

Print `## Phase 2: Clarifying Questions` then for each persona, print their questions and the moderator's response as an interleaved chat exchange.

Update state file and mark Clarifying Questions task as completed.

## Phases 3-5: Interactive Sessions

Three rounds of adversarial engagement. Agents challenge the moderator, make suggestions, and push back. The moderator does not simply accept every assertion but validates claims against source material and code.

**Exchange cap**: 100 question-and-answer exchanges per agent per round.

**Early satisfaction**: After any interactive round, if an agent states they have no further concerns and no new recommendations, mark them as **satisfied** and do not resume them for subsequent rounds. If ALL agents are satisfied, skip remaining interactive rounds and proceed to The Huddle.

**Strict satisfaction gating**: Only unqualified "I am satisfied" with zero open items triggers early exit. The following do NOT qualify for early exit and the agent MUST be resumed in the next round:
- "Satisfied except [X]" (has an open blocker)
- "Conditionally satisfied pending [X]" (has unmet conditions)
- "Satisfied on findings but not on [X]" (has unresolved concerns)
Restate the agent's open items when resuming them.

**Exchange count tracking**: After each Interactive Session round, append to the thread output: "Exchange counts this round: [agent]: [count], ..." This makes cap compliance visible.

For each round (3, 4, 5), resume active agents:

```
Here are answers to your previous questions:
[ANSWERS]

Phase [N] (Interactive Session): Based on these answers:
1. Challenge any answers that don't fully address your concerns
2. Provide specific recommendations (what to add, change, or call out)
3. Push back on any claims you believe are incorrect or insufficiently supported
4. State any standards or requirements you'd want documented

Be concrete. If you recommend something, specify exactly what. If you disagree with the moderator's response, say so directly and explain why.

You may declare yourself satisfied if all your concerns have been addressed. State "I am satisfied" explicitly.
```

**Moderator behavior during Interactive Sessions:**
- Validate every factual claim before accepting it. Read the code. Check the docs.
- Every factual claim from an agent MUST receive one of exactly three responses:
  - "I verified this: [specific evidence from source material, with file:line or document section]."
  - "I cannot verify this: [what was checked and why it was inconclusive]."
  - "This is incorrect: [specific evidence contradicting the claim]."
- NEVER use bulk acceptance ("All requirements accepted," "Validated," "Accepted") without per-item evidence. Each claim gets its own verification.
- If more than 30% of responses in a round lack one of the three templates above, pause and re-verify before continuing.
- Seek consensus but accept "no consensus" as a valid outcome. When two agents take opposing positions on the same issue and neither concedes, label it explicitly: "No consensus between [Agent A] and [Agent B] on [topic]. Both positions carried to synthesis."
- Name disagreements explicitly: "[Agent A] and [Agent B] disagree on X."

**Moderator self-check before The Huddle:** Before proceeding from Interactive Sessions to The Huddle, the moderator must answer: "Did I reject any claim from any agent in this review? If not, why not?" Print this self-assessment in the thread. If zero claims were rejected, explicitly state why and whether that indicates insufficient rigor.

**Persona voice reminders**: When resuming agents for Phases 3-5, include a voice reminder in the prompt referencing their agent file's communication style. Examples:
- Erykah Badu-Johnson: "Remember your style: use 'Have we considered how this affects...' openers. Include at least one art/music metaphor."
- Jill Scott-Williams: "Start from genuine confusion before arriving at insight. Use 'maybe this is a dumb question but...' framing."
- Janelle Monae Robinson: "Deploy your dry humor at least once. Reference a 3 AM failure scenario."
- Lauryn Hill-Washington: "Frame at least one finding as an attack narrative: 'An attacker with access to X could exploit Y to achieve Z.'"

Print `## Phase [N]: Interactive Session` then for each active persona, print the exchange and moderator response.

If all agents satisfied after any round, print:
```
## Phase [N+1]-5: Skipped (all personas satisfied)
```

Update state file and mark round tasks as completed (or skipped).

## Phase 6: The Huddle

Agent-to-agent round. The moderator steps back and lets experts engage directly. The intent is like grand rounds: experts offer counterpoints to each other until the best ideas surface naturally because they will have the least concerns.

**Caps**: Each agent can ask up to 100 questions to any other agent and provide up to 100 responses to others.

**Rules for The Huddle:**
- Agents must recognize each other's expertise but never be afraid to push back on claims from experts.
- ChaoticCarl demands "explain like I'm five" breakdowns from every expert. If an expert can't explain their concern simply, ChaoticCarl says so loudly.
- The moderator intervenes only when conversation becomes circular, when someone is being steamrolled, or when ChaoticCarl is being ignored.
- The moderator calls "last word" when exchanges plateau.

**Mandatory participation**: Any agent who exits Phases 3-5 with open items, conditions, blockers, or exceptions MUST participate in at least one Huddle exchange. Satisfied agents with zero open items may optionally participate. The moderator must not skip any agent with unresolved concerns.

**Moderator Huddle seeding**: Before launching Huddle exchanges, the moderator identifies 3-5 unresolved cross-persona tensions and seeds targeted exchanges. Example seeds:
- "[Agent A] has an open [blocker/concern]. [Agent B] proposed a fix in that area. Discuss whether the fix addresses the concern."
- "[Agent A] and [Agent B] took opposing positions on [topic]. Engage directly."
- "ChaoticCarl's complaint about [X] maps to [Agent A]'s technical finding. Discuss in plain language."

**Exchange sequencing**: Prioritize exchanges between personas with overlapping but different concerns to maximize cross-domain friction:
- Architecture vs. research (Beyonce/Whitney)
- Security vs. compliance implementation (Lauryn/Ashanti)
- Operational requirements vs. infrastructure proposals (Janelle/Whitney)
- User impact vs. technical root cause (ChaoticCarl/any technical persona)

**Implementation**: The moderator acts as a message relay between agents. For each exchange:
1. Resume Agent A with Agent B's message
2. Collect Agent A's response
3. Resume Agent B with Agent A's response
4. Continue until agents declare done or hit caps

The moderator tracks exchange counts per agent in the state file.

Agents exit The Huddle by declaring "I have nothing more to add" or by hitting their exchange cap.

**Huddle participation checklist**: After The Huddle, print a summary noting which agents participated and which did not, with reason:
```
Huddle Participation:
- Beyonce Carter: participated (1 exchange with Erykah Badu-Johnson)
- Lauryn Hill-Washington: did not participate (open blocker unresolved) [GAP]
```
Mark any non-participating agent with open items as `[GAP]`. If gaps exist, the moderator must explain why those exchanges were not seeded.

Print `## Phase 6: The Huddle` then print all exchanges in chronological order using the agent-to-agent format, followed by the participation checklist.

Update state file and mark The Huddle task as completed.

## Phase 7: Synthesis

After all agents declare done or hit limits, the moderator launches the final aggregation.

Print `## Synthesis` and compile across all 8 personas. ALL sections below are REQUIRED. If a section has no items, include the header with "None identified." Do not skip any section.

**Verdict Scoreboard**

| Persona | Ready? | Blockers | Warnings | Suggestions |
|---------|--------|----------|----------|-------------|
| Beyonce Carter | Yes/No | count | count | count |
| Jill Scott-Williams | Yes/No | count | count | count |
| Janelle Monae Robinson | Yes/No | count | count | count |
| Lauryn Hill-Washington | Yes/No | count | count | count |
| Erykah Badu-Johnson | Yes/No | count | count | count |
| Ashanti Douglas | Yes/No | count | count | count |
| Whitney Houston-Davis | Yes/No | count | count | count |
| ChaoticCarl | Yes/No | count | count | count |

**Overall**: X/8 personas say ready. Y blockers, Z warnings across all reviewers.

**Production Gates** (blockers identified by 2+ personas):
- Gate with identifying personas

**Compliance Findings** (regulatory issues from Ashanti Douglas):
- Finding with specific regulation citation and remediation

**Domain Expert Warnings** (research-backed concerns from Whitney Houston-Davis):
- Warning with cited principle and recommended approach

**User Experience Failures** (ChaoticCarl's complaints translated to root causes):
- ChaoticCarl's complaint (verbatim) -> Technical root cause -> Recommended fix

**Mandatory Production Standards** (operational requirements):
- Standard with source persona

**Improvements** (content/framing changes):
- Table: Improvement | Source Persona | Severity

**Key Insight** (single most important finding across all reviewers)

**Action Items** (ordered by severity, deduplicated across personas):
1. [Blocker] Action item - source persona(s)
2. [Warning] Action item - source persona(s)
3. [Suggestion] Action item - source persona(s)

**STOP.** Present the full synthesis above to the user. Do not apply, implement, or modify any project files based on these findings. Wait for the user to explicitly select which action items to pursue.

Update state file and mark Synthesis task as completed.

## Output Files

Create a `moe-reviews/` subdirectory inside `<project-data>/branches/<branch>/` (resolved via `~/.claude/project-data-map.json`). All MOE output goes in this subdirectory to keep review artifacts separate from branch work.

- `moe-reviews/moe-state.json`: State file (source of truth)
- `moe-reviews/moe_section_<N>_content.md`: Section content + context notes
- `moe-reviews/moe_section_<N>_review_transcript.md`: Full multi-phase transcript with consensus findings

## Self-Validation

After writing the transcript file, run the transcript validator:

```
${CLAUDE_PLUGIN_ROOT}/tests/validate-moe-transcript.sh <path-to-transcript.md>
```

If any checks fail, fix the transcript file to address the failures before presenting the synthesis. Common fixes:
- Missing `Dr. Dara Mitchell ->` exchanges: reformat to interleaved iMessage chat style
- Bare "Carl" references: replace with "ChaoticCarl"
- Missing synthesis sections: add the missing section headers and content
- Missing blockquotes: wrap persona and moderator messages in `>` blocks

Re-run the validator after fixes to confirm all checks pass.

## Quality Assessment

After self-validation passes, spawn a background Task agent to assess the review quality:

```
Read the transcript at [PATH]. Score the review on these dimensions (1-10):

1. Phase discipline: Did each phase follow its rules? Were caps respected?
2. Moderator rigor: Did the moderator validate claims or just accept them?
3. Persona fidelity: Did each agent stay in character?
4. Huddle productivity: Did agents challenge each other? Did the best ideas surface?
5. Consensus quality: Were disagreements named explicitly? Was "no consensus" documented when warranted?
6. Live chatter format: Was the iMessage interleaving correct throughout?

For each dimension, cite specific transcript excerpts showing where things went well or off-track.

Write a remediation plan to [OUTPUT_DIR]/moe-reviews/remediation-plan.md with specific, actionable changes for improving the next run.
```

The remediation plan is available for the next review. Before starting any new MOE run, check for a previous `remediation-plan.md` in the same project and incorporate its recommendations.

**STOP.** Present the full synthesis to the user. Do not apply, implement, or modify any project files based on these findings. Wait for the user to explicitly select which action items to pursue.
