% Copyright (C) 2010-2015 Gray Calhoun; MIT license

\name{head}
\alias{nrec}
\alias{head.dbframe}
\alias{tail.dbframe}

\title{Retrieve head or tail of a table}
\description{Retrieves the first or last few records from a
  \samp{dbframe}.  This function mimics the corresponding data frame
  methods.}
\usage{
\method{head}{dbframe}(x, n = 6L, \dots)

\method{tail}{dbframe}(x, n = 6L, \dots)
}
\arguments{
  \item{x}{A \code{dbframe} object}
  \item{n}{An integer.  If positive, the number of records to
      retrieve.  If negative, these functions will retrieve all but
      \samp{n} records.}
  \item{\dots}{Other arguments to pass to \samp{select}}
}

\value{Returns a data frame with the records.}
\author{Gray Calhoun \email{gcalhoun@iastate.edu}}

\seealso{\code{\link{head}}, \code{\link{tail}}, \code{\link{select}}}

\section{Implementation}{
\samp{head} and \samp{tail} are really basic functions; the implementation
is pretty straightforward.  The only complication is that the
\dQuote{\ldots} arguments can be passed multiple times, so I pull them
out and store them in a list.
\preformatted{<<*>>=
    head.dbframe <- function(x, n = 6L,...) \{
      if (n >= 0) \{
        <<Return the first |n| records>>
      \} else \{
        <<Return all but the last |n| records>>
      \}
    \}

    tail.dbframe <- function(x, n = 6L,...) \{
      if (n >= 0) \{
        <<Return the last |n| records>>
      \} else \{
        <<Return all but the first |n| records>>
      \}
    \}
}
We use select statements with \dQuote{limit} and \dQuote{offset} to get
the records.
\preformatted{<<Return the first |n| records>>=
    return(select(x, limit = n, as.data.frame = TRUE,...))
}

\preformatted{<<Return all but the last |n| records>>=
    return(select(x, limit = n + nrow(x), as.data.frame = TRUE,...))
}

\preformatted{<<Return the last |n| records>>=
    return(select(x, limit = sprintf("\%d,\%d", nrow(x) - n, n),
                  as.data.frame = TRUE,...))
}

\preformatted{<<Return all but the first |n| records>>=
    return(select(x, limit = sprintf("\%d,\%d", -n, nrow(x) + n),
                  as.data.frame = TRUE,...))
}
}

\section{Unit tests}{
\preformatted{<<test-head.R>>=
    library(testthat)
    filename <- tempfile(fileext = ".db")

    data(morley)
    test_that("head and tail return the right number of records", \{
      dbf <- dbframe("tab1", dbname = filename, data = morley)
      expect_that(nrow(head(dbf)), equals(6))
      expect_that(nrow(tail(dbf)), equals(6))
  
      nrec <- sample(1:nrow(morley), 1)
      expect_that(nrow(head(dbf, nrec)), equals(nrec))
      expect_that(nrow(tail(dbf, nrec)), equals(nrec))

      expect_that(nrow(head(dbf, -nrec)), equals(nrow(morley) - nrec))
      expect_that(nrow(tail(dbf, -nrec)), equals(nrow(morley) - nrec))
    \})
}
}
\examples{
data(chickwts)
filename <- tempfile(fileext = ".db")
chicksdb <- dbframe("head1", dbdriver = "SQLite", dbname = filename,
                    data = chickwts)
head(chickwts)
tail(chickwts, -60)
tail(chickwts)
unlink(filename)
}

\keyword{database}


