# Industrial Dependencies: reproduction

Reproduces the locally computable analysis behind the Marginal Review post "Industrial Dependencies" (October 2026).

## Run

From this folder, with the `Data/` subfolder in place (already downloaded; the script makes no web request). The folder name is case-sensitive on Linux and macOS, so keep the capital D in `Data/`:

```
Rscript analysis.R > run_log.txt 2>&1
```

In RStudio, open `Industrial-Dependencies.Rproj` (it sets the working directory to this folder) and source `analysis.R`.

Each script in `R/` can also be run on its own, e.g. `Rscript R/09_charts.R` or the Source button in RStudio, again
from this folder. It runs the scripts it depends on first.

This writes `output/numbers.csv` (40 locally computed statistics, with the script file and line that computes each, not every statistic in the post),
`output/fig_N.png/.svg/.csv` (N = the figure number in the post) and `output/sessionInfo.txt`.
`fig_1.csv` contains all 37 country rows plus two weighted-average rows, including source/dataset, rank and
2019/2025 index levels; the chart itself displays ten countries and two averages. No separate coverage CSV is needed.

## Layout

`analysis.R` is a short driver: it sources the scripts in `R/` in the order below into one shared environment, then
writes `numbers.csv`. Every script starts by sourcing `R/00_helpers.R` (packages, options, helpers) and calling
`need()` for each script whose objects it uses. Dependencies are cached only within one top-level run, not across
the R session: each new Source click reruns the required dependencies and resets the number registry.
`R/07_manufacturing_by_economy.R` needs scripts 02 and 04, not the scenario calculations in 06.
Each script starts with a comment saying what it computes and where the post uses it.

| Script | Content (dataset ids as in `SOURCES.txt`) |
|---|---|
| `R/00_helpers.R` | Packages and options, `need()`, `numbers.csv` registry (`add_num`), checks (`chk`), font check |
| `R/02_cbs_production_index.R` | Netherlands: machinery and all-manufacturing production index (D6) |
| `R/03_korea_capacity.R` | Korea: production capacity index, hand-entered (D16) |
| `R/04_taiwan_moea.R` | Taiwan: production index, total manufacturing and groups I1 to I4 (D22) |
| `R/05_asml.R` | ASML 2025 net sales by customer location, hand-entered (D18) |
| `R/06_boom_bust.R` | Past falls, estimated index contributions and conditional manufacturing-index changes: Taiwan ICT, Dutch machinery (D22, D6, D3) |
| `R/07_manufacturing_by_economy.R` | Figure 1: change 2019 to 2025 by economy, OECD and G7 averages (D22, D25, D27, D31, D32) |
| `R/08_oecd_tiva.R` | Gross exports / gross output, broad electronics (C26) and motor vehicles (C29), 2022 (D29) |
| `R/09_charts.R` | Figures 1 to 3 (`fig_1` to `fig_3`: PNG, SVG, CSV) |

## PDF reproduction audit

The local results match the PDF's numerical claims at their stated rounding, with the following corrections and
scope limits. This is a partial reproduction, not independent verification of every externally sourced assertion.

- **Figure 1 covers 37 economies, not 35:** 36 OECD members plus Taiwan. Of these, 25/37 are above 2019,
  including 24/36 OECD members; six G7 economies are below 2019 (the exception is the United Kingdom).
  The OECD and G7 averages are author-calculated, fixed-weight averages using **2019 manufacturing value added
  in current US dollars**, not official OECD aggregates. Costa Rica and Iceland lack local index observations.
- Country changes are `100 * (2025 annual mean index / 2019 annual mean index - 1)`: cumulative production-volume
  changes, not CAGR, GDP growth or nominal output growth. OECD annual means use months, or quarters for Australia
  and New Zealand; Eurostat supplies annual indices. Figure 1 uses unadjusted indices, not the adjusted CBS series.
  Two endpoint years alone do not establish that output has "recently decreased further"; that requires a recent time series.
