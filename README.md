# agent-skills

A small set of subagents for computational-experiment workflows. Each agent is a
single markdown file with YAML frontmatter + prose instructions that
Claude Code can delegate to via the `Agent` tool.

Three of the author agents pair with a named *reviewer* agent so
nothing ships without a second pass.

## Agents

### Author agents

| Agent | Pairs with | What it does |
| --- | --- | --- |
| [`marimo-figures`](agents/marimo-figures.md) | `tufte-reviewer` | Build a figure in a marimo notebook; reviewer scores it against Tufte's principles and returns revisions. |
| [`experiment-report`](agents/experiment-report.md) | `writing-reviewer` | Draft an IMRaD report of a run; reviewer checks structure, claim-evidence linkage, and statistical honesty. |
| [`dataset-insights`](agents/dataset-insights.md) | `insight-reviewer` | Profile a dataset and produce ranked insights; reviewer scores them for novelty, actionability, and evidence. |
| [`experiment-structure`](agents/experiment-structure.md) | — | Canonical folder layout for an experiment (configs, src, scripts, runs, analysis, figures, reports) and rules for keeping it reproducible. |
| [`podman-runner`](agents/podman-runner.md) | — | Single entry point for executing experiment commands inside a reproducible podman container, with GPU passthrough, log capture, and run-directory conventions. |

### Reviewer agents

| Agent | Rubric it enforces |
| --- | --- |
| [`tufte-reviewer`](agents/tufte-reviewer.md) | 8 Tufte dimensions (claim clarity, data-ink ratio, encoding discipline, axis honesty, color, comparison support, annotation economy, reproducibility). |
| [`writing-reviewer`](agents/writing-reviewer.md) | 7 scientific-writing dimensions (claim-evidence linkage, uncertainty, scope honesty, IMRaD discipline, lede quality, reproducibility pointers, prose economy). |
| [`insight-reviewer`](agents/insight-reviewer.md) | 3 insight dimensions (novelty, actionability, evidence) with KEEP / STRENGTHEN / CUT verdicts. |

Reviewer agents are read-only (`Read, Grep, Glob, Bash`) — they score
and propose revisions but never edit the artifact they judge.

## How the agents fit together

```
experiment-structure   ← lays out the directory
        │
        ├─ podman-runner         ← runs scripts/ against configs/
        │        │
        │        └─ produces runs/<id>/
        │
        ├─ dataset-insights      ← reads data/ → writes analysis/<slug>/
        │        └─ insight-reviewer
        ├─ marimo-figures        ← reads runs/<id>/ → writes figures/<slug>.png
        │        └─ tufte-reviewer
        └─ experiment-report     ← reads runs/ + figures/ → writes reports/<slug>.md
                 └─ writing-reviewer
```

Author agents delegate the review pass by calling the `Agent` tool
with `subagent_type="<reviewer-name>"`.

## Layout

```
agent-skills/
├── README.md
├── LICENSE
├── install.sh
├── .claude/
│   └── settings.json          # permissions + auto mode, for use inside this repo
└── agents/
    ├── marimo-figures.md
    ├── tufte-reviewer.md
    ├── experiment-report.md
    ├── writing-reviewer.md
    ├── dataset-insights.md
    ├── insight-reviewer.md
    ├── experiment-structure.md
    └── podman-runner.md
```

## Install

Claude Code discovers subagents in two locations:

- `~/.claude/agents/<agent-name>.md` — available in every project (user scope)
- `<repo>/.claude/agents/<agent-name>.md` — available only when Claude Code runs in that repo (project scope)

Pick one. Symlinking is preferred over copying so `git pull` updates the
installed agents.

### Option 1 — user scope (available everywhere)

```bash
git clone https://github.com/<you>/agent-skills.git ~/agent-skills
~/agent-skills/install.sh
```

Or equivalently:

```bash
mkdir -p ~/.claude/agents
for f in ~/agent-skills/agents/*.md; do
  ln -sfn "$f" ~/.claude/agents/"$(basename "$f")"
done
```

Verify from any project:

```bash
ls ~/.claude/agents
# dataset-insights.md   experiment-report.md  experiment-structure.md
# insight-reviewer.md   marimo-figures.md     podman-runner.md
# tufte-reviewer.md     writing-reviewer.md
```

### Option 2 — project scope (only in a specific repo)

From inside the target repo:

```bash
mkdir -p .claude/agents
for f in ~/agent-skills/agents/*.md; do
  ln -sfn "$f" .claude/agents/"$(basename "$f")"
done
```

Commit `.claude/agents/` so teammates pick the agents up automatically.

### Verify

Start Claude Code in a project where the agents are installed and ask:

> list the subagents you have available

The eight agents above should appear. Trigger one with a matching
phrase from its `description` frontmatter (e.g. "plot this and
tufte-check it" → `marimo-figures`, which will then delegate to
`tufte-reviewer`).

### Uninstall

```bash
# user scope
rm ~/.claude/agents/{marimo-figures,tufte-reviewer,experiment-report,writing-reviewer,dataset-insights,insight-reviewer,experiment-structure,podman-runner}.md
# project scope
rm <repo>/.claude/agents/{marimo-figures,tufte-reviewer,experiment-report,writing-reviewer,dataset-insights,insight-reviewer,experiment-structure,podman-runner}.md
```

## Permissions / auto mode

This repo also ships a project-scoped `.claude/settings.json` adapted from
[briney/codebox](https://github.com/briney/codebox/blob/main/setup/claude/settings.json)
with `permissions.defaultMode` set to `"auto"`. It applies only when Claude
Code runs from the root of this repo. To use the same allowlist in your
own project, copy `.claude/settings.json` into that project's `.claude/`
directory (or merge it with existing settings).
