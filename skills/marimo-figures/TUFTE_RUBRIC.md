# Tufte Rubric

Eight dimensions, each scored 1–5. Total 40. A figure ships at ≥ 32
with no dimension below 3.

The rubric is derived from Tufte's *Visual Display of Quantitative
Information* and *Visual Explanations*, condensed to the checks that
most often catch real problems in research figures.

---

## 1. Claim clarity (1–5)

The title states a single, testable claim — not a topic, not a dataset
name, not "Figure 1".

- **5** — Title is a complete sentence that the figure either supports
  or falsifies ("Accuracy plateaus above 8B parameters on MMLU-Pro").
- **3** — Title names the comparison but not the conclusion
  ("Accuracy vs. parameter count, MMLU-Pro").
- **1** — Title is a label ("Results", "Figure 1", "Training curves").

## 2. Data-ink ratio (1–5)

Every mark on the figure carries information. Chart junk (3D, heavy
borders, background fills, decorative icons, unnecessary gridlines) is
absent.

- **5** — Removing any mark would lose information.
- **3** — One or two decorative elements that don't mislead.
- **1** — Gridlines, background, or 3D effects dominate the data marks.

## 3. Encoding discipline (1–5)

Each variable is mapped to at most one channel. No redundant encodings
(same variable → color and shape), no unused channels burning the
reader's attention budget.

- **5** — One variable, one channel. Unused channels stay unused.
- **3** — One redundant encoding ("category" mapped to both color and
  marker).
- **1** — Multiple redundant encodings, or one channel encodes two
  variables.

## 4. Axis honesty (1–5)

Axes are labelled with units. Scales are appropriate (log when ranges
span > 2 decades; linear otherwise). Baselines are zero **unless** the
data is ratio-like or a log scale is used, in which case the non-zero
baseline is called out. No dual y-axes.

- **5** — Units present, scale justified, baseline honest.
- **3** — Units present but baseline choice is debatable.
- **1** — Missing units, truncated y-axis that exaggerates differences,
  or dual y-axes.

## 5. Color choice (1–5)

Palette matches data type: sequential for ordered, diverging for
centered, categorical for unordered. Colorblind-safe. No rainbow for
sequential data.

- **5** — Viridis/magma for sequential, RdBu for diverging, tab10/Set2
  for ≤ 8 categories, and contrast checked.
- **3** — Reasonable palette but not colorblind-checked.
- **1** — Rainbow (`jet`), red+green without pattern, or palette
  mismatched to data type.

## 6. Comparison support (1–5)

The figure makes the intended comparison *direct*. Baseline shown where
relevant. Confidence/error shown where the claim depends on it. Small
multiples when comparing > 2 conditions against a shared axis.

- **5** — The eye lands on the comparison immediately; baseline and
  uncertainty are visible.
- **3** — Comparison is possible but requires the reader to trace.
- **1** — The comparison the title promises isn't actually drawn.

## 7. Annotation economy (1–5)

Legend, text, and callouts earn their space. Short inline labels beat a
legend when ≤ 4 series. Arrows/annotations mark the point the claim
rests on.

- **5** — Each annotation is load-bearing.
- **3** — Legend present where inline labels would have been cleaner.
- **1** — Legend obscures data, repeated labels, or no annotation
  pointing at the claim.

## 8. Reproducibility (1–5)

The notebook is runnable top-to-bottom. Data path and filter thresholds
are surfaced as parameters in a single cell. Random seeds set where
relevant. The PNG and the notebook are versioned together.

- **5** — `python figures/<slug>.py` (or `marimo run`) reproduces the
  PNG bit-identically (or within a documented tolerance for stochastic
  plots).
- **3** — Reproducible but params are buried inside the plotting cell.
- **1** — Hard-coded paths to the author's home directory, missing
  seeds, or PNG out of sync with the notebook.

---

## Scoring template

The reviewer returns a table like:

```
| Dimension            | Score | Note                                  |
|----------------------|-------|---------------------------------------|
| Claim clarity        | 4     | Title states comparison, not verdict  |
| Data-ink ratio       | 5     | —                                     |
| Encoding discipline  | 3     | Category mapped to color + shape      |
| Axis honesty         | 5     | —                                     |
| Color choice         | 4     | Sequential but not colorblind-checked |
| Comparison support   | 5     | —                                     |
| Annotation economy   | 4     | Legend could be inline                |
| Reproducibility      | 5     | —                                     |
| **Total**            | 35/40 |                                       |
```

Followed by ≤ 5 revisions phrased as diff hints, each pointing at the
cell to edit. An empty revision list means ship.
