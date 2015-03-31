% Copyright (C) 2010-2015 Gray Calhoun; MIT license

\name{booktabs}
\alias{booktabs}
\title{Construct a nice table from a data frame}
\description{Constructs an attractive LaTeX table (using booktabs)
  from an arbitrary data frame.
}
\usage{
booktabs(dframe, align = "l", digits = 1, numberformat = FALSE,
         purgeduplicates = TRUE, tabular.environment = "tabularx",
         scientific = FALSE, include.rownames = FALSE,
         sanitize.text.function = function(x) x, drop = NULL,...)
}

\arguments{
  \item{dframe}{A data frame or an object that can be coerced to a data.frame.}
  \item{align}{A character vector specifying each column's alignment.
    Each element should be \dQuote{l}, \dQuote{c}, or \dQuote{r}.}
  \item{digits}{A vector of integers specifying the number of digits to
    display for each column.}
  \item{numberformat}{logical vector indicating which columns should be
    formatted as numbers.  This adds padding to the left side of the
    numbers so that the column aligns on the decimal point, switches to
    math mode to turn off old-style numbering (if needed), and converts
    hyphens into minus signs.}
  \item{purgeduplicates}{A logical vector that labels which columns
    should have duplicate entries removed.}
  \item{tabular.environment}{Defaults to using tabularx in LaTeX.}
  \item{scientific}{FALSE unless you want to use scientific notation in
    the tables.}
  \item{include.rownames}{Logical indicating whether should the data
  frame's rownames should be included.  Probably not.}
  \item{sanitize.text.function}{Disables escaping out backslashes, etc.
    This is the same as in \samp{xtable}.}
  \item{drop}{A character vector indicating some columns to omit.  This
    can be useful if those columns are used for sorting or to create
    derived columns.}
  \item{\dots}{Additional arguments to pass to \code{xtable}.}
}
\details{This function uses \code{xtable} to generate LaTeX code, then
  modifies the table.  The containing Latex document should use the
  \dQuote{booktabs} package.}
\value{A character object containing LaTeX code for a table.}

\author{Gray Calhoun \email{gcalhoun@iastate.edu}}
\seealso{\code{\link{xtable}}, \code{\link{print.xtable}}}

\section{Implementation}{
The basic implementation is straightforward.
\preformatted{<<*>>=
    booktabs <- function(dframe, align = "l", digits = 1,
                         numberformat = FALSE, purgeduplicates = TRUE,
                         tabular.environment = "tabularx", 
                         include.rownames = FALSE,
                         sanitize.text.function = function(x) x, 
                         drop = NULL,...) \{
      <<Define platform independent null file>>
      <<Format arguments>>
      return(<<Assemble Latex code for table>>)
    \}
}

To assemple the Latex code, we just call \samp{xtable} on the data frame,
then substitute out the first line to make the table span the entire
page.  Note that \samp{devnull} is defined elsewhere in the package.
\preformatted{<<Assemble Latex code for table>>=
    gsub(sprintf("\\\\\\\\begin\\\\\{\%s\\\\\}", tabular.environment),
         sprintf("\\\\\\\\begin\\\\\{\%s\\\\\}\\\\\{\\\\\\\\textwidth\\\\\}", tabular.environment),
         print(xtable(dframe, align = align, digits = digits,...),
               file = devnull, floating = FALSE,
               add.to.row = list(pos=list(-1, 0, nrow(dframe)),
                 command = c("\\\\toprule ", "\\\\midrule ", "\\\\bottomrule ")),
               tabular.environment = tabular.environment,
               sanitize.text.function = sanitize.text.function,
               include.rownames = include.rownames, hline.after = NULL))
}

The variable \samp{devnull} is defined to be a platform independent \samp{/dev/null}:
\preformatted{<<Define platform independent null file>>=
    devnull <- switch(Sys.info()["sysname"],
      Windows = "NUL", 
      Linux   = "/dev/null",
      Darwin  = "/dev/null",
      \{warning("Your OS is not explicitly supported; we'll assume /dev/null exists.")
       "/dev/null"\})
}

A little bit of routine reformatting needs to happen before calling \samp{xtable}.

\preformatted{<<Format arguments>>=
    dframe <- as.data.frame(dframe)
    <<Drop user-specified columns>>
    <<Correct dimensions of arguments>>
    <<Pad formatting columns to accomodate xtables handling of rownames>>
    <<Reformat numeric columns>>
    <<Remove duplicates from specified columns>>
}

The user can choose to leave out some of the columns.  This can be
useful if there are columns that are important for sorting the data
frame, but are not of interest on their own.
\preformatted{<<Drop user-specified columns>>=
    if (!is.null(drop)) \{
      columnnames <- names(dframe)
      if (!all(drop \%in\% columnnames)) \{
        warning("'drop' contains some columns not in 'dframe'")
      \}
      dframe <- dframe[, setdiff(names(dframe), drop), drop = FALSE]
    \}
}

For conveneince, we let arguments that affect column-by-column
formatting be written as a single value if the same value applies to
each column.  In that case, we repeat the value the correct number of times.

\preformatted{<<Correct dimensions of arguments>>=
    ncol <- ncol(dframe) + include.rownames
    if (length(align) == 1) align <- rep(align, ncol)
    if (length(digits) == 1) digits <- rep(digits, ncol)
    if (length(numberformat) == 1) numberformat <- rep(numberformat, ncol)
    if (length(purgeduplicates) == 1)
      purgeduplicates <- rep(purgeduplicates, ncol)
}

The way \samp{xtable} handles the row names is kind of annoying: alignment
and digits need to specified for it, even if the row names will not be
shown.  To avoid doing that, we pad the necessary arguments if the row
names aren't going to be shown.
\preformatted{<<Pad formatting columns to accomodate xtables handling of rownames>>=
    if (!include.rownames) \{
      align <- c("l", align)
      digits <- c(0, digits)
    \}
}

Columns that contain numbers are reformatted to align at the decimal
point and use the correct minus sign.
\preformatted{<<Reformat numeric columns>>=
    dframe[,numberformat] <- lapply(which(numberformat), function (i) \{
      emptyRows <- is.na(dframe[,i])
      rowTex <- rep("", length(emptyRows))
      rowTex[!emptyRows] <- 
        gsub("-", "\\\\\\\\!\\\\\\\\!-", sprintf("$\%s$", gsub(" ", "\\\\\\\\enskip", 
           format(round(as.numeric(dframe[!emptyRows,i]), 
                        digits[i + !include.rownames])))))
      rowTex
    \})
}


Finally, we remove duplicates in a slightly clever way
\preformatted{<<Remove duplicates from specified columns>>=
    repeats <- function(x) c(FALSE, x[-1] == x[seq_len(length(x) - 1)])
    purgeindex <- which(purgeduplicates)
    for (i in rev(seq_along(purgeindex))) \{
      dframe[repeats(dframe[[i]]) &
             duplicated(dframe[, purgeindex[seq_len(i)], drop = FALSE]),
             purgeindex[i]] <- NA
    \}
}
}

\section{Unit tests}{
\preformatted{<<test-booktabs.R>>=
    library(testthat)
    library(xtable)
    filename <- tempfile(fileext = ".db")

    data(longley)
    test_that("booktabs executes at all", \{
      expect_that(booktabs(longley), is_a("character"))
    \})

    test_that("Columns that are labeled 'numberformat' are formatted", \{
      d <- data.frame(x = c(-1.324, 0.93), y = c(10.443, 1.235))
      expect_that(booktabs(d, numberformat = TRUE, 
                           purgeduplicates = FALSE, digits = 2, align = "c"),
        prints_text("\\\\$\\\\\\\\\\\\\\\\\\\\!\\\\\\\\\\\\\\\\\\\\!-1.32\\\\$ & \\\\$10.44\\\\$"))
      expect_that(booktabs(d, numberformat = TRUE,
                           purgeduplicates = FALSE, digits = 2, align = "c"),
        prints_text("\\\\$\\\\\\\\\\\\\\\\enskip0.93\\\\$ & \\\\$\\\\\\\\\\\\\\\\enskip1.24\\\\$"))
    \})

    test_that("Argument checking works as expected", \{
      expect_that(booktabs(longley, drop = "WXYZ"),
        gives_warning("'drop' contains some columns not in 'dframe'"))
    \})
}
}

\examples{
data(chickwts)
cat(booktabs(head(chickwts)))
}


\keyword{methods}
\keyword{printing}

