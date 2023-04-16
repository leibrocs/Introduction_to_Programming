########## Working with a Deforestation Dataset ##########

# load required packages
library(tidytuesdayR)
library(tidyverse)
library(scales)
library(tidytext)
library(fuzzyjoin)
library(ggthemes)
library(gganimate)
library(modelsummary)
library(plotly)
library(reshape2)

getwd()

# set working directory if necessary
# setwd("path/to/your/directory")



########## Load the Data ##########

# get deforestation data from the tidytuesdayR package
tidyTuesday_data <- tt_load("2021-04-06")

forest <- tidyTuesday_data$forest %>%
  rename(country = entity)
forest_area <- tidyTuesday_data$forest_area %>%
  rename(country = entity)
brazil_loss <- tidyTuesday_data$brazil_loss
soybean_use <- tidyTuesday_data$soybean_use %>%
  rename(country = entity)



########## Customized Theme ##########

tidyTuesday_theme <- function(){
  font <- "Arial" # assign font 
  
  theme_minimal() %+replace%
    theme(
      
      # grid elements
      panel.grid.minor = element_blank(),
      panel.background = element_blank(),
      
      # text elements
      plot.title = element_text(
        family = font,
        size = 10,
        hjust = 0.5,
        vjust = 2,
        color = "black"),
    
      plot.caption = element_text(
        family = font,
        size = 6,
        hjust = 1),
      
      axis.title = element_text(
        family = font,
        size = 10),
      
      axis.text = element_text(
        family = font,
        size = 9),
      
      axis.text.x = element_text(
        margin = margin(5, b = 10))
    )
}



########## Forest/ Forest Area Data ##########

# analysis of data statistics
forest_stats <- datasummary(year + net_forest_conversion ~ Mean + Min + Max + N, data = forest, title = "Forest Statistics")
forest_stats

forest_area_stats <- datasummary(year + forest_area ~ Mean + Min + Max + N, data = forest_area, title = "Forest Area Statistics")
forest_area_stats


# check in which country the most deforestation was going on
forest_area %>%
  filter(str_length(code) == 3 & year %in% c(1992, 2020)) %>% # filter only for countries (code == 3) and the years 1992 and 2020 (before 1992 some countries are missing)
  mutate(year = paste0("forest_area_", year)) %>%             # change column names to "forest_area_1990" and "forest_area_2020"
  spread(year, forest_area) %>%                               # spread forest area for 1990 and 2022 over two columns
  arrange(desc(forest_area_1992))                             # arrange data in a descending order


# get the sum of the net forest conversion for each year
forest %>%
  group_by(year) %>%
  summarize(net_forest_conversion = sum(net_forest_conversion))


# map the net forest conversion of each year
forest %>%
  mutate(country = fct_lump(country, 8, w = abs(net_forest_conversion))) %>%          # groups counties except the 8 with the highest conversion into one group ("others")
  group_by(country, year) %>%                                                         # group countries alphabetically and years in a ascending order
  summarize(net_forest_conversion = sum(net_forest_conversion), .groups = "drop") %>% # aggregate net_forest_conversion nd ungroup (to get a grouping by highest conversion and to by country)
  mutate(country = fct_reorder(country, -net_forest_conversion)) %>%                  # order countries by net forest conversion (country with largest conversion on top)
  ggplot(aes(year, net_forest_conversion, color = country)) +
  geom_line(linewidth = 0.8) +
  scale_y_continuous(labels = comma) +
  labs(y = "Net Forest Change [ha]") +
  ggtitle("Global Net Forest Conversion")


# map the forest area of each country 
forest_area %>%
  filter(str_length(code) == 3) %>%
  mutate(country = fct_lump(country, 8, w = abs(forest_area))) %>%
  group_by(country, year) %>%
  summarize(forest_area = sum(forest_area), .groups = "drop") %>%
  mutate(country = fct_reorder(country, -forest_area)) %>%
  ggplot(aes(year, forest_area, color = country)) +
  geom_line(size = 0.8) +
  scale_y_continuous(labels = comma) +
  labs(y = "Forest Area [%]") +
  ggtitle("Global Forest Area")


# map global forest evolution 1990 - 2015
forest_global <- forest %>%
  filter(code != "" & str_length(code) == 3)
forest_global$hover <- paste0(forest_global$country, "\n", forest_global$net_forest_conversion) # combine country name and net_forest_conversion in one column

plot_geo(forest_global, locationnode = 'world', frame = ~ year) %>%
  add_trace(locations = ~ code,
            z = ~ net_forest_conversion,
            zmax = max(forest$net_forest_conversion),
            zmin = min(forest$net_forest_conversion),
            color = ~ net_forest_conversion,
            text = ~ hover,
            hoverinfo = 'text') %>%
  layout(geo = list(scope = 'world'), title = "Global Deforestation 1990 - 2015")


# deforestation trend for some continents over 30 year period
forest_area %>%
  filter(country %in% c("Africa", "Asia", "Australia", "Europe")) %>%
  ggplot(aes(year, forest_area, color = country)) +
  geom_line(size = 1.05) +
  scale_fill_viridis_d(option = "inferno", direction = 1) +
  labs(x = "Year", y = "Forest Area", titel = "Changes in Forest Area 1990 - 2020") +
  tidyTuesday_theme() +
  facet_wrap(vars(country), scales = "free", ncol = 1) +
  geom_point() +
  scale_x_continuous(breaks = 0:200) +
  transition_reveal(year)


