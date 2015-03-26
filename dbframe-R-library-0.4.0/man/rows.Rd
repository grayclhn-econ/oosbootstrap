% Copyright (C) 2010-2015 Gray Calhoun; MIT license

\name{rows}
\alias{rows}
\title{Extract rows from a data frame and present as a list}
\description{This is a convenience function that takes a dataframe \dQuote{x}
  and returns a list where each element is a row of x.  I use this for
  loops.}
\usage{
rows(x)
}

\arguments{
  \item{x}{A data frame or an object that can be coerced to a data frame.}
}

\value{A list; each element is a row of \code{x}.}
\author{Gray Calhoun \email{gcalhoun@iastate.edu}}

\section{Implementation}{
\preformatted{<<*>>=
    rows <- function(x) \{
      x <- as.data.frame(x)
      if (nrow(x) > 0) \{
        lapply(seq.int(nrow(x)), function(i) x[i,])
      \} else \{
        list()
      \}
    \}
} 
}

\examples{
data(chickwts)
for (r in rows(head(chickwts))) print(r)
}
\keyword{utilities}

