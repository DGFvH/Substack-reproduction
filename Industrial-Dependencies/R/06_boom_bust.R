# Boom and bust: past falls of Taiwan's ICT and electronics output (I2) and Dutch machinery (C28), their weight in total
# manufacturing, and the change in total output if the largest fall happened again now (arithmetic, not a forecast).
# Post: Industry prospects and figure 3. Data: D22 (Taiwan), D6 and D3 (Netherlands).

source("R/00_helpers.R")
need("02_cbs_production_index.R")   # nl_production_year_means, nl_index_mean
need("04_taiwan_moea.R")            # taiwan_ict_annual, taiwan_monthly_wide

# A fall runs from a peak (the running maximum) to the lowest point before the series regains that peak.
# Returns one row per fall, largest first.
drawdown_episodes <- function(t, v) {
  stopifnot(length(t) == length(v), !anyNA(t), !anyNA(v), all(is.finite(v)), all(v > 0), !anyDuplicated(t), !is.unsorted(t))
  empty <- data.frame(peak_year = t[FALSE], trough_year = t[FALSE], fall_pct = numeric())
  if (!length(v)) return(empty)
  below <- v < cummax(v)
  if (!any(below)) return(empty)
  eps <- lapply(split(seq_along(v), cumsum(c(TRUE, diff(below) != 0))), function(idx) {
    if (!below[idx[1]]) return(NULL)
    prior <- seq_len(idx[1] - 1L)
    pk <- tail(prior[v[prior] == max(v[prior])], 1)
    tr <- idx[which.min(v[idx])]
    data.frame(peak_year = t[pk], trough_year = t[tr], fall_pct = 100 * (v[tr] / v[pk] - 1))
  })
  eps <- do.call(rbind, eps)
  eps[order(eps$fall_pct), ]
}

# ---- Taiwan: falls of ICT and electronics (I2), annual means 1982-2025 ---------------------------------------------
taiwan_ict_declines <- taiwan_ict_annual |>
  transmute(peak_year = lag(year), trough_year = year, trough_index = mean_index,
            fall_pct = 100 * (mean_index / lag(mean_index) - 1)) |>
  filter(!is.na(fall_pct), fall_pct < 0) |> arrange(fall_pct)
chk(nrow(taiwan_ict_declines) == sum(diff(taiwan_ict_annual$mean_index) < 0), "Taiwan I2: decline count measures falling years, not drawdown episodes")
add_num("taiwan_i2_fall_count_annual_1982_2025", nrow(taiwan_ict_declines), "count",
        "Years in which the ICT and electronics (I2) annual mean fell, 1982-2025 (post: Industry prospects, 'six of the years')", "D22")
add_num("taiwan_i2_largest_fall_pct", taiwan_ict_declines$fall_pct[1], "percent",
        sprintf("Largest fall of the I2 annual mean, %s to %s (post: Industry prospects and figure 3, '16%%')", taiwan_ict_declines$peak_year[1], taiwan_ict_declines$trough_year[1]), "D22")
add_num("taiwan_i2_second_fall_pct", taiwan_ict_declines$fall_pct[2], "percent",
        sprintf("Second-largest fall of the I2 annual mean, %s to %s (post: figure 3, '-14%%')", taiwan_ict_declines$peak_year[2], taiwan_ict_declines$trough_year[2]), "D22")

# ---- Taiwan: weight of I2 in total manufacturing (MOEA d.csv, D22) -------------------------------------------------
# This within-2026 linear approximation recovers the total to rounding, not official published weights.
# Its fit alone does not establish the publisher's index methodology.
taiwan_weight_fit_2026 <- lm(C ~ 0 + I1 + I2 + I3 + I4, data = taiwan_monthly_wide[taiwan_monthly_wide$year == 2026, ])
taiwan_weight_fit_2021_2026 <- lm(C ~ 0 + I1 + I2 + I3 + I4, data = taiwan_monthly_wide[taiwan_monthly_wide$year >= 2021, ])
chk(max(abs(residuals(taiwan_weight_fit_2026))) <= 0.02 && max(abs(residuals(taiwan_weight_fit_2021_2026))) > 0.1,
    "d.csv: the 2026 weights reproduce C to rounding; one set of weights for 2021-2026 does not")
