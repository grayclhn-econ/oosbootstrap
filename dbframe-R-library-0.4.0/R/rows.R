## Copyright (C) 2010-2015 Gray Calhoun; MIT license

    rows <- function(x) {
      x <- as.data.frame(x)
      if (nrow(x) > 0) {
        lapply(seq.int(nrow(x)), function(i) x[i,])
      } else {
        list()
      }
    }
