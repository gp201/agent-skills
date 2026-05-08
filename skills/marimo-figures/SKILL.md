---
name: marimo-figures
description: Use when the user wants to build, refine, or "Tufte-check" a figure in a marimo notebook — phrases like "plot this", "make a figure", "visualize these results", "tufte review this plot", or any request to iterate on a chart inside a `.py` marimo notebook. Pairs an author pass with a reviewer subagent that scores the figure against Tufte's principles and returns concrete revisions. Do not invoke for matplotlib/seaborn/plotly work outside marimo or for dashboards.
---

# marimo-figures

Author a figure inside a [marimo](https://marimo.io) notebook, then run a
Tufte reviewer subagent over the rendered output before handing back to the
user. The aim is: one figure, one claim, defensibly designed.

## When to use

- The user asks for a chart/plot/figure and the surrounding workflow is
  marimo (or no tool has been picked yet and the data fits a notebook).
- The user explicitly requests a "Tufte review" of an existing figure.
- A `figures/` directory exists under an experiment laid out by
  `experiment-structure` and a new figure needs to land there.

Skip this skill for quick throwaway plots in a REPL, for dashboards, or
when the user explicitly asks for matplotlib/plotly scripts outside a
notebook.

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
   (`uv run marimo edit figures/<slug>.py` if starting fresh; otherwise edit
   the file directly — marimo notebooks are plain Python with `@app.cell`
   decorators, so standard Edit/Write tools work).
   Include PEP 723 metadata at the top for reproducibility:
   ```python
   # /// script
   # requires-python = ">=3.12"
   # dependencies = ["marimo", "seaborn", "matplotlib", "polars"]
   # ///
   ```
2. Structure the notebook as independent cells — each cell is a function
   whose parameters are other cells' return values (marimo manages
   dependencies automatically; do not mutate objects across cells):
   - **imports** (marimo, seaborn, matplotlib, polars/pandas, numpy)
   - **params** — a single `mo.md` or dict cell with the claim, the data
     path, and any filter thresholds. Surface them so a reader can flip
     one value and re-run. Use `mo.app_meta().mode == "script"` to swap
     the data source when running non-interactively instead of hiding widgets.
   - **load** — read the data. Gate slow loads with `@mo.cache` (see
     [Expensive notebooks](#expensive-notebooks) for other options).
   - **transform** — shape the dataframe to exactly the columns the plot
     needs. No plotting here.
   - **plot** — return a single `plt.Figure`. Only the final expression
     in a cell renders; don't nest it.
   - **export** — `fig.savefig("figures/<slug>.png", dpi=200,
     bbox_inches="tight")`.
3. **Default to seaborn** for figures — it sits on matplotlib with cleaner
   defaults for statistical plots. Drop to bare matplotlib only for custom
   axes, physical units, or dense scientific conventions (log-log, error
   bars, colorbars). Set label/font sizing once with
   `sns.set_context("notebook", font_scale=1)` and `sns.set_style("white")`.
   For an interactive figure with box/lasso selection, see
   [Interactive figures](#interactive-figures-preferred).
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
5. Render and save the PNG.

## Verify the notebook runs (required)

Before the reviewer pass, confirm the notebook is actually executable —
otherwise the PNG you're shipping may be stale.

```bash
uvx marimo check figures/<slug>.py   # lint: dependency / reactivity issues
uv run figures/<slug>.py             # script-mode execute end-to-end
```

Both must pass. `marimo check` catches missing dependencies and bad
cell graphs; `uv run` executes the notebook in script mode and will
re-emit the PNG. If `uv run` succeeds but the PNG didn't update, the
export cell isn't wired into the dependency graph — fix that before
shipping. See [Expensive notebooks](#expensive-notebooks) below if
execution is too slow to run end-to-end on every iteration.

## Reviewer pass (required)

After the PNG exists, spawn the `tufte-reviewer` agent. It owns the rubric
(8 dimensions, 1–5 each, ship bar ≥ 32/40 with no dimension below 3) and
returns scores plus up to 5 revisions as diff hints.

```
Agent(
  subagent_type="tufte-reviewer",
  description="Tufte review of <slug>",
  prompt="""
  Figure: figures/<slug>.png
  Notebook: figures/<slug>.py
  Claim: <claim>
  """
)
```

Read the reviewer's output. If it meets the ship bar, ship. Otherwise apply
the revisions and re-run the reviewer (max 2 revision rounds — after that,
surface the disagreement to the user rather than iterating silently).

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
  whole point of this skill is the second opinion.
- Don't skip the `marimo check` + `uv run` step — a notebook that
  doesn't run isn't a notebook.
- Don't bundle multiple claims into one figure. If the reviewer flags
  "two claims", split into `figures/<slug>-a.py` and `<slug>-b.py`.
- Don't commit the PNG without the `.py` notebook next to it — the
  notebook is the source of truth.

## UI elements

marimo has a rich set of UI components. The ones most useful for
figure-authoring are listed below. For anything else, query the live
docstring:

```bash
uv run --with marimo python -c "import marimo as mo; help(mo.ui.slider)"
```

### Interactive figures (preferred)

Wrap the axes with `mo.ui.matplotlib` for box (drag) / lasso
(`Shift`+drag) selection. The figure renders as a static image with a
selection overlay; the selection is available downstream as
`chart.value`.

```python
fig, ax = plt.subplots()
sns.scatterplot(data=df, x="x", y="y", ax=ax)
chart = mo.ui.matplotlib(ax)
chart
```

```python
mask = chart.value.get_mask(df["x"], df["y"])
selected = df[mask]
```

Reach for plotly only if you need hover tooltips or 3D.

### Other widgets

Names + use cases below. Run `help(mo.ui.X)` for signatures.

* `slider` / `range_slider` — drive a numeric param or filter range.
* `dropdown` — pick a column or category.
* `checkbox` — toggle a layer (e.g. error bars).
* `run_button` — gate an expensive re-render; pair with
  `mo.stop(not run_btn.value)`.
* `date` / `number` — exact inputs where a slider is too coarse.
* `table` — surface the underlying rows.
* `tabs` — stack alternative views of the same claim (raw / smoothed /
  residuals).
* `.batch().form()` on an `mo.md` template — collect several inputs and
  re-render only on submit; useful when each change is itself expensive.

## Expensive notebooks

When load / transform / render takes more than a couple seconds, pick
the lightest tool that solves your case:

* `mo.stop(cond, msg)` — halt a cell when a precondition isn't met.
* `mo.ui.run_button` + `mo.stop(not btn.value)` — gate an expensive
  render on an explicit click so slider tweaks don't trigger work
  mid-edit.
* `@mo.cache` — in-memory memoization for the kernel session.
* `@mo.persistent_cache` — disk cache across restarts; use for slow
  stable loads (large joins, model inference).
* `mo.lazy(thunk)` — defer rendering until a tab is selected or a table
  scrolls into view.

For notebooks that should never autorun, set
`[tool.marimo.runtime] on_cell_change = "lazy"` in `pyproject.toml`.

## Configuration

The PEP 723 block in [Author pass step 1](#author-pass) is the only
config that travels with the figure. For repo-wide defaults
(`[tool.marimo.runtime] on_cell_change`, `[tool.marimo.display]
default_width`, etc.), run `marimo config describe` for the full key
list and `marimo config show` to see what's currently active.

- Don't put per-figure dependencies in `pyproject.toml` — they belong in
  the PEP 723 block so `uv run figures/<slug>.py` works from a clean
  checkout.
- Don't set `theme = "dark"` for figures exported as PNGs — the saved
  figure inherits matplotlib rcParams, not the marimo theme.
