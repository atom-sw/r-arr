This is **arrr**: an R script to help generate replication packages that
run statistical analyses in R.


# Installation

Clone this repository and add the clone's directory to the shell's
path (or, alternatively, add a link to `arrr` in a directory that is
already within the path).

To check that you have all required R packages installed, try:

```bash
arrr -h
```

If you get any errors, install the missing R packages.


# Usage

Pass to `arrr` all files and directories that you want to include in
the replication package. `arrr` looks for any `.R` and `.Rmd` files
among those files and directories, and determines which R packages
they import or otherwise use (henceforth called *deps*).

Based on this information, it generates:

   1. A Bash bootstrap script. This is a Bash script that can be run
      in an Ubuntu/Anaconda environment to install a basic R system.
	  
   2. An R bootstrap script. This is an R script that can be run in
      any R system to install all *deps*.
	  
   3. A Dockerfile. This can be used to build a Docker image with an
      Ubuntu/Anaconda environment configured using the aforementioned
      bootstrap scripts. It also copies all replication package files
      into the image.
	  
   4. A copy of all replication package files, ready for zipping and
      upload to an open data repository.
	  
   5. A template `README.md`, empty except for the name of the
      replication package and a reference to `arrr`.

The bootstrap scripts install same version of R and of the *deps* as
those that are installed on the system where `arrr` is run
(information from `devtools::session_info`). If a dep is installed
from GitHub, the bootstrap scripts will also try to install it from
the same GitHub repository.

If any package among *deps* is not installed on the system where
`arrr` is run, `arrr` will issue a warning and omit the package from
the bootstrap script. This likely means that analysis may not be fully
rerun in the replication package! However, if such packages are part
of the *base* R installation, this is not a problem; in this case,
`arrr` does not issue a warning but still lists the packages
separately.

For the best results, run `arrr` on the same system that you used to
run the data analysis that goes in the replication package (or a
system configured in a very similar way).


## Arguments and directory structure

From the directory `.` where it is invoked, `arrr` creates an output
directory `<outdir>` where it stores all its output as follows:

```
./<outdir>/README.md
./<outdir>/scripts/{Dockerfile, bash-bootstrap.sh, r-bootstrap.R}
./<outdir>/<content>/ (... replication package files ...)
```

Directory names `<outdir>` and `<content>` can be changed with
arguments `--outdir` and `--content`.

If a directory named `<outdir>` already exists, `arrr` terminates with
an error. Option `--overwrite` overrides this behavior: `arrr` wipes
the existing directory named `<outdir>` and creates a fresh one.

The R bootstrap script includes the URL of a CRAN repository to
download R packages from. Option `--cran` controls this URL, which
must be a [valid CRAN
mirror](https://cran.r-project.org/mirrors.html).


## Building a Docker image

The Dockerfile uses paths relative to `<outdir>`, that is the root
directory of the replication package. Thus, build an image using
Docker option `-f`:

```bash
cd <outdir>
docker build -f scripts/Dockerfile --tag=my-replication-package .
```


# Customization

`arrr` generates bootstrap scripts and Dockerfile based on templates
(also available in this repository). You can modify the structure of
the generated scripts by modifying these templates before calling
`arrr`.

There are two kinds of holes in these templates:

   1. A variable hole has the form `##[<VAR> var_name]##` and can
      appear anywhere in a line (but not more than once per
      line). When it instantiates the templates, `arrr` replaces this
      string with the value of a (string) variable named `var_name`
      surrounded by double quotation marks. If the hole has the form
      `##[<VARU> var_name]##` instead, the string won't be quoted.
      Variable holes can be used in all three templates, but note that
      if you want to pass more variables you will need to
      correspondingly pass them as argument to `str_glue` when
      templates are generated.
	  
   2. A package hole has the form `##[<INSTALL> regex ]##` or
      `##[<INSTALL> regex ][url_list]##` and takes up a whole
      line. When it instantiates the template, `arrr` looks for R
      packages whose name matches the regular expression `regex`, and
      replaces this string with installation commands for all the
      matching packages. Note that the space before the closing `]` is
      required, and terminates the regular expression. Regular
      expressions use the syntax of R's package
      [`stringr`](https://cran.r-project.org/web/packages/stringr/). In
      the second variant of the hole, `url_list` is a comma-separated
      list of URLs of R package repositories. In this case, `arrr`
      also adds those URLs to the installation commands matching
      `regex` using option `repos`. Precisely, it puts those URLs in
      front, followed by the other repositories configured in R, which
      are still available as fallback.  Package holes are only valid
      in the R bootstrap script template.


## Expressions in template

Since `arrr` uses `stringr::str_glue` to fill in holes with values,
you should not not use expressions between curly braces *anywhere* in
the template, as they would trigger an error. Instead, replace single
curly braces by double curly braces, which `str_glue` will turn back
into single curly braces. For example, write `${{X}}` instead of
`${X}` in a template to get the usual variable lookup expression in
Bash.


## Stan and other fixed dependencies

Regardless of the detected dependencies, `arrr`'s bootstrap scripts
always install R's interfaces for [Stan](https://mc-stan.org/)
(packages `rstan` and `cmdstanr`). If you want to override this
behavior, edit the template of the R bootstrap script.

It also installs the R package `tinytex`, so that the R system is also
capable of knitting `.Rmd` files into PDFs. Again, modify the R
bootstrap script template to skip installing this package.
