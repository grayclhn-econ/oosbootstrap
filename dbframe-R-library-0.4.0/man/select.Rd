% Copyright (C) 2010-2015 Gray Calhoun; MIT license

\name{select}
\alias{select}
\alias{select-methods}
\alias{select,ANY,missing-method}
\alias{select,data.frame,character-method}
\alias{select,dbframe,character-method}
\alias{select,dbframe,list-method}
\alias{select,default,missing-method}
\alias{select,list,character-method}
\alias{generate.select.sql}
\title{Retrieve records from a dbframe}
\newcommand{\sql}{\acronym{sql}}
\newcommand{\sqlite}{\acronym{sql}ite}

\description{\samp{select} is a wrapper for the \sql select query and is
  used to retrieve records from a \samp{dbframe} object.
  \samp{generate.select.sql} assembles a valid \sql select statement from
  its arguments.  The arguments map to clauses in the \sql select
  statement, so you may need to consult an introduction to \sql to best
  use these functions.}

\usage{
select(x, cols, as.data.frame = TRUE,...)

generate.select.sql(table, cols = "*", where = NULL, group.by = NULL, 
                    having = NULL, order.by = NULL, limit = NULL,...)
}

\arguments{
  \item{x}{A \samp{dbframe} object that references the table of interest.}
  \item{table}{A character object containing the name of the \sql table to query.}
  \item{cols}{A character vector containing the column names (or
    functions of the column names) to retrieve from the database.}
  \item{where}{A character object that contains conditions to use to
    filter the records.}
  \item{group.by}{A character vector that defines groups of records to
    combine with an aggregate function.}
  \item{having}{A character object that filters the groups defined by \dQuote{group.by}.}
  \item{order.by}{A character vector that lists the columns to be used
    for sorting the results.}
  \item{limit}{A character vector or number that limits and offsets the
    \sql query results.}
  \item{\dots}{Additional arguments to pass to \samp{dbGetQuery}.}
  \item{as.data.frame}{Logical; if \samp{TRUE}, execute the query and
  return the results as a data frame.  If \samp{FALSE}, return a dbframe
  that has the \sql statement for the query as its \dQuote{table}}
}

