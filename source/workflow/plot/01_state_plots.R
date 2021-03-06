# plot state level data

# =============================================================================

# load data

state_data <- read_csv("data/state/state_full.csv") 

non_stl_data <- read_csv("data/county/county_full.csv") %>%
  mutate(geoid = as.character(geoid)) %>%
  filter(state == "Missouri") %>%
  filter(geoid %in% c("29071", "29099", "29113", "29183", "29189", "29219", "29510") == FALSE)

# =============================================================================

# define colors
pal <- brewer.pal(n = 4, name = "Set1")
cols <- c("Illinois" = pal[1], "Kansas" = pal[2], "Missouri" = pal[3], "Oklahoma" = pal[4])

# =============================================================================

# create points
## create end points
state_points <- filter(state_data, report_date == date)

## create reporting change points
report_points <- filter(state_data, report_date == as.Date("2020-04-15")) %>%
  mutate(text = ifelse(state == "Illinois", "reporting change on 15 Apr", NA))

# =============================================================================

# create line label
report_line <- tibble(
  date = as.Date("2020-04-15"),
  case_rate = 270,
  mortality_rate = 12,
  case_fatality_rate = 7,
  text = "reporting change on 15 Apr"
)

# =============================================================================

# plot confirmed rate
## subset data
state_subset <- filter(state_data, report_date >= plot_date)

## define top_val
top_val <- round_any(x = max(state_subset$case_rate), accuracy = 50, f = ceiling)

## create factors
state_subset <- mutate(state_subset, factor_var = fct_reorder2(state, report_date, case_rate))
state_points <- mutate(state_points, factor_var = fct_reorder2(state, report_date, case_rate))

