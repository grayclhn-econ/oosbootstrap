% Copyright (C) 2010-2015 Gray Calhoun; MIT license

\newcommand{\sql}{\acronym{sql}}
\newcommand{\sqlite}{\acronym{sql}ite}

\name{dbframe-package}
\alias{dbframe-package}
\docType{package}
\title{An overview of the dbframe package}

\description{
  This package and documentation are very much under
  development.  Right now, it only provides an interface with \sqlite
  databases and has untested code that will try to guess the right
  interface for other databases.  The function \code{dbframe} creates a
  new dbframe object associated with one of the tables in an \sqlite
  database.  Queries on the database can then be executed through the
  \code{dbframe} object's methods.  This package also provides some
  convenient functions for printing and manipulating data frames, but
  its main role is to make it easier to write queries.}

\details{This package is a collection of functions that I'm developing
  to work more easily with databases.  I find it annoying to have to
  type \acronym{\sql} statements into functions like \code{dbSendQuery},
  etc. to explicitly pull data from a database into an R dataframe,
  especially since I often forget the details of \acronym{\sql}.  When
  the database is updated regularly, this is especially annoying since
  the R dataframe gets out of date and the \acronym{\sql} statement needs
  to be executed again.  This package is my attempt automate this sort
  of routine use of \acronym{\sql}.  I've tried to make the syntax look
  more \dQuote{R-like} than, eg, DBI.  Please let me know if you have
  any suggestions for functionality, appearance, or syntax.

  \subsection{Queries}{So far, I've just implemented \code{insert} and
    \code{select} queries.  \code{insert} allows you to insert new
    records into a database from an R data frame.  \code{select} allows
    you to retrieve those records from the data base.  \code{select}
    also allows some basic data analysis, more or less anything that is
    available as an aggregate function in the \acronym{\sql} database.}

  \subsection{Notes on implementation}{I'm attempting to make this
    package a literate program (Knuth, 1984).  That means that the
    source code is embedded in the documentation.  The
    \dQuote{implementation} section of each help page presents and
    discusses the source code for its functions.  Right now, the
    formatting is pretty rudimentary, but I hope to improve the
    appearance at some point.}

  This package is currently in alpha.  I use it in my research and will
  add functionality as I need it, but I don't have the time to extend it
  in some obviously important directions that are unrelated to my
  workflow.  I plan to do so in the future, though, and even now would
  like to implement specific requests if people are interested.  }

\references{
Knuth, Donald E., Literate Programming. \emph{The Computer Journal},
\bold{27}(2):97--111, 1984.
}

\examples{
filename <- tempfile(fileext = ".db")
example.dbframe <- dbframe("package1", dbname = filename, clear = TRUE)
data(chickwts)
insert(example.dbframe) <- chickwts
select(example.dbframe, "avg(weight)", group.by = "feed")
unlink(filename)
}
\author{Gray Calhoun \email{gcalhoun@iastate.edu}}
\keyword{package}
\keyword{database}

