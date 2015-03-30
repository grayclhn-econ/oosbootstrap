% Copyright (C) 2010-2015 Gray Calhoun; MIT license

\name{dbframe}
\alias{dbframe}
\alias{dbframe_sqlite}
\alias{dbframe_sqlite_temporary}
\alias{dbframe_unknown}

\title{Create a \code{dbframe} object}
\description{This is a constructor for the dbframe class.  I've only
  made a constructor for SQLite databases, but will (probably) add
  others in the future.}

\usage{
dbframe(table, dbname = NULL, dbdriver = "SQLite", data = NULL, 
        readonly = FALSE, clear = FALSE,...)
dbframe_sqlite(table, dbname, readonly = FALSE,...)
dbframe_sqlite_temporary(table, dbname = ":memory:", readonly = FALSE,...)
dbframe_unknown(table, readonly = FALSE,...)
}
\arguments{
  \item{table}{A character string.  This will typically be the name of the table in the
      SQLite database, but it can also be the name of a view, or an SQL
      select statement that defines a query.}
  \item{dbdriver}{The name of the database driver to use.  Right now,
    only "SQLite" is supported.}
  \item{dbname}{The file name of the SQLite database.}
  \item{data}{An optional data frame to insert into the table.}
  \item{readonly}{Logical: prevent the user from inserting to or clearing
    the linked table.}
  \item{clear}{Logical: if the table already exists, should it be
      removed before making the link?}
  \item{\dots}{Optional arguments that will be stored (if necessary) and
    added to \dQuote{dbConnect}}
}

\details{This function constructs a new \samp{dbframe} objet referencing
  the table \dQuote{table} in the database file \dQuote{dbname}.  If
  the argument \samp{data} is not null, its values are inserted into the
  table.  If \samp{clear} is \samp{TRUE}, any existing version of the table
  is removed first.

  \samp{dbframe{\char95}unknown} is a blind guess at a general way to implement a
  generic constructor.  It may or may not work and I haven't tested it
  yet.  The optional arguments are stored (as a list) as a slot of the
  \samp{dbframe} object and are passed to \samp{dbConnect}.  If you use it,
  please let me know and suggest changes/improvements.
}

\value{Returns a \code{dbframe} object.}

\author{Gray Calhoun \email{gcalhoun@iastate.edu}}
\seealso{\code{\link{dbframe-class}}, \code{\link{clear}}, \code{\link{insert<-}}}

\section{Implementation}{These functions are pretty simple; \samp{dbframe}
creates a new object corresponding to \dQuote{dbdriver} and then removes
or inserts data to the table according to the arguments.  If
\dQuote{dbdriver} hasn't been implemented yet, we initialize a
\dQuote{dbframe_unknown} object that will try to guess how to open a
connection to the database (I have no idea if this will work well or
not; if you use it, please be careful and give me feedback on how well
it goes).
\preformatted{<<*>>=
    dbframe <- function(table, dbname = NULL, dbdriver = "SQLite",
                        data = NULL, readonly = FALSE, clear = FALSE,...) \{
      x <- switch(dbdriver, 
                  "SQLite" = \{
                    if (is.null(dbname)) \{
                      warning("'dbname' is null; setting to ':memory:'")
                      dbname <- ":memory:"
                    \}
                    if (dbname \%in\% c(":memory:", "")) \{
                      dbframe_sqlite_temporary(table, dbname, readonly,...)
                    \} else \{
                      dbframe_sqlite(table, dbname, readonly,...)
                    \}
                  \},
                  dbframe_unknown(table, readonly,...))
      <<Clear old table and insert new data>>
      return(x)
    \}

    <<Define "dbframe_sqlite">>
    <<Define "dbframe_sqlite_temporary">>
    <<Define "dbframe_unknown">>
}

Manipulating the \samp{dbframe} object after creating it is easy and we
just use the existing \samp{dbframe} methods.
\preformatted{<<Clear old table and insert new data>>=
    if (clear) clear.result <- clear(x)
    if (!is.null(data)) insert(x) <- data
}

\samp{dbframe{\char95}sqlite} makes sure that the right \samp{RSQLite} libraries are
loaded and creates a new \samp{dbframe{\char95}sqlite} object.
\preformatted{<<Define "dbframe_sqlite">>=
    dbframe_sqlite <- function(table, dbname, readonly = FALSE,...) \{
      <<Load SQLite libraries>>
      return(new("dbframe_sqlite", table = unname(table), rowid = integer(),
                 dbname = unname(dbname), readonly = unname(readonly),
                 dbConnect.arguments = list(...)))
    \}
}

\preformatted{<<Define "dbframe_sqlite_temporary">>=
    dbframe_sqlite_temporary <- 
      function(table, dbname = ":memory:", readonly = FALSE,...)
      stop("Temporary SQLite databases aren't implemented.")
}    

The \samp{dbframe} package only suggests the \samp{RSQLite} and
\samp{RSQLite.extfuns} packages; it doesn't depend formally on them.
Consequently those packages aren't loaded when \samp{dbframe} is first
load; I put off loading those packages until it is clear that the user
wants to interface with an SQLite database, which happens when a
\samp{dbframe{\char95}sqlite} object is created.  As things stand now, this delay
doesn't do very much.  When I add support for other SQL databases,
though, I plan to use the same sort of approach and delay loading the
necessary libraries until the appropriate constructor is called.  This
saves us from loading several database libraries when we're only going
to use one of them, or from requiring the user to load the libraries
explicity.
\preformatted{<<Load SQLite libraries>>=
    require(RSQLite)
    require(RSQLite.extfuns)
}

\samp{dbframe{\char95}unknown} is kind of a crapshoot.  It stores the optional
arguments in a list so that it can pass them to \samp{dbConnect} as needed.
\preformatted{<<Define "dbframe_unknown">>=
    dbframe_unknown <- function(table, readonly = FALSE,...) \{
      return(new("dbframe", table = unname(table), 
                 readonly = unname(readonly),
                 dbConnect.arguments = list(...)))
    \}
}
}
\section{Unit Tests}{
\preformatted{<<test-dbframe.R>>=
    library(testthat)

    data(morley)
    filename <- tempfile(fileext = ".db")

    test_that("Basic constructor works", \{
      d1 <- dbframe("test1", dbname = filename, data = morley)
      expect_that(d1, is_a("dbframe_sqlite"))
      expect_that(morley, is_equivalent_to(select(d1)))
    \})

    test_that("Simple methods work", \{
      d1 <- dbframe("test2", dbname = filename, data = morley)
      expect_that(nrow(morley), equals(nrow(d1)))
    \})
}
}

\examples{
data(chickwts)
filename <- tempfile(fileext = ".db")
example <- dbframe("dbframe1", dbname = "filename", dbdriver = "SQLite",
                   data = chickwts)
tail(example)
## an example where "table" is a select statement on its own
% example2 <- 
%   dbframe("(select min(weight) as smallest from dbframe)",
%           dbname = filename, dbdriver = "SQLite")
% select(example.sqlite2)

## clean up
unlink(filename)
}

\keyword{database}
\keyword{interface}

