library(shiny)
options(shiny.maxRequestSize = 30*1024^2)
source("utils.R")

dp <- load_dp()

example <- file.path(tempdir(), "circles.jpg")
file.copy("circles.jpg", example)

cropper.url <- "https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.12/"

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

ui <- fluidPage(
  shinyjs::useShinyjs(),
  tags$head(
    tags$link(href=paste0(cropper.url, "cropper.min.css"), rel="stylesheet"),
    tags$script(src=paste0(cropper.url, "cropper.min.js")),
    tags$link(href="styles.css", rel="stylesheet"),
  ),
  fluidRow(
    column(
      6, br(),
      fileInput(
        "upload", label="Input image:", width="100%",
        accept=c("image/png", "image/jpeg", "image/jpg")),
      shinycssloaders::withSpinner(imageOutput("container_in", height=NULL)),
      div(zoom, move, cbox, style="padding: 20px 0;")
    ),
    column(
      6, br(),
      div(class="inline", numericInput(
        "resolution", "Output resolution:", NULL, width="150px")),
      actionButton("convert", "Convert", icon("play"), class="btn-primary"),
      shinycssloaders::withSpinner(imageOutput("container_out", height=NULL))
    )
  )
)

server <- function(input, output, session) {
  file_example <- reactiveVal(example)

  get_file_in <- function() if (isTruthy(input$upload$datapath))
    input$upload$datapath else req(file_example())

  output$container_in <- renderImage(deleteFile=FALSE, {
    file_in <- get_file_in()
    updateNumericInput(session, "resolution", value=dp$width(file_in))

    shinyjs::runjs("
      if (typeof cropper != 'undefined')
        cropper.destroy();
      Shiny.setInputValue('data', null);
    ")

    shinyjs::delay(0, shinyjs::runjs("
      image = document.getElementById('image');
      cropper = new Cropper(image, {
        aspectRatio: 1,
        viewMode: 1,
        checkOrientation: false,
        autoCropArea: 0.8
      });
    "))

    list(id="image", src=file_in)
  })

  observeEvent(input$convert, {
    shinyjs::runjs("Shiny.setInputValue('data', null);")
    shinyjs::runjs("Shiny.setInputValue('data', cropper.getData());")
  })

  output$container_out <- renderImage(deleteFile=TRUE, {
    data <- req(input$data)
    resolution <- isolate(req(input$resolution))
    resok <- findInterval(resolution, c(100, 5001)) == 1
    validate(need(resok, "Error: resolution must be between 100 and 5000"))

    file_in <- isolate(get_file_in())
    file_ext <- strsplit(basename(file_in), "\\.")[[1]][2]
    file_out <- file.path(dirname(file_in), paste0("out.", file_ext))
    dp$depolarizer(file_in, file_out, data, resolution)

    list(src=file_out)
  })
}

shinyApp(ui, server)
