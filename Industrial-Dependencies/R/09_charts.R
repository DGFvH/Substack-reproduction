# Figures 1 to 3: PNG (5.5 in wide at 290 dpi, for a phone-width column), SVG with live, editable text, and a CSV of
# the plotted data. Text is at least 11.7 pt so that it stays legible on a phone.

source("R/00_helpers.R")
check_font()
need("03_korea_capacity.R")
need("06_boom_bust.R")                 # also loads Netherlands and Taiwan indices
need("07_manufacturing_by_economy.R")

BASE <- 16    # base font size, pt
TXT <- 4.1    # geom_text size, mm (11.7 pt)
SVG_FONT_STACK <- 'Arial, "Liberation Sans", Helvetica, sans-serif'   # double quotes: svglite writes styles in single-quoted attributes
theme_fig <- function() theme_minimal(base_size = BASE, base_family = FONT) +
  theme(plot.title = element_text(face = "bold", size = rel(0.95), margin = margin(b = 4)), plot.title.position = "plot",
        axis.text = element_text(size = rel(0.8)), axis.title = element_text(size = rel(0.8)), panel.grid.minor = element_blank(),
        legend.position = "none", plot.background = element_rect(fill = "white", colour = NA), plot.margin = margin(4, 8, 2, 6))
# Moves positions apart until neighbours are at least `gap` apart (for line-end labels).
spread_y <- function(y, gap) {
  o <- order(y); ys <- y[o]
  if (length(ys) > 1) for (i in 2:length(ys)) if (ys[i] - ys[i - 1] < gap) ys[i] <- ys[i - 1] + gap
  y[o] <- ys; y
}
lab_end <- function(d, gap) d |> group_by(series) |> slice_max(x, n = 1, with_ties = FALSE) |> ungroup() |> mutate(y_lab = spread_y(value, gap))
# Writes output/<name>.png and .svg. The SVG gets a font stack, so it renders where Liberation Sans is not installed.
save_fig <- function(p, name, height) {
  ggsave(file.path("output", paste0(name, ".png")), p, width = 5.5, height = height, dpi = 290, device = agg_png, bg = "white")
  svg <- file.path("output", paste0(name, ".svg"))
  ggsave(svg, p, width = 5.5, height = height, device = svglite::svglite, bg = "white",
         fix_text_size = FALSE, system_fonts = list(sans = FONT))
  svg_lines <- readLines(svg, warn = FALSE, encoding = "UTF-8")
  writeLines(gsub('font-family: "Liberation Sans";', paste0("font-family: ", SVG_FONT_STACK, ";"), svg_lines, fixed = TRUE), svg, useBytes = TRUE)
  chk(!inherits(try(xml2::read_xml(svg), silent = TRUE), "try-error"), paste0(name, ".svg is well-formed XML"))
  # Show the saved PNG in the Plots pane (the screen device lacks Liberation Sans); Rscript has no screen device
  if (interactive() && isTRUE(getOption("industrial_dependencies.show_plots", TRUE))) {
    if (requireNamespace("png", quietly = TRUE)) {
      grid::grid.newpage()
      grid::grid.raster(png::readPNG(file.path("output", paste0(name, ".png"))))
    } else {
      warning("Install package 'png' for screen previews; the PNG and SVG files were saved.")
    }
  }
  invisible(p)
}

# ---- Figure 1: manufacturing output, 2019 to 2025 (data from R/07_manufacturing_by_economy.R) ----------------------
fig1_bars <- bind_rows(
  tibble(label = c("OECD average", "G7 average"), change_pct = c(oecd_weighted_change_pct, g7_weighted_change_pct), group = "avg"),
  g7_manufacturing |> arrange(desc(change_2019_2025_pct)) |> transmute(label = name, change_pct = change_2019_2025_pct, group = "g7"),
  chip_linked_manufacturing |> arrange(desc(change_2019_2025_pct)) |> transmute(label = name, change_pct = change_2019_2025_pct, group = "chip")) |>
  # three blocks of bars, top to bottom, with gaps between them
  mutate(y = -c(1, 2, 3.7 + 0:6, 11.4 + 0:2), value_lab = sub("^\\+0%$", "0%", sprintf("%+.0f%%", change_pct)))