## create plot
p <- ggplot() +
  geom_line(state_subset, mapping = aes(x = report_date, y = case_rate, color = factor_var), size = 2) +
  geom_point(state_points, mapping = aes(x = report_date, y = case_rate, color = factor_var), 
             size = 4, show.legend = FALSE) +
  geom_vline(xintercept = as.Date("2020-04-15"), linetype="dotted", size = 1.25) + 
  geom_text_repel(data = report_line, mapping = aes(x = date, y = case_rate, label = text),
                  nudge_y = 10, nudge_x = -10, size = 5) +
  scale_colour_manual(values = cols, name = "State") +
  scale_x_date(date_breaks = date_breaks, date_labels = "%d %b") +
  scale_y_continuous(limits = c(0,top_val), breaks = seq(0, top_val, by = 50)) + 
  labs(
    title = "Reported COVID-19 Cases by State",
    subtitle = paste0(as.character(plot_date), " through ", as.character(date)),
    x = "Date",
    y = "Rate per 100,000",
    caption = caption_text_census
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plot
save_plots(filename = "results/high_res/state/b_case_rate.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/state/b_case_rate.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# create days from 10th confirmed infection data, state-level data
## subset data
state_data %>%
  calculate_days(group_var = "state", stat_var = "cases", val = 5) %>%
  select(day, report_date, state, cases) %>%
  arrange(state, day) -> state_subset

## define top_val
top_val <- round_any(x = max(state_subset$day), accuracy = 5, f = ceiling)

## identify max day
state_subset %>%
  group_by(state) %>%
  summarise(day = max(day)) %>%
  left_join(state_points, ., by = "state") -> state_day_points

## add day to report points
state_subset %>%
  select(state, report_date, day) %>%
  left_join(report_points, ., by = c("state", "report_date")) -> report_day_points

report_label <- filter(report_day_points, state == "Illinois")

## create factors
state_subset <- mutate(state_subset, factor_var = fct_reorder2(state, day, cases))
state_day_points <- mutate(state_day_points, factor_var = fct_reorder2(state, day, cases))

## create plot
p <- ggplot() +
  geom_line(state_subset, mapping = aes(x = day, y = cases, color = factor_var), size = 2) +
  geom_point(state_day_points, mapping = aes(x = day, y = cases, color = factor_var), 
             size = 4, show.legend = FALSE) +
  geom_point(report_day_points, mapping = aes(x = day, y = cases), size = 4, shape = 18) +
  geom_text_repel(data = report_label, mapping = aes(x = day, y = cases, label = text),
                  nudge_y = .3, nudge_x = -1, size = 5) +
  scale_colour_manual(values = cols, name = "State") +
  scale_y_log10(limits = c(5, 100000), labels = comma) +
  scale_x_continuous(limits = c(0, top_val), breaks = seq(0, top_val, by = 5)) +
  labs(
    title = "Pace of COVID-19 Cases by State",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text,
    x = "Days Since Fifth Case Reported",
    y = "Count of Reports Cases (Log)"
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plots
save_plots(filename = "results/high_res/state/c_case_log.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/state/c_case_log.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# create days from first day where average confirmed infections were at least 10, state-level data

## subset data
state_data %>%
  calculate_days(group_var = "state", stat_var = "case_avg", val = 5) %>%
  select(day, report_date, state, case_avg) %>%
  arrange(state, day) -> state_subset

## define top_val
top_val <- round_any(x = max(state_subset$day), accuracy = 5, f = ceiling)

## identify max day
state_subset %>%
  group_by(state) %>%
  summarise(day = max(day)) %>%
  left_join(state_points, ., by = "state") -> state_day_points

## add day to report points
state_subset %>%
  select(state, report_date, day) %>%
  left_join(report_points, ., by = c("state", "report_date")) -> report_day_points

report_label <- filter(report_day_points, state == "Illinois")

## create factors
state_subset <- mutate(state_subset, factor_var = fct_reorder2(state, day, case_avg))
state_day_points <- mutate(state_day_points, factor_var = fct_reorder2(state, day, case_avg))

## create plot
p <- ggplot() +
  geom_line(state_subset, mapping = aes(x = day, y = case_avg, color = factor_var), size = 2) +
  geom_point(state_day_points, mapping = aes(x = day, y = case_avg, color = factor_var), 
             size = 4, show.legend = FALSE) +
  geom_point(report_day_points, mapping = aes(x = day, y = case_avg), size = 4, shape = 18) +
  geom_text_repel(data = report_label, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = .2, nudge_x = -1, size = 5) +
  scale_colour_manual(values = cols, name = "State") +
  scale_y_log10(limits = c(1, 3000), breaks = c(1, 3, 10, 30, 100, 300, 1000, 3000), labels = comma_format(accuracy = 1)) +
  scale_x_continuous(limits = c(0, top_val), breaks = seq(0, top_val, by = 5)) +
  labs(
    title = "Pace of New COVID-19 Cases by State",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text,
    x = "Days Since Average of Five Cases Reported",
    y = "7-day Average of New Cases (Log)"
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plot
save_plots(filename = "results/high_res/state/d_case_log_avg.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/state/d_case_log_avg.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# create days from first day where average confirmed infections were at least 10, state-level data

## subset data
state_data %>%
  calculate_days(group_var = "state", stat_var = "case_avg", val = 5) %>%
  select(day, report_date, state, case_avg) %>%
  arrange(state, day) %>%
  filter(state == "Missouri") -> state_subset

## define top_val
top_val <- round_any(x = max(state_subset$day), accuracy = 5, f = ceiling)

## extra points
peak_val <- max(state_subset$case_avg)
peak_point <- filter(state_subset, case_avg == peak_val) %>%
  mutate(text = paste0("peak average of ", round(case_avg, digits = 2), " cases reported on ", format(report_date, format = "%d %b")))
  
current_point <- filter(state_subset, report_date == date) %>%
  mutate(text = paste0("current average of ", round(case_avg, digits = 2), " cases reported on ", format(report_date, format = "%d %b")))

## missouri less stl trend
non_stl_data %>%
  group_by(report_date) %>%
  summarise(new_cases = sum(new_cases)) %>%
  mutate(case_avg = rollmean(new_cases, k = 7, align = "right", fill = NA)) %>%
  select(-new_cases) %>%
  filter(report_date >= state_subset$report_date[1]) %>%
  rowid_to_column(var = "day") %>%
  mutate(day = day-1) %>%
  mutate(state = "Missouri (No STL)") %>%
  mutate(factor_var = as.factor(NA_character_)) -> non_stl_subset

## extra points
peak_val_nostl <- max(non_stl_subset$case_avg)
peak_point_nostl <- filter(non_stl_subset, case_avg == peak_val_nostl) %>%
  mutate(text = paste0("peak average of ", round(case_avg, digits = 2), " cases reported on ", format(report_date, format = "%d %b")))

current_point_nostl <- filter(non_stl_subset, report_date == date) %>%
  mutate(text = paste0("current average of ", round(case_avg, digits = 2), " cases reported on ", format(report_date, format = "%d %b")))

## bind
state_subset <- bind_rows(state_subset, non_stl_subset)

## create state day points
state_day_points <- filter(state_subset, day == max(day))

## creat report day points
report_day_points <- filter(state_subset, report_date == as.Date("2020-04-15"))

report_label <- filter(report_day_points, state == "Missouri") %>%
  mutate(text = ifelse(state == "Missouri", "reporting change on 15 Apr", NA))

## create factors
state_subset <- mutate(state_subset, factor_var = fct_reorder2(state, day, case_avg))
state_day_points <- mutate(state_day_points, factor_var = fct_reorder2(state, day, case_avg))

## create plot
p <- ggplot() +
  geom_line(state_subset, mapping = aes(x = day, y = case_avg, color = factor_var), size = 2) +
  geom_point(state_day_points, mapping = aes(x = day, y = case_avg, color = factor_var), 
             size = 4, show.legend = FALSE) +
  geom_point(report_day_points, mapping = aes(x = day, y = case_avg), size = 4, shape = 18) +
  geom_point(peak_point, mapping = aes(x = day, y = case_avg), size = 4, shape = 16) +
  geom_point(peak_point_nostl, mapping = aes(x = day, y = case_avg), size = 4, shape = 16) +
  geom_text_repel(data = report_label, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = -.3, nudge_x = -2, size = 5) +
  geom_text_repel(data = peak_point, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = .15, nudge_x = -1, size = 5) +
  geom_text_repel(data = current_point, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = .55, nudge_x = -1, size = 5) +
  geom_text_repel(data = peak_point_nostl, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = -.45, nudge_x = -8, size = 5) +
  geom_text_repel(data = current_point_nostl, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = -.5, nudge_x = -1, size = 5) +
  scale_color_brewer(palette = "Dark2", name = "Category") +
  scale_y_log10(limits = c(3, 500), breaks = c(3, 10, 30, 100, 300), labels = comma_format(accuracy = 1)) +
  scale_x_continuous(limits = c(0, top_val), breaks = seq(0, top_val, by = 5)) +
  labs(
    title = "Pace of New COVID-19 Cases in Missouri",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text,
    x = "Days Since Average of Five Cases Reported",
    y = "7-day Average of New Cases (Log)"
  ) +
  sequoia_theme(base_size = 22, background = "white") 

## save plot
save_plots(filename = "results/high_res/state/d_case_log_avg_mo_only.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/state/d_case_log_avg_mo_only.png", plot = p, preset = "lg", dpi = 72)

## create plot
p <- ggplot() +
  geom_line(state_subset, mapping = aes(x = day, y = case_avg, color = factor_var), size = 2) +
  geom_point(state_day_points, mapping = aes(x = day, y = case_avg, color = factor_var), 
             size = 4, show.legend = FALSE) +
  geom_point(report_day_points, mapping = aes(x = day, y = case_avg), size = 4, shape = 18) +
  geom_point(peak_point, mapping = aes(x = day, y = case_avg), size = 4, shape = 16) +
  geom_point(peak_point_nostl, mapping = aes(x = day, y = case_avg), size = 4, shape = 16) +
  geom_text_repel(data = report_label, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = -30, nudge_x = -1, size = 5) +
  geom_text_repel(data = peak_point, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = 25, nudge_x = -1, size = 5) +
  geom_text_repel(data = current_point, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = -15, nudge_x = -1, size = 5) +
  geom_text_repel(data = peak_point_nostl, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = 15, nudge_x = -1, size = 5) +
  geom_text_repel(data = current_point_nostl, mapping = aes(x = day, y = case_avg, label = text),
                  nudge_y = -35, nudge_x = -1, size = 5) +
  scale_color_brewer(palette = "Dark2", name = "Category") +
  scale_y_continuous(limits = c(0, 300), breaks = seq(0, 300, by = 50)) +
  scale_x_continuous(limits = c(0, top_val), breaks = seq(0, top_val, by = 5)) +
  labs(
    title = "Pace of New COVID-19 Cases in Missouri",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text,
    x = "Days Since Average of Five Cases Reported",
    y = "7-day Average of New Cases"
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plot
save_plots(filename = "results/high_res/state/d_case_count_avg_mo_only.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/state/d_case_count_avg_mo_only.png", plot = p, preset = "lg", dpi = 72)

## write data out
readr::write_csv(state_subset, "data/state/state_trend.csv")

# clean-up
rm(peak_val, peak_point, current_point, peak_val_nostl, peak_point_nostl, current_point_nostl,
   non_stl_data, non_stl_subset)

# =============================================================================

# plot mortality rate
## subset data
state_subset <- filter(state_data, report_date >= plot_date)

## define top_val
top_val <- round_any(x = max(state_subset$mortality_rate), accuracy = 2, f = ceiling)

## create factors
state_subset <- mutate(state_subset, factor_var = fct_reorder2(state, report_date, mortality_rate))
state_points <- mutate(state_points, factor_var = fct_reorder2(state, report_date, mortality_rate))

## create plot
p <- ggplot() +
  geom_line(state_subset, mapping = aes(x = report_date, y = mortality_rate, color = factor_var), size = 2) +
  geom_point(state_points, mapping = aes(x = report_date, y = mortality_rate, color = factor_var), 
             size = 4, show.legend = FALSE) +
  geom_vline(xintercept = as.Date("2020-04-15"), linetype="dotted", size = 1.25) + 
  geom_text_repel(data = report_line, mapping = aes(x = date, y = mortality_rate, label = text),
                  nudge_y = 1.5, nudge_x = -10, size = 5) +
  scale_colour_manual(values = cols, name = "State") +
  scale_x_date(date_breaks = date_breaks, date_labels = "%d %b") +
  scale_y_continuous(limits = c(0,top_val), breaks = seq(0, top_val, by = 2)) +
  labs(
    title = "Reported COVID-19 Mortality by State",
    subtitle = paste0(as.character(plot_date), " through ", as.character(date)),
    x = "Date",
    y = "Mortality Rate per 100,000",
    caption = caption_text_census
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plot
save_plots(filename = "results/high_res/state/f_mortality_rate.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/state/f_mortality_rate.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# create days from 3rd death data, state-level data
## subset data
state_data %>%
  calculate_days(group_var = "state", stat_var = "deaths", val = 3) %>%
  select(day, report_date, state, deaths) %>%
  arrange(state, day) -> state_subset

## define top_val
top_val <- round_any(x = max(state_subset$day), accuracy = 5, f = ceiling)

## identify max day
state_subset %>%
  group_by(state) %>%
  summarise(day = max(day)) %>%
  left_join(state_points, ., by = "state") -> state_day_points

## add day to report points
state_subset %>%
  select(state, report_date, day) %>%
  left_join(report_points, ., by = c("state", "report_date")) -> report_day_points

report_label <- filter(report_day_points, state == "Illinois")

## create factors
state_subset <- mutate(state_subset, factor_var = fct_reorder2(state, day, deaths))
state_day_points <- mutate(state_day_points, factor_var = fct_reorder2(state, day, deaths))

## create plot
p <- ggplot() +
  geom_line(state_subset, mapping = aes(x = day, y = deaths, color = factor_var), size = 2) +
  geom_point(state_day_points, mapping = aes(x = day, y = deaths, color = factor_var), 
             size = 4, show.legend = FALSE) +
  geom_point(report_day_points, mapping = aes(x = day, y = deaths), size = 4, shape = 18) +
  geom_text_repel(data = report_label, mapping = aes(x = day, y = deaths, label = text),
                  nudge_y = .3, nudge_x = -3, size = 5) +
  scale_colour_manual(values = cols, name = "State") +
  scale_y_log10(limits = c(3, 4000), breaks = c(3, 10, 30, 100, 300, 1000, 3000), labels = comma_format(accuracy = 1)) +
  scale_x_continuous(limits = c(0, top_val), breaks = seq(0, top_val, by = 5)) +
  labs(
    title = "Pace of COVID-19 Deaths by State",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text,
    x = "Days Since Third Death Reported",
    y = "Count of Reported Deaths (Log)"
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plot
save_plots(filename = "results/high_res/state/g_mortality_log.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/state/g_mortality_log.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# create days from first day where average deaths were over 3, state-level data

## subset data
state_data %>%
  calculate_days(group_var = "state", stat_var = "deaths_avg", val = 3) %>%
  select(day, report_date, state, deaths_avg) %>%
  arrange(state, day) -> state_subset

# define top_val
top_val <- round_any(x = max(state_subset$day), accuracy = 5, f = ceiling)

## identify max day
state_subset %>%
  group_by(state) %>%
  summarise(day = max(day)) %>%
  left_join(state_points, ., by = "state") -> state_day_points

## add day to report points
state_subset %>%
  select(state, report_date, day) %>%
  left_join(report_points, ., by = c("state", "report_date")) -> report_day_points

report_label <- filter(report_day_points, state == "Illinois")

## create factors
state_subset <- mutate(state_subset, factor_var = fct_reorder2(state, day, deaths_avg))
state_day_points <- mutate(state_day_points, factor_var = fct_reorder2(state, day, deaths_avg))

## create plot
p <- ggplot() +
  geom_line(state_subset, mapping = aes(x = day, y = deaths_avg, color = factor_var), size = 2) +
  geom_point(state_day_points, mapping = aes(x = day, y = deaths_avg, color = factor_var), 
             size = 4, show.legend = FALSE) +
  geom_point(report_day_points, mapping = aes(x = day, y = deaths_avg), size = 4, shape = 18) +
  geom_text_repel(data = report_label, mapping = aes(x = day, y = deaths_avg, label = text),
                  nudge_y = .25, nudge_x = -1, size = 5) +
  scale_colour_manual(values = cols, name = "State") +
  scale_y_log10(limits = c(1, 300), breaks = c(1,3,10,30,100, 300), labels = comma_format(accuracy = 1)) +
  scale_x_continuous(limits = c(0, top_val), breaks = seq(0, top_val, by = 5)) +
  labs(
    title = "Pace of New COVID-19 Deaths by State",
    subtitle = paste0("Current as of ", as.character(date)),
    caption = caption_text,
    x = "Days Since Average of Three Deaths Reported",
    y = "7-day Average of New Deaths (Log)"
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plots
save_plots(filename = "results/high_res/state/h_mortality_log_avg.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/state/h_mortality_log_avg.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# plot case fatality rate

## re-subset data
state_subset <- filter(state_data, report_date >= plot_date)

## create factors
state_subset <- mutate(state_subset, factor_var = fct_reorder2(state, report_date, case_fatality_rate))
state_points <- mutate(state_points, factor_var = fct_reorder2(state, report_date, case_fatality_rate))

## create plot
p <- ggplot() +
  geom_line(state_subset, mapping = aes(x = report_date, y = case_fatality_rate, color = factor_var), size = 2) +
  geom_point(state_points, mapping = aes(x = report_date, y = case_fatality_rate, color = factor_var), 
             size = 4, show.legend = FALSE) +
  geom_vline(xintercept = as.Date("2020-04-15"), linetype="dotted", size = 1.25) + 
  geom_text_repel(data = report_line, mapping = aes(x = date, y = case_fatality_rate, label = text),
                  nudge_y = 1.5, nudge_x = -10, size = 5) +
  scale_colour_manual(values = cols, name = "State") +
  scale_x_date(date_breaks = date_breaks, date_labels = "%d %b") +
  scale_y_continuous(limits = c(0,10), breaks = seq(0, 10, by = 1)) +
  labs(
    title = "COVID-19 Case Fatality by State",
    subtitle = paste0(as.character(plot_date), " through ", as.character(date)),
    x = "Date",
    y = "Case Fatality (%)",
    caption = caption_text
  ) +
  sequoia_theme(base_size = 22, background = "white")

## save plot
save_plots(filename = "results/high_res/state/j_case_fatality_rate.png", plot = p, preset = "lg")
save_plots(filename = "results/low_res/state/j_case_fatality_rate.png", plot = p, preset = "lg", dpi = 72)

# =============================================================================

# clean-up
rm(state_data, state_subset, state_points, state_day_points)
rm(top_val, pal, cols, p, report_points, report_label, report_line, report_day_points)
