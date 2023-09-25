smmry_tbl <- as.data.table(readstata13::read.dta13("summary_statistics_table.dta"))
orig_names <- names(smmry_tbl)
new_names <- orig_names %>% gsub("_", " ", ., fixed = TRUE) %>% str_to_title()
names(smmry_tbl) <- new_names

smmry_tbl <- smmry_tbl %>%
    rename(
        " " = "Variable Label",
        "SD" = "Sd",
        "Countries" = "Number Of Countries",
        "Observations" = "Number Of Observations"
    ) %>%
    mutate( 
        " " = case_match(
            ` `, 
            "GDP" ~ "GDP (Billions)",
            "GDP per capita" ~ "GDP per capita",
            "Total Population" ~ "Total Population (Millions)",
            "Total Working-Age Population" ~ "Total Working-Age Population (Millions)",
            .default = ` `
        )
    )

pop_units <- 1000000  # Millions (10^6)
gdp_units <- 1000000000  # Billions (10^9)

smmry_tbl[
    ` ` == "GDP (Billions)",
    `:=`(Mean = Mean / gdp_units, SD = SD / gdp_units)
][
    ` ` %chin% c("Total Population (Millions)", "Total Working-Age Population (Millions)"),
    `:=`(Mean = Mean / pop_units, SD = SD / pop_units)
]


#smmry_tbl[abs(Mean) <= 10^6, Mean := as.numeric(format(Mean, digits = 1, scientific = FALSE))]
#smmry_tbl[abs(Mean) > 10^6, Mean := as.numeric(format(Mean, scientific = TRUE))]


kbl_smmry_numeric <- smmry_tbl %>%
    kbl(
        "latex",
        caption = "Summary Statistics",
        label = "smmry_tbl",
        booktabs = TRUE,
        longtable = TRUE,
        digits = 1,
        align = "c",
        linesep = "",
        format.args = list(scientific = FALSE)
    ) %>%
    kableExtra::kable_styling(
        position = "center",
        font_size = 8,
        latex_options =
            c("hold_position",
              "repeat_header"#,
              #"striped"
              )
    ) %>%
    column_spec(1, width = "24em") %>%
    column_spec(2, width = "4em") %>%
    column_spec(3, width = "4em") %>%
    column_spec(4, width = "4em") %>%
    column_spec(5, width = "4em") %>%
    column_spec(6, width = "4em") %>%
    column_spec(7, width = "4em") %>%
    column_spec(8, width = "4em") %>%
    column_spec(9, width = "4em") %>%
    column_spec(10, width = "10em") #%>%
    # pack_rows(
    #     index = table(output_table_numeric$Source),
    #     color = "black",
    #     background = "gray!10",
    #     hline_after = TRUE
    # ) %>%
    # footnote(general = "Later analysis is dependent on the observations that are present within.", threeparttable = FALSE)

#collapse_rows(columns = 1,latex_hline = "major", valign = "middle")

save_kable(kbl_smmry_numeric, file.path(overleaf_dir, "smmry_tbl.tex"), header = FALSE)

