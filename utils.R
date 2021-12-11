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

control_buttons <- function() {
  zoom <- shinyWidgets::actionGroupButtons(
    paste0("zoom-", c("in", "out")),
    lapply(paste0("search-", c("plus", "minus")), icon),
    status="primary")
  zoom$children[[1]][[1]]$attribs$onclick <- "cropper.zoom(0.1);"
  zoom$children[[1]][[2]]$attribs$onclick <- "cropper.zoom(-0.1);"

  move <- shinyWidgets::actionGroupButtons(
    paste0("move-", c("left", "right", "up", "down")),
    lapply(paste0("arrow-", c("left", "right", "up", "down")), icon),
    status="primary")
  move$children[[1]][[1]]$attribs$onclick <- "cropper.move(-0.2, 0);"
  move$children[[1]][[2]]$attribs$onclick <- "cropper.move(0.2, 0);"
  move$children[[1]][[3]]$attribs$onclick <- "cropper.move(0, -0.2);"
  move$children[[1]][[4]]$attribs$onclick <- "cropper.move(0, 0.2);"

  cbox <- shinyWidgets::actionGroupButtons(
    c("full", "reset"), list("100%", icon("sync")), status="primary")
  cbox$children[[1]][[1]]$attribs$onclick <-
    "cropper.setCropBoxData({left:0, top:0, width:Infinity});"
  cbox$children[[1]][[2]]$attribs$onclick <- "cropper.reset();"

  div(zoom, move, cbox, style="padding: 20px 0;")
}

download_buttons <- function() {
  download_in <- a(
    id="download-in", class="btn btn-primary shiny-download-link",
    icon("download"), "Download crop", href=NULL, download=NULL)
  download_out <- a(
    id="download-out", class="btn btn-primary shiny-download-link",
    icon("download"), "Download result", href=NULL, download=NULL)

  style <- "padding: 20px 0; display: none;"

  div(id="download", download_in, download_out, style=style)
}
