# Manufacturing production index (volume, not seasonally adjusted, annual), 2025 against 2019, for the 36 OECD members
# covered by the local snapshots and Taiwan, and author-calculated OECD-member and G7 weighted averages. Figure 1.
# Sources: Eurostat sts_inpr_a (D25) for EU members, Norway and Switzerland; OECD DF_INDSERV (D27, D31) for the other
# members; MOEA d.csv (D22) for Taiwan; World Bank 2019 manufacturing value added (D32) as weights.

source("R/00_helpers.R")
need("02_cbs_production_index.R")   # nl_index_mean
need("04_taiwan_moea.R")            # taiwan_manufacturing_annual

ECONOMIES <- tibble::tribble(
  ~name,            ~iso3, ~geo,   # geo: Eurostat code; NA = OECD data (MOEA for Taiwan)
  "Austria",        "AUT", "AT",
  "Belgium",        "BEL", "BE",
  "Estonia",        "EST", "EE",
  "Finland",        "FIN", "FI",
  "France",         "FRA", "FR",
  "Germany",        "DEU", "DE",
  "Greece",         "GRC", "EL",
  "Ireland",        "IRL", "IE",
  "Italy",          "ITA", "IT",
  "Latvia",         "LVA", "LV",
  "Lithuania",      "LTU", "LT",
  "Luxembourg",     "LUX", "LU",
  "Netherlands",    "NLD", "NL",
  "Portugal",       "PRT", "PT",
  "Slovakia",       "SVK", "SK",
  "Slovenia",       "SVN", "SI",
  "Spain",          "ESP", "ES",
  "Canada",         "CAN", NA,
  "Japan",          "JPN", NA,
  "United Kingdom", "GBR", NA,
  "United States",  "USA", NA,
  "Australia",      "AUS", NA,
  "Czechia",        "CZE", "CZ",
  "Denmark",        "DNK", "DK",
  "Israel",         "ISR", NA,
  "South Korea",    "KOR", NA,
  "New Zealand",    "NZL", NA,
  "Norway",         "NOR", "NO",
  "Sweden",         "SWE", "SE",
  "Switzerland",    "CHE", "CH",
  "Hungary",        "HUN", "HU",
  "Poland",         "POL", "PL",
  "Chile",          "CHL", NA,
  "Colombia",       "COL", NA,
  "Mexico",         "MEX", NA,
  "Turkey",         "TUR", NA,
  "Taiwan",         "TWN", NA)
OECD38 <- c("AUS", "AUT", "BEL", "CAN", "CHE", "CHL", "COL", "CRI", "CZE", "DEU", "DNK", "ESP", "EST", "FIN", "FRA", "GBR", "GRC", "HUN", "IRL", "ISL",
            "ISR", "ITA", "JPN", "KOR", "LTU", "LUX", "LVA", "MEX", "NLD", "NOR", "NZL", "POL", "PRT", "SVK", "SVN", "SWE", "TUR", "USA")
G7_ISO <- c("CAN", "FRA", "DEU", "ITA", "JPN", "GBR", "USA")
CHIP_ISO <- c("TWN", "KOR", "NLD")
QUARTERLY <- c("AUS", "NZL")   # quarterly observations used in the local snapshot

# ---- Index levels, 2019 and 2025 -----------------------------------------------------------------------------------
eurostat_manufacturing_raw <- read_csv("Data/eurostat_manufacturing_2019_2025.csv", show_col_types = FALSE, col_types = cols(.default = "c"))
chk(all(eurostat_manufacturing_raw$freq == "A") && all(eurostat_manufacturing_raw$s_adj == "NSA") &&
      all(eurostat_manufacturing_raw$indic_bt == "PRD") && all(eurostat_manufacturing_raw$nace_r2 == "C") &&
      all(eurostat_manufacturing_raw$unit == "I21") && all(eurostat_manufacturing_raw$TIME_PERIOD %in% c("2019", "2025")),
    "Eurostat sts_inpr_a: annual, not seasonally adjusted manufacturing production volume index, 2021 = 100, 2019 and 2025")
