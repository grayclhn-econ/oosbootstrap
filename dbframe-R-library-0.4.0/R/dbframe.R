## Copyright (C) 2010-2015 Gray Calhoun; MIT license

    dbframe <- function(table, dbname = NULL, dbdriver = "SQLite",
                        data = NULL, readonly = FALSE, clear = FALSE,...) {
      x <- switch(dbdriver, 
                  "SQLite" = {
                    if (is.null(dbname)) {
                      warning("'dbname' is null; setting to ':memory:'")
                      dbname <- ":memory:"
                    }
                    if (dbname %in% c(":memory:", "")) {
                      dbframe_sqlite_temporary(table, dbname, readonly,...)
                    } else {
                      dbframe_sqlite(table, dbname, readonly,...)
                    }
                  },
                  dbframe_unknown(table, readonly,...))
          if (clear) clear.result <- clear(x)
          if (!is.null(data)) insert(x) <- data
      return(x)
    }

        dbframe_sqlite <- function(table, dbname, readonly = FALSE,...) {
              require(RSQLite)
              require(RSQLite.extfuns)
          return(new("dbframe_sqlite", table = unname(table), rowid = integer(),
                     dbname = unname(dbname), readonly = unname(readonly),
                     dbConnect.arguments = list(...)))
        }
        dbframe_sqlite_temporary <- 
          function(table, dbname = ":memory:", readonly = FALSE,...)
          stop("Temporary SQLite databases aren't implemented.")
        dbframe_unknown <- function(table, readonly = FALSE,...) {
          return(new("dbframe", table = unname(table), 
                     readonly = unname(readonly),
                     dbConnect.arguments = list(...)))
        }
