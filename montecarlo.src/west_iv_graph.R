# General code to convert the Monte Carlo simulations into a table.
# Copyright 2015 Gray Calhoun

args <- commandArgs(trailingOnly = TRUE)
outputfile <- args[1]
datafile <- args[2]

library(lattice)
lattice.options(default.theme = standard.theme(color = FALSE))

d <- read.csv(datafile)
d$P <- factor(d$P)
d$T <- paste("T =", d$T)
pdf(outputfile, width = 4, height = 4.5)
dotplot(P ~ Size | T, d, groups = Method, layout = c(1,2),
        auto.key = list(space = "right"),
        scales = list(y = list(relation = "free")),
        ## Next part taken from an R-help post
        prepanel = function(x, y, ...) {
            ## drop unused levels
            yy <- y[, drop = TRUE]
            ## reset y-limits
            list(ylim = levels(yy),
                 yat = sort(unique(as.numeric(yy))))
        },
        panel = function(x, y, ...) {
            ## drop unused levels...again...
            yy <- y[, drop = TRUE]
            panel.dotplot(x, yy, ...)
        },
        main = "Summary of Monte Carlo results")
dev.off()
