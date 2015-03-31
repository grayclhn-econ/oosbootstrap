## Copyright (C) 2010-2015 Gray Calhoun; MIT license

    setGeneric("clear", function(...)
               standardGeneric("clear"), signature = "...")

    setMethod("clear", signature = "dbframe", function(...) {
      x <- list(...)
      sapply(x, function(y) {
        stopifnot(!readonly(y))
        dbc <- dbConnect(y)
        results <- res <- 
                     if (is.linked(y)) {
                       dbRemoveTable(dbc, tablename(y),...)
                     } else {
                       FALSE
                     }
        dbDisconnect(dbc)
        results
      })})
