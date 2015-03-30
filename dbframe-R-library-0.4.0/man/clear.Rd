% Copyright (C) 2010-2015 Gray Calhoun; MIT license

\name{clear}
\alias{clear}
\alias{clear-methods}
\alias{clear,dbframe-method}
\title{Remove a table from the database}
\description{The function \samp{clear} removes the tables associated with
a collection of \samp{dbframe} objects from their data bases.}
\usage{clear(...)}
\arguments{\item{\dots}{Each argument listed should be a dbframe object.}}

\author{Gray Calhoun \email{gcalhoun@iastate.edu}}

\details{The table is removed and not just emptied, so the column
  names and types are discarded as well.}
\section{Implementation}{
The first step is to define a generic \samp{clear} function.  The actual
function is a method for the \samp{dbframe} class.  Methods for other
classes could be defined as well.
\preformatted{<<*>>=
    setGeneric("clear", function(...)
               standardGeneric("clear"), signature = "...")

    setMethod("clear", signature = "dbframe", function(...) \{
      x <- list(...)
      sapply(x, function(y) \{
        stopifnot(!readonly(y))
        dbc <- dbConnect(y)
        results <- <<Remove table referenced by "y" from database>>
        dbDisconnect(dbc)
        results
      \})\})
} %
Removing the table is pretty easy since we can just use methods
defined by DBI.
\preformatted{<<Remove table referenced by "y" from database>>=
res <- 
  if (is.linked(y)) \{
    dbRemoveTable(dbc, tablename(y),...)
  \} else \{
    FALSE
  \}
}
}
\examples{
filename <- tempfile(fileext = ".db")
example.dbframe <- dbframe("clear1", dbname = filename)
example2.dbframe <- dbframe("clear2", dbname = filename)
clear(example.dbframe, example2.dbframe)

data(chickwts)
insert(example.dbframe) <- chickwts
head(example.dbframe)
clear(example.dbframe)
head(example.dbframe)
unlink(filename)
}

\seealso{dbRemoveTable}
\keyword{database}
\keyword{methods}

