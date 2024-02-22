print("starting  package .Rprofile")

if (interactive() && commandArgs()[1] == "RStudio")
{
  message('loading packages')
  if(!require("pacman")) install.packages("pacman")
  options(shiny.reactlog=TRUE)
  pacman::p_load(
    devtools,
    rsconnect,
    dplyr,
    lubridate,
    magrittr,
    conflicted,
    reprex,
    golem
  )
  # suppressMessages(require(devtools)) # loads usethis
  # suppressMessages(require(rsconnect)) # loads rsconnect
  # suppressMessages(require(dplyr))
  # suppressMessages(require(lubridate))
  # suppressMessages(require(magrittr))
  # suppressMessages(require(conflicted))
  # suppressMessages(require(reprex))
  # suppressMessages(require(golem))
  
  # credentials::set_github_pat() # key to be able to install_github() private repos
  # alternative: store pat in .renviron
  conflicted::conflict_prefer("filter", "dplyr")
  conflicted::conflict_prefer("lag", "dplyr")
  conflicted::conflict_prefer("summarise", "dplyr")
  conflicted::conflict_prefer("summarize", "dplyr")
  conflicted::conflict_prefer("select", "dplyr")
  conflicts_prefer(devtools::install_dev_deps)
  
}
