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
    LshowSw = PlotSettingsLower_ShowSw
}
#PBI_PARAM Show the Diagonal plot area
DshowSw = TRUE
if(exists("PlotSettingsDiag_ShowSw")){
    DshowSw = PlotSettingsDiag_ShowSw
}
#PBI_PARAM Setting for Continuous value on the Upper-Right plot area
UCont = "points"
if(exists("PlotSettingsUpper_Continuous")){
    UCont = PlotSettingsUpper_Continuous
}
#PBI_PARAM Setting for Combination value on the Upper-Right plot area
UCombo = "box"
if(exists("PlotSettingsUpper_Combo")){
    UCombo = PlotSettingsUpper_Combo
}
#PBI_PARAM Setting for Discrete value on the Upper-Right plot area
UDisc = "facetbar"
if(exists("PlotSettingsUpper_Discrete")){
    UDisc = PlotSettingsUpper_Discrete
}
#PBI_PARAM Setting for Continuous value on the Lower-Left plot area
LCont = "points"
if(exists("PlotSettingsLower_Continuous")){
    LCont = PlotSettingsLower_Continuous
}
#PBI_PARAM Setting for Combination value on the Lower-Left plot area
LCombo = "box"
if(exists("PlotSettingsLower_Combo")){
    LCombo = PlotSettingsLower_Combo
}
#PBI_PARAM Setting for Discrete value on the Lower-Left plot area
LDisc = "facetbar"
if(exists("PlotSettingsLower_Discrete")){
    LDisc = PlotSettingsLower_Discrete
}
#PBI_PARAM Setting for Continuous value on the Diagonal plot area
DCont = "densityDiag"
if(exists("PlotSettingsDiag_Continuous")){
    DCont = PlotSettingsDiag_Continuous
}
#PBI_PARAM Setting for Discrete value on the Diagonal plot area
DDisc = "barDiag"
if(exists("PlotSettingsDiag_Discrete")){
    DDisc = PlotSettingsDiag_Discrete
}

if(exists("ColorVal")){
    graphColor = ColorVal[,1]
    if((UshowSw == FALSE) && (LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = "blank")
    } else if((LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (LshowSw == FALSE)){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = "blank", diag = list(continuous = DCont, discrete = DDisc))
    } else if(UshowSw == FALSE){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = "blank", lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = list(continuous = DCont, discrete = DDisc))
    } else if(LshowSw == FALSE){
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = "blank", diag = list(continuous = DCont, discrete = DDisc))
    } else if(DshowSw == FALSE) {
        ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = "blank")
    } else ggp = ggpairs(Values, mapping = aes(color = graphColor), upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = list(continuous = DCont, discrete = DDisc))
} else {
    if((UshowSw == FALSE) && (LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, upper = "blank", lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, upper = "blank", lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = "blank")
    } else if((LshowSw == FALSE) && (DshowSw == FALSE)){
        ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = "blank", diag = "blank")
    } else if((UshowSw == FALSE) && (LshowSw == FALSE)){
        ggp = ggpairs(Values, upper = "blank", lower = "blank", diag = list(continuous = DCont, discrete = DDisc))
    } else if(UshowSw == FALSE){
        ggp = ggpairs(Values, upper = "blank", lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = list(continuous = DCont, discrete = DDisc))
    } else if(LshowSw == FALSE){
        ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = "blank", diag = list(continuous = DCont, discrete = DDisc))
    } else if(DshowSw == FALSE) {
        ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = "blank")
    } else ggp = ggpairs(Values, upper = list(continuous = UCont, combo = UCombo, discrete = UDisc), lower = list(continuous = LCont, combo = LCombo, discrete = LDisc), diag = list(continuous = DCont, discrete = DDisc))
}

print(ggp, progress = F)
####################################################
