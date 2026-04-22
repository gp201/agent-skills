---
name: experiment-structure
description: Use when the user starts a new experiment, asks "how should I organize this", "where should X live", "scaffold an experiment folder", or when other skills (podman-runner, experiment-report, marimo-figures) need a canonical layout to write into. Lays down a reproducible directory structure and the rules that keep it honest. Do not invoke to reorganize an existing, working project without the user's explicit ask.
---

# experiment-structure

Canonical folder layout for a computational experiment and the
conventions that keep it reproducible. The other four skills in this
repo write *into* this layout; don't invent a different one on the fly.

## When to use

- The user says "I'm starting a new experiment" or "scaffold a folder
  for this".
- Another skill (`podman-runner`, `experiment-report`, `marimo-figures`,
  `dataset-insights`) needs a destination directory and none exists.
- The user asks "where does X go?" — answer from this file, don't
  guess.

Do **not** restructure an existing project unless the user explicitly
asks. Migrations are expensive; the cost of a slightly-off layout is
usually lower than the cost of moving everything.

## The layout

```
<experiment-name>/
├── README.md              # one-page "what & why" of the whole experiment
├── pyproject.toml         # or environment.yml — pinned dependencies
├── Containerfile          # consumed by podman-runner
├── .gitignore
│
├── configs/               # every parameter the experiment varies
│   ├── base.yaml          # defaults, committed
│   ├── sweep-lr.yaml      # overrides for a specific run family
│   └── ...
│
├── src/                   # importable library code (no side effects on import)
│   └── <project>/
│       ├── __init__.py
│       ├── data.py
│       ├── models.py
│       └── train.py
│
├── scripts/               # entry points; thin wrappers over src/
│   ├── train.py
│   ├── eval.py
│   └── prepare_data.py
│
├── data/                  # inputs
│   ├── raw/               # read-only, never modified, gitignored
│   ├── interim/           # cleaned/filtered, reproducible from raw
│   └── processed/         # model-ready, reproducible from interim
│
├── runs/                  # one directory per run, immutable after creation
│   └── <run-id>/
│       ├── config.yaml    # the exact config used (resolved, not templated)
│       ├── git.txt        # commit hash + dirty flag
│       ├── env.txt        # `pip freeze` or `uv pip freeze`
│       ├── logs/          # stdout, stderr, per-step logs
│       ├── checkpoints/   # model state
│       ├── metrics.json   # or metrics.parquet — the numbers
│       └── README.md      # (optional) what this run was trying to answer
│
├── analysis/              # post-hoc exploration; outputs of dataset-insights
│   └── <slug>/
│       ├── profile.md
│       ├── insights.md
│       └── figures/
│
├── figures/               # publication-ready figures; outputs of marimo-figures
│   ├── <slug>.py          # marimo notebook
│   └── <slug>.png
│
├── reports/               # outputs of experiment-report
│   └── <slug>.md
│
└── tests/                 # pytest — smoke tests over src/ and scripts/
```

## Hard rules

These are non-negotiable. If you find yourself wanting to break one,
stop and ask the user first.

1. **`data/raw/` is read-only.** Nothing writes to it except the
   initial ingest. If you clean the data, write to `data/interim/`.
2. **`runs/<id>/` is immutable after the run exits.** You may append
   analysis notes to `runs/<id>/README.md`, but never rewrite
   `config.yaml`, `metrics.json`, or checkpoints. A new run gets a
   new id.
3. **Every run captures provenance.** `git.txt` (commit + dirty
   flag), `env.txt` (frozen deps), and `config.yaml` (fully resolved,
   not templated) are required. `podman-runner` writes these
   automatically; if you're running manually, write them yourself.
4. **Scripts are thin.** `scripts/train.py` parses a config path,
   imports from `src/`, and calls a function. All logic lives in
   `src/`. This keeps the library testable and the entry points
   boring.
5. **Configs over flags.** Hyperparameters live in
   `configs/<name>.yaml`. Scripts take `--config <path>` and maybe
   `--override key=value` for one-offs. Do not spread flags across
   argparse calls that you'll regret when you try to reproduce the
   run six months from now.
6. **Figures and reports reference runs, not the other way around.**
   A figure in `figures/` names the run it summarizes; a run never
   refers to the figures built from it (those come later).
