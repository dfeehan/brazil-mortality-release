# How to revert the September 2026 package upgrade

On 2026-09-29 this analysis moved to newer versions of `siblingsurvival`,
`networkreporting`, and `surveybootstrap` (commit `d9e85d0`). The sibling
estimates changed slightly as a result; see
[sibling-code-changes.md](sibling-code-changes.md)
for why and
[results-changes.md](results-changes.md)
for what moved.

This file explains how to undo it. There are four independent pieces: the source,
the results, the Docker image, and the manuscript. Reverting any one of them
alone leaves the others inconsistent, so unless you specifically want a partial
rollback, do all four.

## What the upgrade changed

| version pins (`DESCRIPTION:58-60`) | before | after |
|---|---|---|
| `dfeehan/surveybootstrap` | `1dda0de` (0.1.0.90000) | `a94ca647` (0.2.1) |
| `dfeehan/siblingsurvival` | `60959992414d01e388adf959da405ac18e58c2c0` (0.3.0) | `618ba642` (0.3.0.9000) |
| `dfeehan/networkreporting` | `4793aa9445143a9687af7ac4a4da21826d64bb1f` (0.3.1) | `6a9cefc1` (0.3.2) |

Plus one line of code: `code/03_sibling_estimates.Rmd` called
`siblingsurvival:::get_esc_reports()` (an unexported internal); that function
moved to `networkreporting` and is exported there, so the call is now
`networkreporting::get_esc_reports()`.

Note that the package maintainer does **not** bump `Version:` between commits, so
`packageVersion()` is not a reliable way to tell these apart. Check `RemoteSha`.

## 1. Revert the source

```sh
cd ~/Dropbox/brazil-mortality/brazil-mortality-release
git revert d9e85d0            # keeps history, preferred
# or, to erase it:  git reset --hard 71bfd91
```

`71bfd91` is the commit immediately before the upgrade.

## 2. Revert the results

The pre-upgrade `out/` was preserved before the new results were installed:

```sh
cd ~/Dropbox/brazil-mortality/brazil-mortality-release
rm -rf out
mv old-out-preupgrade-20260929 out
```

`old-out-preupgrade-20260929/` is an APFS clone, so it occupies almost no real
disk despite reporting ~12 GB. It is covered by `.gitignore` (`old-*`).

Sanity check that you have the old numbers back — the pre-upgrade sibling RMSE
was `3.617282`, the post-upgrade value is `3.627206`:

```sh
Rscript -e 'cat(read.csv("out/vr_comparison/city/rmse_tot_diff.csv")$est_rmse_sibling[1], "\n")'
```

## 3. Revert the Docker image

The pre-upgrade image was tagged before anything was rebuilt, so it still exists:

```sh
docker tag brazil-replication:pre-upgrade brazil-replication:latest
```

| tag | image | what it is |
|---|---|---|
| `brazil-replication:pre-upgrade` | `dde3ec73478b` | the original image, built 2026-03-06 |
| `brazil-replication:rebuild` | `88a9e1815746` | rebuilt from the Dockerfile with the new pins |
| `brazil-replication:latest` | currently `88a9e1815746` | whatever `run_docker.sh` will use |
| `brazil-replication:pkgnew` | `3155807124f5` | throwaway test image; safe to delete |

**Important:** `build_docker.sh` tags `-t brazil-replication` with no version, so
running it overwrites `latest` and can orphan whichever image you were relying
on. Tag before you build:

```sh
docker tag brazil-replication:latest brazil-replication:known-good
```

If you would rather rebuild from source than retag, revert `DESCRIPTION` first
(step 1) and then run `build_docker.sh`. A from-scratch rebuild was verified to
reproduce the tested environment exactly — all ~340 installed package versions
matched — so this is reliable. It needs no GitHub token in practice, though
`build_docker.sh` will pass `$GITHUB_PAT` if you have one set.

## 4. Revert the manuscript

Three numbers in `~/Dropbox/brazil-papers/brazil-mortality-paper/paper/brazil_mortality_v3.Rmd`
were updated for the new results:

| location | pre-upgrade | post-upgrade |
|---|---|---|
| RMSE difference (`:533`) | `0.73 deaths per thousand [0.34, 1.12]` | `0.74 deaths per thousand [0.35, 1.13]` |
| SE difference (`:576`) | `0.53 deaths per thousand [0.25, 0.81]` | `0.52 deaths per thousand [0.24, 0.80]` |
| sibling bias count (`:605`) | "Eight of the ten … the two exceptions are males and females aged 55-64" | "Seven of the ten … the three exceptions are males and females aged 55-64 and females aged 45-54" |

If those edits are still uncommitted:

```sh
git -C ~/Dropbox/brazil-papers/brazil-mortality-paper checkout paper/brazil_mortality_v3.Rmd
```

The appendix needs no revert: its 12-month table renders its numbers from
`avg_errs_with_sib12mo.rds`, so it follows whatever is in `out/`.

## What is *not* affected, and needs no reverting

- **`04_network_estimates.Rmd` and every network estimate.** Verified
  bit-identical across all 14 output files. The network code path never touches
  the routine that changed.
- **`00`, `01`, `02`** and everything they write (`data/vr_prepped/`, the sample
  maps, `vr_completeness_estimates.csv`). None of these scripts loads any of the
  three packages.
- **`99_vr_comparison.Rmd` and `06_plots.Rmd` source.** Neither loads the three
  packages; they only consume the estimate files. Their *outputs* do change,
  because their inputs did, which is why step 2 restores the whole `out/` tree
  rather than selected files.

## Re-running from scratch instead of restoring

If you would rather regenerate than restore, note the runtimes measured on this
machine (Intel i9-9880H, 7 workers, full 10,000 bootstrap replicates):

| step | runtime |
|---|---|
| `03_sibling_estimates.Rmd` | ~6.5 min |
| `04_network_estimates.Rmd` | ~4 h 35 min |
| `99_vr_comparison.Rmd`, per comparison × geography | ~20-90 min (city is slowest) |
| `06_plots.Rmd` | ~6 min |

Note that `06_plots.Rmd` stops early on purpose: a `knitr::knit_exit()` ends the
render partway through, so the sections after it (`rmse_barplot.*`,
`err_compare_all_vrsens.*`) are parked work-in-progress and are not produced. It
now says so in its output rather than exiting silently.

Do **not** run `00_run_all.R` casually: it re-downloads a ~6 GB `data.zip` from a
Dropbox URL commented as temporary, and unzips it over `data/`. Render the
individual `.Rmd` files instead.

To run a script against a scratch output directory rather than the real `out/`:

```sh
docker run --rm -w /home/rstudio \
  -v "$(pwd)":/home/rstudio \
  -v /path/to/scratch_out:/home/rstudio/out \
  --memory=40g brazil-replication:latest \
  Rscript -e 'rmarkdown::render("/home/rstudio/code/03_sibling_estimates.Rmd")'
```

`-w /home/rstudio` is required: without it the container's working directory
leaves `here::here()` resolving to `/` and outputs scatter.

## Comparison material kept from the upgrade

`~/pkgtrial/` holds both sides side by side, if you ever need to re-examine the
difference rather than just undo it:

| directory | contents |
|---|---|
| `out_old_run1/`, `out_old_run2/` | two independent `03` runs under the old packages (identical, which is how determinism was established) |
| `out_new/` | `03` + `04` + all six comparison trees under the new packages |
| `cmp_old/` | old-package estimates plus all six comparison trees rebuilt from them |
| `repo_march_net/`, `net_new/` | the network estimates, old and new (identical) |

These are outside the repo and can be deleted freely.
