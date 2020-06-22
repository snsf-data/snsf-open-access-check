# Various functions to calculate/plot components used in the final OA 
# Check report

# Create ggplot2 theme for OA share bar plot
barplot_theme <- theme(
  text = element_text(family = "Source Sans Pro", color = "#22211d"),
  legend.key = element_blank(),
  legend.title = element_text(color = "black", size = 7, angle = 90),
  legend.position = "right",
  legend.text = element_text(size = 7),
  plot.title = element_text(size = 14),
  panel.grid.major.x = element_blank(),
  panel.grid.major.y = element_line(
    color = "#D3D3D3",
    size = 0.3,
    linetype = "longdash"
  ),
  panel.background = element_blank(),
  axis.title.x = element_text(size = 10),
  axis.title.y = element_text(size = 10),
  axis.text.x = element_text(size = 8),
  axis.text.y = element_text(size = 8),
  axis.ticks.x = element_blank(),
  axis.ticks.y = element_blank() 
  
)

# Function to sum up the OA status classes and to prepare the data 
# for plotting
calculate_oa_totals <- function(articles) {
  # Sum up the OA classes
  oa_totals <- articles %>%
    # Remove articles without DOI / Unpaywall Errors
    filter(unpaywall_status == "OK") %>%
    group_by(oa_status) %>%
    summarise(n = n()) %>% 
    mutate(freq = n / sum(n)) %>% 
    ungroup()
  
  # Add zero columns (as they should also be visible in the plot)
  if (!("gold" %in% oa_totals$oa_status)) {
    oa_totals <- oa_totals %>% bind_rows(tibble(
      oa_status = "gold", n = 0, freq = 0
    )) 
  }
  if (!("green" %in% oa_totals$oa_status)) {
    oa_totals <- oa_totals %>% bind_rows(tibble(
      oa_status = "green", n = 0, freq = 0
    )) 
  } 
  if (!("hybrid" %in% oa_totals$oa_status)) {
    oa_totals <- oa_totals %>% bind_rows(tibble(
      oa_status = "hybrid", n = 0, freq = 0
    )) 
  } 
  if (!("other OA" %in% oa_totals$oa_status)) {
    oa_totals <- oa_totals %>% bind_rows(tibble(
      oa_status = "other OA", n = 0, freq = 0
    )) 
  } 
  if (!("closed" %in% oa_totals$oa_status)) {
    oa_totals <- oa_totals %>% bind_rows(tibble(
      oa_status = "closed", n = 0, freq = 0
    )) 
  }
  
  # Get the summed up share of closed articles
  sum_freq_closed <- oa_totals %>%  
    filter(oa_status == "closed") %>%  
    pull(freq)
  
  # Calculate the different shares of the closed OA classes (if there are any)
  if (nrow(filter(articles, oa_status == "closed")) > 0) {
    closed_shares <- articles %>%  
      filter(oa_status == "closed") %>%  
      group_by(closed_oa_class) %>%  
      summarise(n = n()) %>% 
      # Calculate share of the share of closed articles
      mutate(freq = (n / sum(n)) * sum_freq_closed, 
             oa_status = "closed")
    
    # Bind together
    oa_totals <- oa_totals %>%  
      # Remove the summarized closed row
      filter(oa_status != "closed") %>% 
      bind_rows(closed_shares) %>%  
      # Recode the NA values of the open articles
      mutate(closed_oa_class = as.character(closed_oa_class)) %>% 
      mutate(closed_oa_class = if_else(is.na(closed_oa_class), 
                                       paste0("open-", oa_status), 
                                       closed_oa_class))
  } else {
    # When there are no closed OA, nonetheless add the variable (to open)
    oa_totals <- oa_totals %>%  
      mutate(closed_oa_class = paste0("open-", oa_status))
  }
  
  # OA status as factor with set order
  oa_totals <- oa_totals %>%
    # OA status factor and order (no expansion is needed, as we have an 
    # entry for each OA status - also when it's 0)
    mutate(oa_status = fct_relevel(oa_status,
                                   c("gold", 
                                     "green", 
                                     "hybrid", 
                                     "other OA", 
                                     "closed"))) %>%  
    # Fix the order of the closed OA category
    mutate(closed_oa_class = fct_relevel(closed_oa_class, 
                                         c("open-gold", 
                                           "open-green", 
                                           "open-hybrid", 
                                           "open-other OA", 
                                           "<= 6", 
                                           "7 - 12", 
                                           "13 - 24", 
                                           "> 24")))
  
  return(oa_totals)
}