\references{
\sql as understood by \sqlite. \url{http://www.sqlite.org/lang_select.html}
}
\section{Source code}{
The inidividual methods do some minor parsing, but most of the work is
done by \samp{generate.select.sql}.
  
\preformatted{<<*>>=
    generate.select.sql <- function(table, cols = "*", where = NULL, 
      group.by = NULL, having = NULL, order.by = NULL, limit = NULL, ...) \{

      <<Format the "select" part of the statement>>
      <<Format the "group by" part of the statement>>
      <<Format the "order by" part of the statement>>
      <<Format the "having" part of the statement>>
      <<Format the "where" part of the statement>>
      <<Format the "limit" part of the statement>>
      return(paste("select", cols, "from", table, where, 
                   group.by, having, order.by, limit))
    \}

    setGeneric("select", function(x, cols, as.data.frame = TRUE,...)
               standardGeneric("select"))

    setMethod("select", signature = c("ANY", "missing"), 
              function(x, cols, as.data.frame = TRUE,...) \{
                <<Execute select for c("ANY", "missing")>>\})

    setMethod("select", signature = c("dbframe", "character"), 
              function(x, cols, as.data.frame = TRUE,...) \{
                <<Execute select for c("dbframe", "character")>>\})

    setMethod("select", signature = c("data.frame", "character"),
              function(x, cols, as.data.frame = TRUE,...) \{
                <<Handle arguments and set up the local environment>>
                <<Export the new data frame to a temporary SQLite database>>
                <<Query the new database and close database connection>>
                return(queryresults)
              \})

    setMethod("select", signature = c("list", "character"), 
              function(x, cols,...) \{
                <<Detect inappropriate uses of the "list" method>>
                <<Define and attach to "main" db>>
                <<Extract the arguments that describe the join>>
                <<Execute the query and return its results>>
              \})

    ## setMethod("select", signature = c("dbframe", "list"), 
    ##           function(x, cols,...) \{
    ##             <Handle lists of a single query element>>
    ##             <Manage arguments for compound queries>>
    ##             <Construct individual SQL select statements for compound queries>>
    ##             <Execute query and return data>>
    ##           \})
      
      
    <<Define additional useful functions>>
}Unfortunately, this method doesn't yet allow for joins or compound
queries involving data.frames.  Maybe a better approach would be to
always let the \dQuote{main} database be a temporary one on disk.

\subsection{Assembling the \sql select statement}{
To write the "select" part, we add the \samp{group.by} variables and the
\samp{cols} variables together (and store them in \samp{cols}).
\preformatted{<<Format the "select" part of the statement>>=
    <<Add new group.by variables in front of cols variables>>
    labels <- names(cols)
    labels[nchar(labels) > 0] <- paste("AS", labels[nchar(labels) > 0])
    cols <- paste(cols, labels, collapse = ", ")
}
To save typing, I assume that we want to retrieve the grouping variables
and so we don't have to specify them explicitly in the \samp{cols} vector.
I think it makes sense to have the grouping variables on the left side
of the results set instead of the right side.  The next code chunk does
both of those.
\preformatted{<<Add new group.by variables in front of cols variables>>=
    cols <-
      if (is.null(cols)) \{
        group.by
      \} else if (is.null(group.by)) \{
        cols
      \} else \{
        if (is.null(names(cols)))
          names(cols) <- rep("", length(cols))
        if (is.null(names(group.by))) 
          names(group.by) <- rep("", length(group.by))
        c(group.by[!(names(group.by) \%in\% names(cols))
                    |  nchar(names(group.by)) == 0], cols)
      \}
}

Managing the other arguments is easy.  If they're \samp{NULL} we replace
the variable with an empty string; if they're not, we add the
appropriate label and replace the variable with a character object that
contains a clause for the \sql statement.
\preformatted{<<Format the "group by" part of the statement>>=
    group.by <- 
      if (is.null(group.by)) \{
        "" 
      \} else \{
        paste("group by", paste(group.by, collapse = ", "))
      \}
}

\preformatted{<<Format the "order by" part of the statement>>=
    order.by <- 
      if (is.null(order.by)) \{
        ""
      \} else \{
        paste("order by", paste(order.by, collapse = ", "))
      \}
}

\preformatted{<<Format the "having" part of the statement>>=
    having <-
      if (is.null(having)) \{
        ""
      \} else \{
        paste("having", having)
      \}
}

\preformatted{<<Format the "where" part of the statement>>=
    where <-
      if (is.null(where)) \{
        "" 
      \} else \{
        paste("where", where)
      \}
}

\preformatted{<<Format the "limit" part of the statement>>=
    limit <- 
      if (is.null(limit)) \{
        "" 
      \} else \{
        paste("limit", limit)
      \}
}
}
\subsection{Details of argument handling for simple queries}{
  The individual methods just call \samp{generate.select.sql} and execute
  the select statement.    
If \samp{cols} is "missing" it returns results for
\samp{cols} equal to "*" (i.e. all of the columns of the table).
\preformatted{<<Execute select for c("ANY", "missing")>>=
    select(x, "*", as.data.frame,...)
}

\preformatted{<<Execute select for c("dbframe", "character")>>=
    if (!is.linked(x)) \{
      warning("Table does not exist in the data base")
      return(list())
    \}
    arguments <- list(table = tablename(x), cols = cols,...)
    sql.statement <- do.call("generate.select.sql", arguments)
    if (as.data.frame) \{
      dbc <- dbConnect(x)
      d <- do.call("dbGetQuery", c(conn = dbc, statement = sql.statement,
                                   arguments))
      dbDisconnect(dbc)
    \} else \{
      if (is.null(arguments$readonly)) \{
        readonly <- readonly(x)
      \} else \{
        readonly <- arguments$readonly
        arguments$readonly <- NULL
      \}
      d <- do.call("new", c(Class = "dbframe", table = sql.statement,
                   readonly = readonly, dbConnect.arguments = arguments))
    \}
    return(d)
}

\preformatted{<<Handle arguments and set up the local environment>>=
    if (!as.data.frame)
      warning("'as.data.frame' ignored when selecte is called on a data.frame.")
    tablename <- "dataframe"
    require(RSQLite)
    require(RSQLite.extfuns)
}

\preformatted{<<Export the new data frame to a temporary SQLite database>>=
    dbc <- dbConnect("SQLite", dbname = ":memory:")
    dbWriteTable(dbc, tablename, x, row.names = FALSE)
}

\preformatted{<<Query the new database and close database connection>>=
    sql.statement <- generate.select.sql(tablename, cols,...)
    queryresults <- dbGetQuery(dbc, sql.statement)
    dbDisconnect(dbc)
}
}
\subsection{Details of argument handling for joins}{
  So far, I'm only supporting joins for dbframes that are linked to
  \sqlite data bases and for data.frames. 
\preformatted{<<Detect inappropriate uses of the "list" method>>=
    if (length(x) == 1) return(select(x[[1]], cols,...))
    if (is.null(names(x))) names(x) <- LETTERS[seq_along(x)]
    tableclasses <- sapply(x, class)
    if (!all(tableclasses \%in\% c("dbframe_sqlite", "data.frame")))
      stop("Some of your dbframes aren't supported yet")
    if (any(tableclasses == "data.frame")) \{
      require(RSQLite)
      require(RSQLite.extfuns)
    \}
}

One nice feature of this function is that it handles all of the
\dQuote{attach} commands that are necessary to merge tables that exist
in different databases.  If all of the dbframes link to the same
database, then that one will obviously be the main database; otherwise
we connect to a temporary \sqlite database and attach everything there.
\preformatted{<<Define and attach to "main" db>>=
    dbnames <- tablenames <- rep(NA, length(x))
    for (s in seq_along(x)) \{
      if (tableclasses[s] == "dbframe_sqlite") \{
        dbnames[s] <- dbname(x[[s]])
        tablenames[s] <- tablename(x[[s]])
      \} else \{
        dbnames[s] <- "temp"
        tablenames[s] <- names(x)[[s]]
      \}
    \}
    not.data.frames <- which(tableclasses != "data.frame")
    dbalias <- dbnames
    if (isTRUE(sum(!duplicated(dbnames[not.data.frames])) == 1)) \{
      maindbc <- dbConnect(x[[not.data.frames[1]]])
      dbnames[not.data.frames] <- "main"
      dbalias[not.data.frames] <- "main"
    \} else \{
      maindbc <- dbConnect("SQLite", dbname = ":memory:")
      <<Attach sqlite_dbframes to the main db>> 
    \}
    <<Write dataframes to the main db>>
}
Any data frames are just going to be written to the temporary database.
\preformatted{<<Write dataframes to the main db>>=
    sapply(which(tableclasses == "data.frame"), function(s) 
           dbWriteTable(maindbc, paste("temp", tablenames[s], sep = "."),
                                                      x[[s]], row.names = FALSE))
}
Tables that already exist in other databases are attached to the
temporary database.
\preformatted{<<Attach sqlite_dbframes to the main db>>=
    dbcount <- 0
    unique.databases <- unique(dbnames[!(dbnames \%in\% c("temp", "main"))])
    for (db in unique.databases) \{
      dbcount <- dbcount + 1
      currentalias <- sprintf("ALIAS\%d", dbcount)
      dbalias[dbalias == db] <- currentalias
      r <- dbSendQuery(maindbc, sprintf("attach database '\%s' as \%s", db, currentalias))
      dbClearResult(r)
    \} 
}
The columns are already specified for the query; the only thing to do is
assemble the \sql code for the "table" part.
If the join type is not specified, the default is to do an inner join;
there is no default for \dQuote{on} or \dQuote{using}, so one (and only
one) of those arguments must be specified.
\preformatted{<<Extract the arguments that describe the join>>=
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
      sprintf("\%s.\%s \%s", dbalias[1], tablenames[1], names(x)[1]),
      sprintf("\%s join \%s.\%s \%s \%s", join, dbalias[-1], tablenames[-1], 
                                                                   names(x)[-1],
              ifelse(is.na(on), ifelse(is.na(using), "", 
                          sprintf("using(\%s)", using)), sprintf("on \%s", on)))))
}
Actually executing the query is the same as for the other methods.
We're not going to worry about detaching the tables explicitly, since we
know that they were only attached if we're using a temporary data base.
\preformatted{<<Execute the query and return its results>>=
    results <- dbGetQuery(maindbc, do.call(generate.select.sql, arguments))
    dbDisconnect(maindbc)
    return(results)
}
}
\subsection{Miscellaneous function}{
\preformatted{<<Define additional useful functions>>=
    extract.element <- function(name, default, length.required, argument.list) \{
      v <- if (name \%in\% names(argument.list)) argument.list[[name]] else default
      if (is.na(length.required) | length(v) == length.required) return(v)
      else if (length(v) == 1) return(rep(v, length.required))
      else stop("Incorrect length of argument")
    \}
}  
}}

