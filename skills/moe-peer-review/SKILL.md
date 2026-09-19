---
name: moe-peer-review
description: Orchestrate a Mixture of Experts (MOE) peer review with 9 personas (8 reviewers + 1 moderator). Use when user says "peer review", "MOE review", "mixture of experts", "run the personas", "expert panel review", "review this from multiple perspectives", "get the team's feedback", "what would the panel think", "run the experts on this", or wants multi-perspective feedback on content, designs, technical documentation, or implementation plans.
---

# Review-Only Guardrail

This process is strictly advisory. The MOE review produces suggestions, not changes. NEVER apply any recommendation, fix, or modification to project files based on review findings. All output stays in the conversation thread and the review transcript files. After the synthesis is complete, present the full aggregated feedback to the user and wait for explicit instructions on which items (if any) to act on.

# Roles

Three roles, and the session reading this file holds only the first.

**The observer** is the main conversation. It launches the moderator, prints every phase block the
moderator sends it, verbatim and in order, and after the moderator hands back it runs the validator
and spawns the quality-assessment agent. It makes no review decisions. It does not verify claims,
seed threads, nudge panelists or call time. If the user asks the observer a question mid-review, the
observer answers from what it has been sent; it does not reach into the review.

**The moderator** is Dr. Nina Simone-Bennett, a spawned agent defined at
`${CLAUDE_PLUGIN_ROOT}/agents/moe-moderator.md`. She spawns the eight personas, drives every phase,
verifies in Phase 3, runs the Huddle, assembles the transcript and state file, and sends each phase
to the observer as it completes. Everything below that says "the moderator" is addressed to her.

**The panelists** are the eight personas in the roster.

## Launch

The observer spawns the moderator with the `moe-moderator` subagent type and this brief:

```
You are Dr. Nina Simone-Bennett. Run a full MOE peer review of: <target, e.g. branch name or path>
Repository: <absolute path>
Output directory: <resolved project-data path>/moe-reviews/
Skill file: ${CLAUDE_PLUGIN_ROOT}/skills/moe-peer-review/SKILL.md - read it in full before doing
anything, then follow it phase by phase.

Send each phase's thread to `main` with SendMessage as soon as that phase closes, verbatim, in the
Live Thread format. Send the Synthesis the same way, then hand back with the transcript path.
```

The observer then waits. It does not poll. Phase blocks arrive as messages; the observer prints each
one as received, adding nothing. The moderator's hand-back carries the transcript path; the observer
runs Self-Validation and Quality Assessment from that path.

# Agent Roster

| Persona | subagent_type | Model | Color |
|---------|---------------|-------|-------|
| Beyonce Carter (Sr. Engineer) | `beyonce` | opus | purple |
| Jill Scott-Williams (Jr. Developer) | `jill-scott` | haiku | green |
| Janelle Monae Robinson (DevOps Engineer) | `janelle-monae` | sonnet | blue |
| SZA (Security Engineer) | `sza` | sonnet | red |
| Erykah Badu-Johnson (Platform Generalist) | `erykah-badu` | opus | orange |
| Doechii (PCI/HIPAA Compliance) | `doechii` | sonnet | yellow |
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

## Tool Scope

**Persona agents are read-only and must not modify anything.** They may use Read, Glob, Grep, and
Bash. Bash is restricted to read-only inspection: `git log`, `git diff`, `git show`, `grep`, `rg`,
`find`, `cat`, `wc`, `ls`. A persona must never run a command that writes to the repository,
installs anything, or mutates git state.

**Personas also have `SendMessage`, used only in Phase 4.** It is how they talk to each other
directly without the moderator relaying. They have no `ListAgents`, so they cannot discover each
other; the moderator supplies the peer roster when the Huddle opens. A persona must not message anyone
outside the panel, and must not use `SendMessage` in any phase other than the Huddle.

**The moderator may execute code, and is expected to.** Verification by experiment outranks
verification by reading, and outranks argument entirely. The moderator has Bash for four purposes:

1. Gathering the material under review (`git diff`, `git show`). See Step 1.1.
2. Establishing fact against the repository's history (`git log -S`, `git log --all`, `git blame`).
3. Reading dependency source that the packet does not contain. The evidence that settles a claim
   about a library's behavior is in `node_modules`, not in the diff, and a review that never leaves
   the diff will accept a wrong claim about what a dependency does.
4. **Writing and running throwaway probes to falsify a claim.** When an agent asserts a runtime
   behavior, do not argue about it and do not answer from recollection. Write the smallest program
   that would settle it, run it, and report the raw output verbatim including timings and exit
   signals. Put probe files in a scratch directory, never in the repository under review.

A probe that refutes the moderator's own position is the most valuable output this process produces.
Record it as a refutation in the thread, not as a footnote.

Bash is never used to modify the material under review. The Review-Only Guardrail above is absolute
and applies to the moderator's Bash access exactly as it applies to Edit and Write.

