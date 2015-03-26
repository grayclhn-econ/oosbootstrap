## Copyright (C) 2010-2015 Gray Calhoun; MIT license

setClass("dbframe", representation(table = "character",
                                       readonly = "logical",
                                       dbConnect.arguments = "list"))

    setClass("dbframe_sqlite", contains = "dbframe",
             representation(rowid = "integer", dbname = "character"))

        setMethod("dbConnect", signature = "dbframe", 
                  definition = function(drv,...)
                  do.call("dbConnect", drv@dbConnect.arguments))
        setMethod("dbConnect", signature = "dbframe_sqlite", 
          definition = function(drv,...) return(do.call("dbConnect",
            c(drv = "SQLite", dbname = dbname(drv), list(...),
              dbConnect.arguments = drv@dbConnect.arguments))))
 
        as.data.frame.dbframe <- function(x,...) select(x,...)
        dim.dbframe <- function(x) {
          nrows <- select(x, "count(*)")[[1]]
          ncols <- length(select(x, limit = 0))
          c(nrows, ncols)
        }
  
    setGeneric("tablename", function(x) standardGeneric("tablename"))
        setMethod("tablename", signature = c("dbframe"), function(x) x@table)
    setGeneric("dbname", function(x) standardGeneric("dbname"))
        setMethod("dbname", signature = c("dbframe"), function(x) x@dbname)
    setGeneric("readonly", function(x) standardGeneric("readonly"))
        setMethod("readonly", signature = c("dbframe"), function(x) x@readonly)
    setGeneric("is.linked", function(x,...) standardGeneric("is.linked"))
        setMethod("is.linked", signature = c("dbframe"), function(x,...) {
          dbc <- dbConnect(x,...)
          answer <- tablename(x) %in% dbListTables(dbc)
          dbDisconnect(dbc)
          return(answer)
        })
    setGeneric("rowid", function(x,...) standardGeneric("rowid"))
        setMethod("rowid", signature = c("dbframe_sqlite"), 
                  function(x,...) x@rowid)
    setGeneric("rowid<-", function(x,...,value) standardGeneric("rowid<-"))
        setMethod("rowid<-", signature = c("dbframe_sqlite"), function(x,...,value) {
          x@rowid <- as.integer(value)
          return(x)})
