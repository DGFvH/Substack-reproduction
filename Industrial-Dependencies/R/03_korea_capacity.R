# Korea: manufacturing production capacity index, 2020 = 100, all manufacturing and semiconductors, 2016-2025,
# hand-entered from Bank of Korea ECOS table 901Y035 (D16). Figure 2 (top panel) and the 2019-2025 changes.

source("R/00_helpers.R")

korea_capacity <- read_csv("Data/korea_capacity_hand_entered.csv", show_col_types = FALSE)
chk(nrow(korea_capacity) == 20 && all(korea_capacity$hand_entered) && all(korea_capacity$base == "2020=100") &&
      !anyNA(korea_capacity$value) && !anyDuplicated(korea_capacity[c("item_code", "year")]), "Korea capacity: 2 series x 10 years, hand-entered, 2020 = 100")
korea_semiconductor_capacity_index <- setNames(korea_capacity$value[korea_capacity$item_code == "I32AO1"], korea_capacity$year[korea_capacity$item_code == "I32AO1"])
korea_manufacturing_capacity_index <- setNames(korea_capacity$value[korea_capacity$item_code == "I32A"], korea_capacity$year[korea_capacity$item_code == "I32A"])
chk(identical(names(korea_semiconductor_capacity_index), as.character(2016:2025)) && identical(names(korea_manufacturing_capacity_index), names(korea_semiconductor_capacity_index)) &&
      korea_semiconductor_capacity_index[["2020"]] == 100 && korea_manufacturing_capacity_index[["2020"]] == 100,
    "Korea capacity: both series run 2016-2025 in order and equal 100 in 2020")

add_num("korea_semicap_2025_over_2019", korea_semiconductor_capacity_index[["2025"]] / korea_semiconductor_capacity_index[["2019"]], "ratio",
        "Semiconductor production capacity index, 2025 over 2019 (post: Industrial dependence, 'more than doubled')", "D16")
add_num("korea_allmfg_change_2019_2025_pct", 100 * (korea_manufacturing_capacity_index[["2025"]] / korea_manufacturing_capacity_index[["2019"]] - 1), "percent",
        "All-manufacturing production capacity index, change from 2019 to 2025 (post: Industrial dependence, 'rose by 6%')", "D16")
