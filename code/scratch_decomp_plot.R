## ---------------------------------------------------------------------------
## SCRATCH / DRAFT plot: "decomposition" of one aggregate point-and-interval
##
## Goal: take a single point + CI from the RMSE-style aggregate plot
## (e.g. Network method, Male, youngest age group) and show the 27 city-level
## point estimates + CIs that feed into it, with the aggregate shown on the
## right-hand side. This illustrates how one point in fig_rmse is built.
##
## HOW TO RUN:
##   Run 99_vr_comparison.Rmd interactively up through the RMSE chunk so that
##   these objects exist in the environment:
##       asdr_properties_long        (city x sex x age x method)
##       asdr_agesex_properties_long (sex x age x method  -- the aggregate)
##       city.dat, comp_out_dir
##   Then:  source("scratch_decomp_plot.R")
##
## Column pair to plot is swappable, exactly like loss_plot():
##   RMSE : point_est_rmse    / se_jab_rmse_asdr_lopo
##   MARE : point_est_mare    / se_jab_mare_asdr_lopo
##   SE   : point_est_se      / se_jab_se_asdr_lopo
##   bias : point_est_bias    / se_jab_bias_asdr_lopo
## ---------------------------------------------------------------------------

library(tidyverse)
library(patchwork)

## Optional: map state_abbrev -> a nicer label for the x axis.
## Falls back to geo (state_abbrev) if city.dat is not available.
decomp_city_labels <- function() {
  if (exists("city.dat")) {
    city.dat %>%
      transmute(geo = state_abbrev,
                city_label = state_abbrev,
                region = region)
  } else {
    NULL
  }
}

## ---------------------------------------------------------------------------
## decomp_plot(): two-panel figure
##   Panel A (wide, left) : 27 city point estimates + CIs, sorted by value
##   Panel B (narrow, right): the single aggregate point estimate + CI
## Both panels share a y scale, and a dashed line marks the aggregate value
## across both, so you can see the aggregate sits at the mean of the cities.
## ---------------------------------------------------------------------------
decomp_plot <- function(cur_qoi_var,
                        cur_se_var,
                        ylab_text,
                        sel_method  = "Network",
                        sel_sex     = "Male",
                        sel_agegp10 = "[18,25)",
                        city_df   = asdr_properties_long,
                        agg_df    = asdr_agesex_properties_long) {

  ## ---- city-level data (the 27 inputs) ----
  city_plot_df <- city_df %>%
    filter(method == sel_method,
           sex == sel_sex,
           agegp10 == sel_agegp10) %>%
    mutate(cur_qoi = {{ cur_qoi_var }},
           cur_se  = {{ cur_se_var }},
           # truncate the lower CI bound at 0
           cur_ci_low  = pmax(0, cur_qoi - 1.96 * cur_se),
           cur_ci_high = cur_qoi + 1.96 * cur_se)

  labs <- decomp_city_labels()
  if (!is.null(labs)) {
    city_plot_df <- city_plot_df %>% left_join(labs, by = "geo")
  } else {
    city_plot_df <- city_plot_df %>% mutate(city_label = geo, region = NA_character_)
  }

  ## sort cities by point estimate so the plot reads as a caterpillar
  city_plot_df <- city_plot_df %>%
    mutate(city_label = fct_reorder(city_label, cur_qoi))

  ## ---- aggregate data (the single output point) ----
  agg_plot_df <- agg_df %>%
    filter(method == sel_method,
           sex == sel_sex,
           agegp10 == sel_agegp10) %>%
    mutate(cur_qoi = {{ cur_qoi_var }},
           cur_se  = {{ cur_se_var }},
           # truncate the lower CI bound at 0
           cur_ci_low  = pmax(0, cur_qoi - 1.96 * cur_se),
           cur_ci_high = cur_qoi + 1.96 * cur_se,
           #agg_label = "Aggregate")
           agg_label = "Average")

  agg_value <- agg_plot_df$cur_qoi[1]

  ## shared y range across both panels (include CIs from both)
  y_range <- range(c(city_plot_df$cur_ci_low, city_plot_df$cur_ci_high,
                     agg_plot_df$cur_ci_low, agg_plot_df$cur_ci_high),
                   na.rm = TRUE)

  xaxistext <- theme(axis.text.x = element_text(size = 6, angle = 90,
                                                hjust = 1, vjust = 0.5),
                     legend.title = element_blank())

  ## ---- Panel A: cities ----
  panel_cities <- city_plot_df %>%
    ggplot(aes(x = city_label, y = cur_qoi, ymin = cur_ci_low, ymax = cur_ci_high)) +
    #geom_hline(yintercept = agg_value, linetype = "dashed", color = "grey50") +
    geom_pointrange(fatten = 1.5) +
    ylim(y_range) +
    xlab("") + ylab(ylab_text) +
    ggtitle("City estimates") +
    theme_minimal() +
    xaxistext

  ## ---- Panel B: aggregate ----
  panel_agg <- agg_plot_df %>%
    ggplot(aes(x = agg_label, y = cur_qoi, ymin = cur_ci_low, ymax = cur_ci_high)) +
    #geom_hline(yintercept = agg_value, linetype = "dashed", color = "grey50") +
    geom_pointrange(color = "black", fatten = 1.5) +
    ylim(y_range) +
    xlab("") + ylab("") +
    ggtitle("Average") +
    theme_minimal() +
    theme(axis.text.x = element_text(size = 7)) +
    xaxistext

  ## ---- assemble ----
  fig_all <- panel_cities + panel_agg +
    plot_layout(widths = c(6, 1), guides = "collect") +
    plot_annotation(
      title = glue::glue("{sel_method} method - {sel_sex}, age {sel_agegp10}"),
      tag_levels = "A", tag_suffix = ")"
    ) &
    theme(legend.position = "bottom",
          plot.tag = element_text(face = "bold", size = 12))

  return(lst(fig = fig_all, city_df = city_plot_df, agg_df = agg_plot_df))
}

## ---------------------------------------------------------------------------
## Example call: unpack the RMSE aggregate point for Network / Male / youngest
## ---------------------------------------------------------------------------
fig_decomp_rmse <- decomp_plot(
  cur_qoi_var = point_est_rmse,
  cur_se_var  = se_jab_rmse_asdr_lopo,
  ylab_text   = "Estimated RMSE",
  sel_method  = "Network",
  sel_sex     = "Male",
  sel_agegp10 = "[18,25)"
)

fig_decomp_rmse$fig

## Save a scratch copy next to the other figures (comment out if not wanted)
if (exists("comp_out_dir")) {
  ggsave(filename = file.path(comp_out_dir, "scratch_decomp_rmse.pdf"),
         plot = fig_decomp_rmse$fig,
         height = 3.5, width = 8)
}
