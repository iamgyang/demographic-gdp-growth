# set GGPLOT default theme:
theme_set(
    theme_clean() + theme(
        plot.background = element_rect(color = "white"),
        axis.text.x = element_text(angle = 90),
        legend.title = element_blank()
    )
)

# easily import all excel sheets
read.xl.sheets <- function(Test_Cases) {
    names.init <- excel_sheets(Test_Cases)
    test.ex <- list()
    counter <- 1
    for (val in names.init) {
        test.ex[[counter]] <-
            as.data.frame(read_excel(Test_Cases, sheet = val))
        counter <- counter + 1
    }
    names(test.ex) <- names.init
    test.ex <- lapply(test.ex, as.data.table)
    test.ex
}

# wrapper functions for converting from a country code to a name, vice versa
code2name <-
    function(x, ...) {
        countrycode(x, "iso3c", "country.name", ...)
    }

name2code <-
    function(x, ...) {
        countrycode(x, "country.name", "iso3c", ...)
    }

name2region <-
    function(x) {
        countrycode(x, "country.name", "un.region.name")
    }

coalesce2 <- function(...) {
    Reduce(function(x, y) {
        i <- which(is.na(x))
        if (class(x)[1] != class(y)[1])
            stop("ahh! classes don't match")
        x[i] <- y[i]
        x
    },
    list(...))
} 

# function from mrip https://stackoverflow.com/questions/19253820/how-to-implement-coalesce-efficiently-in-r
dfcoalesce <- function(df_, newname, first, second) {
    df_ <- as.data.frame(df_)
    df_[, newname] <- coalesce2(df_[, first],
                                df_[, second])
    df_[, first] <- NULL
    df_[, second] <- NULL
    df_
}

# function that coalesces any duplicates (.x, .y): note: it only merges the
# names that have .x and .y at the END you must make sure that things are
# properly labeled as "NA" from the beginning
dfcoalesce.all <- function(df_) {
    tocolless.1 <- names(df_)[grep("\\.x", names(df_))]
    tocolless.2 <- names(df_)[grep("\\.y", names(df_))]
    tocolless.1 <- gsub("\\.x", "", tocolless.1)
    tocolless.2 <- gsub("\\.y", "", tocolless.2)
    tocolless <- intersect(tocolless.1, tocolless.2)
    
    for (n_ in tocolless) {
        first <- paste0(n_, ".x")
        second <- paste0(n_, ".y")
        different <-
            sum(na.omit(df_[, first] == df_[, second]) == FALSE)
        # error if there is something different between the two merges:
        cat(
            paste0(
                " For the variable ",
                n_,
                ", you have ",
                different,
                " differences between the x and y column. \n Coalesced while keeping x column as default. \n"
            )
        )
        df_ <- dfcoalesce(
            df_,
            newname = n_,
            first = paste0(n_, ".x"),
            second = paste0(n_, ".y")
        )
    }
    df_
}

# function that pauses code if there's an error
waitifnot <- function(cond) {
    if (!cond) {
        msg <- paste(deparse(substitute(cond)), "is not TRUE")
        if (interactive()) {
            message(msg)
            while (TRUE) {
                
            }
        } else {
            stop(msg)
        }
    }
}

my_custom_theme <- list(
    theme(
        plot.subtitle = element_text(margin = margin(0, 0, 10, 0)),
        legend.background = element_blank(),
        legend.position = "top",
        legend.justification = c("left", "top"),
        legend.box.just = "left",
        legend.title = element_blank(),
        legend.text = element_text(
            size = 12,
            color = "black"
        ),
        axis.text.x = element_text(
            angle = 0,
            vjust = 0.5,
            size = 12,
            color = "black"
        ),
        axis.title.x = element_text(
            size = 12
        ),
        axis.title.y = element_text(
            angle = 0,
            vjust = 0.5,
            hjust = 0.5,
            size = 12
        ),
        axis.text.y = element_text(
            size = 12,
            vjust = -0.5,
            margin = unit(c(
                t = 0,
                r = -6,
                b = 0,
                l = 0
            ), "mm"),
            color = "gray57"
        ),
        axis.line.x = element_line(linewidth = 0.5, color = "grey50"),
        axis.line.y = element_blank(),
        text = element_text(size = 16),
        legend.key.size = unit(.5, "line")
    )
)


