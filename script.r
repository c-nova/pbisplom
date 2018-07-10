################# DEBUG in RStudio #################
# setwd("C:/opt/sandbox/pbisplom")
# Values <- read.csv("../testVizRDoc/HR_comma_sep.csv", sep = ",")
# fileRda = "C:/Users/maotsuka.FAREAST/AppData/Local/Temp/tempData.Rda"
# if(file.exists(dirname(fileRda)))
# {
#  if(Sys.getenv("RSTUDIO")!="")
#    load(file= fileRda)
#  else
#    save(list = ls(all.names = TRUE), file=fileRda)
# }
####################################################

############### Library Declarations ###############
#library("progress") <- This moduele not compatible PBI Service
library("ggplot2")
library("showtext")
library("scales")
library("colorspace")
library("GGally")
####################################################

################### Actual code ####################
colorsw = "FALSE"
if(exists("SettingsEnablecolor_colorsw")){
    colorsw = SettingsEnablecolor_colorsw
}
powerbi_rEnableShowTextForCJKLanguages =  1
{
    if(colorsw == "TRUE" && is.na(graphColor) == "FALSE" && is.null(graphColor) == "FALSE") {
        ggp = ggpairs(Values, mapping = aes(colour = graphColor))
    }
    else ggp = ggpairs(Values)
}

print(ggp, progress = F)
####################################################
