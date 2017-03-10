#' Verify that a column contains POSIXct dates
#' @description Set a verification step where
#' a table column is expected to consist entirely
#' of POSIXct dates.
#' @return an agent object.
#' @importFrom tibble tibble
#' @importFrom dplyr bind_rows
#' @export col_is_posix

col_is_posix <- function(agent,
                         column,
                         report_count = 0,
                         warn_count = 1,
                         notify_count = 1,
                         tbl_name = NULL,
                         db_type = NULL,
                         creds_file = NULL,
                         initial_sql = NULL) {
  
  assertion_type <- "col_is_posix"
  
  # If "*" is provided for `column`, select all
  # table columns for this verification
  if (column[1] == "*") {
    column <- get_all_cols(agent = agent)
  }
  
  validation_step <-
    create_validation_step(
      agent = agent,
      assertion_type = assertion_type,
      column = column,
      report_count = report_count,
      warn_count = warn_count,
      notify_count = notify_count,
      tbl_name = ifelse(is.null(tbl_name), as.character(NA), tbl_name),
      db_type = ifelse(is.null(db_type), as.character(NA), db_type),
      creds_file = ifelse(is.null(creds_file), as.character(NA), creds_file),
      init_sql = ifelse(is.null(initial_sql), as.character(NA), initial_sql))
  
  # Append `validation_component` to `validation_set`
  agent$validation_set <-
    dplyr::bind_rows(
      agent$validation_set,
      validation_step)
  
  return(agent)
}