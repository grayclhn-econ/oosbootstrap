% Copyright (C) 2010-2015 Gray Calhoun; MIT license

\name{dbframe-class}
\Rdversion{1.1}
\docType{class}
\alias{dbframe-class}
\alias{==,dbframe,dbframe-method}
\alias{!=,dbframe,dbframe-method}
\alias{dbname,dbframe-method}
\alias{sql,dbframe-method}
\alias{dbframe_sqlite-class}
\alias{==,dbframe_sqlite,dbframe-method}
\alias{!=,dbframe_sqlite,dbframe_sqlite-method}
\alias{dbname,dbframe_sqlite-method}
\alias{sql,dbframe_sqlite-method}
\alias{sql}
\alias{tablename}
\alias{tablename,dbframe-method}
\alias{readonly}
\alias{dbConnect,dbframe-method}
\alias{dbConnect,dbframe_sqlite-method}
\alias{readonly,dbframe-method}
\alias{dbname}

\newcommand{\sql}{\acronym{sql}}
\newcommand{\sqlite}{\acronym{sql}ite}

\title{Class \code{"dbframe"}}
\description{Each \dQuote{dbframe} object references a particular
  table inside an \sql database.  The class and its methods are
  designed to query and manipulate the table easily inside R.}
\section{Objects from the Class}{
Objects can be created by calls of the form
\code{new("dbframe", ...)}, but I recommend that you use the
constructor \samp{dbframe}.

The \samp{dbframe{\char95}sqlite} class creates a link to a table in an \sqlite
database, and \samp{dbframe} acts as a superclass.
\samp{dbframe{\char95}sqlite{\char95}temporary} implements temporary \acronym{sql}ite
databases.  I'd like to add other classes that store links to other
databases (i.e. My\sql and Postgre\sql) as well.  Until then, \samp{dbframe}
also works as an experimental class that tries to guess how to open a
connection to the right database---please let me know how well it works,
or if it works at all.}

