library(shiny)
options(shiny.maxRequestSize = 30*1024^2)
source("utils.R")

dp <- load_dp()
example <- file.path(tempdir(), "circles.jpg")
file.copy("circles.jpg", example)
cropper.url <- "https://cdnjs.cloudflare.com/ajax/libs/cropperjs/1.5.12/"

ui <- navbarPage(
  "Depolarizer",
  theme = bslib::bs_theme(5),
  inverse = TRUE,
  collapsible = TRUE,

  tabPanel(
    "",
    shinyjs::useShinyjs(),
    tags$head(
      tags$link(href=paste0(cropper.url, "cropper.min.css"), rel="stylesheet"),
      tags$script(src=paste0(cropper.url, "cropper.min.js")),
      tags$link(href="styles.css", rel="stylesheet"),
    ),
    fluidRow(
      column(
        6,
        div(
          class="controls",
          fileInput(
            "upload", label="Input image:", width="100%",
            accept=c("image/png", "image/jpeg", "image/jpg"))
        ),
        shinycssloaders::withSpinner(imageOutput("container_in", height=NULL)),
        cropper_buttons()
      ),
      column(
        6,
        div(
          class="controls",
          shiny::tagAppendAttributes(class="d-inline-block", numericInput(
            "axis", "Cut axis (º):", -90, -180, 180, 1,
            width="calc(0.4 * (100% - 115px))")),
          shiny::tagAppendAttributes(class="d-inline-block", numericInput(
            "resolution", "Output resolution (px):", NULL,
            width="calc(0.6 * (100% - 115px))")),
          actionButton(
            "run", "Convert", icon("play"), class="btn-primary", width="105px")
        ),
        shinycssloaders::withSpinner(imageOutput("container_out", height=NULL))
      )
    )
  ),

  bslib::nav_item(a(
    icon("instagram"), "Polar Coordinates",
    href="https://instagram.com/polar_coordinates", target="_blank")),
  bslib::nav_item(a(
    icon("github"), "Source Code",
    href="https://github.com/Enchufa2/depolarizer", target="_blank"))
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

  observeEvent(input$run, {
    shinyjs::runjs("Shiny.setInputValue('data', null);")
    shinyjs::runjs("Shiny.setInputValue('data', cropper.getData());")
  })

  output$container_out <- renderImage(deleteFile=TRUE, {
    data <- req(input$data)
    axis <- isolate(req(input$axis))
    resolution <- isolate(req(input$resolution))
    resok <- findInterval(resolution, c(100, 5001)) == 1
    validate(need(resok, "Error: resolution must be between 100 and 5000"))

    file_in <- isolate(get_file_in())
    file_ext <- strsplit(basename(file_in), "\\.")[[1]][2]
    file_out <- file.path(dirname(file_in), paste0("out.", file_ext))
    dp$depolarizer(file_in, file_out, data, axis, resolution)

    list(src=file_out)
  })
}

shinyApp(ui, server)