fig1 <- ggplot(fig1_bars, aes(x = change_pct, y = y, fill = group)) +
  geom_col(orientation = "y", width = 0.74) +
  geom_vline(xintercept = 0, colour = "grey30", linewidth = 0.5) +
  geom_text(aes(x = change_pct + ifelse(change_pct >= 0, 1.2, -1.2), label = value_lab, hjust = ifelse(change_pct >= 0, 0, 1)),
            size = TXT, family = FONT, colour = "grey20") +
  scale_fill_manual(values = c(avg = "grey25", g7 = "grey62", chip = "#d62728")) +
  scale_y_continuous(breaks = fig1_bars$y, labels = fig1_bars$label, expand = expansion(add = 0.6)) +
  scale_x_continuous(breaks = seq(-10, 40, 10), limits = c(-25, 58), expand = expansion(mult = 0)) +
  labs(title = "Manufacturing output (2019 - 2025)", x = "Change in manufacturing production index,\n2019 to 2025, %", y = NULL) +
  theme_fig() + theme(plot.title = element_text(size = BASE), axis.title.x = element_text(margin = margin(t = 6)),
                      panel.grid.major.y = element_blank(), legend.position = "none", plot.margin = margin(6, 10, 4, 4))
save_fig(fig1, "fig_1", height = 5.2)
write.csv(bind_rows(fig1_bars |> filter(group == "avg") |>
                      transmute(row = label, group = "weighted average", change_2019_2025_pct = change_pct, plotted_label = value_lab),
                    ranked_manufacturing |>
                      transmute(row = name, group = case_when(iso3 %in% G7_ISO ~ "G7", iso3 %in% CHIP_ISO ~ "chip-linked", TRUE ~ "other OECD"),
                                change_2019_2025_pct, plotted_label = ifelse(iso3 %in% c(G7_ISO, CHIP_ISO), sprintf("%+.0f%%", change_2019_2025_pct), NA_character_),
                                iso3, source, dataset, index_2019, index_2025, rank, va2019_usd)),
          "output/fig_1.csv", row.names = FALSE, na = "")

# ---- Figure 2: concentrated growth, three panels on different bases (data from R/02 to R/04) -----------------------
fig2_korea <- bind_rows(data.frame(series = "Semiconductors", x = 2016:2025, value = as.numeric(korea_semiconductor_capacity_index)),
                        data.frame(series = "All manufacturing", x = 2016:2025, value = as.numeric(korea_manufacturing_capacity_index)))
TW_SERIES <- c(I1 = "Metals, machinery,\nelectrical (I1)", I2 = "ICT and electronics (I2)", I3 = "Chemicals (I3)", I4 = "Consumer goods (I4)")
fig2_taiwan <- taiwan_group_annual |> filter(year >= 2015) |>
  transmute(series = factor(TW_SERIES[code], levels = TW_SERIES[c("I2", "I1", "I3", "I4")]), x = year, value = mean_index)
NL_SERIES <- c(C28 = "Machinery (C28)", C = "All manufacturing")
fig2_nl <- nl_production_year_means |> filter(year >= 2015, year <= 2025) |> transmute(series = NL_SERIES[industry], x = year, value = mean_index)

p_korea <- ggplot(fig2_korea, aes(x, value, colour = series)) + geom_line(linewidth = 1.1) + geom_point(size = 2) +
  geom_text(data = lab_end(fig2_korea, 14), aes(y = y_lab, label = series), hjust = 0, nudge_x = 0.25, size = TXT, family = FONT, show.legend = FALSE) +
  scale_colour_manual(values = c("Semiconductors" = "#d62728", "All manufacturing" = "grey25")) +
  scale_x_continuous(breaks = c(2016, 2019, 2022, 2025), limits = c(2016, 2029.6)) + scale_y_continuous(limits = c(50, 195)) +
  labs(title = "Korea: production capacity", x = NULL, y = "Index, 2020 = 100") + theme_fig()
p_taiwan <- ggplot(fig2_taiwan, aes(x, value, colour = series)) + geom_line(linewidth = 1.1) + geom_point(size = 2) +
  geom_text(data = lab_end(fig2_taiwan, 13) |> mutate(lab = sub(" \\(I[1-4]\\)$", "", series)), aes(y = y_lab, label = lab),
            hjust = 0, nudge_x = 0.2, size = TXT, lineheight = 0.9, family = FONT, show.legend = FALSE) +
  scale_colour_manual(values = setNames(c("#1f5fa8", "#d62728", "#2ca02c", "#ff7f0e"), TW_SERIES)) +
  scale_x_continuous(breaks = c(2015, 2020, 2025), limits = c(2015, 2029.6)) + scale_y_continuous(limits = c(50, 175)) +
  labs(title = "Taiwan: production volume", x = NULL, y = "Index, 2021 = 100") + theme_fig()
p_nl <- ggplot(fig2_nl, aes(x, value, colour = series)) + geom_line(linewidth = 1.1) + geom_point(size = 2) +
  geom_text(data = lab_end(fig2_nl, 14) |> mutate(lab = sub(" \\(C28\\)$", "", series)), aes(y = y_lab, label = lab),
            hjust = 0, nudge_x = 0.25, size = TXT, family = FONT, show.legend = FALSE) +
  scale_colour_manual(values = c("Machinery (C28)" = "#1f5fa8", "All manufacturing" = "grey25")) +
  scale_x_continuous(breaks = c(2015, 2020, 2025), limits = c(2015, 2029.6)) + scale_y_continuous(limits = c(40, 175)) +
  labs(title = "Netherlands: production volume", x = NULL, y = "Index, 2021 = 100") + theme_fig()