# Function to generate plot with OA totals
generate_oa_plot <- function(oa_totals, researcher_name) {
  
  # Get the maximum possible Y value (add up closed class shares)
  max_y <- oa_totals %>%  
    group_by(oa_status) %>%  
    summarise(max_freq = sum(freq)) %>%  
    arrange(-max_freq) %>%
    slice(1) %>%  
    pull(max_freq)
  
  # Add a variable with the column total freq and n
  oa_totals <- oa_totals %>%  
    left_join(oa_totals %>%  
                group_by(oa_status) %>%  
                summarise(tot_freq = sum(freq), 
                          tot_n = sum(n)), by = "oa_status")
  
  # Mark the first entries of every oa_status (plot the total for this obs)
  last_oa_status <- ""
  oa_totals$first_per_status <- F
  for (idx in seq_len(nrow(oa_totals))) {
    if (oa_totals$oa_status[idx] != last_oa_status)
      oa_totals$first_per_status[idx] <- T
    last_oa_status <- oa_totals$oa_status[idx]
  }
  
  # Get the number of distinct close classes (to calculate legend item height)
  distinct_closed_classes <- oa_totals %>% 
    distinct(closed_oa_class) %>% 
    filter(!str_starts(closed_oa_class, "open")) %>% 
    nrow()
  
  # Calculate the height of each legend item (mm)
  total_legenditem_height <- 34.5
  legenditem_height <- total_legenditem_height / distinct_closed_classes
  
  # Function that determines, if there is a bar to show for a specific category
  check_if_empty <- function(check_oa_class) {
    return(oa_totals %>% 
             filter(closed_oa_class == check_oa_class, 
                    tot_freq > 0) %>% 
             nrow() > 0)
  }
  
  # Create plot
  p_oa_colors <-
    ggplot(oa_totals, aes(x = oa_status, y = freq, fill = closed_oa_class)) + 
    # Bars
    geom_col(aes(color = if_else(n == 0, "transparent", "white")), 
             position = "stack", width = 0.6) + 
    # Total per column text
    geom_text(aes(y = tot_freq + (max_y / 15),
                  # Only display for the first bar of each OA status
                  label = if_else(first_per_status,
                                  paste0(round(tot_freq * 100, 1), "% (",
                                         prettyNum(tot_n, big.mark = "'"),
                                         ")"), "")),
              color = "#4d4d4d", size = 3, family = "Source Sans Pro") +
    # Individual column part (when closed column is split) text
    geom_text(aes(y = freq,
                  # Show label only if it's the closed access column and the
                  # frequency lies above 1.5% (size)
                  label = if_else(oa_status != "closed" |
                                    freq <= 0.015, "",
                                  paste0(round(freq * 100, 1), "% (",
                                         prettyNum(n, big.mark = "'"),
                                         ")"))),
              color = "white", position = position_stack(vjust = 0.5),
              family = "Source Sans Pro", size = 3) +
    scale_y_continuous(labels = percent_format(accuracy = 1),
                       breaks = seq(0, 1, 0.1),
                       limits = c(0, max_y + (max_y / 8))) +
    # Fix the color scale, so it stays the same, even when not all closed OA
    # states are active for this researcher
    scale_fill_manual(
      values = c(
        # Return NA when to fix small bar displayed for empty columns in 
        # some PDF viewers: https://github.com/tidyverse/ggplot2/issues/2811
        "open-gold" = 
          ifelse(check_if_empty("open-gold"), "#F68B29", NA),
        "open-green" = 
          ifelse(check_if_empty("open-green"), "#34B78B", NA),
        "open-hybrid" = 
          ifelse(check_if_empty("open-hybrid"), "#0160AE", NA),
        "open-other OA" = 
          ifelse(check_if_empty("open-other OA"), "#965D96", NA),
        "<= 6" = "#C5C6C8",
        "7 - 12" = "#919293",
        "13 - 24" = "#5D5E5F",
        "> 24" = "#2A2A2B"
      ),
      labels = c("\u2264 6", # <= 6
                 "7 - 12",
                 "13 - 24",
                 "> 24"),
      # Do not drop factor levels when there is no data
      drop = FALSE,
      name = "Months since publication (closed)",
      # Legend items to display (when available)
      breaks = c("<= 6",
                 "7 - 12",
                 "13 - 24",
                 "> 24"),
      # Legend style
      guide = guide_legend(
        title.position = "left",
        direction = "vertical",
        keyheight = unit(legenditem_height, units = "mm"),
        keywidth = unit(2, units = "mm"),
        label.hjust = 1,
        label.vjust = 0.1,
        title.vjust = 0,
        byrow = FALSE,
        label.position = "right"
      )
    ) +
    scale_color_manual(values = c("white" = "white",
                                  "transparent" = NA),
                       guide = FALSE) +
    labs(x = NULL, y = NULL) +
    barplot_theme
  
  return(p_oa_colors)
}

