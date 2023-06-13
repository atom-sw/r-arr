#!  /usr/bin/env Rscript

repo_URL = ##[<VAR> cran]##

repo = getOption("repos") 
repo["CRAN"] = repo_URL
options(repos=repo)

# remotes::install_version is used by this script
install.packages('remotes')

robust_install_version <- ##[<VARU> robust_install_version_def]##

# Install Stan toolchain first
##[<INSTALL> ^(rstan) ][https://mc-stan.org/r-packages/]##
##[<INSTALL> ^(cmdstanr) ][https://mc-stan.org/r-packages/]##

cpp_opt <- list(
  "CXX" = "g++",
  "TBB_CXX_TYPE" = "gcc"
  )
cmdstanr::install_cmdstan(cores=parallel::detectCores(), cpp_options=cpp_opt)

# Install all other packages
##[<INSTALL> ^(?!(rstan|cmdstanr|tinytex)) ]##

# Install TinyTeX and PDFcrop to knit Rmd files to PDF
##[<INSTALL> ^(tinytex) ]##
tinytex::install_tinytex()
tinytex::tlmgr_install('pdfcrop')


# Log packages that should have been installed, and check whether they are actually available
requirements <- ##[<VARU> requirements]##
check_installed_packages <- ##[<VARU> check_installed_packages_def]##
check_installed_packages(requirements)        