\section{Slots}{
  \subsection{\code{dbframe}}{
    \describe{
      \item{\code{dbConnect.arguments}:}{Object of class \code{"list"}, a
        list of arguments to pass to \samp{dbConnect} when it's time to
        connect to the database.}
      \item{\code{readonly}:}{Object of class \code{"logical"} that
        indicates whether the user is allowed to write to the database.
        Be careful!  This is implemented only as a safeguard against
        carelessness; it is still very easy to write to the table.}
      \item{\code{table}:}{Object of class \code{"character"}, the name
        of the table associated with this \samp{dbframe} object. }
    }
  }
  \subsection{Additional slots for \code{dbframe_sqlite}}{
    \describe{
      \item{\code{dbname}:}{Object of class \code{"character"}, the filename
        of the associated SQLite database.}
      \item{\code{rowid}:}{Object of class \code{"integer"}, the rowid of the
            last value inserted into the table.}
    }
  }
}
\section{Methods}{
  \subsection{\code{dbframe}}{
    \describe{
      \item{clear}{\code{signature(... = "dbframe")}: Remove the table
        corresponding to the \samp{dbframe} object from its database.
        Please see the \samp{clear} documentation for details.}
      \item{dbname}{\code{signature(x = "dbframe_sqlite")}: Returns the
        filename of the \sqlite database associated with the object.
\preformatted{<<Define "dbname" method>>=
    setMethod("dbname", signature = c("dbframe"), function(x) x@dbname)
}}
      \item{dbConnect}{\code{signature(drv = "dbframe")}:
        Establishes a connection with the database associated with the
        object.
\preformatted{<<Define "dbConnect" method for "dbframe">>=
    setMethod("dbConnect", signature = "dbframe", 
              definition = function(drv,...)
              do.call("dbConnect", drv@dbConnect.arguments))
}}
      \item{insert<-}{\code{signature(x = "dbframe")}: Insert records
        into the \samp{dbframe} table.  Please see individual
        documentation for details.}
      \item{readonly}{\code{signature(x = "dbframe")}: Determine whether
        the dbframe object is read-only.
\preformatted{<<Define "readonly" method>>=
    setMethod("readonly", signature = c("dbframe"), function(x) x@readonly)
}}
      \item{select}{Query the \samp{dbframe} table.  Please see individual
        documentation for details.}   
      \item{tablename}{\code{signature(x = "dbframe")}: Returns the table
        name associated with the object.
\preformatted{<<Define "tablename" method>>=
    setMethod("tablename", signature = c("dbframe"), function(x) x@table)
}
      }
      \item{is.linked}{\code{signature(x = "dbframe")}: Check whether
        the table associated with the \samp{dbframe} exists.
\preformatted{<<Define "is.linked" method>>=
    setMethod("is.linked", signature = c("dbframe"), function(x,...) \{
      dbc <- dbConnect(x,...)
      answer <- tablename(x) \%in\% dbListTables(dbc)
      dbDisconnect(dbc)
      return(answer)
    \})
}
      }
    }
  }

  \subsection{For \code{dbframe_sqlite}}{
    \describe{
      \item{dbConnect}{\code{signature(drv = "dbframe_sqlite")}:
        Establishes a connection with the database associated with the
        object.
\preformatted{<<Define "dbConnect" method for "dbframe_sqlite">>=
    setMethod("dbConnect", signature = "dbframe_sqlite", 
      definition = function(drv,...) return(do.call("dbConnect",
        c(drv = "SQLite", dbname = dbname(drv), list(...),
          dbConnect.arguments = drv@dbConnect.arguments))))
}
      }
      \item{rowid}{\code{signature(x = "dbframe_sqlite")}: Returns the
          rowid associated with the last insert.
\preformatted{<<Define "rowid" method>>=
    setMethod("rowid", signature = c("dbframe_sqlite"), 
              function(x,...) x@rowid)
}
      }
      \item{rowid<-}{\code{signature(x = "dbframe_sqlite")}: Assigns the
          rowid associated with the last insert.
\preformatted{<<Define "rowid<-" method>>=
    setMethod("rowid<-", signature = c("dbframe_sqlite"), function(x,...,value) \{
      x@rowid <- as.integer(value)
      return(x)\})
}
      }
    }
  }
}
\section{S3 Methods}{
  \describe{
    \item{as.data.frame}{\code{as.data.frame.dbframe}: Coerce a
    \samp{dbframe} object to a data frame.
\preformatted{<<Define "as.data.frame" method>>=
    as.data.frame.dbframe <- function(x,...) select(x,...)
}
}
    \item{dim}{\code{dim.dbframe}: Determine the number of
      rows and columns in a dbframe.
\preformatted{<<Define "dim" method>>=
    dim.dbframe <- function(x) \{
      nrows <- select(x, "count(*)")[[1]]
      ncols <- length(select(x, limit = 0))
      c(nrows, ncols)
    \}
}
}}}

\author{Gray Calhoun \email{gcalhoun@iastate.edu}}
\section{Implementation}{
  The basic definition of these classes is straightforward.
  Individual methods are defined above; I'll define the generic
  functions here as necessary; note that the generic function for
  \samp{dbConnect} is defined in the DBI package.
\preformatted{<<*>>=
    setClass("dbframe", representation(table = "character",
                                       readonly = "logical",
                                       dbConnect.arguments = "list"))

    setClass("dbframe_sqlite", contains = "dbframe",
             representation(rowid = "integer", dbname = "character"))

    <<Define "dbConnect" method for "dbframe">>
    <<Define "dbConnect" method for "dbframe_sqlite">>
 
    <<Define "as.data.frame" method>>
    <<Define "dim" method>>
  
    setGeneric("tablename", function(x) standardGeneric("tablename"))
    <<Define "tablename" method>>
    setGeneric("dbname", function(x) standardGeneric("dbname"))
    <<Define "dbname" method>>
    setGeneric("readonly", function(x) standardGeneric("readonly"))
    <<Define "readonly" method>>
    setGeneric("is.linked", function(x,...) standardGeneric("is.linked"))
    <<Define "is.linked" method>>
    setGeneric("rowid", function(x,...) standardGeneric("rowid"))
    <<Define "rowid" method>>
    setGeneric("rowid<-", function(x,...,value) standardGeneric("rowid<-"))
    <<Define "rowid<-" method>>
}
}

\seealso{\code{\link{dbframe}}, \code{\link{clear}},
  \code{\link{insert<-}}, \code{\link{select}}}

\keyword{classes}
\keyword{database}

