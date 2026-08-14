# MOE Peer Review

A Claude Code plugin that reviews your work with a panel of nine, then refuses to touch a single file.

Eight reviewer personas and one moderator run a five-phase adversarial deliberation. The personas
disagree by construction: a security engineer who reads everything as an attack surface, a compliance
officer who reads it as an audit exhibit, and a furious non-technical end user who cannot read it at all.
What you get back is a synthesis with named blockers, attributed to the reviewers who raised them.

```
"peer review this"  ->  9 personas  ->  5 phases  ->  synthesis  ->  STOP
```

## Documentation

| Page | What it covers |
|---|---|
| [Architecture](architecture.md) | The parts, the execution model, state, guardrails, self-validation |
| [The Panel](personas.md) | All nine personas, their lenses, and the two assigned per run |
| [Workflow](workflow.md) | The five phases in order, with the prompts each one sends |
| [Conversations](conversations.md) | Annotated example exchanges and the interaction map |

A single-page visual version of all four is at [`index.html`](index.html).

## The central idea

A single reviewer has one blind-spot map. Eight reviewers with deliberately incompatible priorities have
almost none, provided something forces them to argue.

Findings are squeezed along two independent axes before they reach you:

- **Phase 3 tests claims against evidence.** The moderator's default posture is disbelief, and she tries
  to falsify every finding against the actual code.
- **Phase 4 tests claims against other experts.** The moderator steps out and lets the personas attack
  each other's conclusions directly.

The bet is that these two filters fail in different ways, so what survives both is unusually likely to be
real. In practice the second filter produces findings no individual persona reached alone. See
[Conversations](conversations.md#the-exchange-that-justifies-the-design) for a worked example.

## Review-only, enforced

This plugin is strictly advisory. It produces suggestions, never changes.

The guarantee is not a promise in a prompt. The eight persona agents are declared with
`tools: [Read, Grep, Glob]`, so they do not possess a tool capable of writing a file. The moderator can
write, but only to the review output directory. Every run ends with a literal `STOP` before any action is
taken.

## Installing

The plugin is distributed as its own marketplace. From a clone of this repository:

```bash
claude plugin marketplace add /path/to/moe-peer-review
claude plugin install moe-peer-review@moe-peer-review-local
```

Restart Claude Code to load it.

**Updating is version-gated.** `claude plugin update` compares the declared version in
`.claude-plugin/plugin.json` against the installed one and does nothing when they match, printing
"already at the latest version". A change without a version bump never reaches an installed copy.

## Using it

Say any of these, and the skill triggers:

> peer review this · MOE review · mixture of experts · run the personas · expert panel review ·
> review this from multiple perspectives · get the team's feedback · what would the panel think

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

## What a run leaves behind

Everything lands in a `moe-reviews/` subdirectory next to your branch artifacts.

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
docs/               this documentation
```

## License

MIT. See [LICENSE](../LICENSE).