# graph with forest gain or forest loss for 20 countries for the year 2015
forest %>%
  filter(str_length(code) == 3) %>%
  filter(year == 2015) %>%
  arrange((net_forest_conversion)) %>%
  slice_max(abs(net_forest_conversion), n = 20) %>%                               # get the 20 highest values of net_forest_conversion
  mutate(country = fct_reorder(country, net_forest_conversion)) %>%
  ggplot(aes(net_forest_conversion, country, fill = net_forest_conversion > 0)) +
  geom_col() +
  scale_x_continuous(labels = comma) +
  theme(legend.position = "none") +
  labs(x = "Net Change in Forest 2015 [ha]", y = "") +
  ggtitle("20 Countries with the highest and the lowest Net Forest Change in 2015") +
  tidyTuesday_theme() +
  theme(legend.position = "none")



########## Deforestation Brazil ##########

# graph with causes of forest loss for the year 2013
brazil_loss %>%
  pivot_longer(commercial_crops:small_scale_clearing, names_to = "cause", values_to = "loss") %>% # all named columns into two new columns (elongates data frame)
  mutate(cause = str_to_sentence(str_replace_all(cause, "_", " "))) %>%                           # replace all "_" in the column cause with " "
  filter(year == max(year)) %>%
  arrange(desc(loss)) %>%
  mutate(cause = fct_reorder(cause, loss)) %>%
  ggplot(aes(loss, cause, fill = cause)) +
  geom_col() +
  scale_x_continuous(labels = comma) +
  labs(x = "Loss of Forest in 2013 [ha]", y = "") +
  theme(legend.position = "none") +
  ggtitle("Causes of Forest Loss in Brazil (2013)")


# causes of forest loss from 2001 to 2013
brazil_loss %>%
  pivot_longer(commercial_crops:small_scale_clearing, names_to = "cause", values_to = "loss") %>%
  mutate(cause = str_to_sentence(str_replace_all(cause, "_", " "))) %>%
  mutate(cause = fct_reorder(cause, -loss)) %>%
  ggplot(aes(year, loss, color = cause)) +
  geom_line(size = 0.8) +
  scale_y_continuous(labels = comma) +
  labs(y = "Loss of Forest [ha]", x = "")


# causes of forest loss from 2001 to 2013 plotted individually
brazil_loss_df <- melt(brazil_loss, id.vars = "year", variable.name = "causes")[-c(1:26),] %>% # reorganize columns of data frame to one long column and remove row 1 to 26 
  mutate(causes = str_to_sentence(str_replace_all(causes, "_", " ")))
brazil_loss_df$value <- as.numeric(brazil_loss_df$value) / 100                             # transform values from character to numeric and to km2 for easier interpretation
brazil_loss_df$causes <- as.character(brazil_loss_df$causes)                               # change class from factor to character
brazil_loss_df[118:130, 2] <- "Tree plantations"                                           # change to shorter name to fit in plot titel window

ggplot(brazil_loss_df, aes(year, value, color = causes)) +
  geom_line(size = 0.8) +
  facet_wrap(~causes, scale = "free") +
  guides(color = FALSE) +
  labs(y = "Forest Loss [km2]", x = "Year", title = "Causes of Forest Loss in Brazil")


# show the trend of deforestation in Brazil by different categories
brazil_loss %>%
  pivot_longer(commercial_crops:small_scale_clearing, names_to = "cause", values_to = "loss") %>%
  mutate(cause = str_to_sentence(str_replace_all(cause, "_", " "))) %>%
  ggplot() +
  aes(year, loss, color = cause, group = cause) +
  geom_line(size = 0.85) +
  scale_fill_viridis_d(option = "inferno", direction = 1) +
  scale_y_continuous(labels = scales::comma) +
  labs(y = "Loss of Land [ha]", x = "") +
  ggtitle("Loss of Land in Brazil (2001 - 2013)") +
  tidyTuesday_theme() +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", hjust = 0.5)) +
  transition_reveal(year) +
  view_follow(fixed_y = T)



########## Soybean Use Paraguay ##########

# filter the data only for data from Paraguay and plot it
soybean_use %>%
  filter(code == "PRY") %>%
  pivot_longer(human_food:processed, names_to = "Use", values_to = "values") %>%
  mutate(Use = str_to_sentence(str_replace_all(Use, "_", " "))) %>%
  ggplot() +
  aes(year, values, color = Use, group = Use) +
  geom_line(size = 0.8) +
  scale_fill_hue(aesthetics = "colour", direction = 1) +
  scale_y_continuous(labels = scales::comma) +
  labs(y = "Soybean Use [t]", x = "") +
  ggtitle("Soybean Use Paraguay 1961 - 2013") +
  tidyTuesday_theme() +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold", hjust = 0.5)) +
  transition_reveal(year) +
  view_follow(fixed_y = T)

# plot soybean use from 1990-2013 (1990 = start of significant increase)

soybean_use %>%
  filter(code == "PRY" & year >= 1990) %>%
  pivot_longer(human_food:processed, names_to = "Use", values_to = "values") %>%
  mutate(Use = str_to_sentence(str_replace_all(Use, "_", " "))) %>%
  ggplot(aes(year, values, color = Use, group = Use)) +
  geom_line(size = 0.8) +
  scale_fill_hue(aesthetics = "colour", direction = 1) +
  scale_y_continuous(labels = scales::comma) +
  labs(y = "Soybean Use [t]", x = "Year") +
  ggtitle("Soybean Use Paraguay 1990-2013") +
  tidyTuesday_theme() +
  theme(plot.title = element_text(face = "bold", hjust = 0.5))