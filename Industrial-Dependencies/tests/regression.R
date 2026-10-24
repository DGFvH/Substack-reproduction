# Run from the project root. The expected values reproduce the frozen October 2026 inputs, not live data.
library(callr)

expected_numbers <- c(
  prodindex_c28_change_2019_to_2025_pct = 77.57863,
  prodindex_total_change_2019_to_2025_pct = 7.633455,
  korea_semicap_2025_over_2019 = 2.111705,
  korea_allmfg_change_2019_2025_pct = 6.407822,
  taiwan_i2_change_2019_2025_pct = 92.95061,
  taiwan_i3_change_2019_2025_pct = -11.1055,
  taiwan_i4_change_2019_2025_pct = -2.246577,
  asml_kr_tw_share_2025 = 50.50157,
  asml_asia_share_2025 = 85.86323,
  taiwan_i2_fall_count_annual_1982_2025 = 6,
  taiwan_i2_largest_fall_pct = -15.67798,
  taiwan_i2_second_fall_pct = -14.05192,
  taiwan_i2_index_contribution_share_jan_jul_2026 = 0.7183935,
  taiwan_total_mfg_change_if_i2_repeats_largest_fall_pct = -11.26296,
  nl_c28_largest_fall_pct = -21.94464,
  nl_c28_index_contribution_pct_jan_aug_2026 = 26.6755,
  nl_total_mfg_change_if_c28_repeats_largest_fall_pct = -5.853844,
  fig1_oecd_avg_weighted_change_2019_2025_pct = 1.308442,
  fig1_g7_avg_weighted_change_2019_2025_pct = -5.446586,
  mfg_change_2019_2025_pct_can = -6.04499,
  mfg_change_2019_2025_pct_fra = -3.838951,
  mfg_change_2019_2025_pct_deu = -11.36581,
  mfg_change_2019_2025_pct_ita = -6.506507,
  mfg_change_2019_2025_pct_jpn = -9.57892,
  mfg_change_2019_2025_pct_gbr = 2.989203,
  mfg_change_2019_2025_pct_usa = -2.622247,
  mfg_change_2019_2025_pct_twn = 44.92284,
  mfg_change_2019_2025_pct_kor = 14.73504,
  mfg_change_2019_2025_pct_nld = 7.403545,
  fig1_g7_n_below_2019_in_2025 = 6,
  fig1_oecd_n_members_with_index = 36,
  fig1_oecd_n_above_2019_in_2025 = 24,
  fig1_oecd_plus_taiwan_n = 37,
  fig1_rank_in_oecd_plus_taiwan_twn = 2,
  fig1_rank_in_oecd_plus_taiwan_kor = 11,
  fig1_rank_in_oecd_plus_taiwan_nld = 14,
  tiva_export_share_output_2022_c26_min = 53.49474,
  tiva_export_share_output_2022_c26_max = 78.55904,
  tiva_export_share_output_2022_deu_c29 = 45.49178,
  tiva_export_share_output_2022_kor_c29 = 33.89675
)

driver_result <- callr::r(function(root, expected) {
  setwd(root)
  withCallingHandlers(source("analysis.R", local = .GlobalEnv, keep.source = TRUE), warning = function(w) stop(w))
  actual <- setNames(as.numeric(nums$value), nums$id)
  stopifnot(identical(names(actual), names(expected)), isTRUE(all.equal(actual, expected, tolerance = 1e-10)),
            !anyNA(nums$script_line), .DEPENDENCY_DEPTH == 0L, length(.SOURCED) == 8L)
  for (i in seq_len(nrow(nums))) {
    lines <- readLines(file.path("R", nums$script_file[i]), warn = FALSE)
    stopifnot(grepl("add_num(", lines[nums$script_line[i]], fixed = TRUE))
  }
  stopifnot(identical(fig1_bars$value_lab, c("+1%", "-5%", "+3%", "-3%", "-4%", "-6%", "-7%", "-10%", "-11%", "+45%", "+15%", "+7%")),
            nrow(ranked_manufacturing) == 37L, sum(ranked_manufacturing$change_2019_2025_pct > 0) == 25L,
            nrow(read.csv("output/fig_1.csv")) == 39L)
  declines <- fig3_declines[order(fig3_declines$trough_year), ]
  stopifnot(identical(declines$trough_year, c(1985L, 2001L, 2004L, 2009L, 2015L, 2023L)),
            identical(round(declines$fall_pct, 2), c(-4.47, -14.05, -1.32, -3.94, -1.97, -15.68)),
            identical(declines$shaded, c(TRUE, TRUE, FALSE, TRUE, FALSE, TRUE)),
            nrow(fig3_falls) == 4L, identical(fig3_labelled$lab, c("-16%", "-14%")),
            is.null(fig3$labels$subtitle), nrow(ggplot2::ggplot_build(fig3)$data[[1]]) == 4L,
            nrow(ggplot2::ggplot_build(fig3)$data[[2]]) == 2L,
            sum(read.csv("output/fig_3.csv")$series == "I2 fall episode (shaded)") == 4L)
  stopifnot(nrow(drawdown_episodes(integer(), numeric())) == 0L,
            nrow(drawdown_episodes(1:3, c(1, 2, 3))) == 0L,
            drawdown_episodes(1:4, c(10, 10, 8, 10))$peak_year == 2L,
            abs(drawdown_episodes(1:4, c(10, 10, 8, 10))$fall_pct + 20) < 1e-12,
            abs(drawdown_episodes(1:4, c(10, 8, 9, 7))$fall_pct + 30) < 1e-12)
  for (name in paste0("fig_", 1:3)) {
    stopifnot(all(dim(png::readPNG(file.path("output", paste0(name, ".png")))) > 0))
    xml2::read_xml(file.path("output", paste0(name, ".svg")))
  }
  first_numbers <- nums
  source("analysis.R", local = .GlobalEnv, keep.source = TRUE)
  stopifnot(identical(first_numbers, nums))
  original_nl <- nl_index_mean("C", 2025)
  nl_production_year_means$mean_index <- -999
  source("R/07_manufacturing_by_economy.R", local = .GlobalEnv, keep.source = TRUE)
  stopifnot(nl_index_mean("C", 2025) == original_nl, !("06_boom_bust.R" %in% .SOURCED), .DEPENDENCY_DEPTH == 0L)
  source("R/03_korea_capacity.R", local = .GlobalEnv, keep.source = TRUE)
  stopifnot(length(NUMS) == 2L)
  data.frame(test = "driver, PDF values, labels, drawdowns, repeat runs", passed = TRUE)
}, args = list(root = getwd(), expected = expected_numbers))

standalone_results <- lapply(list.files("R", pattern = "^0[2-9]_.*\\.R$", full.names = TRUE), function(script) {
  callr::r(function(root, script) {
    setwd(root)
    withCallingHandlers(source(script, local = .GlobalEnv, keep.source = TRUE), warning = function(w) stop(w))
    stopifnot(!anyDuplicated(names(NUMS)), !anyNA(dplyr::bind_rows(NUMS)$script_line), .DEPENDENCY_DEPTH == 0L)
    data.frame(test = script, passed = TRUE, numbers = length(NUMS))
  }, args = list(root = getwd(), script = script))
})
stopifnot(length(list.files("Data", full.names = TRUE)) == 9L,
          !file.exists("R/01_eurostat_io_tables.R"),
          !file.exists("Data/naio_10_cp1750_NL_2024_IMP.json"),
          !file.exists("Data/naio_10_cp1750_NL_2024_TOTAL.json"))
driver_result
do.call(rbind, standalone_results)