oecd_manufacturing_raw <- read_csv("Data/oecd_manufacturing_2019_2025.csv", show_col_types = FALSE, col_types = cols(.default = "c")) |>
  mutate(production_index = as.numeric(OBS_VALUE), year = as.integer(substr(TIME_PERIOD, 1, 4)))
chk(all(oecd_manufacturing_raw$ADJUSTMENT == "N") && all(oecd_manufacturing_raw$ACTIVITY == "C") &&
      all(oecd_manufacturing_raw$MEASURE == "PRVM") && all(oecd_manufacturing_raw$UNIT_MEASURE == "IX"),
    "OECD DF_INDSERV: manufacturing production volume index, neither seasonally nor calendar adjusted")
chk(!anyDuplicated(oecd_manufacturing_raw[c("REF_AREA", "FREQ", "TIME_PERIOD")]) &&
      !anyNA(oecd_manufacturing_raw$production_index) && all(is.finite(oecd_manufacturing_raw$production_index)) &&
      all(oecd_manufacturing_raw$production_index > 0) && all(oecd_manufacturing_raw$year %in% c(2019, 2025)) &&
      all(oecd_manufacturing_raw$FREQ == ifelse(oecd_manufacturing_raw$REF_AREA %in% QUARTERLY, "Q", "M")) &&
      all(ifelse(oecd_manufacturing_raw$FREQ == "Q",
                 grepl("^(2019|2025)-Q[1-4]$", oecd_manufacturing_raw$TIME_PERIOD),
                 grepl("^(2019|2025)-(0[1-9]|1[0-2])$", oecd_manufacturing_raw$TIME_PERIOD))),
    "OECD DF_INDSERV: unique economy/frequency/period observations, positive indices and valid monthly or quarterly periods")
chk(all(oecd_manufacturing_raw$source_dataset == ifelse(oecd_manufacturing_raw$REF_AREA %in% c("CHL", "COL", "MEX", "TUR"), "D31", "D27")),
    "OECD DF_INDSERV: source dataset identifiers match the two local snapshots")
# Annual index: Eurostat's annual value; for OECD data the mean of the year's months (quarters for Australia and New
# Zealand); for Taiwan the annual mean from R/04_taiwan_moea.R.
oecd_manufacturing_annual <- oecd_manufacturing_raw |>
  group_by(iso3 = REF_AREA, year) |>
  summarise(production_index = mean(production_index), n_periods = n(), .groups = "drop")
chk(all(oecd_manufacturing_annual$n_periods == ifelse(oecd_manufacturing_annual$iso3 %in% QUARTERLY, 4, 12)),
    "OECD DF_INDSERV: a full year of observations for every economy, 2019 and 2025")
taiwan_manufacturing_endpoints <- taiwan_manufacturing_annual |> filter(year %in% c(2019, 2025))
chk(nrow(taiwan_manufacturing_endpoints) == 2 && all(taiwan_manufacturing_endpoints$n_months == 12),
    "Taiwan: twelve monthly observations in each endpoint year")
manufacturing_index_levels <- bind_rows(
  eurostat_manufacturing_raw |>
    inner_join(ECONOMIES |> filter(!is.na(geo)) |> select(iso3, geo), by = "geo") |>
    transmute(iso3, year = as.integer(TIME_PERIOD), production_index = as.numeric(OBS_VALUE)),
  oecd_manufacturing_annual |> select(iso3, year, production_index),
  taiwan_manufacturing_endpoints |> transmute(iso3 = "TWN", year, production_index = mean_index))
chk(nrow(manufacturing_index_levels) == 74 && !anyDuplicated(manufacturing_index_levels[c("iso3", "year")]) &&
      setequal(manufacturing_index_levels$iso3, ECONOMIES$iso3) && n_distinct(manufacturing_index_levels$iso3) == 37 &&
      setequal(manufacturing_index_levels$year, c(2019, 2025)) && !anyNA(manufacturing_index_levels$production_index) &&
      all(is.finite(manufacturing_index_levels$production_index)) && all(manufacturing_index_levels$production_index > 0),
    "Figure 1: 74 unique positive index levels covering both endpoint years for all 37 economies")
