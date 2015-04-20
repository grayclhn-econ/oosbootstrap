# General code to convert the Monte Carlo simulations into a table.
# Copyright 2015 Gray Calhoun

args <- commandArgs(trailingOnly = TRUE)
outputfile <- args[1]
datafile <- args[2]

library(lattice)
lattice.options(default.theme = standard.theme(color = FALSE))

d <- read.csv(datafile)
d$P <- factor(d$P)
d$T <- factor(d$T)
pdf(outputfile, width = 4.5, height = 3)
dotplot(P ~ Size | T, d, groups = Method,
        auto.key = list(space = "right"),
        main = "Summary of Monte Carlo results")
dev.off()
