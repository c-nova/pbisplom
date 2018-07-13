################# DEBUG in RStudio #################
# setwd("C:/opt/sandbox/pbisplom")
# Values <- read.csv("../testVizRDoc/HR_comma_sep.csv", sep = ",")
# Values <- Values[,c(-4:-9)]
# graphColor <- Values[,4]
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
powerbi_rEnableShowTextForCJKLanguages =  1
#PBI_PARAM Show the Upper-Right plot area
UshowSw = TRUE
if(exists("PlotSettingsUpper_ShowSw")){
    UshowSw = PlotSettingsUpper_ShowSw
}
#PBI_PARAM Show the Lower-Left plot area
LshowSw = TRUE
if(exists("PlotSettingsLower_ShowSw")){
    UshowSw = PlotSettingsLower_ShowSw
}
#PBI_PARAM Show the Diagonal plot area
DShowSw = TRUE
if(exists("PlotSettingsDiag_ShowSw")){
    DShowSw = PlotSettingsDiag_ShowSw
}
#PBI_PARAM Setting for Continuous value on the Upper-Right plot area
UCont = "point"
if(exists("PlotSettingsUpper_Continuous")){
    UCont = PlotSettingsUpper_Continuous
}
#PBI_PARAM Setting for Combination value on the Upper-Right plot area
UCombo = "box"
if(exists("PlotSettingsUpper_Combo")){
    UCombo = PlotSettingsUpper_Combo
}
#PBI_PARAM Setting for Discrete value on the Upper-Right plot area
UDisk = "box"
if(exists("PlotSettingsUpper_Discrete")){
    UDisk = PlotSettingsUpper_Discrete
}
#PBI_PARAM Setting for Continuous value on the Lower-Left plot area
LCont = "point"
if(exists("PlotSettingsLower_Continuous")){
    UCont = PlotSettingsLower_Continuous
}
#PBI_PARAM Setting for Combination value on the Lower-Left plot area
LCombo = "box"
if(exists("PlotSettingsLower_Combo")){
    UCombo = PlotSettingsLower_Combo
}
#PBI_PARAM Setting for Discrete value on the Lower-Left plot area
LDisk = "box"
if(exists("PlotSettingsLower_Discrete")){
    UDisk = PlotSettingsLower_Discrete
}
#PBI_PARAM Setting for Continuous value on the Diagonal plot area
DCont = "point"
if(exists("PlotSettingsDiag_Continuous")){
    DCont = PlotSettingsDiag_Continuous
}
#PBI_PARAM Setting for Discrete value on the Diagonal plot area
DDisk = "box"
if(exists("PlotSettingsDiag_Discrete")){
    DDisk = PlotSettingsDiag_Discrete
}

if(exists("ColorVal")){
    graphColor = ColorVal[,1]
    if((UshowSw == FALSE) && (DShowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = list(continuous = UCont, combo = UCombo, discrete = UDisk), diag = "blank")
    } else if((LshowSw == FALSE) && (DShowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisk), lower = "blank", diag = "blank")
    } else if(UshowSw == FALSE){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = list(continuous = UCont, combo = UCombo, discrete = UDisk), diag = list(continuous = DCont, discrete = DDisk))
    } else if(LshowSw == FALSE){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisk), lower = "blank", diag = list(continuous = DCont, discrete = DDisk))
    } else if(DShowSw == FALSE) {
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisk), lower = list(continuous = UCont, combo = UCombo, discrete = UDisk), diag = "blank")
    } else ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisk), lower = list(continuous = UCont, combo = UCombo, discrete = UDisk), diag = list(continuous = DCont, discrete = DDisk))
} else {
    if((UshowSw == FALSE) && (DShowSw == FALSE)){
        ggp = ggpairs(Values, upper = "blank", lower = list(continuous = UCont, combo = UCombo, discrete = UDisk), diag = "blank")
    } else if((LshowSw == FALSE) && (DShowSw == FALSE)){
        ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisk), lower = "blank", diag = "blank")
    } else if(UshowSw == FALSE){
        ggp = ggpairs(Values, upper = "blank", lower = list(continuous = UCont, combo = UCombo, discrete = UDisk), diag = list(continuous = DCont, discrete = DDisk))
    } else if(LshowSw == FALSE){
        ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisk), lower = "blank", diag = list(continuous = DCont, discrete = DDisk))
    } else if(DShowSw == FALSE) {
        ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisk), lower = list(continuous = UCont, combo = UCombo, discrete = UDisk), diag = "blank")
    } else ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisk), lower = list(continuous = UCont, combo = UCombo, discrete = UDisk), diag = list(continuous = DCont, discrete = DDisk))
}

print(ggp, progress = F)
####################################################
