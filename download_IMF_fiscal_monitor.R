library(imfr) # To access IMF data API
library(magrittr)
library(tidyr)
library(data.table)
library(countrycode)

imf_databases$description %>% grep("fiscal monitor", .,
                                   ignore.case = T,
                                   value = T)

imf_databases <- imf_ids() %>% as.data.table()
database_id_val <-
    imf_databases[description == "Fiscal Monitor (FM)"]$database_id
codelist <-
    imf_codelist(database_id = database_id_val) %>% as.data.table()
codelist_val <-
    codelist[description == "Geographical Areas"]$codelist
indicator_val <-
    codelist[description == "Indicator"]$codelist
AREA_codes <-
    imf_codes(codelist = codelist_val) %>% as.data.table()
INDICATOR_codes <-
    imf_codes(codelist = indicator_val) %>% as.data.table()
data(codelist)
country_set <- codelist
country_set <- country_set %>%
    select(country.name.en , iso2c, iso3c, imf, continent, region) %>%
    filter(!is.na(imf) &
               !is.na(iso2c))
iso2_vec <- country_set$iso2c

# Fiscal monitor data

fm_ls <- list()
start_num <- 1
end_index <- start_num + 49
while (end_index < length(iso2_vec)) {
    end_index <- min(start_num + 49, length(iso2_vec))
    fm_ls[as.character(start_num)] <-
        imf_data(
            database_id = "FM" ,
            country = iso2_vec[start_num:end_index],
            start = 2010,
            end = current_year(),
            return_raw = TRUE,
            indicator = "All_indicators"
        )
    start_num <- start_num + 50
}