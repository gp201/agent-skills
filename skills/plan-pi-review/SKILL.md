---
name: plan-pi-review
description: Use when the user wants a PI-level (Principal Investigator) review of a research plan, experimental design, grant aim, or computational analysis plan. Phrases like "review my research plan", "critique this experiment design", "check my specific aims", "is this statistically sound", or "PI review". Applies rigorous scientific thinking — hypothesis validity, experimental controls, statistical power, reproducibility, resource feasibility — without scope-creeping into unrelated work. Do not invoke for code reviews, general software plans, or non-research writing.
---

# plan-pi-review

Review a research plan with the rigor of an experienced Principal Investigator. The goal is to surface flaws before they become failed experiments, wasted resources, or rejected papers.

---

## Four Review Modes

Ask the user which mode they want **before starting**. Default to HOLD SCOPE if they don't specify.

| Mode | Posture |
|------|---------|
| **SCOPE EXPANSION** | Dream big — propose extended hypotheses, follow-on aims, collaborations that would strengthen the work |
| **SELECTIVE EXPANSION** | Hold the stated aims; cherry-pick the highest-leverage additions (e.g., one missing control, a stronger assay) |
| **HOLD SCOPE** | Maximum rigor on exactly what's written; no new experiments suggested unless a fatal flaw demands it |
| **SCOPE REDUCTION** | Strip to minimum viable result — identify the single experiment or analysis that most de-risks the central claim |

Every scope change (even a suggested extra control) requires **explicit opt-in via AskUserQuestion**. Never silently expand.

---

## Pre-Review Audit (always run first)

Before any analysis, read the research context:

```
- git log --oneline -20          # recent progress / prior attempts
- cat TODOS.md 2>/dev/null       # known gaps the PI already flagged
- ls data/ runs/ notebooks/ 2>/dev/null  # what data actually exists
- grep -r "TODO\|FIXME\|HACK\|NOTE" --include="*.py" --include="*.R" --include="*.md" -l
```

Look for: recurring dead ends, prior failed pilots, data quality notes, reviewer comments from past submissions. These are your best signal of where the plan is weakest.

---

## Planning Protocol (always run before any implementation work)

Before writing any code, script, or analysis prompted by findings from this review:

1. **Generate `PLAN.md`** — save a step-by-step plan as `PLAN.md` in the project directory. Each step must be small enough to map to a single commit.
2. **Task granularity** — break work into discrete tasks. If a step takes more than ~30 minutes or touches more than one concern, split it further.
3. **No silent assumptions** — if information needed to complete a step is missing or ambiguous, use `AskUserQuestion` explicitly. Never infer or guess.
4. **Pseudocode first** — before implementing any analysis, pipeline step, or script, write pseudocode in the plan. Confirm the logic is sound before writing real code.

---

## Step 0 — Nuclear Challenge (always before section review)

Before diving into sections, challenge the plan at the root:

1. **Hypothesis clarity** — Can you restate the central hypothesis in one falsifiable sentence? If not, stop and ask.
2. **Prior art check** — Has this been published? Is the novelty claim defensible? Ask for the 3 most relevant papers and check for overlap.
3. **Existing data leverage** — What do you already have? What's the minimum new experiment needed to test the hypothesis?
4. **Dream state mapping** — What does a high-impact result look like? What would Nature/Cell/top venue accept?
5. **Implementation paths** — Propose 2–3 concrete approaches to the central experiment with rough effort/risk trade-offs. Make the user choose; don't pick silently.

---

## Commit Guidelines (enforced when implementing plan changes)

- **Atomic commits** — one logical change per commit. A commit that touches the experiment script AND the figure notebook AND the README is three commits.
- **Prefer many small commits over few large ones** — a reviewer (or future-you) should be able to understand any commit in isolation.
- **No dirty state between tasks** — never start a new task while the working tree has uncommitted changes. Stage and commit (or explicitly stash) before moving to the next step.

---

## Review Sections

Work through all applicable sections in order. Each finding that requires a user decision → one `AskUserQuestion`. Never batch questions.

### 1. Hypothesis & Experimental Logic

- Is the central hypothesis falsifiable and stated in one sentence?
- Does the experimental design logically test the hypothesis (not a proxy)?
- Are positive and negative controls specified for every assay?
- Are expected results defined *before* the experiment (pre-registration mindset)?
- Is there a clear decision rule: what result would cause the PI to pivot or abandon the aim?

**Diagram required**: draw a simple logic tree — hypothesis → prediction → experiment → expected outcome (positive and negative).

### 2. Statistical Design & Power

- Is the sample size justified with a power calculation (effect size, α, β)?
- Is the unit of analysis correct (biological vs. technical replicates)?
- Are planned statistical tests appropriate for the data distribution?
- Are multiple comparisons addressed?
- For machine learning plans: train/val/test split strategy, data leakage risks, baseline comparisons defined?
- Flag any analysis that will be underpowered given available data.

### 3. Reproducibility & Data Management

- Is the computational environment pinned (conda env, Docker image, `uv.lock`, `renv.lock`)?
- Are raw data and processed data kept separate and version-controlled?
- Is the analysis pipeline end-to-end scriptable (no manual Excel steps)?
- Are random seeds set for stochastic steps?
- Does a fresh collaborator have enough info to reproduce the key figure?
- Flag any "it works on my machine" risks.

