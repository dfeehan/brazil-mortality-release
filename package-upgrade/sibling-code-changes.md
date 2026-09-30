# What changed in the sibling estimation code

September 2026 upgrade of `siblingsurvival` / `networkreporting` /
`surveybootstrap` (commit `d9e85d0`). This file explains the one behavioural
change and the package reorganisation around it. For the numbers, see
[results-changes.md](results-changes.md);
to undo it, see
[reverting.md](reverting.md).

## Summary

One substantive change, in compiled code: **the half-open interval used to decide
whether a death falls inside an estimation cell flipped from closed-on-the-right
to closed-on-the-left.** Exposure is computed identically; only the
*event-inclusion test* changed. Everything else in the upgrade is
reorganisation — functions moving between the two packages — with no change in
what they compute.

## The change

`src/compute_occ_exp.cpp`, in the routine that intersects a sibling's
observation window with an estimation cell. Old (`siblingsurvival` @ `60959992`)
versus new (`networkreporting` @ `6a9cefc1`):

```c
- if (a[2] > result[0] && a[2] <= result[1]) {    // event counted in (start, finish]
+ if (a[2] >= result[0] && a[2] <  result[1]) {   // event counted in [start, finish)
```

`a[2]` is the event time (the death); `result[0]` and `result[1]` are the start
and end of the intersected window. Note that the old file carried the new line
directly above it, commented out — this was a known, deliberated toggle rather
than an accident, and it has now been flipped.

## Why (the upstream rationale)

The new source documents the reasoning, which is a correctness argument rather
than a preference:

> The left-closed form matters at the edges of the observation period. An event
> in the very first month of a window contributes exposure to that window, so it
> must also be able to be counted there; closing on the right instead would take
> the exposure and drop the event, leaving the numerator and denominator
> disagreeing about whether that month is in the window. It also puts an event
> exactly on an age-group boundary into the later group, which is what
> `floor((death - dob)/width)` does and what The DHS Program's own tabulation
> code assumes.

So there are two arguments: internal consistency between the numerator
(occurrences) and denominator (exposure) of the death rate, and agreement with
the standard DHS tabulation convention for age at death.

## What this does mechanically

Two kinds of death move:

1. **A death exactly on an age-group boundary** now falls in the *later* age
   group. Someone who dies in the month they turn 35 is counted in `[35,45)`
   rather than `[25,35)`.
2. **A death exactly at the closing edge** of a window or age range is now
   *excluded* rather than included, because the interval is open on the right.

Deaths in the interior of a cell are unaffected, which is why the aggregate
effect is small even though individual cells move.

## Verified behaviour on this dataset

Isolating `get_esc_reports()` on one city (Rio de Janeiro, which shows the
largest change) under both package versions, with identical inputs:

| | old | new |
|---|---|---|
| rows returned | 17,295 | 17,295 |
| distinct siblings | 2,750 | 2,750 |
| total exposure | 17,585.08 | **17,585.08** (unchanged) |
| rows with changed exposure | — | **0** |
| deaths counted | 82 | **79** |
| rows with changed occurrence | — | 5 |

The five records that moved:

| sibling | age group | occurrence | exposure in that cell |
|---|---|---|---|
| 48160 | `[55,65)` | 1 → 0 | 7.00 yr |
| 30041 | `[55,65)` | 1 → 0 | 7.00 yr |
| 21372 | `[25,35)` | 1 → 0 | 2.92 yr |
| 21372 | `[35,45)` | 0 → 1 | 0.083 yr |
| 21174 | `[25,35)` | 1 → 0 | 6.00 yr |

Sibling 21372 is case (1) above: a death on the 35th-birthday boundary, moved
into the cell where that sibling had exactly one month of exposure. The other
three are case (2): deaths at a closing edge, now excluded.

That exposure is bit-identical while occurrences move is the signature of this
specific change, and is how it was distinguished from anything else in the
upgrade.

## Aggregate effect on reported deaths

| reporting window | old | new | net | cities affected |
|---|---|---|---|---|
| 7 years before interview | 950 | 943 | **−7** | 9 of 27 |
| 12 months before interview | 161 | 162 | **+1** | 15 of 27 |

Changes go in both directions. The 12-month window churns far harder relative to
its size — 15 of 27 cities on a base of 161 deaths — which is expected: a short
window is mostly boundary, so a boundary rule change touches proportionally more
of it.

## What did *not* change

Confirmed by diffing sources at the two pinned commits and by comparing the
installed function bodies:

- `occ_exp.R` — byte-identical. The R-level wrapper is unchanged; only the
  compiled routine beneath it changed.
