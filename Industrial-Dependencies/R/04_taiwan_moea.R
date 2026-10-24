# Taiwan: MOEA industrial production index (d.csv, D22), 2021 = 100, monthly from 1982: total manufacturing (C) and the
# four manufacturing groups (I1 to I4). Figure 2 (middle panel), figure 3, the 2019-2025 changes, and inputs for
# R/06_boom_bust.R and R/07_manufacturing_by_economy.R.

source("R/00_helpers.R")

taiwan_production_monthly <- read_csv("Data/taiwan_manufacturing_monthly.csv", show_col_types = FALSE, col_types = cols(.default = "c"),
               locale = locale(encoding = "UTF-8"))
names(taiwan_production_monthly) <- c("item", "code", "name", "roc_period", "production_index", "unit")
# Periods use the Republic of China calendar: 11508 is August 2026 (year 115 + 1911).
taiwan_production_monthly <- taiwan_production_monthly |> mutate(code = trimws(code)) |>
  mutate(roc_period = trimws(roc_period), production_index = as.numeric(production_index),
         year = as.integer(substr(roc_period, 1, 3)) + 1911L, month = as.integer(substr(roc_period, 4, 5)))
chk(all(taiwan_production_monthly$unit == "110年=100") && setequal(taiwan_production_monthly$code, c("C", "I1", "I2", "I3", "I4")) &&
      !anyNA(taiwan_production_monthly$production_index) && all(taiwan_production_monthly$production_index > 0) &&
      !anyDuplicated(taiwan_production_monthly[c("code", "roc_period")]), "d.csv extract: five complete, unique production index series, 2021 = 100")
# One row per month, columns C and I1 to I4
taiwan_monthly_wide <- taiwan_production_monthly |> select(code, year, month, production_index) |>
  pivot_wider(names_from = code, values_from = production_index) |> arrange(year, month)
chk(!anyNA(taiwan_monthly_wide) && nrow(taiwan_monthly_wide) == 536 && min(taiwan_monthly_wide$year) == 1982 &&
      max(taiwan_monthly_wide$year * 100 + taiwan_monthly_wide$month) == 202608,
    "d.csv: total manufacturing (C) and I1 to I4 complete from January 1982 to August 2026")
taiwan_production_annual <- taiwan_production_monthly |> filter(year <= 2025) |> group_by(code, year) |>
  summarise(mean_index = mean(production_index), n_months = n(), .groups = "drop")
chk(all(taiwan_production_annual$n_months == 12) && min(taiwan_production_annual$year) == 1982, "d.csv: twelve months per series in every year 1982-2025")
taiwan_group_annual <- taiwan_production_annual |> filter(code != "C")
taiwan_manufacturing_annual <- taiwan_production_annual |> filter(code == "C")
taiwan_ict_annual <- taiwan_production_annual |> filter(code == "I2") |> arrange(year)
taiwan_index_mean <- function(group_code, yr) taiwan_production_annual$mean_index[taiwan_production_annual$code == group_code & taiwan_production_annual$year == yr]
taiwan_group_change_pct <- sapply(c(I2 = "I2", I3 = "I3", I4 = "I4"), function(g) 100 * (taiwan_index_mean(g, 2025) / taiwan_index_mean(g, 2019) - 1))
chk(taiwan_group_change_pct[["I3"]] < 0 && taiwan_group_change_pct[["I4"]] < 0, "Taiwan: chemicals (I3) and consumer goods (I4) fell from 2019 to 2025")

add_num("taiwan_i2_change_2019_2025_pct", taiwan_group_change_pct[["I2"]], "percent",
        "ICT and electronics (I2) production index, change from the 2019 to the 2025 annual mean (post: Industrial dependence, 'about 93%')", "D22")
add_num("taiwan_i3_change_2019_2025_pct", taiwan_group_change_pct[["I3"]], "percent",
        "Chemicals (I3) production index, change from the 2019 to the 2025 annual mean (post: Industrial dependence, 'decreased')", "D22")
add_num("taiwan_i4_change_2019_2025_pct", taiwan_group_change_pct[["I4"]], "percent",
        "Consumer goods (I4) production index, change from the 2019 to the 2025 annual mean (post: Industrial dependence, 'decreased')", "D22")
