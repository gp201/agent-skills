# Scientific-Writing Rubric

Seven dimensions, each 1–5. Total 35. Report ships at ≥ 28 with no
dimension below 3 **and** zero claims that the reviewer cannot trace
to evidence in the run directory.

The rubric targets the failure modes most common in internal research
write-ups: claim-evidence drift, missing uncertainty, buried lede, and
overclaiming the scope of a single run.

---

## 1. Claim-evidence linkage (1–5)

Every claim in TL;DR, Results, and Discussion can be traced to a
specific number, table, or figure in the run directory. No orphan
claims ("the model generalizes well") without a cited metric.

- **5** — Every claim maps to a specific metric, figure, or table the
  reviewer verified against `runs/<id>/`.
- **3** — One or two hand-wavy claims without a direct citation, but
  none are central to the headline.
- **1** — Central claims have no traceable evidence, or the evidence
  cited contradicts the claim.

## 2. Uncertainty reporting (1–5)

Headline numbers carry CIs, ± SE, or an explicit disclaimer that the
result is from a single run. Effect sizes are reported alongside
p-values. No significance claimed from n=1.

- **5** — Every headline number has uncertainty; seeds/runs noted.
- **3** — Main numbers have uncertainty but secondary claims don't.
- **1** — Point estimates presented as settled facts; "significant"
  appears with no supporting test.

## 3. Scope honesty (1–5)

The Discussion states what the result does *not* mean. Generalization
claims stay within the data distribution tested. No extrapolation
past the evaluated range without flagging it.

- **5** — Explicit scope limits, named confounders, one clearly
  articulated "what we didn't test".
- **3** — Scope implied but not explicit.
- **1** — Results framed as a universal conclusion; extrapolation
  past the test distribution without a caveat.

## 4. Structure / IMRaD discipline (1–5)

All six sections present (or five with a deliberate, noted omission).
Each section does its job and no other: methods doesn't leak into
results, discussion doesn't introduce new methodology.

- **5** — Clean IMRaD with each section earning its place.
- **3** — One minor leak (e.g. a method detail in Results).
- **1** — Missing section, or sections re-ordered in a way that
  buries the headline.

## 5. Lede quality (1–5)

TL;DR is ≤ 4 sentences, leads with the claim, carries the number
plus uncertainty, and names the main caveat. A reader who stops here
still has a correct model of the result.

- **5** — Claim + number + caveat in the first sentence or two; no
  warm-up.
- **3** — Claim is there but caveat is missing, or the first sentence
  is boilerplate ("In this experiment, we evaluated...").
- **1** — Headline is buried past the first paragraph, or there is no
  TL;DR at all.

## 6. Reproducibility pointers (1–5)

The report links `runs/<id>/`, cites the commit hash, names the seed(s),
and points at `config.yaml` rather than restating every flag. Figures
reference their source notebook.

- **5** — A reader with repo access can rerun the exact experiment
  from the report alone.
- **3** — Run directory linked but commit/seed omitted.
- **1** — Methods are hand-written with no pointer to the actual
  artifacts.

## 7. Prose economy (1–5)

Under ~800 words for the main flow (Appendix excluded). Active voice
for claims. No filler sentences ("It is important to note that...").
No unexplained jargon; expand acronyms on first use.

- **5** — Tight prose, every sentence load-bearing.
- **3** — Readable but 10–20% could be cut without loss.
- **1** — Padded past 1200 words, or jargon-dense beyond the intended
  audience.

---

## Scoring template

```
| Dimension               | Score | Note                               |
|-------------------------|-------|------------------------------------|
| Claim-evidence linkage  | 5     | All claims traced                  |
| Uncertainty reporting   | 3     | Secondary metrics missing CIs      |
| Scope honesty           | 4     | Scope limits stated, one confounder|
|                         |       | not named                          |
| IMRaD discipline        | 5     | —                                  |
| Lede quality            | 4     | First sentence has warm-up clause  |
| Reproducibility         | 5     | —                                  |
| Prose economy           | 4     | ~850 words, could cut 50           |
| **Total**               | 30/35 |                                    |
```

Followed by:

**Unverifiable claims:** list any claim the reviewer could not trace
to evidence. A non-empty list is a blocker regardless of score.

**Suggested edits:** up to 5, each phrased as "replace X with Y in
section Z" so the author can apply them mechanically.