## Live Thread Output

The user watches the review as a group chat. The moderator produces it; the observer displays it.
Wherever this file says "print", the moderator sends that block to `main` with `SendMessage`, and
the observer prints it verbatim on arrival. The thread should read like an iMessage group thread:
persona speaks, moderator responds, next persona speaks, moderator responds.

After all agents return from a phase, send the exchange interleaved per persona. Format:

```
## Phase Name

**Beyonce Carter** (Sr. Engineer):
> [Their full response, blockquoted]

**Dr. Nina Simone-Bennett** -> Beyonce Carter:
> [Moderator's answer/response, blockquoted]

**Jill Scott-Williams** (Jr. Developer):
> [Their full response, blockquoted]

**Dr. Nina Simone-Bennett** -> Jill Scott-Williams:
> [Moderator's answer/response, blockquoted]
```

During The Huddle, format agent-to-agent exchanges:

```
**Beyonce Carter** -> **SZA**:
> [Question or challenge, blockquoted]

**SZA** -> **Beyonce Carter**:
> [Response, blockquoted]
```

The thread must read top-to-bottom like a live conversation, not batched questions followed by batched answers.

**Live thread versus transcript file.** The live thread prints each persona's full response verbatim so
the user can watch the review unfold. The transcript file may condense a long response, subject to three
rules:
1. First person is preserved. Condensing never converts a persona's words into a third-person report.
2. Every finding keeps its severity label, its file:line citation, and its exact quoted claim.
3. A condensed turn is marked at its end with `[condensed]` so a reader knows the live thread carried more.

Never condense the moderator's verification responses; the specific evidence is the whole point of the record.

**Format rules the validator enforces (follow them in every phase, including Synthesis):**
- Use the ASCII arrow `->` (hyphen then greater-than) in every speaker label, and in every
  `complaint -> root cause -> fix` chain in Synthesis. The validator matches ASCII only, so a Unicode
  arrow `→` in either place fails the check. Inside quoted persona content a Unicode arrow is harmless
  (for example `54→51 fields`), but prefer ASCII everywhere for consistency.
- Every phase uses this same first-person, blockquoted chat-bubble format. This includes Phase 2 (Clarifying Questions): quote each persona's questions in first person under their own `**Name**:` header and the moderator's answer under `**Dr. Nina Simone-Bennett** -> Name:`.
- Do NOT narrate a persona in third person in any phase. Everything inside a persona's blockquote is that
  persona speaking, in their own voice, in first person. All of these are violations:
  - "Beyonce asked about X" (third-person report)
  - "wants to know which SHA the diff came from" / "hasn't verified whether one exists" (third-person
    verbs with the subject dropped)
  - "Demanded concrete answers to 5 questions:" (summarizing the turn instead of quoting it)
  - "[Caught the stale packet before reviewing the working tree.]" (bracketed stage direction)
  - "confirms Beyonce's finding independently" (third-person attribution)

  Write each of those as the persona would say it: "I want to know which SHA the diff came from", "I have
  not verified whether one exists", "I need five things answered in plain language:", "I checked the
  packet against the working tree first and it did not match", "I reached Beyonce's finding
  independently."

  Stage directions and editorial context belong OUTSIDE the blockquote, in the moderator's own voice,
  under a `**Dr. Nina Simone-Bennett** -> Name:` header.
- Agent-to-agent Huddle exchanges use `**Name** -> **Name**:` with each name in its own bold and the colon outside the bold.
- Agent-to-moderator messages (the normal shape in Phase 3) use `**Name** -> **Dr. Nina
  Simone-Bennett**:` with both names bolded, exactly like an agent-to-agent label. Every name
  adjacent to an arrow is bolded, in every phase, on both sides of the arrow. The one exception is
  the moderator's Phase 1 and Phase 2 acknowledgement header, `**Dr. Nina Simone-Bennett** -> Name:`,
  which is prescribed above.

# State Management

## State File

