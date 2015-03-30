dbframe -- an R to SQL interface
================================

Description
-----------

This package is designed to simplify database queries in R.  It
creates a new "dbframe" class that functions like a data frame, but is
linked to a table, view, or query from a SQL database.  It also
defines "insert" and "select" methods that essentially mimic the
corresponding SQL statements but require much less typing.

So far (as of 2011-12-01), the library works with SQLite
databases.  There is a general method to link with arbitrary database
engines, but I have not run or tested it, so watch out.  Joins have
not been implemented yet, nor have other queries; but I hope to add
them soon.

Use
---

I assume that you know how to load libraries in R.  If not, type
'?library' at the R prompt and read the documentation.  dbframe is
loaded as usual.  At the moment, it needs the RSQLite library to be
installed as well, but that isn't listed as a formal dependency.  See
the package documentation (available as a pdf download from github)
for details of the functions defined by this package.

Installation
------------

You can download a 'source' R package from github, R-forge, or
http://www.econ.iastate.com/~gcalhoun which is installed as usual.

Installation from the original source code is a little trickier.  This
package is a "literate program," meaning that the documentation and
the code are marked up in the files "dbframe/rw/*.rw".  The "noweb"
program parses those files and
- writes the code to .R files in the folder "dbframe/R"
- writes the documentation to .Rd files in the filder "dbframe/man"
- writes the individual tests to .R files in the folder
  "dbframe/inst/tests"

Noweb can be downloaded at http://www.cs.tufts.edu/~nr/noweb/

You also need the backend file 'tord' that can be downloaded at
http://www.econ.iastate.edu/~gcalhoun

If you have noweb and tord installed, typing 'make' will generate the
R/, man/ files and the individual tests and then check the package for
errors.  You may need to change some of the paths to binaries on your
system.  After that, you can install the package as usual.

License and copying
-------------------

Copyright (c) 2010-2015, Gray Calhoun.

All of the code in this directory is licensed under the
[MIT "Expat" License](http://opensource.org/licenses/MIT):

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

Errors and contact information
------------------------------

Please let me know if you find errors. You can email <gray@clhn.org>
or file an issue at
<https://github.com/grayclhn/dbframe-R-library/issues>. Thanks!
