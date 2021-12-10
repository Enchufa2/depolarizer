load_dp <- function() {
  if (file.exists("depolarizer.R") && Sys.info()[["user"]] != "shiny") {
    source("depolarizer.R", local=(dp <- new.env()))
    return(dp)
  }

  virtualenv <- "depolarizer"
  reticulate::virtualenv_create(virtualenv)
  reticulate::virtualenv_install(virtualenv, "opencv-python")
  reticulate::use_virtualenv(virtualenv, TRUE)
  reticulate::import("depolarizer")
}
