# Setup shared by the scripts in R/: packages and options, need() to run dependencies, the numbers.csv registry,
# checks (chk), and the font check.
# Every top-level script starts a fresh run; nested dependencies share that run's registry.

options(keep.source = TRUE, warn = 1)   # keep.source lets add_num() record the line that computes each number
if (.Platform$OS.type != "windows") invisible(Sys.setlocale("LC_ALL", "C.UTF-8"))
suppressPackageStartupMessages({
  library(jsonlite); library(dplyr); library(tidyr); library(readr); library(ggplot2); library(ragg); library(patchwork)
})
dir.create("output", showWarnings = FALSE)

# The charts are laid out against the metrics of Liberation Sans.
FONT <- "Liberation Sans"
check_font <- function() if (!FONT %in% systemfonts::system_fonts()$family) stop("Liberation Sans is not installed (see Requirements in README.md)")

# ---- Dependencies between scripts ----------------------------------------------------------------------------------
# Cache only within a run, never across separate Source clicks.
if (!exists(".DEPENDENCY_DEPTH", inherits = FALSE)) .DEPENDENCY_DEPTH <- 0L
if (.DEPENDENCY_DEPTH == 0L) {
  .SOURCED <- character()
  NUMS <- list()
}
need <- function(script) {
  if (script %in% .SOURCED) return(invisible())
  .DEPENDENCY_DEPTH <<- .DEPENDENCY_DEPTH + 1L
  on.exit(.DEPENDENCY_DEPTH <<- .DEPENDENCY_DEPTH - 1L)
  cat("== R/", script, "\n", sep = "")
  source(file.path("R", script), keep.source = TRUE, local = globalenv())
  .SOURCED <<- union(.SOURCED, script)
}

# ---- numbers.csv registry ------------------------------------------------------------------------------------------
fmt_val <- function(v) {
  if (is.character(v)) return(v)
  if (is.na(v)) return("NA")
  if (abs(v - round(v)) < 1e-9 && abs(v) < 1e15) return(sprintf("%.0f", v))
  format(signif(v, 12), scientific = FALSE, trim = TRUE, drop0trailing = TRUE)
}
# Stores one number with the file and line of the add_num() call (the srcref needs keep.source = TRUE).
add_num <- function(id, value, unit, description, dataset) {
  sr <- attr(sys.call(), "srcref")
  file <- if (is.null(sr)) NA_character_ else basename(attr(sr, "srcfile")$filename)
  if (!grepl("^[a-z0-9_]+$", id)) stop("numbers.csv id is not snake_case: ", id)
  if (id %in% names(NUMS)) stop("duplicate numbers.csv id: ", id)
  if (length(value) != 1) stop("value of ", id, " has length ", length(value))
  NUMS[[id]] <<- data.frame(id = id, value = fmt_val(value), unit = unit, description = description, dataset = dataset,
                            script_file = file, script_line = if (is.null(sr)) NA_integer_ else as.integer(sr[1]))
  invisible(value)
}
# Stops the run if a check fails and logs it if it passes.
chk <- function(cond, msg) { if (!isTRUE(cond)) stop("CHECK FAILED: ", msg); cat("check ok:", msg, "\n") }

