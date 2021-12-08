depolarizer <- function(img_i, res_o=1000, out.color=c(0, 0, 0)) {
  if (is.character(img_i))
    img_i <- imager::load.image(img_i)
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
  img_o
}

if (sys.nframe() == 0) {
  plot(depolarizer("circles.jpg"))
}
