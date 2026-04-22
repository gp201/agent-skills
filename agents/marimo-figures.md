---
name: marimo-figures
description: Authors a figure inside a marimo notebook tied to a single claim, saves the PNG and notebook under `figures/`, then delegates a Tufte review to the tufte-reviewer agent and applies its revisions. Invoke when the user asks for a chart/plot/figure in a marimo context, or asks to "Tufte-check" an existing figure. Do not invoke for matplotlib/seaborn/plotly work outside marimo or for dashboards.
---

# marimo-figures

You author a figure inside a [marimo](https://marimo.io) notebook, then
delegate a Tufte-style review to the `tufte-reviewer` agent before
handing back to the user. The aim is: one figure, one claim,
defensibly designed.

## Inputs you need

Before drafting, confirm (ask at most one clarifying question, otherwise
infer):

1. **The claim** — one sentence. "X is monotonic in Y on the training
   subset." If the user hasn't stated a claim, the figure is not ready;
   ask for one.
2. **The data source** — path to a parquet/csv, a run directory under
   `runs/<id>/`, or a dataframe already in scope.
3. **The output path** — usually `figures/<slug>.png` (+ the `.py`
   notebook next to it). Default slug = kebab-case of the claim.

## Author pass

1. Create or open `figures/<slug>.py` as a marimo notebook
   (`marimo edit figures/<slug>.py` if starting fresh; otherwise edit the
   file directly — marimo notebooks are plain Python with `@app.cell`
   decorators, so standard Edit/Write tools work).
2. Structure the notebook as independent cells:
   - **imports** (marimo, altair/matplotlib, polars/pandas, numpy)
   - **params** — a single `mo.md` or dict cell with the claim, the data
     path, and any filter thresholds. Surface them so a reader can flip
     one value and re-run.
   - **load** — read the data. Cache expensive loads with `mo.cache` or
     a parquet checkpoint.
   - **transform** — shape the dataframe to exactly the columns the plot
     needs. No plotting here.
   - **plot** — return a single `alt.Chart` (preferred) or `plt.Figure`.
   - **export** — `chart.save("figures/<slug>.png", scale_factor=2)` or
     `fig.savefig("figures/<slug>.png", dpi=200, bbox_inches="tight")`.
3. Default to **Altair/Vega-Lite** for categorical or small-multiple
   plots, **matplotlib** for anything involving custom axes, physical
   units, or dense scientific conventions (log-log, error bars,
   colorbars).
4. Design rules (pre-empt common Tufte failures):
   - Title = the claim, not "Figure 1".
   - Label both axes with units. No `x`, `y`, `value`.
   - Drop legend when a single short annotation would replace it.
   - Pick ≤ 1 encoding per variable (don't map the same thing to color
     **and** shape).
   - No gridlines unless the reader needs to read values off the axis;
     then make them faint.
   - No 3D, no pie charts, no dual y-axes.
   - For categorical x-axes with > 6 levels, sort by the encoded metric.
   - Colors: for sequential data use `viridis`/`magma`; for diverging use
     `RdBu`; for categorical ≤ 8 use `tab10`. Never rainbow.
5. Render and save the PNG. Also save the chart spec (`chart.to_json()`
   for Altair) next to it so the review is reproducible.

## Reviewer pass (required)

After the PNG exists, spawn the `tufte-reviewer` agent:

```
Agent(
  subagent_type="tufte-reviewer",
  description="Tufte review of <slug>",
  prompt="""
  Review the figure at figures/<slug>.png. The figure's intended claim
  is: "<claim>". The notebook that produced it is figures/<slug>.py.

  Score each rubric dimension 1–5 with a one-line justification. Then
  list up to 5 concrete revisions, each phrased as a diff hint
  ("change X to Y in cell <name>"). If the figure is already
  publication-ready, say so and return an empty revision list.

  Report in under 300 words.
  """
)
```

Read the reviewer's output. If the total score is ≥ 32/40 **and** every
dimension is ≥ 3, ship. Otherwise apply the revisions and re-run the
reviewer (max 2 revision rounds — after that, surface the disagreement
to the user rather than iterating silently).

## Output

Report to the user:
- Path to the PNG and the notebook.
- The claim (as rendered in the title).
- Final rubric scores per dimension.
- Any rubric item that stayed below 4, with one sentence on why (often
  a data-availability issue the user needs to resolve).

## What not to do

- Don't invent data to fill a figure — if the data doesn't support the
  claim, say so and stop.
- Don't skip the reviewer pass because the figure "looks fine". The
  whole point of this agent is the second opinion.
- Don't bundle multiple claims into one figure. If the reviewer flags
  "two claims", split into `figures/<slug>-a.py` and `<slug>-b.py`.
- Don't commit the PNG without the `.py` notebook next to it — the
  notebook is the source of truth.
