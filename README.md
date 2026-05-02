# agent-skills

Skills and reviewer subagents for computational-experiment workflows.

**Skills** (`skills/`) are user-invoked via `/skill-name` and run inline in the
main conversation. Each skill orchestrates its own workflow and spawns reviewer
subagents as needed.

**Reviewer agents** (`agents/`) are read-only subagents spawned internally by
skills — they score and propose revisions but never edit the artifact they judge.

## Skills

| Skill | Pairs with | What it does |
| --- | --- | --- |
| [`marimo-figures`](skills/marimo-figures/SKILL.md) | `tufte-reviewer` | Build a figure in a marimo notebook; reviewer scores it against Tufte's principles and returns revisions. |
| [`experiment-report`](skills/experiment-report/SKILL.md) | `writing-reviewer` | Draft an IMRaD report of a run; reviewer checks structure, claim-evidence linkage, and statistical honesty. |
| [`dataset-insights`](skills/dataset-insights/SKILL.md) | `insight-reviewer` | Profile a dataset and produce ranked insights; reviewer scores them for novelty, actionability, and evidence. |
| [`experiment-structure`](skills/experiment-structure/SKILL.md) | — | Canonical folder layout for an experiment (configs, src, scripts, runs, analysis, figures, reports) and rules for keeping it reproducible. |
| [`podman-runner`](skills/podman-runner/SKILL.md) | — | Execute experiment commands inside a reproducible podman container with GPU passthrough, log capture, and run-directory conventions. |
| [`plan-pi-fleshout`](skills/plan-pi-fleshout/SKILL.md) | `plan-reviewer` | PI takes a grad student's fuzzy experimental idea, interrogates every vague term ("users", "improve", "the data") via iterative `AskUserQuestion`, drafts `PLAN.md` with atomic-commit-sized tasks and pseudocode, then loops with `plan-reviewer` until SOLID. |

## Reviewer agents

| Agent | Rubric it enforces |
| --- | --- |
| [`tufte-reviewer`](agents/tufte-reviewer.md) | 8 Tufte dimensions (claim clarity, data-ink ratio, encoding discipline, axis honesty, color, comparison support, annotation economy, reproducibility). |
| [`writing-reviewer`](agents/writing-reviewer.md) | 7 scientific-writing dimensions (claim-evidence linkage, uncertainty, scope honesty, IMRaD discipline, lede quality, reproducibility pointers, prose economy). |
| [`insight-reviewer`](agents/insight-reviewer.md) | 3 insight dimensions (novelty, actionability, evidence) with KEEP / STRENGTHEN / CUT verdicts. |
| [`plan-reviewer`](agents/plan-reviewer.md) | 7 plan-fleshout dimensions (no-assumption discipline, atomic-commit task sizing, testable verifiability, pseudocode coverage, input/output specificity, success-criteria observability, out-of-scope clarity) with BLOCK / CLARIFY / NIT faults and SOLID / NEEDS_REVISION verdict. Runs on Opus. |

Reviewer agents are read-only (`Read, Grep, Glob, Bash`) — they score
and propose revisions but never edit the artifact they judge.

## How the pieces fit together

```
/plan-pi-fleshout         ← Socratic Q&A on every vague term, writes PLAN.md
        │                   └─ plan-reviewer (agent, Opus) ──▶ faults loop until SOLID
        ▼
/experiment-structure     ← lays out the directory
        │
        ├─ /podman-runner        ← runs scripts/ against configs/
        │        │
        │        └─ produces runs/<id>/
        │
        ├─ /dataset-insights     ← reads data/ → writes analysis/<slug>/
        │        └─ insight-reviewer (agent)
        ├─ /marimo-figures       ← reads runs/<id>/ → writes figures/<slug>.png
        │        └─ tufte-reviewer (agent)
        └─ /experiment-report    ← reads runs/ + figures/ → writes reports/<slug>.md
                 └─ writing-reviewer (agent)
```

Skills spawn reviewer agents via the `Agent` tool with
`subagent_type="<reviewer-name>"`.

## Layout

```
agent-skills/
├── README.md
├── LICENSE
├── install.sh
├── .claude/
│   └── settings.json          # permissions + auto mode, for use inside this repo
├── agents/
│   ├── insight-reviewer.md
│   ├── plan-reviewer.md
│   ├── tufte-reviewer.md
│   └── writing-reviewer.md
└── skills/
    ├── dataset-insights/
    ├── experiment-report/
    ├── experiment-structure/
    ├── marimo-figures/
    ├── plan-pi-fleshout/
    └── podman-runner/
```

## Install

Claude Code discovers skills and agents in two scopes:

- `~/.claude/` — available in every project (user scope)
- `<repo>/.claude/` — available only when Claude Code runs in that repo (project scope)

Symlinking is preferred over copying so `git pull` updates everything.

### Option 1 — user scope (available everywhere)

```bash
git clone https://github.com/<you>/agent-skills.git ~/agent-skills
~/agent-skills/install.sh
```

Or equivalently:

```bash
mkdir -p ~/.claude/agents ~/.claude/commands
# reviewer agents
for f in ~/agent-skills/agents/*.md; do
  ln -sfn "$f" ~/.claude/agents/"$(basename "$f")"
done
# skills
for d in ~/agent-skills/skills/*/; do
  ln -sfn "$d" ~/.claude/commands/"$(basename "$d")"
done
```

### Option 2 — project scope (only in a specific repo)

From inside the target repo:

```bash
mkdir -p .claude/agents .claude/commands
for f in ~/agent-skills/agents/*.md; do
  ln -sfn "$f" .claude/agents/"$(basename "$f")"
done
for d in ~/agent-skills/skills/*/; do
  ln -sfn "$d" .claude/commands/"$(basename "$d")"
done
```

Commit `.claude/` so teammates pick everything up automatically.

### Verify

Start Claude Code in a project where the skills are installed and ask:

> list the skills and subagents you have available

All skills and reviewer agents should appear. Invoke a skill by name
(e.g. `/marimo-figures`, `/dataset-insights`) or trigger it with a
matching phrase from its `description` frontmatter.

### Uninstall

```bash
# user scope
rm ~/.claude/agents/{tufte-reviewer,writing-reviewer,insight-reviewer,plan-reviewer}.md
rm -r ~/.claude/commands/{dataset-insights,experiment-report,experiment-structure,marimo-figures,plan-pi-fleshout,podman-runner}
```

## Permissions / auto mode

This repo also ships a project-scoped `.claude/settings.json` adapted from
[briney/codebox](https://github.com/briney/codebox/blob/main/setup/claude/settings.json)
with `permissions.defaultMode` set to `"auto"`. It applies only when Claude
Code runs from the root of this repo. To use the same allowlist in your
own project, copy `.claude/settings.json` into that project's `.claude/`
directory (or merge it with existing settings).
