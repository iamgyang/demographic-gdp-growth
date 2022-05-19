smmry_tbl <- as.data.table(readstata13::readdta("summary_statistics_table.dta"))
orig_names <- names(smmry_tbl)
new_names <- orig_names %>% gsub("_", " ", ., fixed = T) %>% str_to_title()
names(smmry_tbl) <- new_names

kbl_smmry_numeric <- smmry_tbl %>% 
    kbl(
        "latex",
        caption = "Summary Statistics",
        label = "smmry_tbl",
        booktabs = TRUE,
        longtable = TRUE,
        digits = 0,
        align = "c",
        linesep = ""
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

setwd(overleaf_dir)
save_kable(kbl_smmry_numeric, "smmry_tbl.tex", header = FALSE)
setwd(input_dir)