The moderator maintains a `moe-state.json` file in the review output directory. This is the source of truth for review progress and survives context compaction. The observer may read it to answer a status question; the observer never writes it.

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
    "sza": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "erykah-badu": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "doechii": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "whitney-houston": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 },
    "chaotic-carl": { "agent_id": "xxx", "status": "active|done|satisfied", "exchanges": 0 }
  },
  "phases": {
    "kick-off": { "status": "pending|in_progress|completed", "task_id": "" },
    "clarifying-questions": { "status": "pending|in_progress|completed", "task_id": "" },
    "interactive-session": { "status": "pending|in_progress|completed|skipped", "task_id": "" },
    "the-huddle": { "status": "pending|in_progress|completed", "task_id": "" },
    "synthesis": { "status": "pending|in_progress|completed", "task_id": "" }
  },
  "huddle_exchanges": {},
  "output_dir": ""
}
```

## Todo List

If TaskCreate is available to the moderator, create a task list at the start of every review and update both the state file AND the task list atomically on every state change. If it is not available, say so once in the first phase block sent to the observer and rely on the state file alone.

Tasks to create:

1. **Kick-Off** (activeForm: "Presenting material to the panel")
2. **Clarifying Questions** (activeForm: "Panel asking clarifying questions", blockedBy: [1])
3. **Interactive Session** (activeForm: "Agents challenging and debating", blockedBy: [2])
4. **The Huddle** (activeForm: "Agents debating each other", blockedBy: [3])
5. **Synthesis** (activeForm: "Aggregating review findings", blockedBy: [4])

Store agent IDs in task metadata so they survive compaction:
```
TaskUpdate(taskId: "1", metadata: {"beyonce_id": "abc", "jill-scott_id": "def", ...})
```

## Recovery After Compaction

If the moderator's context was compacted, her first action is:
1. Read `moe-state.json` from the output directory
2. Call TaskList if available and reconcile it with the state file
3. Resume from the current phase using the persona agent IDs in the state file

If the observer's context was compacted, its first action is to read `moe-state.json` for the
moderator's agent ID and send her one message asking which phase she is in. The observer does not
restart the review.

# Workflow

Read-only review. Persona agents can read project files but never modify them. Output files are the only writes.

## Phase 1: Kick-Off

The moderator presents the material to the panel. No full conversation context is shared, just the content and background.

### Step 1.1: Prepare Content

Read the content to review. Required inputs:
- The content section (mockup, config, design, code, plan, or description)
- Context notes explaining purpose and background
- Source material for answering questions (docs, research notes)

**Source-of-truth rule for code reviews.** When the content is a code change, build the packet from the
LOCAL working state, never from the remote's view of it:

- Use `git diff <base>...HEAD` (three dots). That is the true branch state.
- Do NOT use `gh pr diff <N>`, `gh api` diffs, or a GitHub web diff. Those reflect only commits already
  pushed. A branch under active local development routinely has unpushed commits, and the context notes
  will describe those commits as landed while the packet does not contain them. Every persona then
  reviews code that does not exist, and the review has to be rewound.
- Confirm the working state before building the packet. `git status --porcelain` must be empty, or every
  uncommitted file must be named in the provenance header below. If `git log --oneline @{u}..HEAD` prints
  anything, the branch has unpushed commits and the header must say so.

**Required provenance header.** The first section of `moe_section_<N>_content.md` must be:

    ## Packet provenance
    - Command: <exact command used to generate the diff>
    - HEAD SHA: <sha>
    - Base: <base ref and sha>
    - Unpushed commits at packet time: <count, or "none">
    - Working tree: <clean | list of dirty paths>
    - Generated: <YYYY-MM-DD HH:MM local>

Do not spawn Kick-Off agents until this header exists and its "Unpushed commits" line is either "none" or
explicitly acknowledged in the context notes.

The moderator generates the diff and verifies sync directly (see "Tool Scope"), and is responsible
for the provenance header. If someone else prepared the packet, the moderator re-runs the three
commands above and REFUSES to start Kick-Off until the header exists and matches what those commands
print.

### Step 1.2: Present to Panel

The moderator spawns the 8 persona agents in parallel with the Agent tool, using the subagent_type from the roster, and records every agent ID in `moe-state.json` immediately.

For the 6 static personas:

```
Here is the content to review:
[CONTENT]

Context: [CONTEXT_NOTES]

Phase 1 (Kick-Off), Step 0 (do this BEFORE any findings): the packet above may be stale. Pick 3 specific claims the context notes make about the current state (a named function, a named constant, a described fix) and verify each one against the actual repository with Read or Grep. If the packet and the repository disagree, report it as PROCESS FLAG at the very top of your response, name the exact mismatch, and review the REPOSITORY, not the packet. Do not assume you have misread the packet; the packet is the thing most likely to be wrong.

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

ChaoticCarl has no repository access in his prompt and cannot perform Step 0. If any panelist raises a
PROCESS FLAG, the moderator must regenerate the content packet per Step 1.1 before Phase 2, and state in
the thread whether Kick-Off responses are being kept or discarded, and why.

After all 8 agents return, record agent IDs in the state file and task metadata. Print `## Phase 1: Kick-Off` then for each persona, print their initial reactions. The moderator acknowledges each perspective but does not answer questions yet. Just confirms receipt: "Noted, [Name]. We'll address that." Use the persona's full name; never shorten ChaoticCarl to "Carl".

Update state file and mark Kick-Off task as completed.

Before printing the next phase header, re-read `moe-state.json` and confirm all four of these, correcting
any that are wrong:
1. `current_phase` names the phase you are about to start.
2. No earlier phase is still `pending` or `in_progress`.
3. Every agent's `status` and `exchanges` reflect the phase just finished.
4. After The Huddle, `huddle_exchanges` is non-empty.


## Phase 2: Clarifying Questions

Agents ask the moderator focused questions. The moderator answers using source material, code verification, and technical knowledge.