7. **Experiment folders are git repos, and work happens in
   worktrees.** On first touch, `git init` the folder if it isn't
   already a repo. For any change beyond a trivial scaffold edit —
   new runs, new analyses, new figures, new reports — create a
   worktree (`git worktree add ../<folder>-<slug> -b exp/<slug>`)
   and work there. The main checkout stays clean so parallel
   experiment branches don't contaminate each other.

## Soft conventions

These are defaults — override with a reason.

- **Run id format.** `YYYY-MM-DD-HHMM-<short-slug>` (e.g.
  `2026-04-17-0830-lr-sweep-v2`). Sortable and human-readable; no
  UUIDs unless a sweep tool generates them.
- **Config format.** YAML. One file per named configuration.
  Overrides for sweeps go in their own file that `includes: base.yaml`
  at the top.
- **Metrics schema.** `metrics.json` is a flat dict of
  `{"metric_name": float}` for scalars; `metrics.parquet` for
  time-series or per-step logs.
- **Seeds.** Every run sets a seed and writes it to `config.yaml`
  under `seed: <int>`. Default to seed 0 only if the user is
  explicitly prototyping.
- **Tests.** `tests/` mirrors `src/`. One smoke test per script that
  runs it on a 10-row fixture so CI catches the "import broke on
  main" class of bug.

## What lives where — quick reference

| I have a...                            | Put it in...               |
|----------------------------------------|----------------------------|
| hyperparameter                         | `configs/<name>.yaml`      |
| reusable function                      | `src/<project>/`           |
| CLI entry point                        | `scripts/`                 |
| new data file someone sent me          | `data/raw/`                |
| cleaned-up version of that             | `data/interim/`            |
| model-ready tensors                    | `data/processed/`          |
| output of a single training run        | `runs/<id>/`               |
| exploratory analysis of a dataset      | `analysis/<slug>/`         |
| figure that belongs in a writeup       | `figures/<slug>.{py,png}`  |
| writeup of a run                       | `reports/<slug>.md`        |
| smoke test                             | `tests/`                   |

## Scaffolding a new experiment

When the user says "scaffold", create:
1. The directory tree above (empty except the top-level files).
2. A minimal `README.md` that states the question the experiment is
   meant to answer (one paragraph). Push back if the user can't state
   the question — a nameless experiment is a scope-creep vector.
3. A minimal `configs/base.yaml` with placeholder keys for the
   parameters the user mentioned.
4. A minimal `pyproject.toml` pinning the stack the user named (or
   sensible defaults: `python >= 3.11`, `numpy`, `polars`, `pytest`,
   `ruff`).
5. A `.gitignore` that covers `data/raw/`, `runs/`, `__pycache__/`,
   `.venv/`, `*.egg-info/`.
6. An empty `Containerfile` with a `FROM python:3.11-slim` starter
   and a `# filled in by podman-runner skill` comment.
7. `git init` in the folder and an initial commit of the scaffold
   so later work can branch cleanly. Then create a worktree
   (`git worktree add ../<name>-<slug> -b exp/<slug>`) for the
   first real change and do the work there rather than on the
   main checkout.

Don't scaffold `src/`, `tests/`, or `scripts/` contents — those are
code decisions the user hasn't made yet.

## Working on an existing experiment folder

Before making non-trivial changes to an existing experiment folder:

1. Confirm it's a git repo (`git rev-parse --is-inside-work-tree`).
   If not, `git init` and commit the current state first.
2. Create a worktree off `main` (or the folder's default branch)
   for the change: `git worktree add ../<folder>-<slug> -b exp/<slug>`.
3. Run the experiment and write its outputs inside the worktree.
   Merge (or leave as a branch) only once the run is finished and
   provenance is captured.

This applies when other skills (`podman-runner`, `experiment-report`,
`marimo-figures`, `dataset-insights`) are about to mutate the folder
too — prepare the worktree first, then hand off.

## What not to do

- Don't nest experiments inside experiments. If work branches,
  create a sibling directory.
- Don't commit `data/raw/` or `runs/` to git — use DVC, S3, or a
  shared filesystem. The repo tracks *code* that reproduces those
  directories.
- Don't mix analysis (`analysis/`) and publication-ready figures
  (`figures/`). Analysis is exploratory and allowed to be messy;
  figures are tracked, reviewed, and referenced in reports.
- Don't let `scripts/` grow logic. Push it into `src/` the moment
  you copy-paste anything between two scripts.
