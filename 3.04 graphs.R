# Graphing ---------------------------------------------------------------------------
# UN population figures: working age population
setwd(input_dir)
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

ggsave(glue("{overleaf_dir}/Working Age Population China India Line.png"), plot, width = 9, height = 7)


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

ggsave(glue("{overleaf_dir}/pop_g_line.pdf"), plot, width = 9, height = 7)

# Countries with declining workers vs. those without ----------------------
pvq <- as.data.table(rio::import("un_pop_estimates_cleaned.dta"))

# only 5 year periods
pvq <- pvq[year%%5==0]

# balanced panel:
bal_panel <- CJ(iso3c = unique(pvq$iso3c), year = unique(pvq$year))
pvq <- merge(bal_panel, pvq, by = c('iso3c','year'),all=T)
waitifnot(nrow(pvq) == nrow(na.omit(pvq)))

# negative growth
pvq <- pvq[order(iso3c, year)]
pvq[,diff:=shift(popwork,1), by = "iso3c"]
pvq[,ret:=popwork / diff - 1 , by = "iso3c"]
pvq[,neg_gr:=as.numeric(ret<0), by = "iso3c"]
pvq <- na.omit(pvq)

# number of countries w/ negative growth (and positive) per year
pvq <- pvq[,.(
    negative = sum(neg_gr),
    positive = length(neg_gr) - sum(neg_gr),
    positive_check = sum(neg_gr == 0)
    ), 
    by = "year"]
waitifnot(nrow(pvq[positive!=positive_check])==0)
pvq$positive_check <- NULL

# make longer for graphing
pvq <- as.data.table(pivot_longer(pvq, c("negative", "positive")))
pvq[name == "negative",value:=-value]
pvq[,name:=str_to_title(name)]

# graph
PLOT <- ggplot(pvq) +
    geom_bar(aes(
        x = year,
        y = value,
        color = name,
        fill = name,
        group = name,
    ),
        stat = "identity")+
    my_custom_theme +
    labs(
        subtitle = "Number of Countries",
        x = "",
        y = ""#,
        # title = "Count of countries with negative vs. positive prime-age population growth"
    ) + 
    scale_color_manual(values = c("firebrick4", "dodgerblue2"),
                       labels = c("Negative", "Positive")) + 
    scale_fill_manual(values = c("red2", "grey96"),
                         labels = c("Negative", "Positive")) + 
    scale_y_continuous(breaks=seq(-150,200,by=50),
                       labels=abs(seq(-150,200,by=50))) + 
    scale_x_continuous(breaks = seq(1950,2100,10)) 

setwd(overleaf_dir)
ggsave(
    glue("{overleaf_dir}/count_country_papg.pdf"),
    PLOT,
    width = 10,
    height = 5
)
setwd(input_dir)


# GDP per capita growth ---------------------------------------------------

pvq <- as.data.table(rio::import("un_pop_estimates_cleaned.dta"))

# only 5 year periods
pvq <- pvq[year%%5==0]

# get GDP per capita & its growth
pvq_gdp <- as.data.table(rio::import("pwt_cleaned.dta"))
pvq_gdp <- pvq_gdp[,.(iso3c, year, rgdp_pwt)]

# merge
pvq <- merge(pvq, pvq_gdp, by = c('iso3c','year'),all.x = T)
pvq <- na.omit(pvq)
pvq[,gdppc:=rgdp_pwt / poptotal * 10^6]
pvq <- pvq[,.(iso3c, year, gdppc, popwork)]
pvq <- pvq[order(iso3c, year)]

# balanced panel:
pvq <- pvq[year >= 1960, .(iso3c, year, popwork, gdppc)] %>%
    pivot_wider(.,
                names_from = "year",
                values_from = c("popwork", "gdppc"))
