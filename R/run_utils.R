
#' @export
shape_output <- function(log){
  log %>%
    paste(collapse = "\n") %>%
    purrr::walk(cat)
}

#' @export
run_script <- function(name, script, wd = getwd(), log = getwd(), env = NULL){
  st <- glue::glue("{log}/{name}_{lubridate::today()}.txt")

  if(is.null(env)) env <- c("placeholder" = "")

  if(file.exists(st)) file.copy(st, stringr::str_replace(st, ".txt$", glue::glue("{round(as.numeric(lubridate::now()))}.txt")))


  callr::rscript_process$new(callr::rscript_process_options(script = script,
                                                            wd = wd,
                                                            stdout = st,
                                                            stderr = "2>&1",
                                                            env = env))
}

#' @export
is_running <- function (script, env = NULL, scr_name = NULL){

  if(!is.null(scr_name)){
    nrow(get_proc(cmd_regex = script, args_to_select = c("SCR_NAME" = scr_name))) > 0
  } else {
    nrow(get_proc(cmd_regex = script, args_to_select = env)) > 0
  }
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
