# plot kansas city metro level data

# =============================================================================

# load data
kc_sf <- st_read("data/metro/daily_snapshot_kc.geojson", crs = 4326,
                  stringsAsFactors = FALSE) %>%
  st_transform(crs = 102003) %>%
  mutate(county = ifelse(GEOID %in% c("29511"), NA, county))

county_data <- read_csv("data/county/county_full.csv") %>%
  mutate(geoid = as.character(geoid)) %>%
  filter(geoid %in% c("20091", "20103", "20107", "20121", "20209",
                      "29013", "29025", "29037", "29047", "29049", 
                      "29095", "29107", "29165", "29177", "29511"))

# =============================================================================

# define colors
pal_a <- brewer.pal(n = 8, name = "Set1")
pal_a[6] <- "#FFD60C"
pal <- pal_a
cols <- c("Kansas City" = pal[1], "Wyandotte" = pal[2], "Leavenworth" = pal[3],
          "Lafayette" = pal[4], "Jackson" = pal[5], "Johnson" = pal[6],
          "Clay" = pal[7], "Cass" = pal[8])

# clean-up
rm(pal_a) # pal_b

# define focal metros
county_focal <- c("20209", "20103", "29511", "29107", "29095", "20091", "29047",
                  "29037")

# =============================================================================

# create points
## create end points
county_points <- filter(county_data, report_date == date) %>%
  filter(geoid %in% county_focal)

## create reporting change points
report_points <- filter(county_data, report_date == as.Date("2020-04-15")) %>%
  filter(geoid %in% county_focal) %>%
  mutate(text = ifelse(geoid == "29189", "reporting change on 15 Apr", NA))

# =============================================================================

# create line label
report_line <- tibble(
  date = as.Date("2020-04-15"),
  case_rate = 3,
  mortality_rate = .5,
  case_fatality_rate = 11,
  text = "reporting change on 15 Apr"
)

# =============================================================================

# map Kansas City rates
## create breaks
kc_sf <- map_breaks(kc_sf, var = "case_rate", newvar = "case_breaks",
                     style = "fisher", classes = 5, dig_lab = 2)

## create maps
p <- ggplot(data = kc_sf) +
  geom_sf(mapping = aes(fill = case_breaks)) +
  geom_sf_label(mapping = aes(label = county), label.padding = unit(0.15, "lines"), size = 6) +
  scale_fill_brewer(palette = "GnBu", name = "Rate per 1,000") +
  labs(
    title = "Reported COVID-19 Cases in Metro Kansas City",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text_census_map
  ) +
  sequoia_theme(base_size = 22, background = "white", map = TRUE)

