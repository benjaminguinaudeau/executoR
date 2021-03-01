library(shiny)
library(shiny.semantic)
library(semantic.dashboard)
library(apexcharter)
library(tidyverse)
library(DT)

source("mods/jobs_mod.R")

ui <- shinyUI(dashboard_page(
  shiny::div(
    class = "ui top attached inverted menu",
    # img(src = "logos/Logo_White_wide-5.png", style = "width: 120px; height:30px; margin: 5px 5px; padding: 0px 0px;margin-right:1.1cm"),
    shiny::tags$a(id = "toggle_menu", class = "item", shiny::tags$i(class = "sidebar icon"), "Menu"),
    shiny::div(class = "right icon menu", div(class = "ui inverted header", textOutput("time"))
               #manager_ui("manager")
    ),
    shiny::tags$head(
      suppressDependencies("bootstrap"),
      shinyjs::useShinyjs(),
      shinytoastr::useToastr()
      #suppressDependencies("semantic-ui"),
      # tags$link(id="stylesheet", rel="stylesheet", type="text/css", href="./parapipe_styles.css")
    )
  ),
  dashboard_sidebar(
    side = "left",
    size = "tiny",
    inverted = T,
    sidebar_menu(
      menu_item(
        tabName = "tab_jobs",
        text = "Jobs",
        icon = icon("trophy")
      )
    )
  ),
  dashboard_body(
    tab_items(
      tab_item(
        tabName = "tab_targets",
        jobs_ui("jobs")
      )
    )
  )
)
)

# watch_files <- function(path){
#   dir(path, full.names = T) %>%
#     file.info() %>%
#     dplyr::add_rownames("path") %>%
#     dplyr::as_tibble() %>%
#     dplyr::mutate(task = path %>% str_remove(".rds$") %>% str_extract("\\w+$")) %>%
#     dplyr::select(task, size, atime)
# }
#
# timing <- function() stringr::str_extract(as.character(Sys.time()), "\\d\\d.\\d\\d.\\d\\d$")

server <- function(input, output) {

  shiny::callModule(jobs_server, "jobs")
}

shinyApp(ui = ui, server = server)
