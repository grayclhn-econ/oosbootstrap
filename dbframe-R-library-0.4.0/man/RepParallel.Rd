% Copyright (C) 2010-2015 Gray Calhoun; MIT license

\name{RepParallel}
\alias{RepParallel}

\title{Parallel version of \code{replicate}}
\description{A simple parallel clone of \samp{replicate}; this function
  is a wrapper for \samp{mclapply} just like \samp{replicate} is a wrapper
  for \samp{sapply}.}
\usage{
RepParallel(n, expr, simplify = "array",...)
}

\arguments{
  \item{n}{An integer giving the number of replications to execute.}
  \item{expr}{R code to execute.}
  \item{simplify}{logical or character string; should the result be simplified
          to a vector, matrix or higher dimensional array if possible?}
  \item{\dots}{Optional arguments to \samp{mclapply}.}
}

\value{Just as in replicate.}
\author{Gray Calhoun \email{gcalhoun@iastate.edu}}

\seealso{\code{\link{replicate}}, \code{\link{mclapply}}}

\section{Implementation}{
\preformatted{<<*>>=
    RepParallel <- function(n, expr, simplify = "array",...) \{
      answer <-
        mclapply(integer(n), eval.parent(substitute(function(...) expr)),...)
      if (!identical(simplify, FALSE) && length(answer)) 
        return(simplify2array(answer, higher = (simplify == "array")))
      else return(answer)
    \}
}
}

