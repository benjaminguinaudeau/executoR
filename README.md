
<!-- README.md is generated from README.Rmd. Please edit that file -->

## General Description

Executor orchestrates skript and emulates similar function to rstudio
jobs, which can be executed in any rsession (even if rstudio is not
running)

It entails one R6 class, which has a unique id. When executing a script,
this unique\_id is provided as an environment variable, so that two
different executors can execute the same script at the same time,
without mixing up (you can kill one without killing the other)

To create an instance, you simply need to specify a folder, where all
skript logs will be saved and an executor\_id. If you don’t specify an
id, a random one will be automatically attributed.

``` r
# Random ID
exec_model <- executor$new(folder = "test")
exec_model$ex_id
#> [1] "923096fb"

# Specified id
exec_model <- executor$new(folder = "test", exec_id = "xg15")
exec_model$ex_id
#> [1] "xg15"
```

## Workflow

To execute a task, you need to perform two different actions:

1.  Adding the task to the executor
2.  Starting the task

### Adding tasks

Differntiating these two steps will allow to stop and restart tasks
(eventually, this will be used to implement schedules)

To add a task to an existing executor, you need to specify at least two
arguments:

  - a name: general description of the task, that will be used as an id
    internally
  - a script path: a path to the script that should be executed

You can eventually specify two further arguments

  - wd: the working directory for the script
  - env: environment variables that should be provided to the script.
    This can be used to parametrize scripts.

<!-- end list -->

``` r
## Adding one task
exec_model$add_task(name = "LOL", script = "jobs/test.R", wd = getwd(), env = c("SYMBOL" = "LOL"))
exec_model$add_task(name = "LOL_Schedule", script = "jobs/test.R", wd = getwd(), env = c("SYMBOL" = "LOL_schedule"), infinite_loop = F, period = "2 min")
exec_model$add_task(name = "LOL_Schedule_day", script = "jobs/test.R", wd = getwd(), env = c("SYMBOL" = "LOL_schedule"), infinite_loop = F, period = "day", start = lubridate::as_datetime("2021-02-27 12:50:00", tz = "EST"))
## Adding a serie of task
c("LMFAO", "LOL") %>%
  purrr::walk(~{
    exec_model$add_task(name = .x, script = "jobs/test.R", wd = getwd(), env = c("SYMBOL" = .x))
  })
#> Warning in exec_model$add_task(name = .x, script = "jobs/test.R", wd =
#> getwd(), : Skipping LOL because a task named LOL already exists
```

### Start/Stop tasks

Once a task is added, it can be start/stop. Remember that the name
provided to the task it the internal id, hence it should be unique.

``` r
# Start task
exec_model$start_task(name = "LOL")
# Start all exising tasks
exec_model$start_all()
#> # A tibble: 4 x 5
#>   exec_id name             running infinite_loop period 
#>   <chr>   <chr>            <lgl>   <lgl>         <chr>  
#> 1 xg15    LOL              TRUE    TRUE          ""     
#> 2 xg15    LOL_Schedule     FALSE   FALSE         "2 min"
#> 3 xg15    LOL_Schedule_day FALSE   FALSE         "day"  
#> 4 xg15    LMFAO            FALSE   TRUE          ""
#> ℹ Scheduled: LOL_Schedule
#> ℹ Scheduled: LOL_Schedule_day
#> ℹ Already running: LOL
#> ℹ Starting LMFAO

# Stop task
exec_model$stop_task(name = "LOL")
# Stop all tasks
exec_model$stop_all()
```

If you want to go to sleep and make sure, scripts restart if they break,
you can start a forever loop, that will restart all failed tasks every
`n` seconds.

``` r
sleep <- 60 # in seconds
# exec_model$keep_restarting(sleep = sleep) # forever loop, you'll need to stop this, once this is started
```

An overall log is stored in a log vector

