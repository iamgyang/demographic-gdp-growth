# To do:

# do we want to get the IRON levels from NMC as opposed to CHAT? 
# https://correlatesofwar.org/data-sets/national-material-capabilities

# change to historical income groups instead of current income groups

rm(list = ls()) # clear the workspace


# Options: ----------------------------------------------------------------

# debugging
options(error=browser)
options(error=NULL)

# disable data.table auto-indexing (causes errors w/ dplyr functions)
options(datatable.auto.index = FALSE)


# Notes -------------------------------------------------------------------



# Directories -------------------------------------------------------------

# clear environment objects
rm(list = ls())

# You will have to edit this to be your own computer's working directories:
user<-Sys.info()["user"]
root_dir <- paste0("C:/Users/", user, "/Dropbox/CGD/Projects/dem_neg_labor/")
input_dir <- paste0(root_dir, "input")
output_dir <- paste0(root_dir, "output")
code_dir <- paste0(root_dir, "code")

setwd(input_dir)


# Packages ---------------------------------------------------------------
{
    list.of.packages <- c(
        "base", "car", "cowplot", "dplyr", "ggplot2", "ggthemes", "graphics", "grDevices",
        "grid", "gridExtra", "gvlma", "h2o", "lubridate", "MASS", "readxl", "rio", "rms",
        "rsample", "stats", "tidyr", "utils", "zoo", "xtable", "stargazer", "data.table",
        "ggrepel", "foreign", "fst", "countrycode", "wbstats", "quantmod", "R.utils",
        "leaps", "bestglm", "dummies", "caret", "jtools", "huxtable", "haven", "ResourceSelection",
        "betareg", "quantreg", "margins", "plm", "collapse", "kableExtra", "tinytex",
        "LambertW", "scales", "stringr", "imputeTS", "shadowtext", "pdftools", "glue",
        "purrr", "OECD", "RobustLinearReg", "forcats", "WDI", "xlsx")
}

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# set GGPLOT default theme:
theme_set(theme_clean() + 
              theme(plot.background = 
                        element_rect(color = "white")))


# source(paste0(root_dir, "code/", "helper_functions.R"))
source(paste0("C:/Users/", user, "/Dropbox/Coding_General/personal.functions.R"))

# ... ---------------------------------------------------------------------

# Graphing ------------------------------


# UN population figures: working age population
df <- rio::import("un_pop_with_HIC_LIC.dta") %>% as.data.table()

df <- df %>% 
    filter(country == "High-income countries" |
               country == "Low-income countries" | 
               iso3c == "CHN" |
               iso3c == "IND") %>% 
    dfdt()

df <- df[,.(popwork = sum(popwork, na.rm = TRUE)),by = .(country, year)]
df[,country:=country %>% factor(., levels = c(
    "High-income countries", 
    "Low-income countries", 
    "China", 
    "India"
))]

plot <- df %>% ggplot(.,
           aes(
               x = year,
               y = popwork,
               group = country,
               color = country
           )) +
    geom_line() + 
    my_custom_theme + 
    scale_x_continuous(breaks = seq(1950, 2100, 25)) + 
    labs(y = "", subtitle = "Working Age Population (15-64)") + 
    scale_color_stata()

ggsave("Working Age Population China India Line.png", plot, width = 9, height = 7)


# Percent of world's population with absolute number of workers expected to decline --------

df <- rio::import("final_derived_labor_growth.dta") %>% dfdt()
df[,count:=ifelse(aveP1_popwork<0, 1, 0)]
df <- df[,.(poptotal, count, iso3c, year)]
df <- df[,.(poptotal = sum(poptotal, na.rm = T)),by = .(count, year)]
df <- df[poptotal!=0]
df[count==1, indic:= "Decline"]
df[count==0, indic:= "Growth"]
df[,globalpop:=sum(poptotal, na.rm = T),by=.(year)]
df[,poptotl_perc:=poptotal/globalpop]

plot <- df %>% 
    filter(year!=1950) %>% 
    ggplot(aes(
    x = year,
    y = round(poptotl_perc*100, 1),
    group = indic,
    color = indic
)) + geom_line() +
    my_custom_theme +
    scale_x_continuous(breaks = seq(1950, 2100, 25)) +
    labs(y = "", subtitle = "Percent of global population living in countries where growth in working age population (15-64) is expected \nto grow or decline") +
    scale_color_stata()

ggsave("Number of Population Growth and Decline Line.png", plot, width = 9, height = 7)


#  one concern about the use of fertility as an IV for number of workers 20-65 is 
#  that it doesn't include immigrants *into* a country
#  what does the literature say about growth regressions of this sort?

#  --------------------
#  When did they happen (just a histogram by five year period)? How large the percentage drop in workers (*median* size by five year period)

df <- rio::import("final_derived_labor_growth.dta") %>% dfdt()



# Plots of HICs -----------------------------------------------------------

