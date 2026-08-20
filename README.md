# moe-peer-review

A **Mixture of Experts (MOE)** peer-review plugin for [Claude Code](https://claude.ai/code). It runs a
multi-phase, structured deliberation over your content using **9 specialized personas** (8 reviewers plus
1 moderator) who ask questions, challenge each other, and debate before producing an aggregated verdict.

The review is **strictly advisory**. It produces suggestions, never changes. All output stays in the
conversation and in review-transcript files; nothing in your project is modified.

```
"peer review this"  ->  9 personas  ->  5 phases  ->  synthesis  ->  STOP
```

## What it does

Given content to review (a design, config, mockup, technical doc, code, or plan), the plugin:

1. Presents the material to an 8-persona panel (Kick-Off).
2. Collects clarifying questions and answers them against source material.
3. Runs one maximum-adversarial round between the panel and the moderator, where her default posture is
   disbelief and every claim is verified, refused, or refuted.
4. Runs "The Huddle" — direct agent-to-agent challenges until the strongest ideas surface.
5. Synthesizes a verdict scoreboard, blockers, warnings, and prioritized action items, then stops.

Output reads like a live group chat so you can watch the deliberation unfold.

## The central idea

A single reviewer has one blind-spot map. Eight reviewers with deliberately incompatible priorities have
almost none, provided something forces them to argue.

Findings are squeezed along two independent axes before they reach you. **Phase 3 tests claims against
evidence**, with the moderator trying to falsify each one against the actual code. **Phase 4 tests claims
against other experts**, with the moderator stepping out entirely. The bet is that these two filters fail
in different ways, so what survives both is unusually likely to be real.

In practice the second filter produces findings no individual persona reached alone. See
[Conversations](docs/conversations.md#phase-4-the-exchange-that-justifies-the-design) for a worked example.

## Documentation

| Page | What it covers |
|---|---|
| [Architecture](docs/architecture.md) | The parts, the execution model, state, guardrails, self-validation |
| [The Panel](docs/personas.md) | All nine personas, their lenses, and the two assigned per run |
| [Workflow](docs/workflow.md) | The five phases in order, with the prompts each one sends |
| [Conversations](docs/conversations.md) | Annotated example exchanges and the interaction map |

A single-page visual version of all four is at [`docs/index.html`](docs/index.html).

## The panel

| Persona | Role | Model |
|---------|------|-------|
| Dr. Nina Simone-Bennett | Moderator / facilitator | (runs in main context) |
| Beyonce Carter | Sr. Engineer | opus |
| Jill Scott-Williams | Jr. Developer | haiku |
| Janelle Monae Robinson | DevOps Engineer | sonnet |
| SZA | Security Engineer | sonnet |
| Erykah Badu-Johnson | Platform Generalist | opus |
| Doechii | PCI/HIPAA Compliance | sonnet |
| Whitney Houston-Davis | Dynamic domain specialist (assigned per review) | opus |
| ChaoticCarl | End user (assigned a backstory per review) | haiku |

Two personas are assigned dynamically before each review: Whitney Houston-Davis is given a PhD specialty
matching the content's dominant domain, and ChaoticCarl is given a backstory that places him as a real
user of the thing under review.

## Review-only, enforced

The guarantee is layered rather than absolute. The eight persona agents are declared without `Write`
or `Edit`, and their `Bash` access is restricted by instruction to read-only inspection. The moderator
can write, but only to the review output directory. Every run ends with a literal `STOP` before any
action is taken.

## Install

The plugin ships its own marketplace manifest, so it installs directly from a clone:

```bash
git clone https://github.com/bgreg/moe-peer-review.git
claude plugin marketplace add ./moe-peer-review
claude plugin install moe-peer-review@moe-peer-review-local
```

Restart Claude Code to load it.

**Updating is version-gated.** `claude plugin update` compares the declared version in
`.claude-plugin/plugin.json` against the installed one and does nothing when they match, printing
"already at the latest version". A change without a version bump never reaches an installed copy.

Do not edit an installed copy under `~/.claude/plugins/`. Edit this repository, bump the version, and
reinstall.

## Usage

In a Claude Code session, trigger the skill with phrases such as:

- "peer review this"
- "run the MOE review on this design"
- "review this from multiple perspectives"
- "what would the panel think?"

Give the panel three things:

1. **The content.** A diff, a design, a plan, a config, a mockup, a description.
2. **Context notes.** What it is for and why it exists.
3. **Source material.** Docs or notes the moderator can answer questions from.

Phase 2 is where a review either becomes grounded or drifts, and it can only be grounded against material
you provided or code the personas can read for themselves.

**For code reviews, build the packet from local state.** Use `git diff <base>...HEAD`, never
`gh pr diff`, which reflects only pushed commits. The workflow requires a provenance header naming the
command, the HEAD SHA, and any unpushed commits, and the moderator refuses to start without it. This rule
exists because a real review was launched against a diff missing two local commits, and seven of eight
panelists caught it by reading the repository directly.

## Output location

Review transcripts and the run's state file are written under the author's
`<project-data>/branches/<branch>/moe-reviews/` convention (resolved via a personal
`~/.claude/project-data-map.json`). If you do not use that convention, point the output directory at any
location you prefer when the review starts.

| File | Purpose |
|---|---|
| `moe-state.json` | Source of truth. Agent IDs, phase status, dynamic assignments. Survives compaction. |
| `moe_section_<N>_content.md` | The reviewed content plus context notes, frozen with its provenance header. |
| `moe_section_<N>_review_transcript.md` | The full multi-phase thread. Never edited to satisfy a check. |
| `validator-output.txt` | Verbatim validator run, preserved as an input to scoring. |
| `plugin-improvements.md` | Proposed edits to this plugin, read at the start of the next run. |

## Repository layout

```
.claude-plugin/     plugin.json and the marketplace manifest
agents/             nine persona cards, one per file
skills/             SKILL.md, the entire workflow
hooks/              SubagentStop and PreCompact hooks
tests/              two shell validators plus acceptance criteria
docs/               documentation
```

## License

MIT. See [LICENSE](LICENSE).
