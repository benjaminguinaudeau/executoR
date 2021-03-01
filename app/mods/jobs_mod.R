jobs_ui <- function(id){
  ns <- NS(id)
  tagList(
    div(class = "sixteen wide column",
      br(),
      br(),
      shiny::uiOutput(ns("jobs"))
    )
  )
}


jobs_server <- function(input, output, session){

  jobs <- reactive({
    ex <- executor$new(folder = "/repo/coinrush/packages/executoR/test")
    ex$list_running_task() %>% glimpse
  })


  output$jobs <- renderUI({
    req(jobs())

    div(class="ui styled fluid accordion",
    jobs() %>%
      split(1:nrow(.)) %>%
      purrr::map(~{
        tagList(
         div(class = "title",
            div(class = "ui grid",
                div(class = "trigger ten wide column",
                    HTML('<i class="dropdown icon"></i>'),
                    .x$exec_id
                ),
                div(class = "two wide column",
                    a(class="ui large green circular label", shiny::HTML('<i class="check icon"></i>')),# icon("")),
                    a(class="ui large orange circular label", "."),
                    a(class="ui large red circular label", ".")
                ),
                div(class = "four wide column",
                    action_button(session$ns("stop"), label = "", icon = icon("stop"), class = "ui small basic red button"),
                    action_button(session$ns("restart"), label = "", icon = icon("redo"), class = "ui small basic orange button"),
                    action_button(session$ns("start"), label = "", icon = icon("play"), class = "ui small basic green button")
                )
            )
         ),
         div(class = "content",
            div(class = "ui grid",
                div(class = "eight wide column",
                    shiny::verbatimTextOutput(session$ns(glue::glue("msg_{.x$exec_id}")))
                ),
                div(class = "eight wide column",
                    shiny::verbatimTextOutput(session$ns(glue::glue("prt_{.x$exec_id}")))
                )
            )
         ))
      }),
      #shiny::tags$script("$('.ui.accordion').accordion();"),
      shiny::tags$script(
        "$('.ui.accordion').accordion({ selector: { trigger: '.title .trigger'} });"
      )
    )
  })


  observe({
    req(jobs())
    ex <- executor$new(folder = "/repo/coinrush/packages/executoR/test")
    jobs() %>%
      split(1:nrow(.)) %>%
      walk(~{

        id <- glue::glue("msg_{.x$exec_id}")

        output[[id]] <- shiny::renderPrint({
          ex$read_msg(name = "BTC", n_tail = 50)
        })

        outputOptions(output, id, suspendWhenHidden = F)
      })
  })

  observe({
    req(jobs())
    ex <- executor$new(folder = "/repo/coinrush/packages/executoR/test")
    jobs() %>%
      split(1:nrow(.)) %>%
      walk(~{

        id <- glue::glue("prt_{.x$exec_id}")

        output[[id]] <- shiny::renderPrint({
          ex$read_prt(name = "BTC", n_tail = 50)
        })

        outputOptions(output, id, suspendWhenHidden = F)
      })
  })


}
