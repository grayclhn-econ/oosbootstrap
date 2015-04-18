oosbootstrap overview
=====================

This repository contains the code and data for my (Gray Calhoun's)
unreleased paper *A simple block bootstrap for asymptoticall normal
out-of-sample test statistics*. The current version of the paper is
very preliminary and the mathematical results almost certainly have
errors. You can find the latest version of this repository at
<https://git.ece.iastate.edu/gcalhoun/oosbootstrap>.

This repository is for the "2015-04-18" version of
the paper.  The paper is an offshoot of another paper,
"An asymptotically normal out-of-sample test based on mixed estimation
windows."

Main files
----------

* `oosbootstrap.tex` is the LaTeX source for the paper itself.

Generating the pdf file and dependencies
----------------------------------------

To make the paper, you need LaTeX and Julia (version 0.3 or higher).
If you install GNU Make and latexmk, you can streamline the process by
typing `make` in this directory, which will call all of the necessary
commands in the right order.

Other dependencies
------------------

The `OutOfSampleBootstrap.jl` julia package, which can be installed
from Julia with the command

```
   Pkg.clone("https://github.com/grayclhn/OutOfSampleBootstrap.jl")
```

Known errors and bugs
---------------------

* See the issue tracker at
  <https://git.ece.iastate.edu/gcalhoun/oosbootstrap/issues> for a
  list of known problems.

License and copying
-------------------

Copyright (c) 2011-2015, Gray Calhoun.

All of the R and Julia source code for this project is licensed under
the [MIT "Expat" License](http://opensource.org/licenses/MIT):

> Permission is hereby granted, free of charge, to any person
> obtaining a copy of this software and associated documentation
> files (the "Software"), to deal in the Software without
> restriction, including without limitation the rights to use, copy,
> modify, merge, publish, distribute, sublicense, and/or sell copies
> of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be
> included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
> EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
> MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
> NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
> BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
> ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
> CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

Note that the code in the dbframe-R-library and oosanalysis-R-library
repos is available elsewhere under the GPL license; but I am the
author of those packages and am releasing them here under the MIT
license.

Errors and contact information
------------------------------

Please let me know if you find errors. (Bearing in mind that this
isn't even the first version of the paper.) You can email
<gcalhoun@iastate.edu> or file an issue at
<https://git.ece.iastate.edu/gcalhoun/oosbootstrap/issues>. Thanks!
