# Contributing to this project

This document outlines how to propose a change to this project.
For a detailed discussion on contributing to this and other packages, 
please see the [tidyverse](https://www.tidyverse.org/)'s
[development contributing guide](https://rstd.io/tidy-contrib) 
and [code review principles](https://code-review.tidyverse.org/).

## Fixing typos

You can fix typos, spelling mistakes, or grammatical errors in the documentation 
directly using the GitHub web interface, 
as long as the changes are made in the _source_ file. 
This generally means you'll need to edit 
[roxygen2 comments](https://roxygen2.r-lib.org/articles/roxygen2.html) 
in an `.R`, not a `.Rd` file. 
You can find the `.R` file that generates the `.Rd` by reading the comment in the first line.

## Bigger changes

If you want to make a bigger change, it's a good idea to first file an issue and make sure someone from the team agrees that it’s needed. 
If you’ve found a bug, please file an issue that illustrates the bug with a minimal 
[reprex](https://www.tidyverse.org/help/#reprex) (this will also help you write a unit test, if needed).
See the tidyverse guide on [how to create a great issue](https://code-review.tidyverse.org/issues/) for more advice.


### Pull request process

* [ ] Fork the package and clone onto your computer. If you haven't done this before, we recommend using `usethis::create_from_github("UCD-SERG/serodynamics", fork = TRUE)`.

* [ ] Install all development dependencies with `devtools::install_dev_deps()`, and then make sure the package passes R CMD check by running `devtools::check()`. 
    If R CMD check doesn't pass cleanly, it's a good idea to ask for help before continuing. 
* [ ] Create a Git branch for your pull request (PR). We recommend using `usethis::pr_init("brief-description-of-change")`.

* [ ] Make your changes, commit to git, and then create a PR by running `usethis::pr_push()`, and following the prompts in your browser.
    - [ ] The title of your PR should briefly describe the change.
    - [ ] The body of your PR should contain `Fixes #issue-number`.
    - [ ] Your changes should conform to the tidyverse code style guidelines and design principles described [below](#sec-code-style).

* [ ] For user-facing changes, add a bullet to the top of `NEWS.md` (i.e. just below the first header). Follow the style described in <https://style.tidyverse.org/news.html>.

*  GitHub will [automatically check your PR](https://github.com/r-lib/actions) 
to see if the package is still functional on Mac OS, Windows, and Linux; 
if not, you will receive an email describing the problems. 
   - For help decoding errors, try this resource: <https://github.com/r-lib/actions?tab=readme-ov-file#where-to-find-help>.

### Code style {#sec-code-style}

*   New code should follow the tidyverse [style guide](https://style.tidyverse.org)
and [design principles](https://design.tidyverse.org/).
    You can use 
    the [lintr](https://CRAN.R-project.org/package=lintr) package 
    to automatically check for some style and design issues
    and the [styler](https://CRAN.R-project.org/package=styler) package to 
    automatically correct some issues. 
    Please don't restyle code that has nothing to do with your PR.  



*  We use [roxygen2](https://cran.r-project.org/package=roxygen2), with [Markdown syntax](https://cran.r-project.org/web/packages/roxygen2/vignettes/rd-formatting.html), for documentation.  

*  We use [testthat](https://cran.r-project.org/package=testthat) for unit tests. 
   Contributions with test cases included are easier to accept.  

## Code of Conduct

Please note that the serodynamics project is released with a
[Contributor Code of Conduct](CODE_OF_CONDUCT.md). By contributing to this
project you agree to abide by its terms.
