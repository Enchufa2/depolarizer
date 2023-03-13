library(shiny)
options(shiny.maxRequestSize = 30*1024^2)
source("utils.R")

dp <- load_dp()
example_name <- "circles.jpg"
example_path <- file.path(tempdir(), example_name)
file.copy(example_name, example_path)
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
      tags$script(HTML("
        $(document).on('shiny:inputchanged', function(e) {
          if (e.name == 'upload' || e.name == 'run') {
            $('#download').hide()
          }
        });
        $(document).on('shiny:value', function(e) {
          if (e.name == 'container_out') {
            var im_name = $('#filename').val().split('.')[0];
            var im_type = $('#image').attr('src').split(';')[0].split(':')[1];
            var im_ext = im_type.split('/')[1];
            var im_in = cropper.getCroppedCanvas().toDataURL(im_type);
            $('#download-out').attr('href', e.value.src);
            $('#download-in').attr('href', im_in);
            $('#download-out').attr('download', im_name + '_result.' + im_ext);
            $('#download-in').attr('download', im_name + '_cropped.' + im_ext);
            $('#download').show()
          }
        });
        function zoom(t) {
          var cv = cropper.getCanvasData();
          var z = cv.width * (t=t<0?1/(1-t):1+t) / cv.naturalWidth;
          var cb = cropper.getCropBoxData();
          var c = {x: cb.left + cb.width / 2, y: cb.top + cb.height / 2};
          return cropper.zoomTo(z, c);
        }
        function center() {
          var ct = cropper.getContainerData();
          var cb = cropper.getCropBoxData();
          var c = {x: cb.left + cb.width / 2, y: cb.top + cb.height / 2};
          var m = {x: ct.width / 2 - c.x, y: ct.height / 2 - c.y};
          cropper.setCropBoxData({left: cb.left + m.x, top: cb.top + m.y});
          return cropper.move(m.x, m.y);
        };
      "))
    ),

    fluidRow(
      column(
        6,
        div(
          class="controls",
          fileInput(
            "upload", label="Input image:", width="100%",
            accept=c("image/png", "image/jpeg", "image/jpg")),
          shinyjs::hidden(textInput("filename", NULL, NULL))
        ),
        shinycssloaders::withSpinner(imageOutput("container_in", height=NULL)),
        control_buttons()
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
        shinycssloaders::withSpinner(imageOutput("container_out", height=NULL)),
        download_buttons()
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
  file_example <- reactiveVal(list(name=example_name, datapath=example_path))

  get_file_in <- function() if (isTruthy(input$upload))
    input$upload else req(file_example())

  output$container_in <- renderImage(deleteFile=FALSE, {
    file_in <- get_file_in()$datapath
    updateNumericInput(session, "resolution", value=dp$width(file_in))
    updateTextInput(session, "filename", value=get_file_in()$name)

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
    shinyjs::runjs("
      Shiny.setInputValue('data', null);
      Shiny.setInputValue('data', cropper.getData());
    ")
  })

  output$container_out <- renderImage(deleteFile=TRUE, {
    data <- req(input$data)
    axis <- isolate(req(input$axis))
    resolution <- isolate(req(input$resolution))
    resok <- findInterval(resolution, c(100, 5001)) == 1
    validate(need(resok, "Error: resolution must be between 100 and 5000"))

    file_in <- isolate(get_file_in()$datapath)
    file_ext <- strsplit(basename(file_in), "\\.")[[1]][2]
    file_out <- file.path(dirname(file_in), paste0("out.", file_ext))
    dp$depolarizer(file_in, data)$to_polar(file_out, axis, resolution)

    list(src=file_out)
  })
}

shinyApp(ui, server)
