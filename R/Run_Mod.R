#' @title Run Jags Model
#' @author Sam Schildhauer
#' @description
#'  run_mod() takes a data frame and adjustable mcmc inputs to
#'  [runjags::run.jags()] as an mcmc
#'  bayesian model to estimate antibody dynamic curve parameters.
#'  The [rjags::jags.model()] models seroresponse dynamics to an
#'  infection. The antibody dynamic curve includes the following parameters:
#'  - y0 = baseline antibody concentration
#'  - y1 = peak antibody concentration
#'  - t1 = time to peak
#'  - r = shape parameter
#'  - alpha = decay rate
#' @param data A [base::data.frame()] with the following columns.
#' @param file_mod The name of the file that contains model structure.
#' @param nchain An [integer] between 1 and 4 that specifies
#' the number of mcmc chains to be run per jags model.
#' @param nadapt An [integer] specifying the number of adaptations per chain.
#' @param nburn An [integer] specifying the number of burn ins before sampling.
#' @param nmc An [integer] specifying number of samples in posterior chains
#' @param niter An [integer] specifying number of iterations.
#' @param strat A [character] string specifying the stratification variable,
#' entered in quotes.
#' @param with_post A [logical] value specifying whether a raw `jags.post`
#' component
#' should be included as an element of the [list] object returned by `run_mod()`
#' (see `Value` section below for details).
#' Note: These objects can be large.
#' @param include_subs A [logical] value specifying whether posterior
#' distributions should be included for all subjects. A value of [FALSE] will
#' only include the predictive distribution.
#' @returns A [list] containing the following elements:
#' - `"jags.post"`: a [list] containing one or more [runjags::runjags-class] objects (one per stratum)
#' - A [base::data.frame()] titled `curve_params` that contains the posterior
#' distribution will be exported with the following attributes:
#'   - `iteration` = number of sampling iterations.
#'   - `chain` = number of mcmc chains run; between 1 and 4.
#'   - `indexid` = "newperson", indicating posterior distribution.
#'   - `antigen_iso` = antibody/antigen type combination being evaluated
#'   - `alpha` = posterior estimate of decay rate
#'   - `r` = posterior estimate of shape parameter
#'   - `t1` = posterior estimate of time to peak
#'   - `y0` = posterior estimate of baseline antibody concentration
#'   - `y1` = posterior estimate of peak antibody concentration
#'   - `stratified variable` = the variable that jags was stratified by
#' - A [list] of `attributes` that summarize the jags inputs, including:
#'   - `class`: Class of the output object.
#'   - `nChain`: Number of chains run.
#'   - `nParameters`: The amount of parameters estimated in the model.
#'   - `nIterations`: Number of iteration specified.
#'   - `nBurnin`: Number of burn ins.
#'   - `nThin`: Thinning number (niter/nmc)
#' @export
#' @example inst/examples/run_mod-examples.R
run_mod <- function(data,
                    file_mod,
                    nchain = 4,
                    nadapt = 0,
                    nburn = 0,
                    nmc = 100,
                    niter = 100,
                    strat = NA,
                    with_post = FALSE,
                    include_subs = FALSE) {
  ## Conditionally creating a stratification list to loop through
  if (is.na(strat)) {
    strat_list <- "None"
  } else {
    strat_list <- unique(data[[strat]])
  }

  ## Creating a shell to output results
  jags_out <- data.frame(
    "Iteration" = NA,
    "Chain" = NA,
    "Parameter" = NA,
    "value" = NA,
    "Parameter_sub" = NA,
    "Subject" = NA,
    "Iso_type" = NA,
    "Stratification" = NA
  )

  ## Creating output list for jags.post
  jags_post_final <- list()

  # For loop for running stratifications
  for (i in strat_list) {
    # Creating if else statement for running the loop
    if (is.na(strat)) {
      dl_sub <- data
    } else {
      dl_sub <- data |>
        dplyr::filter(.data[[strat]] == i)
    }

    # prepare data for modeline
    longdata <- prep_data(dl_sub)
    priors <- prep_priors(max_antigens = longdata$n_antigen_isos)

    # inputs for jags model
    nchains <- nchain # nr of MC chains to run simultaneously
    nadapt <- nadapt # nr of iterations for adaptation
    nburnin <- nburn # nr of iterations to use for burn-in
    nmc <- nmc # nr of samples in posterior chains
    niter <- niter # nr of iterations for posterior sample
    nthin <- round(niter / nmc) # thinning needed to produce nmc from niter

    tomonitor <- c("y0", "y1", "t1", "alpha", "shape")

    jags_post <- runjags::run.jags(
      model = file_mod,
      data = c(longdata, priors),
      inits = initsfunction,
      method = "parallel",
      adapt = nadapt,
      burnin = nburnin,
      thin = nthin,
      sample = nmc,
      n.chains = nchains,
      monitor = tomonitor,
      summarise = FALSE
    )
    # Assigning the raw jags output to a list.
    # This object will include a raw output for the jags.post for each
    # stratification and will only be included if specified. 
    jags_post_final[[i]] <- jags_post

    # Unpacking and cleaning mcmc output.
    jags_unpack <- ggmcmc::ggs(jags_post[["mcmc"]])

    # Adding attributes
    mod_atts <- attributes(jags_unpack)
    # Only keeping necesarry attributes
    mod_atts <- mod_atts[3:8]

    # extracting antigen-iso combinations to correctly number
    # then by the order they are estimated by the program.
    iso_dat <- data.frame(attributes(longdata)$antigens)
    iso_dat <- iso_dat |> dplyr::mutate(Subnum = as.numeric(row.names(iso_dat)))
    # Working with jags unpacked ggs outputs to clarify parameter and subject
    jags_unpack <- jags_unpack |>
      dplyr::mutate(
        Subnum = sub(".*,", "", .data$Parameter),
        Parameter_sub = sub("\\[.*", "", .data$Parameter),
        Subject = sub("\\,.*", "", .data$Parameter)
      ) |>
      dplyr::mutate(
        Subnum = as.numeric(sub("\\].*", "", .data$Subnum)),
        Subject = sub(".*\\[", "", .data$Subject)
      )
    # Merging isodat in to ensure we are classifying antigen_iso
    jags_unpack <- dplyr::left_join(jags_unpack, iso_dat, by = "Subnum")
    ids <- data.frame(attr(longdata, "ids")) |>
      mutate(Subject = as.character(dplyr::row_number()))
    jags_unpack <- dplyr::left_join(jags_unpack, ids, by = "Subject")
    jags_final <- jags_unpack |>
      dplyr::select(!c("Subnum", "Subject")) |>
      dplyr::rename(c("Iso_type" = "attributes.longdata..antigens",
                      "Subject" = "attr.longdata...ids.."))
    # Creating a label for the stratification, if there is one.
    # If not, will add in "None".
    jags_final$Stratification <- i
    ## Creating output
    jags_out <- data.frame(rbind(jags_out, jags_final))
  }
  # Ensuring output does not have any NAs
  jags_out <- jags_out[complete.cases(jags_out), ]
  # Outputting the finalized jags output as a data frame with the
  # jags output results for each stratification rbinded.
  # Logical argument to include posterior of all subjects or just the
  # predictive distribution (new person).
  if (!include_subs) {
    jags_out <- jags_out |>
      filter(.data$Subject == "newperson")
  }

  # Logical argument to keep the raw jags post or not.
  if (with_post) {
    jags_out <- list(
      "curve_params" = jags_out,
      "jags.post" = jags_post_final,
      "attributes" = mod_atts
    )
  } else { 
    jags_out <- list(
      "curve_params" = jags_out,
      "attributes" = mod_atts
    )
  }
  jags_out
}