color_ordered <-
    c(
        "#000000",
        "#f82387",
        "#53c24c",
        "#a464e0",
        "#99bb2b",
        "#5753bf",
        "#85c057",
        "#c93da3",
        "#50942f",
        "#e073d3",
        "#49c380",
        "#9646a7",
        "#b3b23d",
        "#667ce9",
        "#daae40",
        "#655ea2",
        "#de8c31",
        "#618dcf",
        "#e4662c",
        "#4cb5dd",
        "#c53822",
        "#5eccb7",
        "#e03d47",
        "#3da08b",
        "#db3963",
        "#35772f",
        "#e1478c",
        "#5da266",
        "#ad3a76",
        "#9ac074",
        "#b78fdd",
        "#7d8220",
        "#cf87b9",
        "#52701e",
        "#e5769b",
        "#307646",
        "#be4b49",
        "#24765a",
        "#eb8261",
        "#536c31",
        "#924f7a",
        "#8b9751",
        "#a4485b",
        "#c2b572",
        "#a75521",
        "#636527",
        "#e28889",
        "#a6812a",
        "#a05940",
        "#d79e6c",
        "#84662e"
    )

scale_color_custom <- 
    list(
        scale_color_manual(values = color_ordered),
        scale_fill_manual(values = color_ordered)
    )

SameElements <- function(a, b) return(identical(sort(a), sort(b)))

dfdt <- function(x) as.data.table(as.data.frame(x))

# insert line breaks into paragraph for commenting
con <- function(string_) {cat(strwrap(string_, 60),sep="\n")}

# clean names
name.df <- function(df){names(df) <- tolower(make.names(names(df))) %>% 
    gsub("..",".",.,fixed=TRUE) %>% gsub("[.]$","",.); df}

cleanname <- function (name) {
    name <- tolower(make.names(names(name))) %>%
        gsub("..", ".", ., fixed = TRUE) %>%
        gsub("[.]$", "", .)
    name
}

# country code interactive
code2name <- function(x,...) {countrycode(x,"iso3c","country.name",...)}
name2code <- function(x,...) {countrycode(x,"country.name","iso3c",...)}

# automatically convert columns to numeric:
auto_num <- function(df_, sample_=10 , cutoff_ = 7){
    to_numeric <- sample_n(df_, sample_, replace = T) %>%
        lapply(function(x)
            sum(as.numeric(grepl("[0-9]", x))) >= cutoff_)
    to_numeric <- unlist(names(to_numeric)[to_numeric == TRUE])
    setDT(df_)[, (to_numeric) := lapply(.SD, as.numeric), .SDcols = to_numeric]
    df_
}

# create a function that counts number of NA elements within a row
fun4 <- function(indt) indt[, num_missing_obs := Reduce("+", lapply(.SD, is.na))]  

nonempty_len <- function(x) {length(unique(na.omit(x)))}

# check we don't have duplicated ID values
check_dup_id <-
    function(df, id.vars, na.rm = FALSE) {
        require(dplyr)
        df <- as.data.frame(df)
        if (nonempty_len(id.vars) > 1 & na.rm == FALSE) {
            waitifnot(nrow(distinct(df[, id.vars])) == nrow(df[, id.vars]))
        } else if (nonempty_len(id.vars) > 1 & na.rm == TRUE) {
            waitifnot(nrow(distinct(na.omit(df[, id.vars]))) ==
                          nrow(na.omit(df[, id.vars])))
        } else if (nonempty_len(id.vars) == 1 & na.rm == FALSE) {
            waitifnot(length(unique(df[, id.vars])) == length(df[, id.vars]))
        } else if (nonempty_len(id.vars) == 1 & na.rm == TRUE) {
            waitifnot(length(na.omit(unique(df[, id.vars]))) == 
                          length(na.omit(df[, id.vars])))
        } else if (nonempty_len(id.vars) <= 0) {
            cat('id.vars must exist')
        }
    }

# weighted standard deviation function:
w.sd <- function(x, wt) {sqrt(Hmisc::wtd.var(x, wt))}

# weighted mean function (with NA.RM):
weighted_mean <-  function(x, w, ..., na.rm = FALSE) {
    if (na.rm == TRUE) {
        x1 = x[!is.na(x) & !is.na(w)]
        w = w[!is.na(x) & !is.na(w)]
        x = x1
    }
    weighted.mean(x, w, ..., na.rm = FALSE)
}

# getting percentiles of a group using empirical CDF: <-- ok, literally is an
# inefficient way to call quantile(vector, probs = value)...but keeping it here
# so code doesn't break
per_cdf <- function(value, vector) {
    empirical_cdf <- ecdf(vector)
    return(empirical_cdf(value))
}


# get the number of decimal places after a number
decimalplaces <- function(x) {
    if ((x %% 1) != 0) {
        strs <- strsplit(as.character(format(x, scientific = F)), "\\.")
        n <- nchar(strs[[1]][2])
    } else {
        n <- 0
    }
    return(n) 
}