## save maps
save_plots(filename = "results/high_res/kc_metro/a_case_map.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/kc_metro/a_case_map.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# plot confirmed rate
## subset data
county_subset <- filter(county_data, report_date >= plot_date)

## define top_val
top_val <- round_any(x = max(county_subset$case_rate), accuracy = 1, f = ceiling)

## create factors
county_subset <- mutate(county_subset, factor_var = fct_reorder2(county, report_date, case_rate))
county_points <- mutate(county_points, factor_var = fct_reorder2(county, report_date, case_rate))

## create plot
p <- ggplot() +
  geom_line(county_subset, mapping = aes(x = report_date, y = case_rate, color = factor_var), size = 2) +
  geom_point(county_points, mapping = aes(x = report_date, y = case_rate, color = factor_var), 
             size = 4, show.legend = FALSE) +
  gghighlight(geoid %in% county_focal, use_direct_label = FALSE, use_group_by = FALSE) +
  geom_vline(xintercept = as.Date("2020-04-15"), linetype="dotted", size = 1.25) + 
  geom_text_repel(data = report_line, mapping = aes(x = date, y = case_rate, label = text),
                  nudge_y = .15, nudge_x = -10, size = 5) +
  scale_colour_manual(values = cols, name = "County") +
  scale_x_date(date_breaks = date_breaks, date_labels = "%d %b") +
  scale_y_continuous(limits = c(0,top_val), breaks = seq(0, top_val, by = 1)) + 
  labs(
    title = "Reported COVID-19 Cases in Metro Kansas City",
    subtitle = paste0(as.character(plot_date), " through ", as.character(date)),
    x = "Date",
    y = "Rate per 1,000",
    caption = caption_text_census
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plot
save_plots(filename = "results/high_res/kc_metro/b_case_rate.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/kc_metro/b_case_rate.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# create days from 5th confirmed infection data

## subset data
county_data %>%
  calculate_days(group_var = "geoid", stat_var = "cases", val = 5) %>%
  select(day, report_date, geoid, county, cases) %>%
  arrange(county, day) -> county_subset

## define top_val
top_val <- round_any(x = max(county_subset$day), accuracy = 5, f = ceiling)

## identify max day
county_subset %>%
  group_by(geoid) %>%
  summarise(day = max(day)) %>%
  left_join(county_points, ., by = "geoid") -> county_day_points

## add day to report points
county_subset %>%
  select(county, report_date, day) %>%
  left_join(report_points, ., by = c("county", "report_date")) -> report_day_points

report_label <- filter(report_day_points, county == "Kansas City")

## create factors
county_subset <- mutate(county_subset, factor_var = fct_reorder2(county, day, cases))
county_day_points <- mutate(county_day_points, factor_var = fct_reorder2(county, day, cases))

## create plot
p <- ggplot(data = county_subset) +
  geom_line(mapping = aes(x = day, y = cases, color = factor_var), size = 2) +
  geom_point(county_day_points, mapping = aes(x = day, y = cases, color = factor_var), 
             size = 4, show.legend = FALSE) +
  gghighlight(geoid %in% county_focal, use_direct_label = FALSE, use_group_by = FALSE) +
  geom_point(report_day_points, mapping = aes(x = day, y = cases), size = 4, shape = 18) +
  geom_text_repel(data = report_label, mapping = aes(x = day, y = cases, label = text),
                  nudge_y = .3, nudge_x = -1, size = 5) +
  scale_colour_manual(values = cols, name = "County") +
  scale_y_log10(limits = c(5, 3000), breaks = c(5,10,30,100,300,1000,3000), 
                labels = comma_format(accuracy = 1)) +
  scale_x_continuous(limits = c(0, top_val), breaks = seq(0, top_val, by = 5)) +
  labs(
    title = "Pace of COVID-19 Cases in Metro Kansas City",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text,
    x = "Days Since Fifth Case Reported",
    y = "Count of Reported Cases (Log)"
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plots
save_plots(filename = "results/high_res/kc_metro/c_case_log.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/kc_metro/c_case_log.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# create days from first day where average confirmed infections were at least 5

## subset data
county_data %>%
  calculate_days(group_var = "geoid", stat_var = "case_avg", val = 5) %>%
  select(day, report_date, geoid, county, case_avg) %>%
  arrange(county, day) -> county_subset

# define top_val
top_val <- round_any(x = max(county_subset$day), accuracy = 5, f = ceiling)

## identify max day
county_subset %>%
  group_by(geoid) %>%
  summarise(day = max(day)) %>%
  left_join(county_points, ., by = "geoid") %>%
  filter(county %in% unique(county_subset$county)) -> county_day_points

## add day to report points
county_subset %>%
  select(county, report_date, day) %>%
  left_join(report_points, ., by = c("county", "report_date")) %>%
  filter(county %in% unique(county_subset$county)) -> report_day_points

report_label <- filter(report_day_points, county == "Kansas City")

## create factors
county_subset <- mutate(county_subset, factor_var = fct_reorder2(county, day, case_avg))
county_day_points <- mutate(county_day_points, factor_var = fct_reorder2(county, day, case_avg))

## create plot
p <- ggplot(data = county_subset) +
  geom_line(mapping = aes(x = day, y = case_avg, color = factor_var), size = 2) +
  geom_point(county_day_points, mapping = aes(x = day, y = case_avg, color = factor_var), 
             size = 4, show.legend = FALSE) +
  gghighlight(geoid %in% county_focal, use_direct_label = FALSE, use_group_by = FALSE) +
  geom_point(report_day_points, mapping = aes(x = day, y = case_avg), size = 4, shape = 18) +
  geom_text_repel(data = report_label, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = .3, nudge_x = -1, size = 5) +
  scale_colour_manual(values = cols, name = "County") +
  scale_y_log10(limits = c(.3, 300), breaks = c(.3, 1, 3, 10, 30, 100, 300), labels = comma_format(accuracy = 1)) +
  scale_x_continuous(limits = c(0, top_val), breaks = seq(0, top_val, by = 5)) +
  labs(
    title = "Pace of New COVID-19 Cases in Metro Kansas City",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text,
    x = "Days Since Average of Five Cases Reached",
    y = "7-day Average of Reported Cases (Log)"
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plots
save_plots(filename = "results/high_res/kc_metro/d_case_log_avg.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/kc_metro/d_case_log_avg.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# map mortality rate
## create breaks
kc_sf <- map_breaks(kc_sf, var = "mortality_rate", newvar = "mortality_breaks",
                     style = "fisher", classes = 5, dig_lab = 2)

## create maps
p <- ggplot(data = kc_sf) +
  geom_sf(mapping = aes(fill = mortality_breaks)) +
  geom_sf_label(mapping = aes(label = county), label.padding = unit(0.15, "lines"), size = 6) +
  scale_fill_brewer(palette = "YlGn", name = "Percent") +
  labs(
    title = "COVID-19 Mortality in Metro Kansas City",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text_census_map
  ) +
  sequoia_theme(base_size = 22, background = "white", map = TRUE)

## save maps
save_plots(filename = "results/high_res/kc_metro/e_mortality_map.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/kc_metro/e_mortality_map.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# plot mortality rate
## subset data
county_subset <- filter(county_data, report_date >= plot_date)

## define top_val
top_val <- round_any(x = max(county_subset$mortality_rate), accuracy = .05, f = ceiling)

## create factors
county_subset <- mutate(county_subset, factor_var = fct_reorder2(county, report_date, mortality_rate))
county_points <- mutate(county_points, factor_var = fct_reorder2(county, report_date, mortality_rate))

## create plot
p <- ggplot() +
  geom_line(county_subset, mapping = aes(x = report_date, y = mortality_rate, color = factor_var), size = 2) +
  geom_point(county_points, mapping = aes(x = report_date, y = mortality_rate, color = factor_var), 
             size = 4, show.legend = FALSE) +
  gghighlight(geoid %in% county_focal, use_direct_label = FALSE, use_group_by = FALSE) +
  geom_vline(xintercept = as.Date("2020-04-15"), linetype="dotted", size = 1.25) + 
  geom_text_repel(data = report_line, mapping = aes(x = date, y = mortality_rate, label = text),
                  nudge_y = .01, nudge_x = -10, size = 5) +
  scale_colour_manual(values = cols, name = "County") +
  scale_x_date(date_breaks = date_breaks, date_labels = "%d %b") +
  scale_y_continuous(limits = c(0,top_val), breaks = seq(0, top_val, by = .05)) +
  labs(
    title = "Reported COVID-19 Mortality in Metro Kansas City",
    subtitle = paste0(as.character(plot_date), " through ", as.character(date)),
    x = "Date",
    y = "Mortality Rate per 1,000",
    caption = caption_text_census
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plot
save_plots(filename = "results/high_res/kc_metro/f_mortality_rate.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/kc_metro/f_mortality_rate.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# plot days from 3rd confirmed death data

## subset data
county_data %>%
  calculate_days(group_var = "geoid", stat_var = "deaths", val = 3) %>%
  select(day, report_date, geoid, county, deaths) %>%
  arrange(county, day) -> county_subset

## define top_val
top_val <- round_any(x = max(county_subset$day), accuracy = 5, f = ceiling)

## identify max day
county_subset %>%
  group_by(geoid) %>%
  summarise(day = max(day)) %>%
  left_join(county_points, ., by = "geoid") %>%
  filter(county %in% unique(county_subset$county)) -> county_day_points

## add day to report points
county_subset %>%
  select(county, report_date, day) %>%
  left_join(report_points, ., by = c("county", "report_date")) %>%
  filter(county %in% unique(county_subset$county)) -> report_day_points

report_label <- filter(report_day_points, county == "Kansas City")

## create factors
county_subset <- mutate(county_subset, factor_var = fct_reorder2(county, day, deaths))
county_day_points <- mutate(county_day_points, factor_var = fct_reorder2(county, day, deaths))

## create plot
p <- ggplot(data = county_subset) +
  geom_line(mapping = aes(x = day, y = deaths, color = factor_var), size = 2) +
  geom_point(county_day_points, mapping = aes(x = day, y = deaths, color = factor_var), 
             size = 4, show.legend = FALSE) +
  gghighlight(geoid %in% county_focal, use_direct_label = FALSE, use_group_by = FALSE) +
  geom_point(report_day_points, mapping = aes(x = day, y = deaths), size = 4, shape = 18) +
  geom_text_repel(data = report_label, mapping = aes(x = day, y = deaths, label = text),
                  nudge_y = .3, nudge_x = -1, size = 5) +
  scale_colour_manual(values = cols, name = "County") +
  scale_y_log10(limits = c(3, 400), breaks = c(3, 10, 30, 100, 300), labels = comma_format(accuracy = 1)) +
  scale_x_continuous(limits = c(0, top_val), breaks = seq(0, top_val, by = 5)) +
  labs(
    title = "Pace of COVID-19 Deaths in Metro Kansas City",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text,
    x = "Days Since Third Death Reported",
    y = "Count of Reported Deaths (Log)"
  ) +
  sequoia_theme(base_size = 22, background = "white")

save_plots(filename = "results/high_res/kc_metro/g_mortality_log.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/kc_metro/g_mortality_log.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# map case fatality rate
## create breaks
kc_sf <- map_breaks(kc_sf, var = "case_fatality_rate", newvar = "case_fatality_breaks",
                     style = "fisher", classes = 5, dig_lab = 2)

## create maps
p <- ggplot(data = kc_sf) +
  geom_sf(mapping = aes(fill = case_fatality_breaks)) +
  geom_sf_label(mapping = aes(label = county), label.padding = unit(0.15, "lines"), size = 6) +
  scale_fill_brewer(palette = "BuPu", name = "Percent") +
  labs(
    title = "COVID-19 Case Fatality in Metro Kansas City",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text_census_map2
  ) +
  sequoia_theme(base_size = 22, background = "white", map = TRUE)

## save maps
save_plots(filename = "results/high_res/kc_metro/i_case_fatality_map.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/kc_metro/i_case_fatality_map.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# plot case fatality rate

## re-subset data
county_subset <- filter(county_data, report_date >= plot_date)

## create factors
county_subset <- mutate(county_subset, factor_var = fct_reorder2(county, report_date, case_fatality_rate))
county_points <- mutate(county_points, factor_var = fct_reorder2(county, report_date, case_fatality_rate))

## create plot
p <- ggplot() +
  geom_line(county_subset, mapping = aes(x = report_date, y = case_fatality_rate, color = factor_var), size = 2) +
  geom_point(county_points, mapping = aes(x = report_date, y = case_fatality_rate, color = factor_var), 
             size = 4, show.legend = FALSE) +
  gghighlight(geoid %in% county_focal, use_direct_label = FALSE, use_group_by = FALSE) +
  geom_vline(xintercept = as.Date("2020-04-15"), linetype="dotted", size = 1.25) + 
  geom_text_repel(data = report_line, mapping = aes(x = date, y = case_fatality_rate, label = text),
                  nudge_y = .15, nudge_x = -10, size = 5) +
  scale_colour_manual(values = cols, name = "County") +
  scale_x_date(date_breaks = date_breaks, date_labels = "%d %b") +
  scale_y_continuous(limits = c(0,12), breaks = seq(0, 12, by = 1)) +
  labs(
    title = "COVID-19 Case Fatality in Metro Kansas City",
    subtitle = paste0(as.character(plot_date), " through ", as.character(date)),
    x = "Date",
    y = "Case Fatality (%)",
    caption = caption_text
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plot
save_plots(filename = "results/high_res/kc_metro/j_case_fatality_rate.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/kc_metro/j_case_fatality_rate.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# clean-up
rm(kc_sf, county_focal, county_points, report_points, report_label, county_subset,
   county_data, county_day_points, report_day_points, report_line)
rm(top_val, pal, cols, p)