tolongnames <- setdiff(names(pvq), "iso3c")
pvq <- pvq %>% 
    na.omit() %>%
    pivot_longer(cols = all_of(tolongnames)) %>%
    separate(col = name, sep = "_", into = c("variable", "year")) %>% 
    as.data.table()
pvq <- pvq %>% 
    pivot_wider(values_from = "value", names_from = "variable") %>% 
    as.data.table()
pvq[,n:=.N,by="iso3c"]
waitifnot(max(pvq$n)==min(pvq$n))
pvq$n <- NULL

# avg GDP per capita for negative vs. positive 5 year periods
pvq <- pvq[order(iso3c, year)]
for (i in c("popwork", "gdppc")){
pvq[,c(glue("gr_{i}")):=eval(as.name(i)) / shift(eval(as.name(i)))-1, by = "iso3c"]
}
pvq[gr_popwork<0,neg_popwork:=1]
pvq[gr_popwork>=0,neg_popwork:=0]
pvq <- pvq[, .(gr_gdppc = mean((1+gr_gdppc) ^ (1 / 5)-1)), by = c("year", "neg_popwork")]
pvq <- na.omit(pvq) 
pvq[neg_popwork==1,name:="Countries with negative prime-age population growth"]
pvq[neg_popwork==0,name:="Countries with positive prime-age population growth"]
pvq$year <- as.numeric(pvq$year)

# plot
# graph
PLOT <- ggplot(pvq) +
    geom_bar(aes(
        x = year,
        y = gr_gdppc,
        color = name,
        fill = name,
        group = name
    ),
    # width = 2,
    stat = "identity")+
    my_custom_theme +
    labs(
        subtitle = "Annualized GDP per capita growth",
        x = "",
        y = ""
    ) + 
    scale_color_manual(values = c("firebrick4", "dodgerblue2"),
                       labels = c("Countries with negative prime-age population growth", 
                                  "Countries with positive prime-age population growth")) + 
    scale_fill_manual(values = c("red2", "grey96"),
                      labels = c("Countries with negative prime-age population growth", 
                                 "Countries with positive prime-age population growth")) + 
    facet_wrap(~name) + 
    geom_hline(yintercept = 0) + 
    theme(legend.position = "none") + 
    theme(axis.text.y = element_text(
        size = 12,
        vjust = 0.5,
        margin = unit(c(
            t = 0,
            r = 1,
            b = 0,
            l = 0
        ), "mm"),
        color = "gray57"
    )) + 
    scale_x_continuous(breaks = seq(1965, 2020, 5)) + 
    scale_y_continuous(breaks = seq(-0.04,0.04,0.01))

setwd(overleaf_dir)
ggsave(
    glue("{overleaf_dir}/gdppc_country_papg.pdf"),
    PLOT,
    width = 12,
    height = 5
)
setwd(input_dir)

# Government Revenue Growth ----------------------------------------

pvq <- as.data.table(rio::import("un_pop_estimates_cleaned.dta"))

# only 5 year periods
pvq <- pvq[year%%5==0]

# get government revenue
pvq_rev <- as.data.table(rio::import("clean_grd.dta"))
pvq_rev <- pvq_rev[,.(iso3c, year, govrev = rev_inc_sc)]
check_dup_id(pvq_rev, c("iso3c", "year"))

# merge
pvq <- merge(pvq, pvq_rev, by = c('iso3c','year'),all.x = T)
pvq <- na.omit(pvq)
pvq <- pvq[,.(iso3c, year, govrev, popwork)]
pvq <- pvq[order(iso3c, year)]

# balanced panel:
pvq <- pvq[year >= 1960 & year <= 2022, .(iso3c, year, popwork, govrev)] %>%
    pivot_wider(.,
                names_from = "year",
                values_from = c("popwork", "govrev"))
tolongnames <- setdiff(names(pvq), "iso3c")
pvq <- pvq %>% 
    na.omit() %>%
    pivot_longer(cols = all_of(tolongnames)) %>%
    separate(col = name, sep = "_", into = c("variable", "year")) %>% 
    as.data.table()