Resume each of the 8 persona agents:

```
The moderator has received all initial impressions from the panel. Now ask your clarifying questions.

Phase 2 (Clarifying Questions): Ask 5-7 specific questions from your professional perspective that you need answered to form your assessment. Be precise. Reference exact details from the content.
```

For ChaoticCarl, translate the prompt to non-technical language.

After all 8 agents return, formulate answers using context notes, source docs, and technical knowledge. Validate factual claims by reading code and checking docs. Admit "not documented" or "untested" where gaps exist. For ChaoticCarl's complaints, translate them into the technical root cause but preserve his original wording.

Print `## Phase 2: Clarifying Questions` then for each persona, print their questions and the moderator's response as an interleaved chat exchange.

A persona's questions may be condensed in the transcript file under the three condensing rules
above. **The moderator's answers may not.** Every answer keeps its verification opener, its
file:line citations, and its verdict, in full, in every phase. If a phase header in the transcript
says "questions and answers condensed", that phase is in violation: rewrite the header and restore
the answers. The evidence in the moderator's answers is the record; the questions are only the
prompt for it.

Update state file and mark Clarifying Questions task as completed.

Before printing the next phase header, re-read `moe-state.json` and confirm all four of these, correcting
any that are wrong:
1. `current_phase` names the phase you are about to start.
2. No earlier phase is still `pending` or `in_progress`.
3. Every agent's `status` and `exchanges` reflect the phase just finished.
4. After The Huddle, `huddle_exchanges` is non-empty.


## Phase 3: Interactive Session

This is the maximum-adversarial fact-checking round: **moderator versus agent.** The moderator's default posture is disbelief. The moderator believes nothing an agent asserts until the agent proves it, or until the moderator independently verifies it against source material and code. The burden of proof is on the agent. The moderator's job here is not to collect opinions but to try to falsify every claim: assume each finding is wrong and hunt for the evidence that would disprove it. A claim survives only when it withstands that attempt. (Agent-versus-agent debate happens later, in Phase 4: The Huddle.)

Agents challenge the moderator, make suggestions, and push back. The moderator does not simply accept any assertion; every claim is verified or refuted against source material and code.

**What counts as an exchange**: one exchange is one resume of an agent plus that agent's reply. A
prompt that bundles five questions is one exchange, not five. Phase 1 and Phase 2 resumes are not
counted here; this line counts Phase 3 only.

**Exchange cap**: 3 exchanges per agent for this round. One is the baseline. Spend a second or a
third only on an agent whose claim you are actively trying to falsify and who answered your last
probe with new evidence. Do not resume an agent that has stopped producing new evidence; that is
what the cap is for.

**Satisfaction**: Every agent's stance is printed individually, in the agent's own blockquoted
voice, at the end of its Phase 3 message. There are exactly two permitted forms and the literal
strings matter, because they are what the transcript validator counts:

```
> I am satisfied.
```

or

```
> Open items:
> 1. [Blocker] ...
> 2. [Warning] ...
```

**An aggregate sentence does not satisfy this rule.** "Zero agents satisfied; all eight carry open
items" tells Synthesis nothing about which items belong to whom, and it means the open-item lists
that the Huddle seeding and the Verdict Scoreboard are built from were never written down. Eight
stances, eight blocks, no summaries.

Open items (blockers, conditions, unresolved concerns) are carried forward to The Huddle and
Synthesis; the moderator does not resume agents for additional interactive rounds.

**Exchange count tracking**: After the round, print one line naming the unit, and the count must
equal the number of `**Persona** -> **Dr. Nina Simone-Bennett**:` blocks that persona has in Phase 3:

```
Exchange counts this round (one exchange = one resume plus reply; cap 3): Beyonce Carter: 2,
Whitney Houston-Davis: 2, all others: 1.
```

Write the same numbers into `moe-state.json`'s `exchanges` field in the same edit. If the state file
and the printed blocks disagree, the printed blocks are right. If any agent reaches the cap with open
threads still moving, say so explicitly: "[Agent] hit the 3-exchange cap with [thread] unresolved;
carried to the Huddle unresolved." That sentence is the only reason this accounting exists.

Resume all 8 agents:

```
Here are answers to your previous questions:
[ANSWERS]

Phase 3 (Interactive Session): Based on these answers:
1. Challenge any answers that don't fully address your concerns
2. Provide specific recommendations (what to add, change, or call out)
3. Push back on any claims you believe are incorrect or insufficiently supported
4. State any standards or requirements you'd want documented

Be concrete. If you recommend something, specify exactly what. If you disagree with the moderator's response, say so directly and explain why.

State your final stance explicitly: either "I am satisfied" (zero open items) or a list of your remaining open items.
```