manufacturing_by_economy <- ECONOMIES |>
  left_join(pivot_wider(manufacturing_index_levels, names_from = year, names_prefix = "index_", values_from = production_index), by = "iso3") |>
  mutate(source = case_when(iso3 == "TWN" ~ "moea", !is.na(geo) ~ "eurostat", TRUE ~ "oecd"),
         dataset = case_when(source == "moea" ~ "D22", source == "eurostat" ~ "D25", iso3 %in% c("CHL", "COL", "MEX", "TUR") ~ "D31", TRUE ~ "D27"),
         change_2019_2025_pct = 100 * (index_2025 / index_2019 - 1)) |>
  select(name, iso3, geo, source, dataset, index_2019, index_2025, change_2019_2025_pct)
chk(nrow(manufacturing_by_economy) == 37 && !anyNA(manufacturing_by_economy$change_2019_2025_pct),
    "Figure 1: a 2019 to 2025 change for all 37 economies")

# ---- Cross-check against the national source -------------------------------------------------------------------------
nl_eurostat_change_pct <- manufacturing_by_economy$change_2019_2025_pct[manufacturing_by_economy$iso3 == "NLD"]
nl_cbs_change_pct <- 100 * (nl_index_mean("C", 2025) / nl_index_mean("C", 2019) - 1)
chk(abs(nl_eurostat_change_pct - nl_cbs_change_pct) < 1,
    sprintf("Netherlands: Eurostat (%.2f%%) and CBS, seasonally adjusted (%.2f%%), agree within 1 point", nl_eurostat_change_pct, nl_cbs_change_pct))

# ---- OECD and G7 averages ------------------------------------------------------------------------------------------
# These are author-calculated fixed-weight averages, not official OECD or G7 aggregates: members' changes weighted by
# 2019 manufacturing gross value added in current US$. Costa Rica and Iceland are outside the local index snapshots.
worldbank_manufacturing_value_added <- fromJSON("Data/worldbank_NV.IND.MANF.CD_2019_oecd38.json", simplifyVector = TRUE)[[2]]
chk(all(worldbank_manufacturing_value_added$indicator$id == "NV.IND.MANF.CD") &&
      all(worldbank_manufacturing_value_added$date == "2019") &&
      setequal(worldbank_manufacturing_value_added$countryiso3code, OECD38) &&
      nrow(worldbank_manufacturing_value_added) == 38 && !anyDuplicated(worldbank_manufacturing_value_added$countryiso3code) &&
      !anyNA(worldbank_manufacturing_value_added$value) && all(is.finite(worldbank_manufacturing_value_added$value)) &&
      all(worldbank_manufacturing_value_added$value > 0),
    "World Bank: unique positive 2019 manufacturing value-added weights for all 38 OECD members")
oecd_manufacturing <- manufacturing_by_economy |> filter(iso3 %in% OECD38) |>
  left_join(tibble(iso3 = worldbank_manufacturing_value_added$countryiso3code,
                   va2019_usd = worldbank_manufacturing_value_added$value), by = "iso3")
chk(nrow(oecd_manufacturing) == 36 && setequal(setdiff(OECD38, oecd_manufacturing$iso3), c("CRI", "ISL")) &&
      !anyNA(oecd_manufacturing$va2019_usd) && all(oecd_manufacturing$va2019_usd > 0),
    "Figure 1: local index snapshots cover 36 OECD members, excluding Costa Rica and Iceland, with positive weights")
