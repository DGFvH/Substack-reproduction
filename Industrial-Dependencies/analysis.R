# Reproduces the figures and numbers of "Industrial Dependencies" (The Marginal Review, October 2026).
# Reads Data/ (no web requests; sources in SOURCES.txt) and writes to output/: numbers.csv (locally calculated numbers,
# with the script file and line that computes it), fig_1 to fig_3 (.png, .svg, .csv) and sessionInfo.txt.
# Run from this folder: Rscript analysis.R > run_log.txt 2>&1
# Each script in R/ also runs on its own (it sources R/00_helpers.R and the scripts it needs); this file runs them all.

if (!file.exists("analysis.R") || !dir.exists("R")) stop("Run this script from the folder that holds analysis.R, R/ and Data/; the working directory is ", getwd())
source("R/00_helpers.R")
check_font()   # stop before any data work if the charts' font is missing
t_start <- Sys.time()

SCRIPTS <- c("02_cbs_production_index.R", "03_korea_capacity.R", "04_taiwan_moea.R",
             "05_asml.R", "06_boom_bust.R", "07_manufacturing_by_economy.R", "08_oecd_tiva.R", "09_charts.R")
for (s in SCRIPTS) need(s)

nums <- bind_rows(NUMS)
chk(!anyNA(nums$script_line), "numbers.csv: every row has the script line that computes it")
write.csv(nums, "output/numbers.csv", row.names = FALSE)
writeLines(capture.output(sessionInfo()), "output/sessionInfo.txt")
cat("numbers.csv:", nrow(nums), "rows. Finished in", round(as.numeric(difftime(Sys.time(), t_start, units = "secs")), 1), "s\n")
