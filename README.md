# moe-peer-review

A **Mixture of Experts (MOE)** peer-review plugin for [Claude Code](https://claude.ai/code). It runs a multi-phase, structured deliberation over your content using **9 specialized personas** (8 reviewers plus 1 moderator) who ask questions, challenge each other, and debate before producing an aggregated verdict.

The review is **strictly advisory**. It produces suggestions, never changes. All output stays in the conversation and in review-transcript files; nothing in your project is modified.

## What it does

Given content to review (a design, config, mockup, technical doc, code, or plan), the plugin:

1. Presents the material to an 8-persona panel (Kick-Off).
2. Collects clarifying questions and answers them against source material.
3. Runs several rounds of adversarial interactive debate between the panel and the moderator.
4. Runs "The Huddle" — direct agent-to-agent challenges until the strongest ideas surface.
5. Synthesizes a verdict scoreboard, blockers, warnings, and prioritized action items.

Output reads like a live group chat so you can watch the deliberation unfold.

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

Two personas are assigned dynamically before each review: Whitney Houston-Davis is given a PhD specialty matching the content's dominant domain, and ChaoticCarl is given a backstory that places him as a real user of the thing under review.

## Install

Copy this repository into your Claude Code plugins directory:

```bash
git clone https://github.com/bgreg/moe-peer-review.git ~/.claude/plugins/moe-peer-review
```

The plugin provides a skill, 8 persona agents, and hooks that persist review state across context compaction. It loads the next time Claude Code starts.

## Usage

In a Claude Code session, trigger the skill with phrases such as:

- "peer review this"
- "run the MOE review on this design"
- "review this from multiple perspectives"
- "what would the panel think?"

Then provide the content and any context. The panel runs, and the final synthesis is presented for you to act on. No recommendation is applied automatically.

## Output location

Review transcripts and the run's state file are written under the author's
`<project-data>/branches/<branch>/moe-reviews/` convention (resolved via a
personal `~/.claude/project-data-map.json`). If you do not use that convention,
point the output directory at any location you prefer when the review starts.

## License

MIT. See [LICENSE](LICENSE).
