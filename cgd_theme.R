library(ggthemes)
#library(tidyverse)

# Instructions to install the latex font: https://fulowa.medium.com/latex-font-in-a-ggplot-9120caaa5250#:~:text=First%20one%20needs%20to%20go,ttf%20file%20and%20click%20install.&text=then%20run%20font_import(pattern%20%3D%20%E2%80%9C,in%20R%20to%20add%20fonts.
# execute once to add fonts:
library(extrafont) 
#font_import(pattern = "lmroman*") 
#font_import(pattern = "Source*")
#loadfonts()
fonts()


##########################################################################
########## Implementing the CGD graphics guide in ggplot2 ################
##########################################################################
## Guide: https://centerforglobaldevelop.sharepoint.com/sites/fileshare/Shared%20Documents/Forms/AllItems.aspx?ga=1&id=%2Fsites%2Ffileshare%2FShared%20Documents%2FNDrive%2FCommunications%2FCGD%20Branding%20Materials%2FCGD%2DData%2DViz%2DStyle%2DGuide%2Epdf&viewid=23e5bfee%2D12a8%2D4a15%2Dac13%2Dfba17c53a2db&parent=%2Fsites%2Ffileshare%2FShared%20Documents%2FNDrive%2FCommunications%2FCGD%20Branding%20Materials

## This script:
## 1) Provides the colors and color order to use CGD colors for graphs. 

## 2) Provides a theme_cgd object that can be added to ggplots to automate 
## non-data aspects of plots.


#####################################
############## Colors ###############
#####################################

## It's not really possible to automate how color is used, as it depends so
## much on the data. Below are some general instructions on how the guide
## recommends they be used (but feel free to experiment yourself).

## There are three types of color order: categorical is for non-ordered, categorical
## variables; sequential is for neutral or all-positive scales/gradations,
## like 10%>20%>30% or good>better>best; polar is for when there is a negative
## component, like -10%>0>10% or bad>neutral>good.

## For each of sequential and polar, there are several options depending on how
## much of a range of color the user wants the scale to cover. Will generally
## want to use sequential2 or sequential3 (looks cleaner), but if they want to
## tease out differences in middle parts of the scale they can use higher.

## When using 'scale_fill_discrete()' or 'scale_color_discrete()' with polar or sequential,
## you can use 'type = sequential' or 'type = polar' and ggplot will automatically
## use the version with the same number of colors as levels of the factor it is graphing.

## For sequential, an alternative is using alpha: set alpha = continuous_variable within aes,
## and use fill = light_teal (or another CGD color) outside of it

## Note that guide also recommends light gray to denote 'none/neutral' for categorical
## or sequential graphs. If you use all light gray for category or part of sequence,
## and also have none/neutral elements, then need to use a different color to denote 'none/neutral'

teal <- "#0B4C5B"
gold <- "#FFB52C"
teal_gray <- "#85A5AD"
light_teal <- "#006970"
cream <- "#F3F6F7"
dark_gray <- "#394649"
teal_black <- "#1A272A"
blue <- "#2D99B5"
light_blue <- "#BFDEE0"
light_gold <- "#FEE8BF"
light_gray <-  "#DFE0E2"
red <- "#D15553"
green <- "#00896C"

categorical <- c(light_teal, gold, blue, light_blue, light_gold, teal_gray,
                 dark_gray, light_gray)

sequential1 <- light_teal
sequential2 <- c(light_blue, light_teal)
sequential3 <- c(light_gray, light_blue, light_teal)
sequential4 <- c(light_gray, light_blue, light_teal, dark_gray)
sequential8 <- c(light_gray, teal_gray, light_blue, blue, light_teal,
                  teal, dark_gray, teal_black)
sequential <- list(sequential1, sequential2, sequential3, sequential4, sequential8)

polar1 <- light_teal
polar2 <- c(light_teal, gold)
polar3 <- c(light_teal, teal_gray, gold)
polar4 <- c(light_teal, teal_gray, light_gold, gold)
polar5 <- c(light_teal, teal_gray, light_blue, light_gold, gold)
polar <- list(polar1, polar2, polar3, polar4, polar5)

stoplight <- c(green, gold, red)


#####################################
############ CGD theme ##############
#####################################

## You can just save theme_cgd as an object and then add it to a graph like this:
## ggplot(data) +
##   geom_point(aes(x, y)) +
##   theme_cgd

## Note, no brackets after.

theme_cgd_sofia <- theme_classic() +
  theme(text = element_text(family = "Sofia Pro"),
        plot.title = element_text(color = teal),
        plot.subtitle = element_text(color = teal), ## Ideally, these should be in bold
        axis.title = element_text(color = teal), ## Ideally, these should be in bold
        axis.text = element_text(color = teal_black),
        axis.line = element_line(color = teal_black), ## size = 1 is too large here
        axis.ticks = element_blank(),
        axis.title.y = element_blank(),
        #legend.title = element_text(color = teal),
        #legend.text = element_text(color = teal_black),
        strip.text = ggplot2::element_text(hjust = 0)
  )

theme_cgd_texfont <- theme_classic() +
  theme(text = element_text(family = "Source Code Pro ExtraLight"),
        plot.title = element_text(color = teal),
        plot.subtitle = element_text(color = teal), ## Ideally, these should be in bold
        axis.title = element_text(color = teal), ## Ideally, these should be in bold
        axis.text = element_text(color = teal_black),
        axis.line = element_line(color = teal_black), ## size = 1 is too large here
        axis.ticks = element_blank(),
        axis.title.y = element_blank(),
        #legend.title = element_text(color = teal),
        #legend.text = element_text(color = teal_black),
        strip.text = ggplot2::element_text(hjust = 0)
  )

theme_cgd_nofont <- theme_classic() +
  theme(
      plot.title = element_text(color = teal),
      plot.subtitle = element_text(color = teal), ## Ideally, these should be in bold
      axis.title = element_text(color = teal), ## Ideally, these should be in bold
      axis.text = element_text(color = teal_black),
      axis.line = element_line(color = teal_black), ## size = 1 is too large here
      axis.ticks = element_blank(),
      axis.title.y = element_blank(),
      #legend.title = element_text(color = teal),
      #legend.text = element_text(color = teal_black),
      strip.text = ggplot2::element_text(hjust = 0)
  )

texfont <- theme(
      text = element_text(family = "Source Code Pro ExtraLight")
)