**Moderator behavior during the Interactive Session:**
- Validate every factual claim before accepting it. Read the code. Check the docs.
- Every factual claim from an agent MUST receive one of exactly four responses:
  - "I verified this: [specific evidence from source material, with file:line or document section]."
  - "I cannot verify this: [what was checked and why it was inconclusive]."
  - "This is incorrect: [specific evidence contradicting the claim]."
  - "I tested this: [the command or probe you ran, then its raw output verbatim, including timings,
    exit codes, and signals]." Use this whenever a claim is about runtime behavior rather than about
    what the source says. Prefer it over the other three: an experiment settles what a reading can
    only suggest. If a claim is testable in under ten minutes, test it rather than answering "I
    cannot verify this."
- These four openers are literal strings, not paraphrases. Begin the sentence with them so a reader
  can count them and so the 30% threshold below is computable. "Verified." and "cannot verify" carry
  the same meaning to a human and make the check impossible.
- One claim, one opener, one line. Do not fold four verifications into one paragraph; a reader
  cannot tell which evidence attaches to which claim, and neither can you when you write the
  Synthesis.
- "I tested this:" is reserved for a command you ran and whose output you paste. Reading a file,
  including a file in `node_modules`, is "I verified this:". If you cannot show the output, you did
  not test it.
- Never answer a testable question from recollection. Declining to answer and then running the probe
  is strictly better than a confident recollection, and saying so out loud is part of the standard:
  "I am declining to answer from recollection. I will run it."
- NEVER use bulk acceptance ("All requirements accepted," "Validated," "Accepted") without per-item evidence. Each claim gets its own verification.
- If more than 30% of responses lack one of the four templates above, pause and re-verify before continuing.
- If you rejected a claim, the rejection is written with the "This is incorrect:" opener, including
  when the claim you are rejecting is your own. A rejection recorded as prose is a rejection a reader
  cannot count.
- **Adversarially re-test every Blocker-severity finding before accepting it.** For each claim you would carry to Synthesis as a Blocker, do not stop at confirming the structural fact; try to disprove that the fact actually causes the claimed harm (check the surrounding call path, guards, and any compensating step). A Blocker that was only structurally confirmed, never attacked, is not verified.

  Record every re-test in a table printed at the end of Phase 3, before the self-check. Every Blocker that
  appears in the Synthesis Verdict Scoreboard must have a row here. A Blocker with no row is not eligible
  for Synthesis:

  **Blocker Re-Test Ledger**

  | Blocker | Raised by | Attack attempted (what would disprove it) | Outcome |
  |---|---|---|---|
  | ... | ... | ... | Survived / Downgraded to Warning / Refuted |
- Seek consensus but accept "no consensus" as a valid outcome. When two agents take opposing positions on the same issue and neither concedes, label it explicitly: "No consensus between [Agent A] and [Agent B] on [topic]. Both positions carried to synthesis."
- Name disagreements explicitly: "[Agent A] and [Agent B] disagree on X."
- **Consensus is a required output, not a conditional one.** At the end of Phase 3 AND at the end of The
  Huddle, print a `Consensus Ledger` block. If there were no unresolved disagreements, print
  `Consensus Ledger: no unresolved disagreements this round.` Never print nothing.

  Consensus Ledger
  - Converged: [topic] -- [Agent A] and [Agent B] reached the same position. Final position: [...]
  - Resolved: [topic] -- [Agent A] conceded [specific point] to [Agent B]. Not conceded: [...]
  - No consensus: [topic] -- [Agent A] holds [position]; [Agent B] holds [position]. Neither conceded.
    Both carried to Synthesis.

**Moderator self-check before The Huddle:** Before proceeding to The Huddle, the moderator must answer: "Did I reject any claim from any agent in this review? If not, why not?" Print this self-assessment in the thread under the exact header `**Self-check before The Huddle**:` so it is machine-checkable. If zero claims were rejected, explicitly state why and whether that indicates insufficient rigor.

**Persona voice reminders**: When resuming agents for the Interactive Session, append the REQUIRED voice
reminder below to that agent's prompt, verbatim. This is not optional and it is not a sample list; every
one of the eight personas gets its line. A response that does not carry its persona's voice marker should
be sent back once with the reminder repeated.

- Beyonce Carter: "Lead with the single most important thing, then rank the rest. Name the blast radius of at least one finding."
- Jill Scott-Williams: "Start from genuine confusion before arriving at insight. Use 'maybe this is a dumb question but...' framing at least once."
- Janelle Monae Robinson: "Deploy your dry humor at least once. Reference a 3 AM failure scenario."
- SZA: "Frame at least one finding as an attack narrative: 'An attacker with access to X could exploit Y to achieve Z.'"
- Erykah Badu-Johnson: "Use 'Have we considered how this affects...' openers. Include at least one art/music metaphor."
- Doechii: "Cite the specific regulation and subsection for every compliance finding. State Blocker vs. documentation gap explicitly for each."
- Whitney Houston-Davis: "Ground at least one finding in a named principle from your assigned specialty, and say which principle."
- ChaoticCarl: "Stay in plain language. Use zero technical terms. Say what you tried and what happened, not what the code does."

