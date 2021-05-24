#' @export
get_proc <- function(cmd_regex = ".", args_to_select = NULL){

  raw_list <- system("ps -aeufx", intern = T) %>%
    tail(-1)

  user <- raw_list %>%
    stringr::str_extract("\\w+")

  pid <- raw_list %>%
    stringr::str_extract("\\d+")

  numbers <- raw_list %>%
    stringr::str_extract_all("\\d+((\\.|\\:)\\d+)?")

  cpu <- numbers %>% purrr::map_chr(2)
  mem <- numbers %>% purrr::map_chr(3)
  vsz <- numbers %>% purrr::map_chr(4)
  rss <- numbers %>% purrr::map_chr(5)

  start_time <- raw_list %>%
    stringr::str_extract("(\\d{1,2}\\:\\d{1,2})|(\\s+\\w+\\d+\\s+)(?=\\d{1,2}\\:\\d{1,2})") %>%
    stringr::str_trim()

  time <- raw_list %>%
    stringr::str_extract("\\d+\\:\\d+\\s+(?=(\\[|\\\\_|\\/|\\||\\w))") %>%
    stringr::str_trim()

  cmd <- raw_list %>%
    stringr::str_extract("(?<=\\d\\:\\d{1,2})\\s+.*?$") %>%
    stringr::str_remove("\\d\\:\\d{1,2}") %>%
    stringr::str_trim()

  out <- tibble::tibble(user, pid, cpu, mem, vsz, rss, start_time, time, cmd) %>%
    dplyr::filter(stringr::str_detect(cmd, !!cmd_regex))

  if(nrow(out) == 0) return(out)

  out$args <- out$cmd %>%
    stringr::str_split("\\s") %>% #bashR::simule_map(1)
    purrr::map(~{
      if(all(!stringr::str_detect(.x, "\\="))) return(tibble::tibble())
      .x %>%
        stringr::str_subset("\\=") %>%
        stringr::str_split("\\=") %>% #bashR::simule_map(1)
        purrr::map(~{
          tibble::tibble(!!.x[1] := .x[2])
        }) %>%
        purrr::reduce(dplyr::bind_cols, .name_repair = c("minimal")) %>%
        janitor::clean_names()
    })

  if(!is.null(args_to_select) & nrow(out) > 0){
    to_keep <- args_to_select %>%
      purrr::imap(~{
        which(purrr::map(out$args, janitor::make_clean_names(.y)) == .x)
      }) %>%
      purrr::reduce(intersect)

    if(length(to_keep) == 0) return(tibble::tibble())
    out <- out[to_keep,]

  }

  return(out)
}
