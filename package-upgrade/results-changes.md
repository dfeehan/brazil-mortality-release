# How the results changed

September 2026 upgrade of `siblingsurvival` / `networkreporting` /
`surveybootstrap` (commit `d9e85d0`). For the cause see
[sibling-code-changes.md](sibling-code-changes.md);
to undo it see
[reverting.md](reverting.md).

## Bottom line

**Network estimates: completely unchanged.** All 14 output files bit-identical.

**Sibling estimates: changed.** 46 of 270 city/age/sex death rates moved; deaths
falling inside the 7-year window went 950 → 943.

**Performance estimands (RMSE, standard error, bias): moved slightly**, entirely
on the sibling side — about 0.3% at city level, rising to about 5% nationally.

**No substantive conclusion in the paper changes**, but one counted claim did and
three borderline intervals crossed the significance threshold. Three reported
digits changed.

## Why the network side is untouched

The change is in the routine that assigns deaths to age × time cells. The network
estimator never calls it — `network.survival.estimator_()`, `kp.estimator_()` and
`report.aggregator_()` reference neither `occ.exp`, `compute_occ_exp`, nor
`cell_config`. Verified rather than assumed: a fresh `04` run under the new
packages reproduced the March output files exactly.

That result did double duty. `04_network_estimates.Rmd` has no `set.seed`
anywhere — it relies only on `future_options(seed = TRUE)` — so reproducing March
bit-for-bit also proves the network estimator consumes no RNG and that `04` is
deterministic despite the missing seed.

## Estimates

### Sibling deaths falling inside the estimation cells

| reporting window | old | new | net | cities affected |
|---|---|---|---|---|
| 7 years | 950 | 943 | **−7** | 9 of 27 |
| 12 months | 161 | 162 | **+1** | 15 of 27 |

Both directions, and proportionally much larger churn in the short window.
Sibling *counts* are unchanged (42,719 in both), as is total exposure — only
occurrences move.

### City age-specific death rates

| | |
|---|---|
| cells (city × age × sex) | 270 |
| unchanged | 224 (83%) |
| changed | **46 (17%)** — 26 down, 20 up |
| among changed, median \|relative change\| | 21% |
| 90th percentile | 86% |
| maximum | 197% |

Large relative swings because city cells contain few deaths, so ±1 death moves
them a lot.

## Performance estimands

All values per 1,000, with 95% jackknife-after-bootstrap intervals. "unadj" is
`vr_comparison`, "adj" is `vr_adj_comparison` (the VR-completeness sensitivity
analysis).

### Overall mean RMSE

| level | method | old | new | change |
|---|---|---|---|---|
| city (unadj) | network | 2.889 [2.599, 3.178] | 2.889 [2.599, 3.178] | **0.00%** |
| | sibling | 3.617 [3.360, 3.875] | 3.627 [3.369, 3.885] | +0.27% |
| | difference | −0.729 [−1.117, −0.340] | −0.739 [−1.128, −0.349] | −1.36% |
| region (unadj) | network | 1.852 [1.601, 2.103] | 1.852 [1.601, 2.103] | **0.00%** |
| | sibling | 1.883 [1.563, 2.203] | 1.914 [1.594, 2.235] | +1.68% |
| | difference | −0.031 [−0.446, 0.384] | −0.063 [−0.477, 0.352] | — |
| national (unadj) | network | 1.531 [1.178, 1.885] | 1.531 [1.178, 1.885] | **0.00%** |
| | sibling | 1.052 [0.571, 1.533] | 1.103 [0.624, 1.582] | +4.85% |
| | difference | 0.480 [−0.121, 1.081] | 0.429 [−0.169, 1.026] | −10.6% |
| city (adj) | sibling | 3.648 [3.392, 3.903] | 3.659 [3.402, 3.915] | +0.30% |
| region (adj) | sibling | 1.911 [1.589, 2.234] | 1.943 [1.621, 2.266] | +1.67% |
| national (adj) | sibling | 1.085 [0.598, 1.573] | 1.135 [0.651, 1.618] | +4.55% |

### Overall mean standard error

| level | method | old | new | change |
|---|---|---|---|---|
| city | network | 1.593 [1.385, 1.801] | 1.593 [1.385, 1.801] | **0.00%** |
| | sibling | 2.121 [1.928, 2.314] | 2.111 [1.918, 2.305] | −0.46% |
| | difference | −0.528 [−0.805, −0.251] | −0.519 [−0.796, −0.241] | +1.84% |
| region | sibling | 1.248 [1.068, 1.427] | 1.240 [1.060, 1.421] | −0.59% |
| national | sibling | 0.607 [0.332, 0.882] | 0.599 [0.324, 0.875] | −1.27% |

Standard errors are identical between the adjusted and unadjusted comparisons,
since sampling variance does not depend on the reference values.

### Overall mean bias

| level | method | old | new | change |
|---|---|---|---|---|
| city (unadj) | network | 0.680 [0.406, 0.954] | 0.680 [0.406, 0.954] | **0.00%** |
| | sibling | −0.685 [−1.079, −0.291] | −0.721 [−1.115, −0.328] | −5.30% |
| region (unadj) | sibling | −0.491 [−0.977, −0.004] | −0.542 [−1.026, −0.057] | −10.4% |
| national (unadj) | sibling | −0.490 [−1.103, 0.123] | −0.564 [−1.182, 0.054] | −15.2% |
| city (adj) | sibling | −0.773 [−1.167, −0.379] | −0.810 [−1.203, −0.416] | −4.70% |
| national (adj) | sibling | −0.549 [−1.162, 0.064] | −0.623 [−1.241, −0.005] | −13.5% |

### The pattern: the shift grows as you pool

