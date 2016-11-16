# Copyright (c) 2011-2015 Gray Calhoun.

args <- commandArgs(trailingOnly = TRUE)
outputfile = args[1]
datafile = args[2]
configfile = args[3]
library(oosanalysis, lib.loc = "lib")
library(dbframe, lib.loc = "lib")
source(configfile)
bootsize <- 0.10
windowlength <- 10

gwdata <- ts(read.csv(datafile)[,-1], start = 1871, frequency = 1)
stock.returns <- ((gwdata[,"price"] + gwdata[,"dividend"]) / 
                                           lag(gwdata[,"price"], -1) - 1)
financial.data <- 
  data.frame(window(start = 1927, end = 2009, lag(k = -1, cbind(
    equity.premium =        lag(log1p(stock.returns) - log1p(gwdata[,"risk.free.rate"]), 1),
    default.yield.spread =  gwdata[,"baa.rate"] - gwdata[,"aaa.rate"],
    inflation =             gwdata[,"inflation"],
    stock.variance =        gwdata[,"stock.variance"],
    dividend.payout.ratio = log(gwdata[,"dividend"]) - log(gwdata[,"earnings"]),
    long.term.yield =       gwdata[,"long.term.yield"],
    term.spread =           gwdata[,"long.term.yield"] - gwdata[,"t.bill"],
    treasury.bill =         gwdata[,"t.bill"],
    default.return.spread = gwdata[,"corp.bond"] - gwdata[,"long.term.rate"],
    dividend.price.ratio =  log(gwdata[,"dividend"]) - log(gwdata[,"price"]),
    dividend.yield =        log(gwdata[,"dividend"]) - log(lag(gwdata[,"price"], -1)),
    long.term.rate =        gwdata[,"long.term.rate"],
    earnings.price.ratio =  log(gwdata[,"earnings"]) - log(gwdata[,"price"]),
    book.to.market =        gwdata[,"book.to.market"],
    net.equity =            gwdata[,"net.equity"]))))

predictor.names <- setdiff(names(financial.data), "equity.premium")
names(predictor.names) <- predictor.names

benchmark <- function(d) lm(equity.premium ~ 1, data = d)
alternatives_gw <- lapply(predictor.names, function(n)
  eval(parse(text = sprintf("function(d) lm(equity.premium ~ %s, data = d)", n))))

oos.bootstrap <- mixedbootstrap(benchmark, alternatives_gw, financial.data,
				R = windowlength, nboot = nboot, blocklength = 1,
				window = "rolling", bootstrap = "circular")

## 'wrong' oos bootstrap
forecasts.null <- recursive_forecasts(benchmark, financial.data, windowlength, "recursive")
forecasts.alt <- sapply(alternatives_gw, function(m) {
    recursive_forecasts(m, financial.data, windowlength, "recursive")
})
y <- financial.data$equity.premium[-(1:windowlength)]
f.t <- (y - forecasts.null)^2 - (y - forecasts.alt)^2 + (forecasts.null - forecasts.alt)^2
naiveboot <- replicate(nboot, {
    fboot <- f.t[sample(1:length(y), replace = TRUE),]
    bootstat <- sqrt(length(y)) * colMeans(fboot) / apply(fboot, 2, sd)
})
naivecrit <- quantile(naiveboot - rowMeans(naiveboot), 1 - bootsize)

stepm.results <- stepm(oos.bootstrap$statistics, oos.bootstrap$replications, 
                       NA, bootsize)

results.data <- data.frame(stringsAsFactors = FALSE,
                           predictor = names(oos.bootstrap$statistics),
                           value = oos.bootstrap$statistics,
                           naive = ifelse(oos.bootstrap$statistics > qnorm(1 - bootsize), "sig.", ""),
                           SPA = ifelse(oos.bootstrap$statistics > naivecrit, "sig.", ""),
                           ours = ifelse(stepm.results$rejected, "sig.", ""))

results.data <- results.data[order(results.data$value, decreasing = TRUE),]
results.data$predictor <- gsub("\\.", " ", results.data$predictor)
names(results.data)[1] <- " "

integer.macros <- c(nboot = nboot, bootsize = 100 * bootsize,
                       windowlength = windowlength)
real.macros <- c(empiricalcriticalvalue = unname(stepm.results$rightcrit),
                 spacriticalvalue = unname(naivecrit))

cat(file = outputfile, sep = "\n",
    sprintf("\\newcommand{\\%s}{%.2f}", names(real.macros), real.macros),
    sprintf("\\newcommand{\\%s}{%d}", names(integer.macros), integer.macros),
    sprintf("\\newcommand{\\empiricaltable}{%s}",
            booktabs(results.data, align = c("l", rep("C", 4)),
                     numberformat = c(FALSE, TRUE, FALSE, FALSE, FALSE),
                     digits = rep(2, 5)),"}"))
