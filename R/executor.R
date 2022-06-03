#' @export
executor <- R6::R6Class(
  "executor",
  public = list(
    folder = "",
    task_file = "",
    proc = list(),
    tasks = list(),
    log = list(),
    ex_id = "",
    initialize = function(folder = "/repo/coinrush/packages/executoR/test", exec_id = ""){
      self$folder <- folder
      if(!fs::dir_exists(folder)) fs::dir_create(folder)
      self$task_file <- glue::glue("{folder}/task.rds")
      self$log <- glue::glue("[ {Sys.time()} ] Initializing")
      if(exec_id == "") exec_id <- stringr::str_sub(digest::digest(Sys.time()), 1, 8)
      self$ex_id <- exec_id
      self$tasks <- tibble::tibble(exec_id = self$ex_id, name = NA_character_, script = NA_character_, wd = NA_character_, stamp = NA, status = NA_character_, pid = NA_real_, env = list(list("EXECUTOR_ID" = self$ex_id)),
                                   infinite_loop = T, period = "daily", start = Sys.time())
    },
    add_log = function(msg){

      self$log <- c(self$log, glue::glue("[ {Sys.time()} ] {msg}"))

    },
    add_task = function(name = "", script = "", wd = "", env = c("placeholder" = ""), infinite_loop = T, period = "", start = Sys.time()){

      if(name %in% self$tasks$name){warning(glue::glue("Skipping {name} because a task named {name} already exists")) ; return()}

      env <- c(env, "EXECUTOR_ID" = self$ex_id, "TASK_ID" = paste0(self$ex_id, name)) %>%
        list

      self$tasks <- dplyr::bind_rows(self$tasks, tibble::tibble(exec_id = self$ex_id, name = name, script = script, wd = wd, stamp = Sys.time(), status = "stopped", env = env,
                                                                infinite_loop = infinite_loop, period = period, start = start)) %>%
        dplyr::filter(!is.na(name)) %>%
        dplyr::mutate(task_id = paste0(self$ex_id, name)) %>%
        unique

      self$add_log(glue::glue("Adding {name} {script}"))

    },
    start_task = function(name) {

      if(!name %in% self$tasks$name) stop("Task not found. Did you add it? ")

      to_run <- self$tasks %>%
        dplyr::filter(name == !!name)

      new_task <- run_script(name = name, script = to_run$script, wd = to_run$wd, log = self$folder, env = to_run$env[[1]])
      pid <- new_task$get_pid()
      self$proc <- c(self$proc, new_task)
      self$tasks$status[self$tasks$name == name] <- "started"
      self$tasks$pid[self$tasks$name == name] <- pid
      self$add_log(glue::glue("Starting {name} {to_run$script} (pid: {pid})"))
    },
    stop_task = function(name){

      self$tasks %>%
        dplyr::filter(name == !!name) %>%
        split(1:nrow(.)) %>%
        purrr::walk(~{
          kill(.x$script, env = .x$env[[1]], all = T)
        })
      self$tasks$status[self$tasks$name == name] <- "stopped"
      self$add_log(glue::glue("Stopping {name}"))
    },
    start_all = function(){
      tasks <- self$list_running_task()
      cat(capture.output(tasks), sep = "\n")

      tasks %>%
        dplyr::filter(!infinite_loop) %>%
        dplyr::pull(name) %>%
        purrr::walk(~{
          cli::cli_alert_info("Scheduled: {.x}")
        })

      tasks %>%
        dplyr::filter(infinite_loop) %>%
        dplyr::filter(running) %>%
        dplyr::pull(name) %>%
        purrr::walk(~{
          cli::cli_alert_info("Already running: {.x}")
        })

      tasks %>%
        dplyr::filter(infinite_loop) %>%
        dplyr::filter(!running) %>%
        dplyr::pull(name) %>%
        purrr::walk(~{
          cli::cli_alert_info("Starting {.x}")
          self$start_task(.x)
        })
    },
    stop_all = function(){
      self$tasks$name %>% purrr::walk(~self$stop_task(.x))
    },
    read_out = function(name, n_tail = NULL){
      out <- readr::read_lines(glue::glue("{self$folder}/{name}_{lubridate::today()}.txt"))
      if(!is.null(n_tail)){ out <- out %>% tail(n_tail)}
      return(out)
    },
    list_running_task = function(next_run = F){

      if(!next_run){
        self$tasks %>%
            dplyr::mutate(running = purrr::map2_lgl(script, task_id, ~is_running(cmd_regex = .x, task_id = .y))) %>%
            dplyr::select(exec_id, name, running, infinite_loop, period)
      } else {
        self$tasks %>%
          dplyr::mutate(running = purrr::map2_lgl(script, task_id, ~is_running(cmd_regex = .x, task_id = .y)),
                        next_run = lubridate::as_datetime(purrr::map2_dbl(period, start, ~scheduled_at(period = .x, start = .y, return_next = T)), tz = "EST")) %>%
          dplyr::select(exec_id, name, running, infinite_loop, period, start, next_run)
      }

    },
    restart = function(name){
      to_run <- self$tasks %>%
        dplyr::filter(name == !!name)
      kill(to_run$script)
      self$add_log(glue::glue("Stopping {name} {to_run$script}"))
      self$start_task(name)
      self$add_log(glue::glue("Starting {name} {to_run$script}"))
    },
    keep_restarting = function(sleep = 60){
      while(T){

        cat("\n\n\n") ; cli::cli_alert_info(as.character(Sys.time()))

        tasks <- self$list_running_task(next_run = T)
        # cat(capture.output(select(tasks, -start)), sep = "\n")


        if(any(!tasks$infinite_loop)){
          ## Scheduled
          tasks %>%
            dplyr::filter(!infinite_loop) %>%
            split(1:nrow(.)) %>%
            purrr::walk(~{
              if(scheduled_at(period = .x$period, start = .x$start)){
                cli::cli_alert_info("Starting scheduled {.x$name}")
                self$start_task(.x$name)
              }
            })
        }


        ## Infinite Loop
        tasks %>%
          dplyr::filter(infinite_loop) %>%
          dplyr::filter(!running) %>%
          dplyr::pull(name) %>%
          purrr::walk(~{
            cli::cli_alert_info("Restarting {.x}")
            self$start_task(.x)
          })

        Sys.sleep(sleep)

      }
    }


  )

)
