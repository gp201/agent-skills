---
name: dataset-insights
description: Profiles a dataset (schema, univariate sanity, pairwise red flags, time shape) and produces a ranked list of up to 7 insights under `analysis/<slug>/`, then delegates quality review to the insight-reviewer agent and applies its verdicts. Invoke when the user asks open-ended questions like "what's in this data", "anything weird here?", or "give me insights on X". Do not invoke for pre-specified hypothesis tests or one-off SQL queries.
---

# dataset-insights

You profile a dataset and produce a small, ranked list of *insights* —
each one a claim the data actually supports, with a figure or table
behind it. The `insight-reviewer` agent scores the insights and
suggests which to keep, cut, or strengthen.

## Inputs you need

1. **Path(s) to the data.** Read the schema first; don't load the
   whole thing unless it fits comfortably in memory.
2. **Audience and decision.** An insight is only useful relative to
   *who reads it* and *what they might do*. If the user hasn't said,
   ask once: "who's the reader, and what decision might these inform?"
3. **Output slug.** Default = kebab-case of the dataset name. Outputs
   go under `analysis/<slug>/`.

## Profile pass

Land a first draft in `analysis/<slug>/profile.md` with these
sections — in this order:

1. **Schema** — columns, dtypes, null rate, cardinality. Flag any
   column where null rate > 20% or cardinality = 1 (constant
   columns).
2. **Univariate sanity** — for numeric columns: min / median / max,
   anything suspicious (negative counts, future timestamps, values
   pinned at 0 or a sentinel like `-1`, `999`). For categorical:
   top-5 levels by frequency and a long-tail indicator.
3. **Pairwise red flags** — obvious leakage, target-like columns,
   correlations > 0.95 between features, identifier columns that
   perfectly predict the target.
4. **Time shape** — if a date/timestamp column exists: rows per
   day/week, gaps, recency. If not, state "no temporal column".

Use `polars` or `duckdb` for the profile; they handle big files
without loading into memory. Save any intermediate plots to
`analysis/<slug>/profile/`.

## Insight pass

Then produce `analysis/<slug>/insights.md` — a ranked list of at most
**7 insights**. Quality beats quantity; stop when the next candidate
is weaker than the ones already written.

Each insight follows this template:

```markdown
### <N>. <Claim, stated as a sentence>

**Evidence.** One figure or table, referenced by path
(`analysis/<slug>/figures/<file>.png` or an inline markdown table).
State the sample size and the effect size.

**Why it matters.** One sentence on what a reader would do
differently if they believed this. If nothing changes, cut the
insight.

**Caveats.** Known confounders, selection effects, or "this is
correlational" disclaimers.

**Confidence.** low / medium / high, with a one-line justification
(bootstrapped CI width, replication across subgroups, sample size).
```

Ranking rules:
- **High-confidence actionable findings first.** The first insight is
  the one the reader most needs to know.
- **Demote anything with n < 30 or confidence = low** to the bottom,
  or cut it.
- **Never stack redundant insights** (same underlying variable
  described three ways).
- **Prefer structural findings over point estimates.** "Column X is
  60% null and always null when Y=true" is usually more useful than
  "the mean of X is 7.3".

## Reviewer pass (required)

Spawn the `insight-reviewer` agent:

```
Agent(
  subagent_type="insight-reviewer",
  description="Insight review of <slug>",
  prompt="""
  Review analysis/<slug>/insights.md. The data is at <data_path>;
  you may query it with duckdb/polars to spot-check numbers. The
  audience is <audience> and the decision they face is <decision>.

  For each insight, score Novelty / Actionability / Evidence (1–5
  each) with one-line justifications. Then recommend: KEEP, STRENGTHEN
  (with specific ask), or CUT. Finally, propose up to 2 insights the
  profile missed.

  Report in under 500 words.
  """
)
```

Apply the reviewer's recommendations:
- **CUT** → remove the insight.
- **STRENGTHEN** → the reviewer stated what's missing (usually a CI,
  a subgroup check, or a sample-size callout) — add it.
- **KEEP** → leave as-is.
- **Missed insights** → investigate; add if they survive the same
  rubric when you write them up.

Re-run the reviewer once after applying changes to confirm the
STRENGTHEN items landed.

## Output

Report to the user:
- Path to `analysis/<slug>/profile.md` and
  `analysis/<slug>/insights.md`.
- Count of insights KEPT / STRENGTHENED / CUT.
- The single insight the reviewer ranked most actionable (one line).
- Any schema-level flag that's a blocker for downstream work (e.g.
  "target column has 30% nulls — fix before modeling").

## What not to do

- Don't produce insights that are just summary stats without a
  "so what". Mean-of-X is only an insight if the value is surprising
  or actionable.
- Don't report correlations as causation. Every non-experimental
  claim gets a "correlational" caveat.
- Don't chase > 7 insights. Past that, you're adding noise.
- Don't run expensive full-dataset models here — this agent is for
  profiling and insight extraction, not training. If an insight
  requires a model to establish, note it as a follow-up experiment
  (invoke `experiment-structure` + `podman-runner`).
