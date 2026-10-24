# ASML net sales 2025 by location of customers' facilities, hand-entered from the 20-F (XBRL page R71; D18).
# Post: half to Taiwan and South Korea, 86% to Asia (International dependence).

source("R/00_helpers.R")

asml <- read_csv("Data/asml_r71_2025_hand_entered.csv", show_col_types = FALSE)
asml_total_sales_eur_m <- asml$net_sales_eur_m[asml$region == "Total"]
chk(abs(sum(asml$net_sales_eur_m[asml$region != "Total"]) - asml_total_sales_eur_m) <= 0.15, "ASML: regions sum to the published total (within rounding)")
asml_sales_share_pct <- function(regions) 100 * sum(asml$net_sales_eur_m[asml$region %in% regions]) / asml_total_sales_eur_m

add_num("asml_kr_tw_share_2025", asml_sales_share_pct(c("Taiwan", "South Korea")), "percent",
        "Share of ASML's 2025 net sales to customers in Taiwan and South Korea (post: International dependence, 'half')", "D18")
add_num("asml_asia_share_2025", asml_sales_share_pct(c("China", "Taiwan", "South Korea", "Japan", "Singapore", "Rest of Asia")), "percent",
        "Share of ASML's 2025 net sales to customers in Asia (post: International dependence, '86%')", "D18")