fig2 <- (p_korea / p_taiwan / p_nl) +
  plot_annotation(title = "Concentrated Growth",
                  theme = theme(plot.title = element_text(face = "bold", size = BASE, family = FONT, lineheight = 1.0, margin = margin(b = 4)),
                                plot.background = element_rect(fill = "white", colour = NA), plot.margin = margin(6, 4, 4, 4)))
save_fig(fig2, "fig_2", height = 9.6)
write.csv(bind_rows(fig2_korea |> mutate(panel = "Korea", measure = "production capacity index, 2020=100, annual (hand-entered from ECOS 901Y035)"),
                    fig2_taiwan |> mutate(series = gsub("\n", " ", series, fixed = TRUE), panel = "Taiwan",
                                           measure = "production index, 2021=100, annual mean (MOEA d.csv, dataset 6607)"),
                    fig2_nl |> mutate(panel = "Netherlands", measure = "production volume index, seasonally and calendar adjusted, 2021=100, annual mean (CBS 85806NED A050903_1)")) |>
            transmute(panel, series, period = as.character(x), value, measure),
          "output/fig_2.csv", row.names = FALSE)

# ---- Figure 3: Taiwan's ICT and electronics against total manufacturing (data from R/06_boom_bust.R) ---------------
FIG3_SERIES <- c("ICT and electronics (I2)", "Total manufacturing")
fig3_lines <- bind_rows(taiwan_ict_annual |> transmute(series = FIG3_SERIES[1], x = year, value = mean_index),
                        taiwan_manufacturing_annual |> transmute(series = FIG3_SERIES[2], x = year, value = mean_index)) |>
  mutate(series = factor(series, levels = FIG3_SERIES))
fig3_declines <- taiwan_ict_declines |>
  mutate(shaded = fall_pct < -2)
fig3_falls <- fig3_declines |>
  filter(shaded) |>
  mutate(lab = sprintf("%.0f%%", fall_pct))
fig3_labelled <- fig3_falls |> arrange(fall_pct) |> slice_head(n = 2)
chk(setequal(fig3_labelled$lab, c("-14%", "-16%")), "Figure 3: the two largest shaded falls are labelled -14% and -16%")
lab_fig3 <- fig3_lines |> group_by(series) |> slice_max(x, n = 1) |> ungroup() |>
  mutate(lab = ifelse(series == FIG3_SERIES[1], "ICT and\nelectronics", "Total\nmanufacturing"), y_lab = 10^spread_y(log10(value), 0.19))
fig3 <- ggplot() +
  geom_rect(data = fig3_falls, aes(xmin = peak_year, xmax = trough_year, ymin = 1, ymax = 400), fill = "grey82", alpha = 0.7) +
  geom_text(data = fig3_labelled, aes(x = (peak_year + trough_year) / 2, y = 300, label = lab), size = TXT, colour = "grey20", family = FONT) +
  geom_line(data = fig3_lines, aes(x, value, colour = series), linewidth = 1.1) +
  geom_text(data = lab_fig3, aes(x, y_lab, label = lab, colour = series), hjust = 0, vjust = 0.5, nudge_x = 0.8, size = TXT,
            lineheight = 0.9, family = FONT, show.legend = FALSE) +
  scale_colour_manual(values = setNames(c("#d62728", "grey25"), FIG3_SERIES)) +
  scale_x_continuous(breaks = c(1982, 1990, 2000, 2010, 2020), limits = c(1981.5, 2038)) +
  coord_cartesian(clip = "off") +
  scale_y_log10(breaks = c(1, 2, 5, 10, 20, 50, 100, 200), limits = c(1, 400), expand = expansion(mult = c(0, 0))) +
  labs(title = "Taiwan: ICT and electronics output against all\nmanufacturing", x = NULL, y = "Index, 2021 = 100, log scale") +
  theme_fig() + theme(plot.title = element_text(size = BASE), legend.position = "none", plot.margin = margin(6, 10, 4, 4))
save_fig(fig3, "fig_3", height = 6.6)
write.csv(bind_rows(fig3_lines |> transmute(series = as.character(series), period = as.character(x), value,
                                             measure = "production index, 2021=100, annual mean (MOEA d.csv, dataset 6607)"),
                    fig3_falls |> transmute(series = "I2 fall episode (shaded)", period = paste0(peak_year, "-", trough_year), value = fall_pct,
                                            measure = "fall of the I2 annual mean from peak to trough, percent")),
          "output/fig_3.csv", row.names = FALSE)
