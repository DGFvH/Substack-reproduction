# Netherlands: CBS production index 85806NED, machinery (C28) and all manufacturing, 2021 = 100, seasonally and calendar
# adjusted (D6). Figure 2 (bottom panel), the 2019-2025 changes, and inputs for R/06_boom_bust.R.

source("R/00_helpers.R")

CBS_CODES <- c(`307500` = "C", `336500` = "C28")
nl_production_monthly <- fromJSON("Data/cbs_85806NED_A050903_1_prodindex_2005_c28_total.json")$value |>
  filter(grepl("MM", Perioden)) |>
  transmute(industry = CBS_CODES[BedrijfstakkenBranchesSBI2008], period = Perioden, production_index = Value,
            year = as.integer(substr(period, 1, 4)), month = as.integer(substr(period, 7, 8))) |>
  arrange(industry, year, month)
chk(nrow(nl_production_monthly) == 520 && !anyNA(nl_production_monthly) &&
      !anyDuplicated(nl_production_monthly[c("industry", "period")]) &&
      min(nl_production_monthly$period) == "2005MM01" && max(nl_production_monthly$period) == "2026MM08",
    "CBS 85806NED: machinery and all manufacturing, monthly from 2005MM01 to 2026MM08")
nl_production_year_means <- nl_production_monthly |> group_by(industry, year) |>
  summarise(mean_index = mean(production_index), n_months = n(), .groups = "drop")
chk(all(nl_production_year_means$n_months == ifelse(nl_production_year_means$year == 2026, 8, 12)), "CBS 85806NED: twelve months in every year 2005-2025, eight in 2026 (Jan-Aug)")
nl_index_mean <- function(industry_code, yr) nl_production_year_means$mean_index[nl_production_year_means$industry == industry_code & nl_production_year_means$year == yr]

add_num("prodindex_c28_change_2019_to_2025_pct", 100 * (nl_index_mean("C28", 2025) / nl_index_mean("C28", 2019) - 1), "percent",
        "Machinery (C28) production index, change from the 2019 to the 2025 annual mean (post: Industrial dependence, 'grew by 78%')", "D6")
add_num("prodindex_total_change_2019_to_2025_pct", 100 * (nl_index_mean("C", 2025) / nl_index_mean("C", 2019) - 1), "percent",
        "All-manufacturing production index, change from the 2019 to the 2025 annual mean (post: Industrial dependence, 'grew only 8%')", "D6")
