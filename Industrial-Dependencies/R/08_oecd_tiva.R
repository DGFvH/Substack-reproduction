# OECD Trade in Value Added, 2025 edition (D29; data to 2022): gross exports as a share of gross output, for computer,
# electronic and optical products (C26) in the Netherlands, Germany, South Korea and Taiwan, and for motor vehicles (C29)
# in Germany and South Korea. Post: International dependence ("53 to 79%", "45%", "34%").

source("R/00_helpers.R")

tiva_exports_output_raw <- read_csv("Data/oecd_tiva2025_exports_output_2022.csv", show_col_types = FALSE, col_types = cols(.default = "c"))
chk(all(grepl("TiVA\\) 2025 edition", tiva_exports_output_raw$STRUCTURE_NAME)) &&
      all(tiva_exports_output_raw$UNIT_MEASURE == "USD") && all(tiva_exports_output_raw$UNIT_MULT == "6") &&
      all(tiva_exports_output_raw$COUNTERPART_AREA == "W") && all(tiva_exports_output_raw$FREQ == "A") &&
      all(tiva_exports_output_raw$TIME_PERIOD == "2022") &&
      all(tiva_exports_output_raw$MEASURE %in% c("EXGR", "PROD")) &&
      all(tiva_exports_output_raw$Measure == ifelse(tiva_exports_output_raw$MEASURE == "EXGR", "Gross exports", "Production, gross output")),
    "TiVA: 2025 edition, annual 2022 gross exports and gross output, USD million, partner World")
chk(!anyDuplicated(tiva_exports_output_raw[c("REF_AREA", "ACTIVITY", "MEASURE", "TIME_PERIOD")]),
    "TiVA 2022: unique economy/industry/measure/year observations")
tiva_exports_output <- tiva_exports_output_raw |>
  transmute(iso3 = REF_AREA, industry = ACTIVITY,
            measure = ifelse(MEASURE == "EXGR", "gross_exports_usd_m", "gross_output_usd_m"),
            amount_usd_m = as.numeric(OBS_VALUE)) |>
  pivot_wider(names_from = measure, values_from = amount_usd_m) |>
  mutate(export_share_pct = 100 * gross_exports_usd_m / gross_output_usd_m)
chk(!anyNA(tiva_exports_output[c("gross_exports_usd_m", "gross_output_usd_m")]) &&
      all(is.finite(tiva_exports_output$gross_exports_usd_m)) && all(is.finite(tiva_exports_output$gross_output_usd_m)) &&
      all(tiva_exports_output$gross_exports_usd_m > 0) && all(tiva_exports_output$gross_output_usd_m > 0),
    "TiVA 2022: positive nonmissing gross exports and gross output for every economy and industry used")
computer_electronics_export_shares <- tiva_exports_output |> filter(industry == "C26", iso3 %in% c("NLD", "DEU", "KOR", "TWN"))
motor_vehicle_export_shares <- tiva_exports_output |> filter(industry == "C29", iso3 %in% c("DEU", "KOR"))
export_shares_pct <- c(computer_electronics_export_shares$export_share_pct, motor_vehicle_export_shares$export_share_pct)
chk(nrow(tiva_exports_output) == 6 && nrow(computer_electronics_export_shares) == 4 && nrow(motor_vehicle_export_shares) == 2 &&
      all(export_shares_pct > 0 & export_shares_pct < 100),
    "TiVA 2022: an export share of gross output between 0 and 100% for all six economy/industry pairs used")

add_num("tiva_export_share_output_2022_c26_min", min(computer_electronics_export_shares$export_share_pct), "percent of gross output",
        sprintf("Lowest gross exports as a percentage of gross output in C26 among the Netherlands, Germany, South Korea and Taiwan, 2022: %s (post: International dependence, '53 to 79%%')", computer_electronics_export_shares$iso3[which.min(computer_electronics_export_shares$export_share_pct)]), "D29")
add_num("tiva_export_share_output_2022_c26_max", max(computer_electronics_export_shares$export_share_pct), "percent of gross output",
        sprintf("Highest gross exports as a percentage of gross output in C26 among the Netherlands, Germany, South Korea and Taiwan, 2022: %s (post: International dependence, '53 to 79%%')", computer_electronics_export_shares$iso3[which.max(computer_electronics_export_shares$export_share_pct)]), "D29")
add_num("tiva_export_share_output_2022_deu_c29", motor_vehicle_export_shares$export_share_pct[motor_vehicle_export_shares$iso3 == "DEU"], "percent of gross output",
        "Gross exports as a percentage of gross output, motor vehicles (C29), Germany, 2022 (post: International dependence, '45%')", "D29")
add_num("tiva_export_share_output_2022_kor_c29", motor_vehicle_export_shares$export_share_pct[motor_vehicle_export_shares$iso3 == "KOR"], "percent of gross output",
        "Gross exports as a percentage of gross output, motor vehicles (C29), South Korea, 2022 (post: International dependence, '34%')", "D29")