manufacturing_weighted_change_pct <- function(economies) {
  sum(economies$va2019_usd * economies$change_2019_2025_pct) / sum(economies$va2019_usd)
}
g7_manufacturing <- oecd_manufacturing |> filter(iso3 %in% G7_ISO)
oecd_weighted_change_pct <- manufacturing_weighted_change_pct(oecd_manufacturing)
g7_weighted_change_pct <- manufacturing_weighted_change_pct(g7_manufacturing)
chip_linked_manufacturing <- manufacturing_by_economy |> filter(iso3 %in% CHIP_ISO)
add_num("fig1_oecd_avg_weighted_change_2019_2025_pct", oecd_weighted_change_pct, "percent",
        "Author-calculated change in the manufacturing production index from 2019 to 2025 for 36 OECD members, fixed 2019 manufacturing gross value added in current US$ weights; not an official aggregate (post: figure 1)", "D25;D27;D31;D32")
add_num("fig1_g7_avg_weighted_change_2019_2025_pct", g7_weighted_change_pct, "percent",
        "Author-calculated G7 change in the manufacturing production index from 2019 to 2025, fixed 2019 manufacturing gross value added in current US$ weights; not an official aggregate (post: figure 1)", "D25;D27;D32")
for (iso in c(G7_ISO, CHIP_ISO)) {
  economy <- manufacturing_by_economy[manufacturing_by_economy$iso3 == iso, ]
  add_num(paste0("mfg_change_2019_2025_pct_", tolower(iso)), economy$change_2019_2025_pct, "percent",
          paste0("Manufacturing production index, change from 2019 to 2025, ", economy$name, " (post: figure 1)"), economy$dataset)
}

# ---- Claims in the text and caption --------------------------------------------------------------------------------
g7_n_below_2019 <- sum(g7_manufacturing$change_2019_2025_pct < 0)
chk(g7_n_below_2019 == 6 && g7_manufacturing$change_2019_2025_pct[g7_manufacturing$iso3 == "GBR"] > 0,
    "Figure 1: six of the seven G7 economies are below 2019, all but the United Kingdom")
add_num("fig1_g7_n_below_2019_in_2025", g7_n_below_2019, "economies",
        "G7 economies whose 2025 manufacturing production index is below 2019 (post: Industrial dependence and figure 1)", "D25;D27")
add_num("fig1_oecd_n_members_with_index", nrow(oecd_manufacturing), "economies",
        "OECD members covered by the local manufacturing-index snapshots, all included in the author-calculated weighted average (post: figure 1)", "D25;D27;D31")
add_num("fig1_oecd_n_above_2019_in_2025", sum(oecd_manufacturing$change_2019_2025_pct > 0), "economies",
        "OECD members in the local snapshots whose 2025 manufacturing production index is above 2019 (post: figure 1, 'most are above 2019')", "D25;D27;D31")
ranked_manufacturing <- bind_rows(oecd_manufacturing, manufacturing_by_economy |> filter(iso3 == "TWN")) |>
  arrange(desc(change_2019_2025_pct)) |> mutate(rank = row_number())
chk(all(ranked_manufacturing$rank[ranked_manufacturing$iso3 %in% CHIP_ISO] <= nrow(ranked_manufacturing) / 2),
    "Figure 1: Taiwan, South Korea and the Netherlands rank in the top half by all-manufacturing index change among the covered OECD members plus Taiwan")
add_num("fig1_oecd_plus_taiwan_n", nrow(ranked_manufacturing), "economies",
        "The 36 OECD members in the local snapshots plus Taiwan: the comparison set for ranks by all-manufacturing index change (post: Industrial dependence)", "D22;D25;D27;D31")
for (iso in CHIP_ISO) {
  add_num(paste0("fig1_rank_in_oecd_plus_taiwan_", tolower(iso)), ranked_manufacturing$rank[ranked_manufacturing$iso3 == iso], "rank (1 = largest rise)",
          paste0("Rank of ", ranked_manufacturing$name[ranked_manufacturing$iso3 == iso], " by all-manufacturing index change from 2019 to 2025 among the 36 covered OECD members and Taiwan (post: Industrial dependence, 'top half')"), "D22;D25;D27;D31")
}