| level | units averaged | sibling RMSE | sibling bias |
|---|---|---|---|
| city | 270 | +0.3% | −5% |
| region | 50 | +1.7% | −10% |
| national | 10 | +4.9% | −15% |

The 46 moved cells go in both directions, so they largely cancel when averaged
over 270 and barely cancel at all when collapsed to 10 national figures. Across
all 36 estimand × aggregation-level rows in `err_diffs_jab.csv` at city level:
median change 0.14%, maximum 5.30%.

## Conclusion changes

Every counted and threshold-based claim in the results section was checked.

### One counted claim changed — the manuscript was updated

The main text said:

> Eight of the ten age-sex groups have sibling estimates whose mean bias is not
> distinguishable from zero; the two exceptions are males and females aged 55-64.

**Females aged 45–54 now also excludes zero:**

```
old  -0.7019 [-1.5267, +0.1229]   includes zero
new  -0.8239 [-1.6104, -0.0374]   excludes zero
```

So it is now seven of ten, with three exceptions. Marginal — the new upper bound
is −0.037 — but it changes a counted statement, and the text was corrected.

### Three borderline intervals crossed zero

All knife-edge, none altering a substantive interpretation:

| quantity | old | new |
|---|---|---|
| region 47q18 RMSE difference (unadj) | −0.01365 [−0.02787, **+0.00056**] | −0.01496 [−0.02949, **−0.00043**] |
| region 47q18 MARE difference (adj) | −0.06734 [−0.13574, **+0.00105**] | −0.07539 [−0.14609, **−0.00469**] |
| national sibling bias (adj) | −0.549 [−1.162, **+0.064**] | −0.623 [−1.241, **−0.005**] |

The first two are plotted in the appendix pooling figure. The third is not used:
`06_plots.Rmd` filters `err_diffs_jab.csv` to `loss ∈ {rmse, mare}` and
`metric == 'diff'`, discarding per-method bias.

### One sign flip, immaterial

`vr_adj_comparison/city`, male `[25,35)` RMSE difference: +0.065 → −0.001. The
interval includes zero both before ([−0.689, 0.819]) and after ([−0.756, 0.755]),
so the paper's claim for that group — that the interval includes zero — holds
either way.

### Counts that did not change

| claim | old | new |
|---|---|---|
| age-sex groups where network bias excludes zero | 7 of 10 | 7 of 10 |
| age-sex groups where SE difference excludes zero | 6 of 10 | 6 of 10 |
| age-sex groups where MARE difference excludes zero | 7 of 10 | 7 of 10 |
| age-sex groups changing RMSE-difference verdict | — | **0 of 10** |

The appendix pooling story is intact: across the 24 quantities that figure plots,
zero sign flips, and for age-specific death rates the pattern the appendix argues
— city-level difference significant in favour of the network method, region and
national not distinguishable from zero — holds in every case.

## Numbers that changed in the paper

Three digits:

| location | old | new |
|---|---|---|
| main text, RMSE difference (`:533`) | 0.73 [0.34, 1.12] | **0.74 [0.35, 1.13]** |
| main text, SE difference (`:576`) | 0.53 [0.25, 0.81] | **0.52 [0.24, 0.80]** |
| appendix, 12-month table, `Sibling12mo` MARE | 1.5 | **1.6** |

Plus the bias sentence above. The appendix digit needs no edit — that table
renders from `avg_errs_with_sib12mo.rds`.

Everything else survives at reported precision: network RMSE 2.9, sibling RMSE
3.6, network SE 1.6, sibling SE 2.1, the young-male RMSE difference 1.6 [0.3,
3.0], and the 12-month table's RMSEs 3.6 and 7.0.

The full 12-month appendix table:

| method | RMSE old → new | MARE old → new |
|---|---|---|
| Network | 2.8885 → 2.8885 | 0.7619 → 0.7619 |
| Sibling (7 year) | 3.6173 → 3.6272 | 0.9072 → 0.9068 |
| Sibling (12 month) | 6.9624 → 6.9863 | 1.5258 → 1.5653 |

## A pre-existing discrepancy, unrelated to this upgrade

The main text says:

> For seven of the ten age-sex groups, the network method produced a lower
> estimated average standard error. For the remaining three age-sex groups, the
> confidence interval … includes zero.

The analysis gives **6 of 10 excluding zero and 4 including it** — and gives that
identically before *and* after the upgrade, so the prose drifted from the analysis
at some earlier point. (For completeness, 8 of 10 have a negative point estimate,
so no reading of the data produces 7/3.) This was left unchanged, as it is
outside the scope of the upgrade.

## How this was verified

Three controls, so the comparison could not be an artefact:

1. **Determinism.** Two independent `03` runs under the *unchanged* image
   differed by exactly 0 across all 18 output files, including the 2.7M-row
   bootstrap draws. So `future_options(seed = TRUE)` contributes no run-to-run
   variation.
2. **Provenance.** A fresh run under the pinned image reproduced the March 2026
   output files exactly, confirming the Docker image really is the environment
   that produced the published estimates and is therefore a sound baseline.
3. **Isolation.** Comparing all ~340 installed packages between the old and new
   images, *only* the three target packages changed version. No analysis
   dependency moved. (Five pkgdown/docs packages were added as a side effect of
   `dependencies=TRUE`; none is on the analysis path.)

`99_vr_comparison.Rmd` was run over both the old and the new estimates **in the
same container image**, for all six comparison × geography combinations, so the
only thing differing between the two sides was the estimate inputs. Comparisons
used a relative tolerance of 1e-10, treating anything below that as arithmetic
noise.

Both sides remain on disk under `~/pkgtrial/` if any of this needs re-examining.