- `get_esc_reports.R` — differs only in comments and roxygen.
- `cell_config.R` — one change, which does **not** affect this analysis. A final
  `else` that used to `stop("No time periods specified.")` was split into
  `else if (is.null(time.periods))` plus a new branch accepting a custom
  `make.time.periods()` object. This analysis passes the string shortcuts
  `'7yr_beforeinterview'` and `'12mo_beforeinterview'`, which take an earlier
  branch that is unchanged. (The two `make.time.periods()` objects built at
  `03:185` and `03:189` are dead assignments — never referenced.)
- `make.age.groups()`, `make.time.periods()` — unchanged.
- **The whole network path.** `network.survival.estimator_()`, `kp.estimator_()`,
  and `report.aggregator_()` never call `occ.exp`, `compute_occ_exp`, or
  `cell_config`, so this change cannot reach them. Verified empirically: all 14
  network output files are bit-identical.

## Package reorganisation (no behavioural effect)

The estimator "spine" moved from `siblingsurvival` into `networkreporting` so it
could be shared with non-sibling ties.

- **`sibling_estimator()` is now a wrapper** over
  `networkreporting::network_survival_estimator()`. Upstream states its
  signature, defaults, and output are unchanged, and that the DHS and MICS
  validation harnesses reproduce byte-identically. It still supplies the clique
  tie, renames `alter.age` back to `sib.age`, and reports mistyped columns using
  the caller's own argument names.
- **`cell_config()`, `make.time.periods()`, `make.age.groups()`, `occ.exp()`** and
  others now live in `networkreporting` and are re-exported from
  `siblingsurvival` unchanged — each re-exported name *is* the networkreporting
  object. So `siblingsurvival::cell_config()` in `03` keeps working untouched.
- **`get_esc_reports()`** also moved, and is now **exported** from
  `networkreporting`. It was previously an unexported internal of
  `siblingsurvival`, which `03` reached through `:::`. This is the one source
  change the upgrade required:

  ```r
  # code/03_sibling_estimates.Rmd:304
  - esc_dat <- siblingsurvival:::get_esc_reports(...)
  + esc_dat <- networkreporting::get_esc_reports(...)
  ```

  Same four argument names (`sib.dat`, `sib.id`, `ego.id`, `cell.config`); their
  order changed, which is harmless because every call site passes them by name.
- **New optional arguments** on `sibling_estimator()`: a `visibility` rule
  (defaulting to `vis_from_clique()`, which is exactly the historical behaviour —
  `1/y.F` for an on-frame sibling, `1/(y.F + 1)` otherwise) and a `tie` that can
  carry `ego.in.group` and its own `frame.indicator`. Both default to the
  existing behaviour; this analysis passes neither.

## `surveybootstrap`

Upgraded from `1dda0de` (0.1.0.90000) to `a94ca647` (0.2.1), but nothing in this
repo calls it. It matters only because
`networkreporting::network.survival.estimator_()` calls
`surveybootstrap:::vcat()` internally, so the two have to move together.

Its 0.2.x changes are all about *generating* bootstrap weights — a
`boot_weight_rep.N` → `boot_weight_N` column rename, a `weight.scale` /
`weight_scale` mismatch fix, a single-PSU warning. This analysis does not
generate weights: all 10,000 replicate weights are read pre-computed from
`data/survey/bootstrap_weights_*.rds` and the PSU counts from
`bootstrap_cc_jab10k.rds`, and nothing in the repo writes those files. So none of
it applies here.

## A note for future upgrades

Three places in this analysis are coupled to package internals and would break
quietly rather than loudly:

1. `04_network_estimates.Rmd:321-335` and `:409-423` recompute the network
   estimator by hand from five internal columns of `boot.estimates`
   (`y.F.Dcell.hat`, `y.Fcell.kp.hat`, `N.F.hat`, `N.Fcell.hat`,
   `total.kp.size`). If that decomposition is ever restructured, the regional and
   national network numbers change with no error.
2. Seven `$`-on-list extractions (`$asdr.agg`, `$boot.asdr.agg`,
   `$boot.estimates`) return `NULL` rather than erroring if a name changes,
   yielding an empty frame from the `future_*_dfr` bind.
3. `03` assumes `sex` is numeric-coded 1/2 at `:428`, `:535`, `:607`, `:813`; a
   coding change would silently make everything `'female'`.

Also: `04` still calls the now-deprecated `network.survival.estimator_()`. That
is deliberate and currently unavoidable — the new generic cannot express this
design, because it needs an ego × alter roster and this survey collects aggregate
network-size reports plus known populations, and because it has no equivalent of
`within.alter.weights`. Upstream keeps the entry point alive for exactly these
two reasons. The `.Deprecated()` warning it emits is currently swallowed by the
`tryCatch`/`withCallingHandlers` wrapper inside the furrr workers, so its
eventual removal would arrive without visible warning.
