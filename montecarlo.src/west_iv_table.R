# General code to convert the Monte Carlo simulations into a table.
# Copyright 2015 Gray Calhoun

args <- commandArgs(trailingOnly = TRUE)
outputfile = args[1]
datafile = args[2]

library(dbframe, lib.loc = "lib")
library(lattice)

d <- read.csv(datafile)
d$P <- factor(d$P)
d$R <- factor(d$R)
pdf(outputfile, width = 4)
dotplot(P ~ Size | R, d, groups = Method, auto.key = TRUE,
        main = "Summary of Monte Carlo results", layout = c(1,3))
dev.off()
