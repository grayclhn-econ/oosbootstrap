% Copyright (C) 2010-2015 Gray Calhoun; MIT license

\newcommand{\sql}{\acronym{sql}}
\newcommand{\sqlite}{\acronym{sql}ite}
\name{insert<-}
\alias{insert<-}
\alias{insert<--methods}
\alias{insert<-,dbframe-method}
\title{Insert a data frame into the \sql database}

\description{This function inserts data from a data frame into a
  table referenced by a dbframe object.  As the example makes clear
  (I hope) this function is dead easy to use; the columns of
  \samp{value} can be in any order, and, if the table referenced by
  \samp{x} exits, only the columns that already defined in the table
  are inserted.}

\usage{insert(x,\dots) <- value}

\arguments{
  \item{x}{A dbframe object that links to a table in an \sql database.}
  \item{value}{A data frame containing the data to insert into the
    database.}
  \item{\dots}{Additional arguments to pass to \samp{dbWriteTable}.}
}

\value{Since this is an assignment function, it returns the dbframe
  \samp{x}.  The function is used for its side effect, which is to insert
  the contents of \samp{value} into the table reference by \samp{x}.}

\seealso{The DBI package and documentation, \code{\link{dbWriteTable}}, \code{\link{dbframe-class}}}
\section{Implementation}{
I've implemented this function as a method of the dbframe class;
presumably it could be extended to other classes.  So, the main steps
in the defining the function are to define a generic and then set the
specific method for the dbframe class.  The difference between the main
method and the method for \samp{dbframe{\char95}sqlite{\char95}temporary} objects is that
the second method shouldn't open and close the database connection.
\preformatted{<<*>>=
    setGeneric("insert<-", function(x,..., value) standardGeneric("insert<-"))

    setMethod("insert<-", signature = "dbframe", function(x,...,value) \{
      stopifnot(!readonly(x))
      dbc <- dbConnect(x)
      <<Determine whether the table exists>>
      <<Write to database and store rowid>>
      dbDisconnect(dbc)
      return(x)
    \})
}

We can use the \samp{dbExistsTable} method (from DBI) to determine
whether the table already exists in the database.  If it does, we
find out which columns in \samp{value} already exists, because we will
only insert those columns into the database.  If the table does not
exist, we insert all of the columns of \samp{value}.
\preformatted{<<Determine whether the table exists>>=
    cols <-
      if (dbExistsTable(dbc, tablename(x))) \{
        colnames <- names(select(x, limit = 0))
        colnames[colnames \%in\% names(value)]
      \} else \{
        names(value)
      \}
}

Writing to the database is straightforward---we just use the
\samp{dbWriteTable} method (also from DBI).  The columns of the data
frame \samp{value} are rearranged to agree with the table in the
database automatically by indexing \samp{value} with the vector
\samp{cols} determined above.
\preformatted{<<Write to database and store rowid>>=
    dbWriteTable(dbc, tablename(x), value[, cols, drop=FALSE],
                 row.names = FALSE, overwrite = FALSE, append = TRUE,...)
    rowid(x) <- unname(unlist(dbGetQuery(dbc, "select last_insert_rowid();")))
}
}

\examples{
data(chickwts)
filename <- tempfile(fileext = ".db")
chicksdb <- dbframe("insert1", dbdriver = "SQLite", 
                    dbname = filename, clear = TRUE)
## Add some records
insert(chicksdb) <- chickwts[1:2,]
select(chicksdb)
## Add some more
insert(chicksdb) <- tail(chickwts)
}
\keyword{database}

