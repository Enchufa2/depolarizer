tryCatch(
  suppressMessages(invisible(exiftoolr::exif_version())),
  error = function(e) exiftoolr::install_exiftool()
)

orientation <- function(file_i) {
  or_i <- exiftoolr::exif_read(file_i)$Orientation
  deg <- if (is.null(or_i) || or_i < 3) 0
  else if (or_i < 5) 180
  else if (or_i < 7) 90
  else 270
  list(rotate=deg, mirror=isTRUE(or_i %in% c(2, 4, 5, 7)))
}

width <- function(file_i) {
  img_i <- imager::load.image(file_i)
  if (orientation(file_i)$rotate %in% c(90, 270))
    imager::height(img_i)
  else imager::width(img_i)
}

depolarizer <- function(file_i, file_o, crop, res_o=1000, out.color=c(0, 0, 0)) {
  or_i <- orientation(file_i)
  img_i <- imager::load.image(file_i)
  img_i <- imager::imrotate(img_i, or_i$rotate)
  if (or_i$mirror) img_i <- imager::mirror(img_i, "x")

  if (!missing(crop)) img_i <- img_i[
    crop$x + seq_len(crop$width),
    crop$y + seq_len(crop$height),,, drop=FALSE]
  stopifnot(imager::width(img_i) == imager::height(img_i))

  dim_i <- imager::width(img_i)
  res_i <- sqrt(2) * dim_i/2

  pix_o <- expand.grid(x=seq_len(res_o), y=rev(seq_len(res_o)))
  r <- res_i * exp(2*pi*(pix_o$y / res_o - 1))
  angle <- 2*pi * pix_o$x / res_o
  pix_i <- r * data.frame(x=cos(angle), y=sin(angle)) + dim_i/2
  cha_o <- imager::interp(img_i, pix_i)

  if (length(out.color) == 3) {
    outside <- rowSums(sapply(pix_i, findInterval, c(1, dim_i), TRUE) != 1) > 0
    for (i in seq_along(cha_o))
      cha_o[[i]][outside] <- out.color[i]
  }

  img_o <- imager::imfill(res_o, res_o, val=c(0, 0, 0))
  for (i in seq_along(cha_o))
    img_o[,,,i] <- cha_o[[i]]

  if (missing(file_o))
    return(img_o)
  imager::save.image(img_o, file_o)
}

if (sys.nframe() == 0) {
  plot(depolarizer("circles.jpg"))
}