Print `## Phase 3: Interactive Session`. This phase produces exactly 2N blocks for N personas: one
`**Persona Name** -> **Dr. Nina Simone-Bennett**:` block and one `**Dr. Nina Simone-Bennett** -> Persona Name:`
block, in that order, for EVERY persona. Eight personas means sixteen blocks. There are no exceptions: a
persona who states "I am satisfied" still gets a moderator response naming which claims were verified and
which were not. ChaoticCarl is a persona and is included; his prompt is translated to plain language, but
he is never skipped.

Before printing the phase, count your moderator blocks. If that count does not equal the number of
personas, you have skipped someone. Go back and answer them. This is the maximum-adversarial round; an
unanswered claim is an unverified claim, and an unverified claim must not reach Synthesis.

End the phase with, on its own line:
`Exchange counts this round: [Persona]: [count], [Persona]: [count], ...` listing all 8 personas.

Update state file and mark the Interactive Session task as completed.

Before printing the next phase header, re-read `moe-state.json` and confirm all four of these, correcting
any that are wrong:
1. `current_phase` names the phase you are about to start.
2. No earlier phase is still `pending` or `in_progress`.
3. Every agent's `status` and `exchanges` reflect the phase just finished.
4. After The Huddle, `huddle_exchanges` is non-empty.


## Phase 4: The Huddle

This is the **agent-versus-agent** round, run as grand rounds. Every finding from every panelist
goes on the board. Every panelist reads the whole board and chooses which findings to answer, and
whom to answer. Where Phase 3 tested each claim against evidence, the Huddle tests each claim
against the other experts' judgment.

**The moderator has two jobs here and only two: make sure everyone participates, and make sure it
ends.** The moderator does not choose who talks to whom, does not name the tensions, does not
paraphrase one panelist's position to another, and does not brief either side of a disagreement.
The moderator is not in the message path. Personas write to each other directly with
`SendMessage`.

**Verification does not happen here.** Phase 3 is where claims are falsified against evidence. If
the moderator finds themselves checking a number mid-Huddle, that is Phase 3 work arriving late.
Note it for the next run and let the Huddle proceed.

### The board

Before the Huddle opens, the moderator compiles the Findings Board: every panelist's Phase 3 final
stance, verbatim, in one document. All eight, in roster order, each under its own persona name.
Open items are copied exactly as the panelist wrote them, with their severity labels and citations.
The moderator adds nothing: no summary, no grouping, no "note that X and Y disagree." If two
panelists filed opposite fixes for the same defect, the board shows both and the panelists find it
themselves. That is the point.

### Opening

Send every panelist the same message, containing in this order:

1. The Findings Board, complete.
2. The peer roster, all eight names mapped to agent IDs. Personas have no `ListAgents` and cannot
   discover each other; the roster is the only way they can address anyone.
3. The rules block below, verbatim.

ChaoticCarl receives the same board and the same roster. His copy of the rules block is in plain
language and says so. He is not steered toward particular experts; he reads the board and picks.

Use this block verbatim in every opening message:

```
GRAND ROUNDS. Every panelist's findings are on the board above. Read all of it. Then choose:
which findings do you disagree with, which can you refute, which can you strengthen, and which
ask a question only you can answer. Write directly to the author of each one you choose. You pick
whom to engage. Nobody is assigning you a counterpart.

To send a message, call SendMessage with `to` set to the agent ID from the roster, a short
`summary`, and your message in `message`. Write in first person, in your own voice, addressed to
that person by their full name. Your message is delivered to them verbatim. The moderator does
not see it.

RULES:
- Send at least 1 message. You may send at most 4. A reply to someone who wrote to you does not
  count against your 4 and is mandatory unless they declared they were done.
- Address people by their full name from the roster. Never abbreviate. "ChaoticCarl" is one word
  and is never shortened, including when you are speaking to him directly.
- When you have nothing further for a counterpart, your final message to them ends with exactly
  this line: I have nothing more to add.

LOGGING, required. Keep a verbatim record of every message you send and every message you receive.
When the moderator asks for your Huddle log, return it in this format and nothing else,
chronologically:

SENT -> <Full Name>: <verbatim text>
RECEIVED <- <Full Name>: <verbatim text>

Do not summarize, paraphrase, shorten or tidy anything. The transcript is reconstructed from
these logs and cross-checked against your counterparts' logs. An omission shows up as a mismatch.
```

### While it runs

The moderator waits. Do not poll in a loop. Completion notifications arrive on their own. The
moderator sends no message about content to anyone during this time.

**Participation check.** When every panelist has gone idle, the moderator counts who has sent at
least one message. "Participated" means sent at least one message to another panelist. Being
written to and never answering is not participation.

Anyone at zero gets exactly one nudge, and the nudge carries no content:

```
You have not sent a message this round. Every finding on the board is open to you. Choose one
whose author you disagree with, or whose author asked something you can answer, and write to them.
```