\section{Unit Tests}{
I just have some basic sanity-check type unit tests; i.e. do the
functions run at a minimal level.
\preformatted{<<test-select.R>>=
    library(testthat)
    data(chickwts)
    chickwts$feed <- as.character(chickwts$feed)
    test_that("insert and select work", \{
      <<Individual tests that insert and select work>>\})
    test_that("column renaming scheme works", \{
      <<Individual tests that column renaming works>>\})
    test_that("joins work", \{
      <<Individual tests that joins work>>\})
}

First we'll check that the methods defined on data frames work, then
that they work for dbframes.
\preformatted{<<Individual tests that insert and select work>>=
    expect_that(chickwts, is_equivalent_to(select(chickwts)))
    <<Create temporary test database and dbframe>>
    insert(testdbframe) <- chickwts
    expect_that(chickwts, is_equivalent_to(select(testdbframe)))
    <<Remove temporary test database>>
}

\preformatted{<<Individual tests that column renaming works>>=
    expect_that(
      c("feed", "AverageWeight"), 
      is_identical_to(names(select(chickwts, 
           c(AverageWeight = "avg(weight)"), group.by = "feed"))))
    <<Create temporary test database and dbframe>>
    insert(testdbframe) <- chickwts
    expect_that(
      c("feed", "AverageWeight"), 
      is_identical_to(names(select(testdbframe, 
           c(AverageWeight = "avg(weight)"), group.by = "feed"))))
    <<Remove temporary test database>>
}

\preformatted{<<Individual tests that joins work>>=
    <<Create temporary test database and dbframe>>
    expect_that(select(list(A = chickwts,B =  chickwts), 
                    c("feed", weightA = "A.weight", weightB = "B.weight"), 
                    using = "feed", order.by = c("feed", "weightA", "weightB")),
                equals(\{
                  d <- merge(chickwts, chickwts, by = "feed", 
                                                         suffixes = c("A", "B"))
                  d$feed <- as.character(d$feed)
                  d[do.call(order, d),]
                \}, check.attributes = FALSE))

    avgwts <- dbframe("select2", dbname = testdbfile, clear = TRUE,
                       data = select(chickwts, c(averageweight = "avg(weight)"),
                                                group.by = c(thefeed = "feed")))
    expect_that(select(list(a = chickwts, b = avgwts), 
                       c("feed", "weight", "averageweight"),
                       on = ("feed = thefeed"), order.by = "feed, weight"),
                equals(\{
                  d <- merge(chickwts, select(avgwts), by.x = "feed", 
                                                               by.y = "thefeed")
                  d$feed <- as.character(d$feed)
                  d[do.call(order, d),]
                \}, check.attributes = FALSE))
    <<Remove temporary test database>>
}

\preformatted{<<Create temporary test database and dbframe>>=
    testdbfile <- tempfile(fileext = ".db")    
    testdbframe <- dbframe("select1", testdbfile)
    clear(testdbframe)
}

\preformatted{<<Remove temporary test database>>=
    unlink(testdbfile)
}
}

\examples{
filename <- tempfile(fileext = ".db")
data(chickwts)
chicksdb <- dbframe("select1", dbname = filename, 
                    clear = TRUE, data = chickwts)
select(chicksdb, where = "weight > 200", order.by = "weight")
select(chicksdb, c(averageweight = "avg(weight)"), group.by = "feed")
select(chicksdb, c(averageweight = "avg(weight)"), group.by = "feed",
       having = "averageweight > 250")

## and an example of querying the data frame directly
select(chickwts, c(averageweight = "avg(weight)"), 
       group.by = c(thefeed = "feed"))
avgwts <- dbframe("select2", dbname = filename, clear = TRUE,
                  data = select(chickwts, c(averageweight = "avg(weight)"), 
                                group.by = c(thefeed = "feed")))
## an example of a join
select(list(a = chicksdb, b = avgwts), c("feed", "weight", "averageweight"),
       on = ("feed = thefeed"), order.by = "feed, weight")
}

\keyword{methods}
\keyword{database}

