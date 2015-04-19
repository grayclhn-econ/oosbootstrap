# General code to convert the Monte Carlo simulations into a table.
# Copyright 2015 Gray Calhoun

args <- commandArgs(trailingOnly = TRUE)
outputfile <- args[1]
datafile <- args[2]

library(dbframe, lib.loc = "lib")
library(reshape2)

d <- read.csv(datafile)
d <- d[as.character(d$Method) != "Nominal",]
d$Size <- 100 * d$Size
cat(booktabs(dcast(d, T + P ~ Method), "r", c(0,0,1,1), numberformat = TRUE,
             tabular.environment = "tabular"),
    file = outputfile)
