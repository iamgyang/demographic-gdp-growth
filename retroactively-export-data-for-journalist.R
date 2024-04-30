
# Options: ----------------------------------------------------------------

# debugging
options(error=browser)
options(error=NULL)

# disable data.table auto-indexing (causes errors w/ dplyr functions)
options(datatable.auto.index = FALSE)

# Directories -------------------------------------------------------------

# clear environment objects
rm(list = ls())

require("tidyverse")
require("data.table")
require("rio")
require("ggplot2")
require("ggthemes")


# You will have to edit this to be your own computer's working directories:
root_dir <- file.path("C:/Users/zgehan/CGD Education Dropbox/Zachary Gehan/80 Inherited Folders/dem_neg_labor")
overleaf_dir <- file.path("C:/Users/zgehan/CGD Education Dropbox/Zachary Gehan/Apps/Overleaf/Demographic Labor")

input_dir <- file.path(root_dir, "input")
output_dir <- file.path(root_dir, "output")
code_dir <- file.path(root_dir, "labor-growth")

setwd(input_dir)

# source(paste0(root_dir, "code/", "helper_functions.R"))
source(file.path(code_dir, "personal.functions.R"))
# set GGPLOT default theme:
theme_set(theme_clean() + 
              theme(plot.background = 
                        element_rect(color = "white")))



df <- rio::import("final_derived_labor_growth.dta") %>% dfdt() #as.data.table(as.data.frame(.))
df[, count := ifelse(aveP1_popwork < 0, 1, 0)]
df <- df[, .(poptotal, count, iso3c, year)]
df_full <- df
df <- df[, .(poptotal = sum(poptotal, na.rm = TRUE)), by = .(count, year)]
df <- df[poptotal != 0]
df[count == 1, indic := "Decline"]
df[count == 0, indic := "Growth"]
df[, globalpop := sum(poptotal, na.rm = TRUE), by = .(year)]
df[, poptotl_perc := poptotal / globalpop]
nrow(df)
df <- df %>% 
    filter(year != 1950 & !is.na(indic))
nrow(df)
#ggsave(glue("{overleaf_dir}/pop_g_line.pdf"), plot, width = 9, height = 7)

write_csv(df, file.path(output_dir, "pop_g_line.csv"))

require("countrycode")
df_full2 <- as_tibble(df_full) %>% 
  arrange(year, iso3c) %>%
  filter(!is.na(poptotal)) %>%
  mutate(
    country_name = code2name(iso3c),
    indic = ifelse(count == 1, "Decline", "Growth")
  ) %>%
  mutate(
    globalpop = sum(poptotal, na.rm = TRUE), 
    poptotl_perc = poptotal / globalpop,
    .by = year
  ) %>%
  rename(pop_declining = count) %>%
  relocate(iso3c, year, country_name, indic, pop_declining, poptotal, globalpop, poptotl_perc)

write_csv(df_full2, file.path(output_dir, "percent in neg popgrowth countries full.csv"))

plot <- df %>% 
    ggplot(
        aes(
            x = year,
            y = round(poptotl_perc * 100, 1),
            group = indic,
            color = indic
        )
    ) + 
    geom_line() +
    my_custom_theme + # texfont + 
    scale_x_continuous(breaks = seq(1950, 2100, 25)) +
    labs(y = "", subtitle = "Percent of global population living in countries where growth in working age population (15-64) is expected \nto grow or decline") #+
    #scale_color_stata()
plot

ggsave(file.path(output_dir, "pop_g_line.pdf"), plot, width = 9, height = 7)