pvq <- pvq %>% 
    pivot_wider(values_from = "value", names_from = "variable") %>% 
    as.data.table()
pvq[,n:=.N,by="iso3c"]
waitifnot(max(pvq$n)==min(pvq$n))
pvq$n <- NULL

# avg GDP per capita for negative vs. positive 5 year periods
pvq <- pvq[order(iso3c, year)]
for (i in c("popwork", "govrev")){
pvq[,c(glue("gr_{i}")):=eval(as.name(i)) / shift(eval(as.name(i)))-1, by = "iso3c"]
}
pvq[gr_popwork<0,neg_popwork:=1]
pvq[gr_popwork>=0,neg_popwork:=0]
pvq <- pvq[, .(gr_govrev = mean((1+gr_govrev) ^ (1 / 5)-1)), by = c("year", "neg_popwork")]
pvq <- na.omit(pvq) 
pvq[neg_popwork==1,name:="Countries with negative prime-age population growth"]
pvq[neg_popwork==0,name:="Countries with positive prime-age population growth"]
pvq$year <- as.numeric(pvq$year)

# plot
# graph
PLOT <- ggplot(pvq) +
    geom_bar(aes(
        x = year,
        y = gr_govrev,
        color = name,
        fill = name,
        group = name
    ),
    # width = 2,
    stat = "identity")+
    my_custom_theme +
    labs(
        subtitle = "Annualized government revenue (% GDP) growth",
        x = "",
        y = ""
    ) + 
    scale_color_manual(values = c("firebrick4", "dodgerblue2"),
                       labels = c("Countries with negative prime-age population growth", 
                                  "Countries with positive prime-age population growth")) + 
    scale_fill_manual(values = c("red2", "grey96"),
                      labels = c("Countries with negative prime-age population growth", 
                                 "Countries with positive prime-age population growth")) + 
    facet_wrap(~name) + 
    geom_hline(yintercept = 0) + 
    theme(legend.position = "none") + 
    theme(axis.text.y = element_text(
        size = 12,
        vjust = 0.5,
        margin = unit(c(
            t = 0,
            r = 1,
            b = 0,
            l = 0
        ), "mm"),
        color = "gray57"
    )) + 
    scale_x_continuous(breaks = seq(1965, 2020, 5)) + 
    scale_y_continuous(breaks = seq(-0.04,0.04,0.01))

setwd(overleaf_dir)
ggsave(
    glue("{overleaf_dir}/govrev_country_papg.pdf"),
    PLOT,
    width = 12,
    height = 5
)
setwd(input_dir)


#  one concern about the use of fertility as an IV for number of workers 20-65
#  is that it doesn't include immigrants *into* a country what does the
#  literature say about growth regressions of this sort?

# Plots of HICs -----------------------------------------------------------

df <- readstata13::read.dta13("hics_collapsed_final_derived_labor_growth.dta") %>% as.data.table()

df <- df %>% rename(
    "GDP, PPP (PWT)" = "rgdp_pwt",
    "Government expenditures (% of GDP) (IMF Fiscal Monitor)" = "fm_gov_exp",
    "Government revenue including Social Contributions (UN GRD)" = "rev_inc_sc",
    # "Stock returns (%)" = "l1avgret",
    "Female Labor Force Participation (%)" = "flp",
    "Total Labor Force Participation (%)" = "lp"
) %>% as.data.frame() %>% as.data.table()

for (i in c(
    "GDP, PPP (PWT)",
    "Government expenditures (% of GDP) (IMF Fiscal Monitor)",
    "Government revenue including Social Contributions (UN GRD)",
    # "Stock returns (%)",
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
    
    ggsave(
        paste0(
            overleaf_dir,
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
ggsave(glue("{overleaf_dir}/HIC_UMIC_10yr_event.pdf"), plot, width = 10, height = 10)
# setwd(input_dir)