``` r
exec_model$log
#>  [1] "[ 2021-03-01 10:53:57 ] Initializing"                           
#>  [2] "[ 2021-03-01 10:53:57 ] Adding LOL jobs/test.R"                 
#>  [3] "[ 2021-03-01 10:53:57 ] Adding LOL_Schedule jobs/test.R"        
#>  [4] "[ 2021-03-01 10:53:57 ] Adding LOL_Schedule_day jobs/test.R"    
#>  [5] "[ 2021-03-01 10:53:57 ] Adding LMFAO jobs/test.R"               
#>  [6] "[ 2021-03-01 10:53:57 ] Starting LOL jobs/test.R (pid: 92809)"  
#>  [7] "[ 2021-03-01 10:53:58 ] Starting LMFAO jobs/test.R (pid: 92831)"
#>  [8] "[ 2021-03-01 10:53:58 ] Stopping LOL"                           
#>  [9] "[ 2021-03-01 10:53:58 ] Stopping LOL"                           
#> [10] "[ 2021-03-01 10:53:59 ] Stopping LOL_Schedule"                  
#> [11] "[ 2021-03-01 10:53:59 ] Stopping LOL_Schedule_day"              
#> [12] "[ 2021-03-01 10:53:59 ] Stopping LMFAO"
```

## Retrieving information

### Meta information

To know the existing tasks in an executor, you can take a look at
`exec_model$task`

``` r
exec_model$tasks
#> # A tibble: 4 x 11
#>   exec_id name  script wd    stamp               status   pid env  
#>   <chr>   <chr> <chr>  <chr> <dttm>              <chr>  <dbl> <lis>
#> 1 xg15    LOL   jobs/… /bgr… 2021-03-01 10:53:57 stopp… 92809 <chr…
#> 2 xg15    LOL_… jobs/… /bgr… 2021-03-01 10:53:57 stopp…    NA <chr…
#> 3 xg15    LOL_… jobs/… /bgr… 2021-03-01 10:53:57 stopp…    NA <chr…
#> 4 xg15    LMFAO jobs/… /bgr… 2021-03-01 10:53:57 stopp… 92831 <chr…
#> # … with 3 more variables: infinite_loop <lgl>, period <chr>, start <dttm>
```

If you’re interested in which scripts are running, you can use the
following function:

``` r
exec_model$list_running_task()
#> # A tibble: 4 x 5
#>   exec_id name             running infinite_loop period 
#>   <chr>   <chr>            <lgl>   <lgl>         <chr>  
#> 1 xg15    LOL              FALSE   TRUE          ""     
#> 2 xg15    LOL_Schedule     FALSE   FALSE         "2 min"
#> 3 xg15    LOL_Schedule_day FALSE   FALSE         "day"  
#> 4 xg15    LMFAO            FALSE   TRUE          ""
```

``` r
exec_model$list_running_task(next_run = T)
#> # A tibble: 4 x 7
#>   exec_id name  running infinite_loop period start              
#>   <chr>   <chr> <lgl>   <lgl>         <chr>  <dttm>             
#> 1 xg15    LOL   FALSE   TRUE          ""     2021-03-01 10:53:57
#> 2 xg15    LOL_… FALSE   FALSE         "2 mi… 2021-03-01 10:53:57
#> 3 xg15    LOL_… FALSE   FALSE         "day"  2021-02-27 12:50:00
#> 4 xg15    LMFAO FALSE   TRUE          ""     2021-03-01 10:53:57
#> # … with 1 more variable: next_run <dttm>
```

## Individual script information

Each script produces one output, saved in the log\_folder specified when
creating the executor.

If you navigate to `"test"`, you will see that each script has one
output file `LOL.txt`. If the script breaks and is restarted, the
previous output is archived with a timestamp, so that we can know which
error happened. So `LOL_111111111.txt` is the output of a previous run
of the task `LOL`. Using this output, you can communicate with what’s
happening in the process.

``` r
exec_model$read_out(name = "LOL", n_tail = 50) %>% glimpse # Read the last 50 lines of the stream output of the task LOL
#>  chr [1:4] "[1] \"xg15\"" "[1] \"LOL\"" "[1] \"2021-03-01 10:53:58 EST\"" ...
```