taiwan_jan_jul_2026 <- taiwan_monthly_wide |> filter(year == 2026, month <= 7)
taiwan_ict_index_contribution_share_jan_jul_2026 <- coef(taiwan_weight_fit_2026)[["I2"]] * mean(taiwan_jan_jul_2026$I2) / mean(taiwan_jan_jul_2026$C)
chk(taiwan_ict_index_contribution_share_jan_jul_2026 > 0 && taiwan_ict_index_contribution_share_jan_jul_2026 < 1, "Taiwan: inferred I2 index contribution lies between zero and one")
add_num("taiwan_i2_index_contribution_share_jan_jul_2026", taiwan_ict_index_contribution_share_jan_jul_2026, "estimated index contribution share (0-1)",
        "Estimated I2 contribution to Taiwan's manufacturing index, Jan-Jul 2026; coefficient fitted to Jan-Aug 2026 times mean I2 / mean C; not nominal output share or official weight (post: 'about 72%')", "D22")
add_num("taiwan_total_mfg_change_if_i2_repeats_largest_fall_pct", taiwan_ict_index_contribution_share_jan_jul_2026 * taiwan_ict_declines$fall_pct[1], "percent",
        "Scenario change in Taiwan's manufacturing index at Jan-Jul 2026 levels if I2 repeated its largest annual fall, other groups and inferred coefficients held fixed; not a forecast (post: 'about 11%')", "D22")

# ---- Netherlands: falls of machinery (C28), annual means 2005-2025 -------------------------------------------------
nl_machinery_annual <- nl_production_year_means |> filter(industry == "C28", year <= 2025) |> arrange(year)
nl_machinery_drawdowns <- drawdown_episodes(nl_machinery_annual$year, nl_machinery_annual$mean_index)
add_num("nl_c28_largest_fall_pct", nl_machinery_drawdowns$fall_pct[1], "percent",
        sprintf("Largest peak-to-trough fall of machinery's annual mean since 2005, %s to %s (post: Industry prospects, '22%%')", nl_machinery_drawdowns$peak_year[1], nl_machinery_drawdowns$trough_year[1]), "D6")
# Approximate the contribution using 2025 nominal GVA shares, updated by relative production-index movements.
# This is an assumption for the scenario, not an official CBS index weight.
nl_gva_2025 <- read_csv("Data/nl_manufacturing_machinery_gva_2025.csv", show_col_types = FALSE)
chk(nrow(nl_gva_2025) == 2 && setequal(nl_gva_2025$nace_r2, c("C", "C28")) &&
      all(nl_gva_2025$TIME_PERIOD == 2025) && all(nl_gva_2025$unit == "CP_MEUR") &&
      all(nl_gva_2025$na_item == "B1G") && !anyNA(nl_gva_2025$OBS_VALUE), "nama_10_a64: 2025 gross value added of manufacturing and machinery, current EUR million")
nl_machinery_gva_share_2025 <- nl_gva_2025$OBS_VALUE[nl_gva_2025$nace_r2 == "C28"] / nl_gva_2025$OBS_VALUE[nl_gva_2025$nace_r2 == "C"]
nl_machinery_index_contribution_share_jan_aug_2026 <- nl_machinery_gva_share_2025 *
  (nl_index_mean("C28", 2026) / nl_index_mean("C28", 2025)) / (nl_index_mean("C", 2026) / nl_index_mean("C", 2025))
add_num("nl_c28_index_contribution_pct_jan_aug_2026", 100 * nl_machinery_index_contribution_share_jan_aug_2026, "estimated index contribution (percent)",
        "Estimated C28 contribution to the manufacturing index, Jan-Aug 2026, from its 2025 nominal GVA share updated by relative index changes; not official CBS weights (post: 'about a quarter')", "D3;D6")
add_num("nl_total_mfg_change_if_c28_repeats_largest_fall_pct", nl_machinery_index_contribution_share_jan_aug_2026 * nl_machinery_drawdowns$fall_pct[1], "percent",
        "Scenario change in the Dutch manufacturing index at Jan-Aug 2026 levels if machinery repeated its largest peak-to-trough fall, other industries and assumed contribution weights held fixed (post: '6%')", "D3;D6")

# ---- Korea ---------------------------------------------------------------------------------------------------------
# No Korean semiconductor output/weight series is included; the capacity series cannot substitute for it.
