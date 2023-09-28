setwd(input_dir)

bob <- as.data.table(readstata13::read.dta13("final_derived_labor_growth.dta"))

reg_list <- list()
reg_list[[1]] <- list()
reg_list[[2]] <- list()
reg_list[[3]] <- list()

names(reg_list) <- c("LLR1", "TWFE", "LLR2")

bob[,D:=as.numeric(aveP1_popwork<0)]
bob[,Year:=as.factor(year)]
bob[,Country:=as.factor(iso3c)]
bob[,aveP1_popwork:=aveP1_popwork*100] # want everything in % percents. e.g. For a 1 percentage point increase in PAPG, real GDP growth increases by X percentage points.

# for these variables, we need to make sure that they're in % growth (b/c the levels aren't really important)
bob <- bob[order(iso3c, year)]
bob[, rgdppc_pwt_pctgrowth := 100 * ((rgdppc_pwt/shift(rgdppc_pwt)) - 1), by = "iso3c"]   
bob[, cpi_pctgrowth := 100 * ((cpi/shift(cpi)) - 1), by = "iso3c"]
bob[, index_inf_adj_pctgrowth := 100 * ((index_inf_adj/shift(index_inf_adj)) - 1), by = "iso3c"]

# rename variables of interest:
bob <- bob %>%
    rename(
        "Real GDP/Capita % growth" = "rgdppc_pwt_pctgrowth",
        "Govt expenditure (% GDP)" = "fm_gov_exp",
        "Govt revenue (% GDP)" = "rev_inc_sc",
        "Inflation %" = "cpi_pctgrowth",
        "10 year yield" = "yield_10yr",
        "Stock index % growth" = "index_inf_adj_pctgrowth",
        "Female labor force participation" = "flp",
        "Labor force participation" = "lp"
    )

var_interest <-
    c(
        "Real GDP/Capita % growth",
        "Govt expenditure (% GDP)",
        "Govt revenue (% GDP)",
        "Inflation %",
        "10 year yield",
        "Stock index % growth",
        "Female labor force participation",
        "Labor force participation"
    )

for (i in var_interest) {
    reg_bob <- as.data.table(bob)
    reg_bob <-
        reg_bob %>%
        rename("X" = all_of(i),
               "PAPG" = "aveP1_popwork",
               "PAPG<0" = "D") %>% 
        dplyr::select(X, PAPG, `PAPG<0`, Year, Country) %>% 
        as.data.table()

    # local linear regression allowing for different intercepts ONLY
    reg_list[[1]][[i]] <- fixest::feols(X ~ PAPG + `PAPG<0` |
                                    Year + Country,
                                data = reg_bob)
    
    # TWFE regression
    reg_list[[2]][[i]] <- fixest::feols(X ~ PAPG |
                                    Year + Country,
                                data = reg_bob)
    
    # local linear regression allowing for different intercepts & slopes
    reg_list[[3]][[i]] <- fixest::feols(X ~ PAPG + 
                                    `PAPG<0` + 
                                    `PAPG<0`:PAPG | 
                                    Year + Country, 
                                data = reg_bob)

}

# FIRST ---------------------
modelsummary::modelsummary(
    reg_list[[1]],
    statistic =  NULL,
    # statistic =  "[{conf.low}, {conf.high}]",
    vcov = NULL,
    output = 'latex',
    estimate = "{estimate}{stars}",
    gof_omit = "AIC|BIC|Log|Std.Errors|R2 Pseudo",
    title = "Local linear regression with different intercepts \\label{tab:llr1int}",
    stars = c('*' = .1, '**' = .05, '***' = .01, '****' = .001)
) %>%
    kableExtra::kable_styling(
        position = "center",
        font_size = 8,
        latex_options = c("hold_position")
    ) %>%
    footnote(general = "OLS of variable of interest on annual percent PAPG and an indicator variable of whether PAPG is negative, with country and year fixed effects. **** p<0.001, *** p<0.01, ** p<0.05, * p<0.1.", threeparttable = TRUE) %>%
    column_spec(1, width = "10em") %>%
    column_spec(2, width = "5em") %>%
    column_spec(3, width = "5em") %>%
    column_spec(4, width = "5em") %>%
    column_spec(5, width = "5em") %>%
    column_spec(6, width = "5em") %>%
    column_spec(7, width = "5em") %>%
    column_spec(8, width = "5em") %>%
    column_spec(9, width = "5em") %>%
    column_spec(10, width = "5em") %>%
    kableExtra::save_kable(glue("{overleaf_dir}/llr1_int.tex"))

# SECOND ----------------
modelsummary::modelsummary(
    reg_list[[2]],
    statistic =  NULL,
    # statistic =  "[{conf.low}, {conf.high}]",
    # vcov = "HC3",
    output = 'latex',
    estimate = "{estimate}{stars}",
    gof_omit = "AIC|BIC|Log|Std.Errors|R2 Pseudo",
    title = "Two way fixed effects regression \\label{tab:twfeint}",
    stars = c('*' = .1, '**' = .05, '***' = .01, '****' = .001)
) %>%
    kableExtra::kable_styling(
        position = "center",
        font_size = 8,
        latex_options = c("hold_position")
    ) %>%
    footnote(general = "OLS of variable of interest on annual percent PAPG, with country and year fixed effects. **** p<0.001, *** p<0.01, ** p<0.05, * p<0.1.", threeparttable = TRUE) %>%
    column_spec(1, width = "10em") %>%
    column_spec(2, width = "5em") %>%
    column_spec(3, width = "5em") %>%
    column_spec(4, width = "5em") %>%
    column_spec(5, width = "5em") %>%
    column_spec(6, width = "5em") %>%
    column_spec(7, width = "5em") %>%
    column_spec(8, width = "5em") %>%
    column_spec(9, width = "5em") %>%
    column_spec(10, width = "5em") %>%
    kableExtra::save_kable(glue("{overleaf_dir}/twfe_int.tex"))

# THIRD --------------------
modelsummary::modelsummary(
    reg_list[[3]],
    statistic =  NULL,
    # statistic =  "[{conf.low}, {conf.high}]",
    # vcov = "HC3",
    output = 'latex',
    estimate = "{estimate}{stars}",
    gof_omit = "AIC|BIC|Log|Std.Errors|R2 Pseudo",
    title = "Local linear regression with different intercepts and slopes \\label{tab:llr2int}",
    stars = c('*' = .1, '**' = .05, '***' = .01, '****' = .001)
) %>%
    kableExtra::kable_styling(
        position = "center",
        font_size = 8,
        latex_options = c("hold_position")
    ) %>%
    footnote(general = "OLS of variable of interest on annual percent PAPG, an indicator variable of whether PAPG is negative, and an interaction term, with country and year fixed effects. **** p<0.001, *** p<0.01, ** p<0.05, * p<0.1.", threeparttable = TRUE) %>%
    column_spec(1, width = "10em") %>%
    column_spec(2, width = "5em") %>%
    column_spec(3, width = "5em") %>%
    column_spec(4, width = "5em") %>%
    column_spec(5, width = "5em") %>%
    column_spec(6, width = "5em") %>%
    column_spec(7, width = "5em") %>%
    column_spec(8, width = "5em") %>%
    column_spec(9, width = "5em") %>%
    column_spec(10, width = "5em") %>%
    kableExtra::save_kable(glue("{overleaf_dir}/llr2_int.tex"))
