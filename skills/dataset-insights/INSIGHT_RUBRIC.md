# Insight-Quality Rubric

Each insight is scored on three dimensions, 1–5 each. Total 15 per
insight. An insight survives at ≥ 11 with no dimension below 3.

The rubric is deliberately narrow: an insight is only valuable if it
is (a) something the reader didn't already assume, (b) something they
could act on, and (c) actually supported by the data shown.

---

## 1. Novelty (1–5)

Does the insight tell the reader something they would not have
defaulted to believing before reading it?

- **5** — Counterintuitive or overturns a stated prior; the reader's
  mental model has to update.
- **4** — Non-obvious: consistent with one reasonable prior, contrary
  to another.
- **3** — Confirms a known pattern with better numbers or scope.
- **2** — Restates common knowledge about this kind of data.
- **1** — Trivial summary stat that appears in any describe() output
  ("the mean of X is ~7") without a twist.

**Reviewer check.** State what the default prior was and how this
insight differs. If you can't state the prior, novelty is ≤ 3.

## 2. Actionability (1–5)

Would the named audience make a different decision, next query, or
next experiment because of this insight?

- **5** — Named decision changes (model choice, feature set, data
  cleaning step, eligibility criterion).
- **4** — Suggests a specific follow-up that's worth the cost.
- **3** — Interesting but no concrete next step named.
- **2** — "Good to know" framing; no downstream consequence.
- **1** — Pure trivia relative to the audience's decision.

**Reviewer check.** Name the concrete action. If you can't, the
insight's "Why it matters" section is weak and should be rewritten
or cut.

## 3. Evidence (1–5)

Is the claim actually supported by the data shown, at an appropriate
sample size, with caveats matching the strength of the evidence?

- **5** — Effect size + uncertainty + sufficient n (usually ≥ 100 for
  distributional claims; ≥ 30 per group for comparisons); caveats
  acknowledge confounders and selection.
- **4** — Numbers check out; one caveat is missing or understated.
- **3** — Claim is supported but overstated relative to the data
  (e.g. "strong" used for r ≈ 0.2).
- **2** — Numbers are close to the claim but a selection effect or
  leakage source undermines it.
- **1** — Reviewer spot-checked the underlying data and the claim
  does not hold, or n < 10 for a distributional claim.

**Reviewer check.** Re-query the data for the insight's headline
number. If it doesn't match within rounding, Evidence is ≤ 2 and the
insight should be CUT unless STRENGTHEN can rescue it.

---

## Per-insight verdict

After the three scores, the reviewer gives one of:

- **KEEP** — total ≥ 11, all dimensions ≥ 3, numbers verified.
- **STRENGTHEN** — the insight is real but underbaked; reviewer states
  precisely what's missing (usually: a CI, a subgroup breakdown, a
  comparison baseline, or a caveat).
- **CUT** — Evidence ≤ 2 (the data doesn't support the claim), or
  Novelty + Actionability ≤ 5 (nobody would change their mind or
  their behavior because of this).

## Missed insights (up to 2)

After reviewing the submitted list, the reviewer proposes up to two
insights the profile missed. Each proposal names:

- the claim (one sentence),
- the query or figure that would establish it,
- the expected Novelty / Actionability scores if it holds.

The proposals go back to the author, who writes them up and re-runs
the reviewer on the new entries only.

---

## Scoring template

```
| # | Claim (short)            | Nov | Act | Ev | Total | Verdict     |
|---|--------------------------|-----|-----|----|-------|-------------|
| 1 | Nulls cluster in cohort A| 4   | 5   | 5  | 14    | KEEP        |
| 2 | Feature X pred. target   | 3   | 4   | 2  |  9    | STRENGTHEN: |
|   |                          |     |     |    |       | add CI + n  |
| 3 | Mean of Y is ~7          | 1   | 2   | 4  |  7    | CUT         |
```

Followed by the missed-insights list (0–2 items).