- Netherlands machinery grows **77.5786%** and total manufacturing **7.63345%** on CBS's seasonally/calendar-adjusted
  series (the latter is **7.40%** on Figure 1's Eurostat series). Korean semiconductor **capacity** is **2.1117×**
  its 2019 level, versus **6.41%** all-manufacturing capacity growth; capacity is not production volume.
  Taiwan I2 grows **92.95%**, while chemicals fall **11.11%** and consumer goods **2.25%**.
- ASML's 2025 sales shares are **50.50%** to Taiwan/South Korea and **85.86%** to Asia, by customers' facility locations.
  TiVA's **53.49–78.56%** for C26 and **45.49%** (Germany) / **33.90%**
  (South Korea) for motor vehicles are **gross exports / gross output**, not value-added export shares.
- The scenarios estimate Taiwan I2's index contribution at **71.84%** for Jan–Jul 2026 using coefficients fitted to
  Jan–Aug, and Dutch C28's at **26.68%** for Jan–Aug using a 2025 nominal-GVA-share assumption updated by relative
  index movements. Repeating the largest historical falls implies **−11.26% / −5.85%** manufacturing-index changes,
  respectively, with other components held fixed. These are not forecasts, nominal output shares or official weights.
- Figure 3 shades the four I2 drawdowns exceeding 2% on unrounded values; only the two largest are labelled **−14%**
  and **−16%**, as in the original figure. The six individual declining years are counted separately in the calculations.
- Not computed locally: Taiwan's electronics export-share rise from **41% to 79%**, semiconductors' roughly half of
  Korean exports in September 2026, the IMF's **62%** AI-hardware claim, and the EU's **20% by 2030** target.

Suggested corrected Figure 1 caption: “Manufacturing production-index change, 2019–2025, for selected economies
from a comparison set of 37 (36 OECD members plus Taiwan). Ten countries and two author-calculated weighted
averages are displayed. Most covered economies (25/37; 24/36 OECD members) are above 2019; six G7 economies are
below it. Averages use fixed 2019 manufacturing-value-added weights in current US dollars and are not official aggregates.”
Suggested Figure 3 caption: “Taiwan ICT and electronics (I2) and total manufacturing, annual mean production indices,
2021=100, logarithmic scale. I2 drawdowns greater than 2% are shaded; the two largest are labelled.”

### Full country coverage

- **Eurostat (24):** Austria, Belgium, Czechia, Denmark, Estonia, Finland, France, Germany, Greece, Hungary, Ireland,
  Italy, Latvia, Lithuania, Luxembourg, Netherlands, Norway, Poland, Portugal, Slovakia, Slovenia, Spain, Sweden, Switzerland.
- **OECD (12):** Australia, Canada, Chile, Colombia, Israel, Japan, Mexico, New Zealand, South Korea, Turkey, United Kingdom,
  United States.
- **MOEA (1):** Taiwan.

### Variable and unit guide

`_index` / `_mean_index` denote index levels, not money; `_share` denotes a 0–1 fraction and `_pct` percentage units
(100 × a fraction; changes can be negative) in the clarified names below. Legacy `numbers.csv` IDs are retained except for four renamed
measure IDs; consult `unit` rather than inferring units from older IDs (e.g. ASML's `_share_2025` IDs are percentages).
I2 and C26 cover broad electronics, and C28 broad machinery: none is an exact semiconductor-output proxy.

| Object / registry ID | Meaning |
|---|---|
| `production_index`, `mean_index` | Period index level and mean over the specified months; not money |
| `nl_production_year_means` | Full-year means through 2025; January–August only for 2026, with `n_months` recorded |
| `korea_semiconductor_capacity_index`, `korea_manufacturing_capacity_index` | Capacity indices, 2020=100; distinct from production indices |
| `taiwan_i2_index_contribution_share_jan_jul_2026` | Registry ID replacing `taiwan_i2_weight_latest`; same fractional value |
| `nl_c28_index_contribution_pct_jan_aug_2026` | Registry ID replacing `nl_c28_weight_latest`; same percentage value |
| `gross_exports_usd_m`, `gross_output_usd_m`, `export_share_pct` | TiVA current USD million levels and 100 × their ratio |

## Data extracts and checks

The active input inventory is 9 files. `SOURCES.txt` records the original download URLs, access dates, licences and
the exact row filters used to remove unused series/periods. These are local filtered extracts, not fresh downloads:
retained value strings, flags and period metadata are unchanged; no price update, time update or aggregation was applied.
The active data total is 334,260 bytes. The original downloads and removed files remain under
`backup/pdf-audit-2026-10-23/` (ignored by Git; excluded from this size comparison).

Run the regression checks from the project root with `Rscript tests/regression.R`; `callr` is an optional test dependency
(`install.packages("callr")`).

## Requirements

### R packages

```r
install.packages(c(
  "jsonlite", "dplyr", "tidyr", "readr", "ggplot2", "ragg",
  "patchwork", "svglite", "systemfonts", "xml2", "tibble", "png"
))
```

`png` enables saved-chart previews in RStudio; files are still saved without it.

### Liberation Sans font

The three figures of the post are laid out against the exact metrics of the
**Liberation Sans** font, so that chart layout is reproducible across machines regardless of which
commercial fonts (e.g. Arial) are licensed there. `analysis.R` checks this at the start of the run, before any data work (`FONT %in% systemfonts::system_fonts()$family`), and stops if the font isn't installed.

Liberation Sans is open source (SIL Open Font License) and metric-compatible with Arial. To install it:

- **Linux**: install your distribution's `liberation-fonts` (or `fonts-liberation`) package, or copy
  the TTFs to `~/.fonts` and run `fc-cache`.
- **macOS**: install via Homebrew, e.g. `brew install --cask font-liberation`, or drop the TTFs into
  `~/Library/Fonts`.
- **Windows**: download the TTFs from the
  [liberation-fonts releases](https://github.com/liberationfonts/liberation-fonts/releases) and
  double-click each file to install, or install per-user (no admin rights required) by copying the
  four `LiberationSans-*.ttf` files into `%LOCALAPPDATA%\Microsoft\Windows\Fonts` and registering
  each one under `HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Fonts`.

A fresh R session is needed after installing the font so that `systemfonts::system_fonts()` picks it up.