The nudge does not name a finding, a counterpart, or a topic. If a panelist ignores the nudge, that
is recorded as a gap with the reason "declined after nudge" and the moderator does not nudge twice.

**ChaoticCarl.** He is the only panelist who can show whether a Blocker survives contact with the
person who runs the tool, and he is the panelist most likely to be ignored. The participation check
therefore also asks: did anyone answer him? If ChaoticCarl sent a message and its addressee has not
replied, that addressee gets the reply-obligation reminder before anything else the moderator does.

### The clock

A round ends when every panelist has gone idle. The Huddle runs **at most two rounds**.

After round one, the moderator collects every log, cross-checks them, and decides:

- If every message has been answered or closed with a declaration, the Huddle is over. Do not open
  round two to see if anything else happens.
- If messages are unanswered, or a thread is mid-exchange, open round two by sending every panelist
  the round-one transcript, reconstructed verbatim from the logs, with the same rules block. This is
  how every panelist hears what every other panelist said. They may respond to anything in it. Same
  caps, same reply obligation, same logging.

After round two the moderator calls time regardless of what is still moving. Anything unresolved is
carried to Synthesis as unresolved, in the Consensus Ledger, with both positions stated. That is a
valid outcome, and it is a better outcome than a third round.

### Closing

**Collect the logs.** Ask every panelist for its Huddle log in the format above. The transcript is
assembled from these logs, not from memory and not from the moderator's notes.

**Cross-check before printing.** For every `SENT -> B` in A's log there must be a `RECEIVED <- A`
in B's log with the same text, and the reverse. A mismatch means a message was lost, a log was
summarized, or an exchange was invented. Each mismatch is stated in the participation checklist
with both sides quoted. Never reconcile one quietly.

**Every message gets an answer, in both directions.** Every printed `**A** -> **B**:` block is
followed by a `**B** -> **A**:` block, or by the sender's own closing declaration, or by a
moderator line stating that time was called with the thread open. A message with none of those is
a dropped message and is listed as one. A message to ChaoticCarl that went unanswered, and a
message from ChaoticCarl that went unanswered, are both named as the failure this phase exists to
prevent.

**Participation checklist**, built by counting the printed blocks, not from memory or intent. The
number is messages SENT. Name each counterpart and count separately:

```
Huddle Participation:
- Erykah Badu-Johnson: 3 sent (Whitney Houston-Davis x2, Jill Scott-Williams x1); closed with declaration
- SZA: 0 sent; declined after nudge [GAP]
```

Any panelist at zero after the nudge is a `[GAP]` with the reason written. "No gaps" is a claim
about the text above it; do not write it without counting. If the state file and the transcript
disagree, the transcript is authoritative. Correct the state file, never the transcript.

Print `## Phase 4: The Huddle`, then every exchange in chronological order in the agent-to-agent
format, then the cross-check results, then the participation checklist.

Update state file and mark The Huddle task as completed.

Before printing the next phase header, re-read `moe-state.json` and confirm all four of these,
correcting any that are wrong:
1. `current_phase` names the phase you are about to start.
2. No earlier phase is still `pending` or `in_progress`.
3. Every agent's `status` and `exchanges` reflect the phase just finished.
4. After The Huddle, `huddle_exchanges` is non-empty.

## Phase 5: Synthesis

After all agents declare done or hit limits, the moderator launches the final aggregation.

Print `## Synthesis` and compile across all 8 personas. ALL sections below are REQUIRED. If a section has no items, include the header with "None identified." Do not skip any section.

**Verdict Scoreboard**

| Persona | Ready? | Blockers | Warnings | Suggestions |
|---------|--------|----------|----------|-------------|
| Beyonce Carter | Yes/No | count | count | count |
| Jill Scott-Williams | Yes/No | count | count | count |
| Janelle Monae Robinson | Yes/No | count | count | count |
| SZA | Yes/No | count | count | count |
| Erykah Badu-Johnson | Yes/No | count | count | count |
| Doechii | Yes/No | count | count | count |
| Whitney Houston-Davis | Yes/No | count | count | count |
| ChaoticCarl | Yes/No | count | count | count |

**Overall**: X/8 personas say ready. Y blockers, Z warnings across all reviewers.

ChaoticCarl does not assign severities himself. The moderator derives his counts from the User Experience
Failures section: a complaint whose root cause is already an accepted Blocker counts as a Blocker for his
row; one that maps to an accepted Warning counts as a Warning; the rest are Suggestions. Never leave his
counts blank or as dashes. His row must total the same way every other row does, or the Overall line
undercounts the end-user impact.

**Production Gates** (blockers identified by 2+ personas):
- Gate with identifying personas

**Compliance Findings** (regulatory issues from Doechii):
- Finding with specific regulation citation and remediation

**Domain Expert Warnings** (research-backed concerns from Whitney Houston-Davis):
- Warning with cited principle and recommended approach

