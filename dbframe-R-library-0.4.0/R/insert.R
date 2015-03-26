## Copyright (C) 2010-2015 Gray Calhoun; MIT license

    setGeneric("insert<-", function(x,..., value) standardGeneric("insert<-"))

    setMethod("insert<-", signature = "dbframe", function(x,...,value) {
      stopifnot(!readonly(x))
      dbc <- dbConnect(x)
          cols <-
            if (dbExistsTable(dbc, tablename(x))) {
              colnames <- names(select(x, limit = 0))
              colnames[colnames %in% names(value)]
            } else {
              names(value)
            }
          dbWriteTable(dbc, tablename(x), value[, cols, drop=FALSE],
                       row.names = FALSE, overwrite = FALSE, append = TRUE,...)
          rowid(x) <- unname(unlist(dbGetQuery(dbc, "select last_insert_rowid();")))
      dbDisconnect(dbc)
      return(x)
    })
