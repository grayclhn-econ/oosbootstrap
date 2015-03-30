## Copyright (C) 2010-2015 Gray Calhoun; MIT license

    head.dbframe <- function(x, n = 6L,...) {
      if (n >= 0) {
            return(select(x, limit = n, as.data.frame = TRUE,...))
      } else {
            return(select(x, limit = n + nrow(x), as.data.frame = TRUE,...))
      }
    }

    tail.dbframe <- function(x, n = 6L,...) {
      if (n >= 0) {
            return(select(x, limit = sprintf("%d,%d", nrow(x) - n, n),
                          as.data.frame = TRUE,...))
      } else {
            return(select(x, limit = sprintf("%d,%d", -n, nrow(x) + n),
                          as.data.frame = TRUE,...))
      }
    }