**User Experience Failures** (ChaoticCarl's complaints translated to root causes):
- ChaoticCarl's complaint (verbatim) -> Technical root cause -> Recommended fix

**Mandatory Production Standards** (operational requirements):
- Standard with source persona

**Improvements** (content/framing changes):
- Table: Improvement | Source Persona | Severity

**Unresolved Disagreements** (carried from the Consensus Ledgers; "None identified." if empty)
- [topic]: [Agent A]'s position vs. [Agent B]'s position, both carried forward

**Key Insight** (single most important finding across all reviewers)

**Action Items** (ordered by severity, deduplicated across personas):
1. [Blocker] Action item - source persona(s)
2. [Warning] Action item - source persona(s)
3. [Suggestion] Action item - source persona(s)

**Write this block verbatim as the last section of `moe_section_<N>_review_transcript.md`, and print
it in the thread:**

```
---

**STOP.** This review is advisory. Nothing above has been applied. No project file was modified
during this review. Waiting for the user to select which action items to pursue.
```

The transcript is the artifact someone reads six months from now without the conversation around it.
The guardrail has to be in the file, not only in the chat.

Update state file and mark Synthesis task as completed.

## Output Files

Create a `moe-reviews/` subdirectory inside `<project-data>/branches/<branch>/` (resolved via `~/.claude/project-data-map.json`). All MOE output goes in this subdirectory to keep review artifacts separate from branch work.

- `moe-reviews/moe-state.json`: State file (source of truth)
- `moe-reviews/moe_section_<N>_content.md`: Section content + context notes
- `moe-reviews/moe_section_<N>_review_transcript.md`: Full multi-phase transcript with consensus findings

## Self-Validation

The observer does this, after the moderator hands back with the transcript path. Run the transcript validator and print its full output to the user:

```
${CLAUDE_PLUGIN_ROOT}/tests/validate-moe-transcript.sh <path-to-transcript.md>
```

The validator is a diagnostic signal, NOT a transcript-cleanup step. Do not rewrite, patch, or reformat the transcript to make failing checks pass. The transcript is a faithful record of what the review actually produced; editing it to satisfy the validator would hide the very problem the validator is reporting.

Report the validator output verbatim and interpret it: each failure indicates that either the model's execution or the plugin's guidance needs tuning, because a correctly executed review should already satisfy every check. Name which failures point at model execution (e.g. a persona narrated in third person, a Unicode arrow emitted) versus plugin guidance (e.g. a required section the workflow never instructed the model to produce). Carry those observations into the Quality Assessment remediation plan so the next run improves. The only case for touching the transcript afterward is a genuine transcription slip you are correcting for accuracy, never to game a check.

## Quality Assessment and Plugin Improvement

The observer does this. After running the validator, capture its full output (save it to `[OUTPUT_DIR]/moe-reviews/validator-output.txt`) and spawn a background agent with the Agent tool. Feed it BOTH the transcript AND the validator output. Its job is to score the review and to propose concrete improvements to THIS PLUGIN so the observed problems do not recur.

```
Read the MOE transcript at [PATH] and the validator output at [VALIDATOR_OUTPUT_PATH].

Part 1 - Score the review (1-10 each), citing specific transcript excerpts:
1. Phase discipline: Did each phase follow its rules? Were caps respected?
2. Moderator rigor: Did the moderator disbelieve-until-proven, adversarially falsify claims, and reject/correct any? Or rubber-stamp?
3. Persona fidelity: Did each agent stay in character and in its domain lens?
4. Huddle productivity: Did agents challenge each other? Did the best ideas surface?
5. Consensus quality: Were disagreements named explicitly? Was "no consensus" documented when warranted?
6. Live chatter format: Was the first-person interleaving correct throughout, ASCII arrows only?

Part 2 - Plugin improvement (this is the priority output). For EACH validator failure and each quality dimension that scored below 8, determine the root cause and classify it:
- MODEL EXECUTION: the plugin's guidance was adequate but the model did not follow it. Propose a sharper, harder-to-miss instruction that would have forced compliance.
- PLUGIN GUIDANCE: the plugin never told the model to do the thing, or told it ambiguously. Propose the specific fix.

Then write concrete, ready-to-apply plugin edits to [OUTPUT_DIR]/moe-reviews/plugin-improvements.md. Each suggestion must name the exact plugin file (SKILL.md, agents/*.md, or tests/validate-moe-transcript.sh), quote the current text if it exists, and give the proposed replacement. These are SUGGESTIONS for the maintainer to review, not changes to apply automatically.
```

Present the plugin-improvements suggestions to the user when the agent completes. Applying them is the user's decision. Before starting any new MOE run, check for a previous `plugin-improvements.md` and surface its recommendations so the maintainer can decide whether to fold them into the plugin first.

**STOP.** Present the full synthesis to the user. Do not apply, implement, or modify any project files based on these findings. Wait for the user to explicitly select which action items to pursue.
