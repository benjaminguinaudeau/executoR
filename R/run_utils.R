
#' @export
shape_output <- function(log){
  log %>%
    paste(collapse = "\n") %>%
    purrr::walk(cat)
}

#' @export
run_script <- function(name, script, wd = getwd(), log = getwd(), env = NULL){
  st <- glue::glue("{log}/{name}.txt")

  if(is.null(env)) env <- c("placeholder" = "")

  # if(file.exists(st_prt)) file.copy(st_prt, stringr::str_replace(st_prt, ".txt$", glue::glue("{round(as.numeric(lubridate::now()))}.txt")))
  # if(file.exists(st_msg)) file.copy(st_msg, stringr::str_replace(st_msg, ".txt$", glue::glue("{round(as.numeric(lubridate::now()))}.txt")))
  if(file.exists(st)) file.copy(st, stringr::str_replace(st, ".txt$", glue::glue("{round(as.numeric(lubridate::now()))}.txt")))


  callr::rscript_process$new(callr::rscript_process_options(script = script,
                                                            wd = wd,
                                                            stdout = st,
                                                            stderr = "2>&1",
                                                            env = env))
}

#' @export
is_running <- function(script, env = NULL){
  nrow(get_proc(cmd_regex = script, args_to_select = env)) > 0
}

#' @export
kill <- function(script, env = NULL, all = T){
  to_kill <- get_proc(script, args_to_select = env)[["pid"]]


  if(length(to_kill) > 0 & !all){
    stop("More than one script running. Set 'all = T' to kill all scripts.")
  }

  to_kill %>%
    purrr::walk(~{system(glue::glue("kill {.x}"))})
}
