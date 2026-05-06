---
name: experiment-report
description: Use when the user asks to "write up", "summarize", or "report on" an experiment run — phrases like "draft a report for run X", "write up these results", "summarize what we found". Produces an IMRaD-style markdown report under `reports/<slug>.md` and runs a scientific-writing reviewer subagent over it before handing back. Do not invoke for blog posts, commit messages, or casual summaries.
---

# experiment-report

Draft a short, claim-driven report of a completed experiment, then hand
it to the `writing-reviewer` agent, which checks structure, claim-evidence
linkage, and statistical honesty.

## When to use

- A run directory exists (typically `runs/<id>/` from `podman-runner`
  output) and the user wants a write-up suitable for a lab notebook,
  PR description, or internal memo.
- The user asks for a "report", "writeup", or "summary" of specific
  results — *not* a status update of in-flight work.

Skip this skill for:
- commit messages / PR titles (too short to justify IMRaD),
- generic status updates that don't claim anything about results,
- publication-grade manuscripts (use a domain-specific template).

## Inputs you need

Before drafting, collect:

1. **Run directory or result file(s)** — path(s) under `runs/<id>/`.
   Read `runs/<id>/config.yaml` (or equivalent) and the metrics file
   (`metrics.json` / `results.parquet`).
2. **The question the experiment was asked to answer** — if not in
   the run's README or config, ask once.
3. **The figures** — any PNGs under `figures/` that belong to this
   run. Embed them inline in Results using markdown image syntax
   (`![caption](../figures/<name>.png)`) rather than re-plotting or
   linking to them as bare URLs. Use a path that resolves from the
   report's location (`reports/<slug>.md` → `../figures/...`).
4. **Output path** — default `reports/<slug>.md`. Slug = kebab-case of
   the question.

If the run has no metrics or the config doesn't state a question, stop
and surface that — there is nothing honest to report yet.

## Structure (IMRaD, tight)

Use exactly these six sections. Keep the whole report under ~800
words; a reader should finish it in under 4 minutes.

```markdown
---
run_id: <id>
date: YYYY-MM-DD
author: ~
tldr: <one-sentence headline finding>
status: draft | reviewed | final
---

# <The question, phrased as a title>

## TL;DR
One paragraph (≤ 4 sentences). State the claim, the evidence scale
(n, effect size, CI), and the main caveat.

## Introduction
What question does this run answer? Why now? One paragraph. End with
the pre-registered hypothesis or the decision this run is meant to
inform.

## Methods
- Data: source, size, preprocessing.
- Model / procedure: architecture or pipeline, key hyperparameters.
- Evaluation: metric, test split, baseline.
- Compute: hardware, wall-clock, seed(s).
Link to `runs/<id>/config.yaml` — don't restate every flag.

## Results
Lead with the headline number and its uncertainty. Embed each figure
inline as a markdown image with a caption that states what the reader
should conclude — not a re-description of the axes:

```markdown
![Figure 1. Accuracy exceeds the baseline across all five seeds.](../figures/<slug>.png)
```

Number figures (`Figure 1`, `Figure 2`, ...) and reference them in the
surrounding prose by number. One subheading per sub-claim if there are
multiple; otherwise prose.

## Discussion
- What the result means for the question.
- What it *doesn't* mean (scope limits).
- Threats to validity: confounds, leakage risks, p-hacking flags,
  baseline strength.
- Next step: the single most informative follow-up run.

## Appendix (optional)
Extra tables, ablations, reproducibility notes. Only include if a
reader would want them but they'd bloat the main flow.
```

## Draft rules

- **Lead with the claim.** Every section's first sentence carries the
  load. If a reader stops after the first sentence of TL;DR, they
  should have the headline.
- **Numbers get uncertainty.** Every headline metric gets either a CI,
  a ± SE, or an explicit "single run, no bootstrap" disclaimer.
  Point estimates without uncertainty are a rubric fail.
- **No passive voice for claims.** "The model reached 74%" not
  "74% was reached". Passive is fine for methods boilerplate.
- **Figures are embedded, not re-described.** Every figure that
  belongs to the run appears inline in Results as a markdown image
  with a numbered caption. The caption states what the reader should
  conclude; the surrounding prose references the figure by number
  ("Figure 2 shows..."). Verify each referenced PNG actually exists
  under `figures/` before shipping — broken image links are a rubric
  fail.
- **Cite the run.** Always link `runs/<id>/` and name the commit
  hash if the code is versioned.

## Reviewer pass (required)

After the draft exists, spawn the `writing-reviewer` agent. It owns the
rubric (7 dimensions, 1–5 each; ship bar ≥ 28/35, no dimension < 3, zero
unverifiable claims) and returns scores, unverifiable-claim flags, and up
to 5 mechanical edits.

```
Agent(
  subagent_type="writing-reviewer",
  description="Scientific-writing review of <slug>",
  prompt="""
  Report: reports/<slug>.md
  Run: runs/<id>/
  """
)
```

Apply the edits. Re-run the reviewer at most twice; after that, surface
disagreements to the user.

Flip the frontmatter `status` to `reviewed` once the reviewer's ship bar
is met.

## Output

Report to the user:
- Path to `reports/<slug>.md`.
- TL;DR line.
- Reviewer's rubric scores.
- Any claim the reviewer flagged as unsupported (these are blockers).

## What not to do

- Don't invent numbers. If a metric isn't in the run, say the run
  didn't produce it — don't round, don't estimate.
- Don't re-run the experiment to produce missing metrics inside this
  skill. That's a separate run (use `podman-runner`).
- Don't expand the report past ~800 words to look thorough. Length is
  not a proxy for rigor.
- Don't ship with `status: draft` in frontmatter — either flip it to
  `reviewed` or tell the user why you couldn't.