df <- readstata13::read.dta13("hics_collapsed_final_derived_labor_growth.dta") %>% as.data.table()

df <- df %>% rename(
    "GDP, PPP (PWT)" = "rgdp_pwt",
    "Government expenditures (% of GDP) (IMF Fiscal Monitor)" = "fm_gov_exp",
    "Government revenue including Social Contributions (UN GRD)" = "rev_inc_sc",
    "Stock returns (%)" = "l1avgret",
    "Female Labor Force Participation (%)" = "flp",
    "Total Labor Force Participation (%)" = "lp"
) %>% as.data.frame() %>% as.data.table()


for (i in c(
    "GDP, PPP (PWT)",
    "Government expenditures (% of GDP) (IMF Fiscal Monitor)",
    "Government revenue including Social Contributions (UN GRD)",
    "Stock returns (%)",
    "Female Labor Force Participation (%)",
    "Total Labor Force Participation (%)"
)) {
    plot <-
        ggplot(
            df,
            aes(
                x = year,
                y = eval(as.name(i)),
                group = NEG_popwork,
                linetype = NEG_popwork
            )
        ) +
        geom_line() +
        my_custom_theme +
        scale_x_continuous(limits = c(1985, 2020)) +
        labs(
            x = "",
            y = "",
            title = paste0(i, " in HICs"),
            subtitle = 
                paste0(strwrap("When working-age population growth is Negative or Positive. Years were dropped if there were less than 10 countries in sample.", 100), collapse = "\n")
        ) +
        scale_color_manual(values = c("#00677F", "#8B0000", "#693C5E", "#FFBF3F", "#000000"))
    
    ggsave(paste0(
        cleanname(cleanname(make.names(i)))
        , "_HIC_line",  ".pdf"), plot)
}


# Plots of HICs 2 ---------------------------------------------------------

# import and convert country codes:
j <- readstata13::read.dta13("hic_10yr_event_study.dta") %>% dfdt()
j[,country:=code2name(iso3c)]

# variable labels
a <- fread("
name	varlab
rgdp_pwt	GDP
rgdppc_pwt	GDP per capita
fm_gov_exp	Government expenditures
rev_inc_sc	Government revenue
cpi	CPI
yield_10yr	10 year yields
index_inf_adj	Stock Index
flp	Female Labor Force Participation
lp	Labor Force Participation
")

# gather our variables
j <- j %>% rename(x = var) %>% dfdt()

# get variable labels
j <- merge(j, a, by.x = "x", by.y = "name", all = T) %>% dfdt()

# all rows should have a variable label
waitifnot(sum(is.na(j$varlab))==0)

# remove things without values
j <- j[!is.na(value)]

# for formatting in graph: define the max year:
j[, maxyr := max(year), by = .(iso3c, x)]

plot <- ggplot(data = j) +
    geom_line(aes(x = year,
                  y = value,
                  group = country),
              color = "grey75") +
    geom_line(aes(x = year,
                  y = value_mean),
              color = "red") +
    geom_point(data = j[year == maxyr],
               aes(x = year,
                   y = value,
                   group = country),
               color = "grey75") +
    geom_point(data = j[year == 10],
               aes(x = year,
                   y = value_mean),
               color = "red") +
    my_custom_theme +
    scale_x_continuous(breaks = seq(-10, 10, 2),
                       limits = c(-10, 10)) +
    labs(x = "", y = "") +
    scale_color_custom +
    geom_text_repel(
        data = j[year == maxyr],
        aes(
            x = year,
            y = value,
            group = country,
            label = country
        ),
        color = "grey50"
    ) + 
    geom_vline(xintercept = 1,
                color="gray80", 
                linetype="dashed")+
    facet_wrap( ~ varlab, scales = "free")

# setwd(output_dir)
ggsave("HIC_UMIC_10yr_event.pdf", plot, width = 10, height = 10)
# setwd(input_dir)
    






















# \\\\\\ ------------------------------------------------------------------

#  What were economic growth rates during those five year periods compared to the (last) (ten year?) period before labor force growth was negative?
# 
#  What were economic growth rates during those five year periods compared to the global (and country income group) average growth?
#  ---------------------------------------------
# 
#  What happened to government revenues and deficits during those periods compared to prior?
# 
#  What happened to interest rates and stock market returns?
# 
#  What happened to the unemployment rate total labor force participation and female labor force participation?
# 
#  Take out cases which overlap with a country being at war (https:# correlatesofwar.org/data-sets) and then take out low and lower middle income countries and see if that makes a difference.
# 
#  Look forward: according to the UN population forecasts, how many countries in each forthcoming five year period will see declining working age population? How large the percentage drop in workers (*median* size by five year period)
# 
#  "instrument' or just use the predicted change in working age population from ten years prior (e.g. us value for population aged 10-54 in 1980 as the value for population aged 20-64 in 1990) and/or try 20 year lag.
# 
#  Thanks!


































