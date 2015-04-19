# General code to convert the Monte Carlo simulations into a table.
# Copyright 2015 Gray Calhoun

args <- commandArgs(trailingOnly = TRUE)
outputfile <- args[1]
datafile <- args[2]

library(lattice)
lattice.options(default.theme = standard.theme(color = FALSE))

d <- read.csv(datafile)
d$Size <- 100 * d$Size
d$P <- factor(d$P)
d$T <- factor(d$T)
pdf(outputfile, width = 3.5, height = 3)
dotplot(P ~ Size | T, d, groups = Method,
        auto.key = list(space = "right"),
        xlim = c(0, 1.1 * max(d$Size)),
        main = "Summary of Monte Carlo results")
dev.off()
