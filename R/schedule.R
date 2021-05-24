#' @export
scheduled_at <- function(stamp = Sys.time(), period = "", start = 0, return_next = F){
  if(period == "") return(NA_real_)
  if(stringr::str_count(period, "\\s") > 1) stop("Two many spaces in the period-string")

  n <- as.numeric(stringr::str_extract(period, "\\d+"))
  if(is.na(n)) n <- 1
  unit <- stringr::str_extract(period, "\\w+$")

  unit <- dplyr::case_when(
    # stringr::str_detect(period, "sec") ~ 1,
    stringr::str_detect(period, "min") ~ 60,
    stringr::str_detect(period, "hour") ~ 60*60,
    stringr::str_detect(period, "day") ~ 24*60*60,
    stringr::str_detect(period, "week") ~ 7*24*60*60,
  )

  modulo <- n*unit
  time_since_last_step <- (abs((as.numeric(stamp) + 60)- as.numeric(start)) %% modulo)
  if(return_next){
    return(Sys.time() + modulo - time_since_last_step)
  } else {
    return(time_since_last_step < 60)
  }
}