# Function to create some dynamic parts of the report text
generate_short_summary <- function(researcher_name,
                                   # division,  
                                   articles) {
  
  # Subset the articles successfully Unpaywall queried
  articles_unpaywall_ok <- articles %>%
    filter(unpaywall_status == "OK")
  
  # Calculate the percentage (SNSF definition)
  percentage_is_oa_snsf <- articles_unpaywall_ok %>%
    count(is_oa_snsf) %>% 
    mutate(freq = n / sum(n)) %>% 
    filter(is_oa_snsf == TRUE) %>% 
    select(freq) %>% 
    pull()
  
  # Calculate the percentage (broad definition)
  percentage_is_oa_broad <- articles_unpaywall_ok %>%
    count(is_oa) %>% 
    mutate(freq = n / sum(n)) %>% 
    filter(is_oa == TRUE) %>% 
    select(freq) %>% 
    pull()
  
  # No OA articles (SNSF definition) found, set percentage to zero
  if (length(percentage_is_oa_snsf) == 0)
    percentage_is_oa_snsf <- 0
  
  # No OA articles (broad definition) found, set percentage to zero
  if (length(percentage_is_oa_broad) == 0)
    percentage_is_oa_broad <- 0
  
  # Create sentence
  sentence <- paste0(
    "Overall, __", 
    round(percentage_is_oa_broad * 100),
    "%__ of ",
    researcher_name,
    "'s analysed articles are openly available. __", 
    round(percentage_is_oa_snsf * 100), 
    "%__ are open access according to SNSF's definition, only taking gold,", 
    " green and hybrid articles into account.")
  
  return(sentence)
}

# Get a string of the years under examination formatted for the report
get_year_list_string <- function(years_to_examine) {
  # If only one year, return it
  if (length(years_to_examine) == 1)
    return(years_to_examine)
  
  # Might be a character, convert to numeric
  years_to_examine <- as.numeric(years_to_examine)
  
  # If there are 'year gaps' in the provided year vector, display the
  # years separated by commas
  if (any(diff(years_to_examine) > 1)) {
    return(paste(years_to_examine, collapse = ", "))
  }
  
  # There are no 'year gaps', return hyphenated period
  return(paste0(min(years_to_examine, na.rm = TRUE), " - ",
                max(years_to_examine, na.rm = TRUE)))
}

# Function to classify the closed articles in classes depending on time passed 
# since their publication
classify_closed_articles <- function(articles) {
  
  # Only classify closed status when at least one article could be queried to 
  # Unpaywall successfully
  if ("is_oa" %in% names(articles)) {
    articles %>%
      # Dimensions dates can also be not full dates (according to documentation)
      mutate(months_since_pub = if_else(nchar(date) == 10, 
                                        as_date(date), NULL)) %>%
      # Calculate exact decimal value of the period between today and
      # the date of the publication
      # 1) If there is a pub date, calculate a lubridate interval
      # 2) If there is a pub date, get the decimal number of months out of the
      # lubridate period extracted from the lubridate interval
      mutate(months_since_pub =
               time_length(
                 as.period(
                   interval(
                     months_since_pub, today(tzone = "Europe/Zurich")
                   )
                 ), unit = "months")) %>%
      # Set the class for the closed OA articles to one of for levels
      mutate(closed_oa_class =
               if_else(oa_status == "closed",
                       # Classify into 4 classes, according to time passed
                       # since the article's publication
                       case_when(
                         months_since_pub <= 6 ~ "<= 6",
                         (months_since_pub > 6 &
                            months_since_pub <= 12) ~ "7 - 12",
                         (months_since_pub > 12 &
                            months_since_pub <= 24) ~ "13 - 24",
                         months_since_pub > 24 ~ "> 24",
                         TRUE ~ "> 24" # Instead of 'undefined'
                       ),
                       "open")) %>%
      # Expand the closed OA categories with levels that might not in the data 
      # of the selected researcher
      mutate(
        closed_oa_class = fct_expand(closed_oa_class,
                                     c("open-gold", 
                                       "open-green", 
                                       "open-hybrid", 
                                       "open-other OA", 
                                       "<= 6", 
                                       "7 - 12", 
                                       "13 - 24", 
                                       "> 24")), 
        # Fix the order
        closed_oa_class = fct_relevel(closed_oa_class,
                                      c("open-gold", 
                                        "open-green", 
                                        "open-hybrid", 
                                        "open-other OA", 
                                        "<= 6", 
                                        "7 - 12", 
                                        "13 - 24", 
                                        "> 24"))) %>%
      return()
  } else {
    return(articles)
  } 
}
