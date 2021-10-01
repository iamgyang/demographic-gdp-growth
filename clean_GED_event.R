setwd("C:/Users/user/Dropbox/CGD/Projects/dem_neg_labor/input/ucdp_war")

load("GEDEvent_v21_1.RData")
df <- as.data.table(GEDEvent_v21_1)
df <- df[, .(year, country, best)]
df[, iso3c := name2code(country, custom_match = c("Yemen (North Yemen)" = "YEM"))]
df <- df[, .(est_deaths = sum(best, na.rm = TRUE)), by = c("iso3c", "year")][]
df.exp <- CJ(year = seq(min(df$year), max(df$year), by = 1), iso3c = unique(df$iso3c))
df <- merge(df.exp, df, by = c("iso3c", "year"), all.x = TRUE)
df[is.na(est_deaths),est_deaths:=0]
df <- df[order(iso3c, year)]

setwd("C:/Users/user/Dropbox/CGD/Projects/dem_neg_labor/input/")
readstata13::save.dta13(df, "UCDP_geography_deaths.dta")
