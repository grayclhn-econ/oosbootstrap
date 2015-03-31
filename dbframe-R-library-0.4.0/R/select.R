## Copyright (C) 2010-2015 Gray Calhoun; MIT license

    generate.select.sql <- function(table, cols = "*", where = NULL, 
      group.by = NULL, having = NULL, order.by = NULL, limit = NULL, ...) {

              cols <-
                if (is.null(cols)) {
                  group.by
                } else if (is.null(group.by)) {
                  cols
                } else {
                  if (is.null(names(cols)))
                    names(cols) <- rep("", length(cols))
                  if (is.null(names(group.by))) 
                    names(group.by) <- rep("", length(group.by))
                  c(group.by[!(names(group.by) %in% names(cols))
                              |  nchar(names(group.by)) == 0], cols)
                }
          labels <- names(cols)
          labels[nchar(labels) > 0] <- paste("AS", labels[nchar(labels) > 0])
          cols <- paste(cols, labels, collapse = ", ")
          group.by <- 
            if (is.null(group.by)) {
              "" 
            } else {
              paste("group by", paste(group.by, collapse = ", "))
            }
          order.by <- 
            if (is.null(order.by)) {
              ""
            } else {
              paste("order by", paste(order.by, collapse = ", "))
            }
          having <-
            if (is.null(having)) {
              ""
            } else {
              paste("having", having)
            }
          where <-
            if (is.null(where)) {
              "" 
            } else {
              paste("where", where)
            }
          limit <- 
            if (is.null(limit)) {
              "" 
            } else {
              paste("limit", limit)
            }
      return(paste("select", cols, "from", table, where, 
                   group.by, having, order.by, limit))
    }

    setGeneric("select", function(x, cols, as.data.frame = TRUE,...)
               standardGeneric("select"))

    setMethod("select", signature = c("ANY", "missing"), 
              function(x, cols, as.data.frame = TRUE,...) {
                    select(x, "*", as.data.frame,...)})

    setMethod("select", signature = c("dbframe", "character"), 
              function(x, cols, as.data.frame = TRUE,...) {
                    if (!is.linked(x)) {
                      warning("Table does not exist in the data base")
                      return(list())
                    }
                    arguments <- list(table = tablename(x), cols = cols,...)
                    sql.statement <- do.call("generate.select.sql", arguments)
                    if (as.data.frame) {
                      dbc <- dbConnect(x)
                      d <- do.call("dbGetQuery", c(conn = dbc, statement = sql.statement,
                                                   arguments))
                      dbDisconnect(dbc)
                    } else {
                      if (is.null(arguments$readonly)) {
                        readonly <- readonly(x)
                      } else {
                        readonly <- arguments$readonly
                        arguments$readonly <- NULL
                      }
                      d <- do.call("new", c(Class = "dbframe", table = sql.statement,
                                   readonly = readonly, dbConnect.arguments = arguments))
                    }
                    return(d)})

    setMethod("select", signature = c("data.frame", "character"),
              function(x, cols, as.data.frame = TRUE,...) {
                    if (!as.data.frame)
                      warning("'as.data.frame' ignored when selecte is called on a data.frame.")
                    tablename <- "dataframe"
                    require(RSQLite)
                    require(RSQLite.extfuns)
                    dbc <- dbConnect("SQLite", dbname = ":memory:")
                    dbWriteTable(dbc, tablename, x, row.names = FALSE)
                    sql.statement <- generate.select.sql(tablename, cols,...)
                    queryresults <- dbGetQuery(dbc, sql.statement)
                    dbDisconnect(dbc)
                return(queryresults)
              })

    setMethod("select", signature = c("list", "character"), 
              function(x, cols,...) {
                    if (length(x) == 1) return(select(x[[1]], cols,...))
                    if (is.null(names(x))) names(x) <- LETTERS[seq_along(x)]
                    tableclasses <- sapply(x, class)
                    if (!all(tableclasses %in% c("dbframe_sqlite", "data.frame")))
                      stop("Some of your dbframes aren't supported yet")
                    if (any(tableclasses == "data.frame")) {
                      require(RSQLite)
                      require(RSQLite.extfuns)
                    }
                    dbnames <- tablenames <- rep(NA, length(x))
                    for (s in seq_along(x)) {
                      if (tableclasses[s] == "dbframe_sqlite") {
                        dbnames[s] <- dbname(x[[s]])
                        tablenames[s] <- tablename(x[[s]])
                      } else {
                        dbnames[s] <- "temp"
                        tablenames[s] <- names(x)[[s]]
                      }
                    }
                    not.data.frames <- which(tableclasses != "data.frame")
                    dbalias <- dbnames
                    if (isTRUE(sum(!duplicated(dbnames[not.data.frames])) == 1)) {
                      maindbc <- dbConnect(x[[not.data.frames[1]]])
                      dbnames[not.data.frames] <- "main"
                      dbalias[not.data.frames] <- "main"
                    } else {
                      maindbc <- dbConnect("SQLite", dbname = ":memory:")
                          dbcount <- 0
                          unique.databases <- unique(dbnames[!(dbnames %in% c("temp", "main"))])
                          for (db in unique.databases) {
                            dbcount <- dbcount + 1
                            currentalias <- sprintf("ALIAS%d", dbcount)
                            dbalias[dbalias == db] <- currentalias
                            r <- dbSendQuery(maindbc, sprintf("attach database '%s' as %s", db, currentalias))
                            dbClearResult(r)
                          }  
                    }
                        sapply(which(tableclasses == "data.frame"), function(s) 
                               dbWriteTable(maindbc, paste("temp", tablenames[s], sep = "."),
                                                                          x[[s]], row.names = FALSE))
                    arguments <- list(...)
                    join  <- extract.element("join", "inner", length(x) - 1, arguments)
                    on    <- extract.element("on", NA, length(x) - 1, arguments)
                    using <- extract.element("using", NA, length(x) - 1, arguments)
                    if (any(is.na(on) & is.na(using)))
                      stop("'on' and 'using' can't both be specified for the same join.")
                    arguments$join  <- NULL
                    arguments$on    <- NULL
                    arguments$using <- NULL
                    arguments$cols  <- cols
                    arguments$table <- paste(collapse = " ", c(
                      sprintf("%s.%s %s", dbalias[1], tablenames[1], names(x)[1]),
                      sprintf("%s join %s.%s %s %s", join, dbalias[-1], tablenames[-1], 
                                                                                   names(x)[-1],
                              ifelse(is.na(on), ifelse(is.na(using), "", 
                                          sprintf("using(%s)", using)), sprintf("on %s", on)))))
                    results <- dbGetQuery(maindbc, do.call(generate.select.sql, arguments))
                    dbDisconnect(maindbc)
                    return(results)
              })

    ## setMethod("select", signature = c("dbframe", "list"), 
    ##           function(x, cols,...) {
    ##             <Handle lists of a single query element>>
    ##             <Manage arguments for compound queries>>
    ##             <Construct individual SQL select statements for compound queries>>
    ##             <Execute query and return data>>
    ##           })
      
      
        extract.element <- function(name, default, length.required, argument.list) {
          v <- if (name %in% names(argument.list)) argument.list[[name]] else default
          if (is.na(length.required) | length(v) == length.required) return(v)
          else if (length(v) == 1) return(rep(v, length.required))
          else stop("Incorrect length of argument")
        }
