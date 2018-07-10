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
source('./r_files/flatten_HTML.r')

############### Library Declarations ###############
libraryRequireInstall("ggplot2");
libraryRequireInstall("plotly")
libraryRequireInstall("lattice")
####################################################

################### Actual code ####################
splom(~Values[1:5],groups=as.factor(sales),data=Values,pch=20,type='p',cex=1)
# g = qplot(`Petal.Length`, data = iris, fill = `Species`, main = Sys.time());
####################################################

############# Create and save widget ###############
# p = ggplotly(g);
# internalSaveWidget(p, 'out.html');
####################################################