> **Related skills**
> - `/experiment-structure` — if the project lacks a canonical reproducible directory layout (raw vs processed data separation, runs/, notebooks/, etc.), invoke this skill to scaffold it before auditing further.
> - `/podman-runner` — if experiment runs are not containerised, invoke this skill to wrap the pipeline in a Podman container with pinned dependencies and provenance-captured logs.

### 4. Data Quality & Confounds

- What are the known batch effects, biases, or confounders in this dataset?
- Are QC steps defined and applied before analysis?
- Is missingness handled explicitly (not silently dropped)?
- For multi-site or longitudinal data: are site/time effects modeled?
- For sequencing/imaging data: are upstream pipeline versions pinned?
- Enumerate every confound → for each: controlled, modeled, acknowledged, or unaddressed.

> **Related skill**
> - `/dataset-insights` — if the raw data has not yet been profiled or the user cannot enumerate known confounds, invoke this skill first to surface distribution anomalies, missing-value patterns, and unexpected correlations before completing this section.

### 5. Resource Feasibility

- Is the timeline realistic given lab capacity, equipment access, and personnel bandwidth?
- Are reagent/compute costs estimated?
- What is the critical path? What's the single experiment that blocks everything else?
- Are there equipment or sequencing bottlenecks that need to be booked now?
- Flag any aim that requires a skill or instrument the lab doesn't currently have.

**Diagram required**: rough Gantt or dependency graph — which experiments can run in parallel, which are blocked.

### 6. Risk & Contingency

- What are the 3 most likely failure modes for this plan?
- For each: what's the probability, what's the impact, and what's the mitigation?
- Is there a pivot experiment if the main hypothesis fails?
- Are there regulatory risks (IRB, IACUC, biosafety, data use agreements) that could stall the work?
- Flag any single-point-of-failure experiments with no backup.

**Registry required**: list every risk with (failure mode | probability | mitigation | owner).

### 7. Literature Positioning & Novelty

- Is the claimed novelty real given the last 24 months of literature?
- Which 1–3 papers are the closest competitors? How is this work differentiated?
- Is the framing correct for the target venue (methods paper vs. discovery paper vs. resource)?
- Are there obvious prior art gaps that a reviewer will catch?

### 8. Figure & Narrative Plan

- Is there a "key figure" that, if it works, tells the whole story?
- Is the figure plan defensible against Tufte principles (one claim per figure)?
- Is the narrative arc clear: problem → gap → approach → result → impact?
- Does the data plan generate the figures, or are the figures aspirational?
- Flag any planned figure that requires data not yet collected or a method not yet validated.

> **Related skill**
> - `/marimo-figures` — when the user is ready to build or Tufte-check a planned figure, invoke this skill to author it inside a marimo notebook and run an automated reviewer pass over the rendered output.

### 9. Collaboration & Authorship

- Are all contributors identified and their roles clear?
- Are there shared reagents, data, or code that require MTA/DUA/data-sharing agreements?
- Is authorship order discussed and agreed upon?
- Are there any conflict-of-interest disclosures needed?
- Flag any collaboration dependency that could stall the timeline.

### 10. Long-Term Trajectory

- Does this work open a fundable follow-on aim or close a dead end?
- Is the method/dataset reusable for future questions?
- Does this strengthen or weaken the lab's position in the field?
- Are there IP considerations for translational work?
- Is the approach building toward a K/R01/ERC or a publication-only endpoint?

---

## Critical Operational Rules

- **One issue = one AskUserQuestion.** Never batch. Never silently resolve.
- **No data invention.** If the data doesn't exist to support the analysis, say so and stop.
- **Pre-empt reviewer objections.** Every finding should be framed as "Reviewer 2 will say…"
- **Mode commitment.** Once a mode is selected, don't drift. If you need to suggest an expansion in HOLD SCOPE mode, ask permission first.
- **Diagrams mandatory** for sections 1, 5, and 6. ASCII is fine.
- **Flag silent failures** — any analysis step where a bug or data issue would produce a plausible-looking wrong answer with no error message.

---

## Deliverables

At the end of the review, produce:

1. **Risk Registry** — all failure modes with probability, impact, mitigation, owner.
2. **Open Questions List** — things the plan doesn't answer that a reviewer will ask.
3. **Minimum Viable Experiment** — the single result that most de-risks the central claim.
4. **Scope Decision Log** — every expansion or reduction discussed, with the user's explicit decision.
5. **TODOS.md patch** — concrete additions to the project's TODOS.md (experiments to add, controls to specify, analyses to pre-register).
6. **PI Plan document** (EXPANSION and SELECTIVE EXPANSION modes only) — a revised research plan incorporating all accepted changes.

> **Related skill**
> - `/experiment-report` — once experiments from the approved plan are completed, invoke this skill to draft an IMRaD-style write-up with an automated scientific-writing reviewer pass.

---

## Philosophy

A PI's job is to ask the question that makes the student uncomfortable before a reviewer does. Every plan has a load-bearing assumption that hasn't been tested. Find it, name it, and force a decision. "We'll figure it out" is not a plan.

Completeness is cheap with modern tools — a missing control or a pre-registration costs one extra experiment, not a year. Flag gaps early and explicitly rather than hoping the data will cover for them.
