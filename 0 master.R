rm(list = ls()) # clear the workspace

# Options: ----------------------------------------------------------------

# debugging
options(error=browser)
options(error=NULL)

# disable data.table auto-indexing (causes errors w/ dplyr functions)
options(datatable.auto.index = FALSE)

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
list.of.packages <- c( "base", "car", "cowplot", "dplyr", "ggplot2",
    "ggthemes", "graphics", "grDevices", "grid", "gridExtra", "gvlma", "h2o",
        "lubridate", "MASS", "readxl", "rio", "rms", "rsample", "stats",
        "tidyr", "utils", "zoo", "xtable", "stargazer", "data.table",
        "ggrepel", "foreign", "fst", "countrycode", "wbstats", "quantmod",
        "R.utils", "leaps", "bestglm", "dummies", "caret", "jtools",
        "huxtable", "haven", "ResourceSelection", "betareg", "quantreg",
        "margins", "plm", "collapse", "kableExtra", "tinytex", "LambertW",
        "scales", "stringr", "imputeTS", "shadowtext", "pdftools", "glue",
        "purrr", "OECD", "RobustLinearReg", "forcats", "WDI", "xlsx", "readstata13")

new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
if (length(new.packages)) install.packages(new.packages, dependencies = TRUE)
for (package in list.of.packages) {library(eval((package)), character.only = TRUE)}

# set GGPLOT default theme:
theme_set(theme_clean() + 
              theme(plot.background = 
                        element_rect(color = "white")))

# source(paste0(root_dir, "code/", "helper_functions.R"))
source(paste0("C:/Users/", user, "/Dropbox/Coding_General/personal.functions.R"))

