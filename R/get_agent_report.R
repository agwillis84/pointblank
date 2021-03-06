#' Get a summary report from an agent
#' 
#' @description 
#' We can get an informative summary table from an agent by using the
#' `get_agent_report()` function. The table can be provided in two substantially
#' different forms: as a **gt** based display table (the default), or, as a
#' tibble. The amount of fields with intel is different depending on whether or
#' not the agent performed an interrogation (with the [interrogate()] function).
#' Basically, before [interrogate()] is called, the agent will contain just the
#' validation plan (however many rows it has depends on how many validation
#' functions were supplied a part of that plan). Post-interrogation, information
#' on the passing and failing test units is provided, along with indicators on
#' whether certain failure states were entered (provided they were set through
#' `actions`). The display table variant of the agent report, the default form,
#' will have the following columns:
#' 
#' \itemize{
#' \item i (unlabeled): the validation step number
#' \item STEP: the name of the validation function used for the validation step
#' \item COLUMNS: the names of the target columns used in the validation step
#' (if applicable)
#' \item VALUES: the values used in the validation step, where applicable; this
#' could be as literal values, as column names, an expression, a set of
#' sub-validations (for a [conjointly()] validation step), etc.
#' \item TBL: indicates whether any there were any preconditions to apply
#' before interrogation; if not, a script 'I' stands for 'identity' but, if so,
#' a right-facing arrow appears
#' \item EVAL: a character value that denotes the result of each validation
#' step functions' evaluation during interrogation
#' \item UNITS: the total number of test units for the validation step
#' \item PASS: the number of test units that received a *pass*
#' \item FAIL: the fraction of test units that received a *pass*
#' \item W, S, N: indicators that show whether the `warn`, `stop`, or `notify`
#' states were entered; unset states appear as dashes, states that are set with
#' thresholds appear as unfilled circles when not entered and filled when
#' thresholds are exceeded (colors for W, S, and N are amber, red, and blue)
#' \item EXT: a column that provides buttons with data extracts for each
#' validation step where failed rows are available (as CSV files)
#' }
#' 
#' The small version of the display table (obtained using `size = "small"`)
#' omits the `COLUMNS`, `TBL`, and `EXT` columns. The width of the small table
#' is 575px; the standard table is 875px wide.
#' 
#' If choosing to get a tibble (with `display_table = FALSE`), it will have the
#' following columns:
#' 
#' \itemize{
#' \item i: the validation step number
#' \item type: the name of the validation function used for the validation step
#' \item columns: the names of the target columns used in the validation step
#' (if applicable)
#' \item values: the values used in the validation step, where applicable; for
#' a [conjointly()] validation step, this is a listing of all sub-validations
#' \item precon: indicates whether any there are any preconditions to apply
#' before interrogation and, if so, the number of statements used
#' \item active: a logical value that indicates whether a validation step is
#' set to `"active"` during an interrogation
#' \item eval: a character value that denotes the result of each validation
#' step functions' evaluation during interrogation
#' \item units: the total number of test units for the validation step
#' \item n_pass: the number of test units that received a *pass*
#' \item f_pass: the fraction of test units that received a *pass*
#' \item W, S, N: logical value stating whether the `warn`, `stop`, or `notify`
#' states were entered
#' \item extract: a logical value that indicates whether a data extract is
#' available for the validation step
#' }
#' 
#' @param agent An agent object of class `ptblank_agent`.
#' @param arrange_by A choice to arrange the report table rows by the validation
#'   step number (`"i"`, the default), or, to arrange in descending order by
#'   severity of the failure state (with `"severity"`).
#' @param keep An option to keep `"all"` of the report's table rows (the
#'   default), or, keep only those rows that reflect one or more
#'   `"fail_states"`.
#' @param display_table Should a display table be generated? If `TRUE` (the
#'   default), and if the **gt** package is installed, a display table for the
#'   report will be shown in the Viewer. If `FALSE`, or if **gt** is not
#'   available, then a tibble will be returned.
#' @param size The size of the display table, which can be either `"standard"`
#'   (the default) or `"small"`. This only applies to a display table (where
#'   `display_table = TRUE`).
#' 
#' @return A **gt** table object if `display_table = TRUE` or a tibble if
#'   `display_table = FALSE`.
#' 
#' @examples
#' # Create a simple table with a
#' # column of numerical values
#' tbl <- 
#'   dplyr::tibble(a = c(5, 7, 8, 5))
#' 
#' # Validate that values in column
#' # `a` are always greater than 4
#' agent <-
#'   create_agent(tbl = tbl) %>%
#'   col_vals_gt(vars(a), 4) %>%
#'   interrogate()
#' 
#' # Get a tibble-based report from the
#' # agent by using `get_agent_report()`
#' # with `display_table = FALSE`
#' agent %>%
#'   get_agent_report(display_table = FALSE)
#'   
#' # View a the report by printing the
#' # `agent` object anytime, but, return a
#' # gt table object by using this with
#' # `display_table = TRUE` (the default)
#' report <- get_agent_report(agent)
#' class(report)
#' 
#' # What can you do with the report?
#' # Print it from an R Markdown code,
#' # use it in an email, put it in a
#' # webpage, or further modify it with
#' # the **gt** package
#' 
#' # The agent report as a **gt** display
#' # table comes in two sizes: "standard"
#' # (the default) and "small"
#' small_report <- 
#'   get_agent_report(agent, size = "small")
#' class(small_report)
#' 
#' # The standard report is 875px wide
#' # the small one is 575px wide
#' 
#' @family Post-interrogation
#' @section Function ID:
#' 5-1
#' 
#' @export
get_agent_report <- function(agent,
                             arrange_by = c("i", "severity"),
                             keep = c("all", "fail_states"),
                             display_table = TRUE,
                             size = "standard") {

  arrange_by <- match.arg(arrange_by)
  keep <- match.arg(keep)
  
  validation_set <- agent$validation_set
  
  agent_name <- agent$name
  agent_time <- agent$time
  
  lang <- agent$reporting_lang
  
  eval <- 
    validation_set %>%
    dplyr::select(eval_error, eval_warning) %>%
    dplyr::mutate(condition = dplyr::case_when(
      !eval_error & !eval_warning ~ "OK",
      eval_error & eval_warning ~ "W + E",
      eval_error ~ "ERROR",
      eval_warning ~ "WARNING"
    )) %>%
    dplyr::pull(condition)
  
  columns <- 
    validation_set$column %>%
    vapply(
      FUN.VALUE = character(1),
      USE.NAMES = FALSE,
      FUN = function(x) {
        ifelse(
          is.null(x),
          NA_character_,
          unlist(x)
        )
      }
    )
  
  values <- 
    validation_set$values %>%
    vapply(
      FUN.VALUE = character(1),
      USE.NAMES = FALSE,
      FUN = function(x) {
        ifelse(
          is.null(x),
          NA_character_,
          paste(x %>% gsub("~", "", .), collapse = ", ")
        )
      } 
    )
  
  precon_count <-
    validation_set$preconditions %>%
    vapply(
      FUN.VALUE = character(1),
      USE.NAMES = FALSE,
      FUN = function(x) {
        ifelse(
          is.null(x),
          NA_character_,
          x %>% rlang::as_function() %>% length() %>% as.character()
        )
      }
    )
  
  if (!has_agent_intel(agent)) {
    
    extract_count <- rep(NA, nrow(validation_set))
    
  } else {
    
    extract_count <- as.character(validation_set[["i"]]) %in% names(agent$extracts)
    
    extract_count[extract_count == FALSE] <- NA_integer_
    
    extract_count[!is.na(extract_count)] <- 
      vapply(
        agent$extracts,
        FUN.VALUE = integer(1),
        USE.NAMES = FALSE,
        FUN = nrow
      )
  }

  report_tbl <- 
    dplyr::tibble(
      i = validation_set$i,
      type = validation_set$assertion_type,
      columns = columns,
      values = values,
      precon = precon_count,
      active = validation_set$active,
      eval = eval,
      units = validation_set$n,
      n_pass = validation_set$n_passed,
      f_pass = validation_set$f_passed,
      W = validation_set$warn,
      S = validation_set$stop,
      N = validation_set$notify,
      extract = extract_count
    )
  
  report_tbl <-
    report_tbl %>%
    dplyr::mutate(
      eval_pts = ifelse(eval != "OK", 10, 0),
      N_pts = ifelse(!is.na(N) & N, 3, 0),
      S_pts = ifelse(!is.na(S) & S, 2, 0),
      W_pts = ifelse(!is.na(W) & W, 1, 0),
      total_pts = eval_pts + N_pts + S_pts + W_pts
    )
  
  if (arrange_by == "severity") {
    report_tbl <-
      report_tbl %>%
      dplyr::arrange(dplyr::desc(total_pts))
  }
  
  if (keep == "fail_states") {
    report_tbl <- report_tbl %>% dplyr::filter(total_pts > 0)
  }
  
  report_tbl <-
    report_tbl %>%
    dplyr::select(-dplyr::ends_with("pts"))
  
  
  validation_set <- validation_set[report_tbl$i, ]
  eval <- eval[report_tbl$i]
  
  extracts <- 
    agent$extracts[as.character(base::intersect(as.numeric(names(agent$extracts)), report_tbl$i))]
  
  # nocov start
  
  if (display_table) {

    if (size == "small") {
      scale <- 1.0
      email_table <- TRUE
    } else {
      scale <- 1.0
      email_table <- FALSE
    }
    
    make_button <- function(x, scale, color, background, text = NULL, border_radius = NULL) {
      
      paste0(
        "<button title=\"", text, "\" style=\"background: ", background,
        "; padding: ", 5 * scale, "px ", 5 * scale, "px; ",
        "color: ", color, "; font-size: ", 15 * scale,
        "px; border: none; border-radius: ", border_radius, "\">",
        x, "</button>"
      )
    }
    
    # Reformat `type`
    assertion_type <- validation_set$assertion_type
    type_upd <- 
      seq_along(assertion_type) %>%
      vapply(
        FUN.VALUE = character(1),
        USE.NAMES = FALSE,
        FUN = function(x) {

          title <- gsub("\"", "'", agent$validation_set$brief[[x]])
          
          paste0(
            "<div><p title=\"", title, "\"style=\"margin-top: 0px; margin-bottom: 0px; ",
            "font-family: monospace; white-space: nowrap; ",
            "text-overflow: ellipsis; overflow: hidden;\">",
            assertion_type[x],
            "</p></div>"
          )
        }
      )

    # Reformat `columns`
    columns_upd <- 
      validation_set$column %>%
      vapply(
        FUN.VALUE = character(1),
        USE.NAMES = FALSE,
        FUN = function(x) {

          if (is.null(x) | (is.list(x) && is.na(unlist(x)))) {
            x <- NA_character_
          } else if (is.na(x)) {
            x <- NA_character_
          } else {
            text <- x %>% unlist() %>% strsplit(", ") %>% unlist()
            title <- text
            text <- 
              paste(
                paste0(
                  "<span style=\"color: purple; ",
                  "font-size: bigger;\">&marker;</span>",
                  text
                ),
                collapse = ", "
              )
            x <- 
              paste0(
                "<div><p title=\"", paste(title, collapse = ", "), "\"style=\"margin-top: 0px;margin-bottom: 0px; ",
                "font-family: monospace; white-space: nowrap; ",
                "text-overflow: ellipsis; overflow: hidden;\">",
                text,
                "</p></div>"
              )
          }
          x
        }
      )

    # Reformat `values`
    values_upd <- 
      validation_set$values %>%
      vapply(
        FUN.VALUE = character(1),
        USE.NAMES = FALSE,
        FUN = function(x) {

          if (is.list(x) && length(x) == 2 && all(names(x) %in% c("TRUE", "FALSE")) && !is_formula(x[[1]])) {
            # Case of in-between comparison validation where there are
            # one or two columns specified as bounds
            bounds_incl <- as.logical(names(x))
            
            if (rlang::is_quosure(x[[1]])) {
              x_left <- 
                paste0(
                  "<span style=\"color: purple; font-size: bigger;\">&marker;</span>",
                  rlang::as_label(x[[1]])
                )
            } else {
              x_left <- x[[1]]
            }
            
            if (rlang::is_quosure(x[[2]])) {
              x_right <- 
                paste0(
                  "<span style=\"color: purple; font-size: bigger;\">&marker;</span>",
                  rlang::as_label(x[[2]])
                )
            } else {
              x_right <- x[[2]]
            }
            
            title <- paste0(rlang::as_label(x[[1]]), ", ", rlang::as_label(x[[2]]))
            text <- paste0(x_left, ", ", x_right)

            x <- 
              paste0(
                "<div><p title=\"", title, "\" style=\"margin-top: 0px; margin-bottom: 0px; ",
                "font-family: monospace; white-space: nowrap; ",
                "text-overflow: ellipsis; overflow: hidden;\">",
                text,
                "</p></div>"
              )

          } else if (is.list(x) && length(x) > 0 && inherits(x, "col_schema")) {
            # Case of column schema as a value
            
            column_schema_text <- report_column_schema[lang]
            column_schema_type_text <- 
              if (inherits(x, "r_type")) {
                report_r_col_types[lang]
              } else {
                report_r_sql_types[lang]
              }
            
            x <- 
              paste0(
                "<div>",
                "<p style=\"margin-top: 0px; margin-bottom: 0px; ",
                "font-size: 0.75rem;\">", column_schema_text, "</p>",
                "<p style=\"margin-top: 2px; margin-bottom: 0px; ",
                "font-size: 0.65rem;\">", column_schema_type_text, "</p>",
                "</div>"
              )
            
          } else if (is_call(x)) {
            
            text <- rlang::as_label(x)
            
            x <- 
              paste0(
                "<div><p title=\"", text , "\" style=\"margin-top: 0px; margin-bottom: 0px; ",
                "font-family: monospace; white-space: nowrap; ",
                "text-overflow: ellipsis; overflow: hidden;\">",
                text,
                "</p></div>"
              )
            
          } else if (is.list(x) && length(x) > 0 && !inherits(x, "quosures")) {
            # Conjointly case
            
            step_text <- 
              if (length(x) > 1) {
                paste0(length(x), " ", report_col_steps[lang])
              } else {
                paste0(length(x), " ", report_col_step[lang])
              }
            
            x <- 
              paste0(
                "<div><p style=\"margin-top: 0px; margin-bottom: 0px; ",
                "font-size: 0.75rem;\">", step_text, "</p></div>"
              )
            
          } else if (is.null(x)) {
            
            x <- NA_character_
            
          } else {

            text <-
              x %>%
              tidy_gsub(
                "~",
                "<span style=\"color: purple; font-size: bigger;\">&marker;</span>"
              ) %>%
              unname()
          
            text <- paste(text, collapse = ", ")
            
            x <- 
              paste0(
                "<div><p title=\"", x %>% tidy_gsub("~", "") %>% paste(., collapse = ", "), "\" style=\"margin-top: 0px; margin-bottom: 0px; ",
                "font-family: monospace; white-space: nowrap; ",
                "text-overflow: ellipsis; overflow: hidden;\">",
                text,
                "</p></div>"
              )
          }
          x
        } 
      )

    # Reformat `precon`
    precon_upd <- 
      validation_set$preconditions %>%
      vapply(
        FUN.VALUE = character(1),
        USE.NAMES = FALSE,
        FUN = function(x) {

          if (is.null(x)) {
            x <- 
              make_button(
                x = "&Iscr;",
                scale = scale,
                color = "#333333",
                background = "#EFEFEF",
                text = "No table preconditions applied.",
                border_radius = "4px"
              )
            
          } else if (rlang::is_formula(x) || rlang::is_function(x)) {

            if (rlang::is_formula(x)) {
              text <- rlang::as_label(x) %>% tidy_gsub("^~", "")
            } else {
              text <- rlang::as_label(body(x))
            }
            
            x <- 
              make_button(
                x = "&#10174;",
                scale = scale,
                color = "#FFFFFF",
                background = "#67C2DC",
                text = paste0("Table altered with preconditions: ", gsub("\"", "'", text)),
                border_radius = "4px"
              )
          }
          x
        } 
      )

    # Reformat `eval`
    eval_upd <- 
      seq_along(eval) %>%
      vapply(
        FUN.VALUE = character(1),
        USE.NAMES = FALSE,
        FUN = function(x) {

          if (is.na(eval[x])) {
            
            out <- "&mdash;"
            
          } else if (eval[x] == "OK") {
            
            out <- 
              make_button(
                x = "&check;",
                scale = scale,
                color = "#4CA64C",
                background = "transparent",
                text = "No evaluation issues."
              )
            
          } else if (eval[x] == "W + E") {
            
            text <- agent$validation_set$capture_stack[[x]]$error
            
            if (!is.null(text)) {
              text <- as.character(text)
            } else {
              text <- ""
            }
            
            out <- 
              make_button(
                x = "&#128165;",
                scale = scale,
                color = "#FFFFFF",
                background = "transparent",
                text = text
              )
            
          } else if (eval[x] == "WARNING") {
            
            text <- agent$validation_set$capture_stack[[x]]$warning
            
            if (!is.null(text)) {
              text <- as.character(text)
            } else {
              text <- ""
            }
            
            out <- 
              make_button(
                x = "&#9888;",
                scale = scale,
                color = "#222222",
                background = "transparent",
                text = text
              )
            
          } else if (eval[x] == "ERROR") {
            
            text <- agent$validation_set$capture_stack[[x]]$error
            
            if (!is.null(text)) {
              text <- as.character(text)
            } else {
              text <- ""
            }
            
            out <- 
              make_button(
                x = "&#128165;",
                scale = scale,
                color = "#FFFFFF",
                background = "transparent",
                text = text
              )
          }
          out
        } 
      )

    # Reformat `extract`
    extract_upd <-
      validation_set$i %>%
      vapply(
        FUN.VALUE = character(1),
        USE.NAMES = FALSE,
        FUN = function(x) {

          if (is.null(extracts[as.character(x)][[1]])) {
            x <- "&mdash;"
          } else {

            df <- 
              extracts[as.character(x)][[1]] %>%
              as.data.frame(stringsAsFactors = FALSE)
            
            title_text <- paste0(nrow(df), " failing rows available.")
            
            temp_file <- 
              tempfile(pattern = paste0("csv_file_", x), fileext = ".csv")
            
            utils::write.csv(df, file = temp_file, row.names = FALSE)
            
            on.exit(unlink(temp_file))
            
            file_encoded <- base64enc::base64encode(temp_file)
            
            output_file_name <- 
              paste0(
                agent_name, "_",
                formatC(x, width = 4, format = "d", flag = "0"),
                ".csv"
              ) %>%
              tidy_gsub(":", "_")

            x <- 
              htmltools::a(
                href = paste0(
                  "data:text/csv;base64,", file_encoded
                ),
                download = output_file_name,
                htmltools::tags$button(
                  title = title_text,
                  style = "background-color: #67C2DC; color: #FFFFFF; border: none; padding: 5px; font-weight: bold; cursor: pointer; border-radius: 4px;",
                  "CSV"
                )
              ) %>%
              as.character()
            
          }
          x
        } 
      )

    # Reformat W, S, and N
    W_upd <- 
      validation_set$warn %>%
      vapply(
        FUN.VALUE = character(1),
        USE.NAMES = FALSE,
        FUN = function(x) {
          if (is.na(x)) {
            x <- "&mdash;"
          } else if (x == TRUE) {
            x <- "<span style=\"color: #FFBF00;\">&#9679;</span>"
          } else if (x == FALSE) {
            x <- "<span style=\"color: #FFBF00;\">&cir;</span>"
          }
          x
        }
      )
    
    S_upd <- 
      validation_set$stop %>%
      vapply(
        FUN.VALUE = character(1),
        USE.NAMES = FALSE,
        FUN = function(x) {
          if (is.na(x)) {
            x <- "&mdash;"
          } else if (x == TRUE) {
            x <- "<span style=\"color: #CF142B;\">&#9679;</span>"
          } else if (x == FALSE) {
            x <- "<span style=\"color: #CF142B;\">&cir;</span>"
          }
          x
        }
      )
    
    N_upd <- 
      validation_set$notify %>%
      vapply(
        FUN.VALUE = character(1),
        USE.NAMES = FALSE,
        FUN = function(x) {
          if (is.na(x)) {
            x <- "&mdash;"
          } else if (x == TRUE) {
            x <- "<span style=\"color: #439CFE;\">&#9679;</span>"
          } else if (x == FALSE) {
            x <- "<span style=\"color: #439CFE;\">&cir;</span>"
          }
          x
        }
      )

    f_pass_val <- report_tbl$f_pass
    f_pass_val <- ifelse(f_pass_val > 0 & f_pass_val < 0.01, 0.01, f_pass_val)
    f_pass_val <- ifelse(f_pass_val < 1 & f_pass_val > 0.99, 0.99, f_pass_val)
    f_pass_val <- as.numeric(f_pass_val)
    
    f_fail_val <- 1 - report_tbl$f_pass
    f_fail_val <- ifelse(f_fail_val > 0 & f_fail_val < 0.01, 0.01, f_fail_val)
    f_fail_val <- ifelse(f_fail_val < 1 & f_fail_val > 0.99, 0.99, f_fail_val)
    f_fail_val <- as.numeric(f_fail_val)

    gt_agent_report <- 
      report_tbl %>%
      dplyr::mutate(
        type = type_upd,
        columns = columns_upd,
        values = values_upd,
        precon = precon_upd,
        eval_sym = eval_upd,
        units = units,
        n_pass = n_pass,
        n_fail = units - n_pass,
        f_pass = f_pass_val,
        f_fail = f_fail_val,
        W_val = W,
        S_val = S,
        N_val = N,
        W = W_upd,
        S = S_upd,
        N = N_upd,
        extract = extract_upd
      ) %>%
      dplyr::select(
        i, type, columns, values, precon, eval_sym, units,
        n_pass, f_pass, n_fail, f_fail, W, S, N, extract,
        W_val, S_val, N_val, eval, active
      ) %>%
      gt::gt() %>%
      gt::cols_merge(columns = gt::vars(n_pass, f_pass), hide_columns = gt::vars(f_pass)) %>%
      gt::cols_merge(columns = gt::vars(n_fail, f_fail), hide_columns = gt::vars(f_fail)) %>%
      gt::text_transform(
        locations = gt::cells_body(columns = gt::vars(n_pass, n_fail)),
        fn = function(x) {
          dplyr::case_when(
            x == "NA NA"  ~ "&mdash;",
            TRUE ~ x %>%
              tidy_gsub(" ", "</code><br><code>") %>%
              paste0("<code>", ., "</code>")
          )
        }
      ) %>%
      gt::cols_label(
        i = "",
        type = report_col_step[lang],
        columns = report_col_columns[lang],
        values = report_col_values[lang],
        precon = "TBL",
        eval_sym = "EVAL",
        units = report_col_units[lang],
        n_pass = "PASS",
        n_fail = "FAIL",
        extract = "EXT"
      ) %>%
      gt::tab_header(
        title = pointblank_validation_title_text[lang],
        subtitle = gt::md(paste0("`", agent_name, " (", agent_time, ")`<br><br>"))
      ) %>%
      gt::tab_options(
        table.font.size = gt::pct(90 * scale),
        row.striping.include_table_body = FALSE
      ) %>%
      gt::cols_align(
        align = "center",
        columns = gt::vars(precon, eval_sym, W, S, N, extract)
      ) %>%
      gt::cols_align(
        align = "center",
        columns = gt::vars(f_pass, f_fail)
      ) %>%
      gt::fmt_number(
        columns = gt::vars(units, n_pass, n_fail, f_pass, f_fail),
        decimals = 0, drop_trailing_zeros = TRUE, suffixing = TRUE
      ) %>%
      gt::fmt_number(columns = gt::vars(f_pass, f_fail), decimals = 2) %>%
      gt::fmt_markdown(columns = gt::vars(type, columns, values, precon, eval_sym, W, S, N, extract)) %>%
      gt::fmt_missing(columns = gt::vars(columns, values, units, extract)) %>%
      gt::cols_hide(columns = gt::vars(W_val, S_val, N_val, active, eval)) %>%
      gt::text_transform(
        locations = gt::cells_body(columns = gt::vars(units)),
        fn = function(x) {
          dplyr::case_when(
            x == "&mdash;" ~ x,
            TRUE ~ paste0("<code>", x, "</code>")
          )
        }
      ) %>%
      gt::tab_style(
        style = gt::cell_text(align = "left", indent = gt::px(5)),
        locations = gt::cells_title("title")
      ) %>%
      gt::tab_style(
        style = gt::cell_text(align = "left", indent = gt::px(5)),
        locations = gt::cells_title("subtitle")
      ) %>%
      gt::tab_style(
        style = gt::cell_text(weight = "bold", color = "#666666"),
        locations = gt::cells_body(columns = gt::vars(i))
      ) %>%
      gt::tab_style(
        style = list(
          gt::cell_fill(color = "#F2F2F2", alpha = 0.75),
          gt::cell_text(color = "#8B8B8B")
        ),
        locations = gt::cells_body(
          columns = TRUE,
          rows = active == FALSE
        )
      ) %>%
      gt::tab_style(
        style = gt::cell_fill(color = "#FFC1C1", alpha = 0.35),
        locations = gt::cells_body(
          columns = TRUE,
          rows = eval == "ERROR"
        )
      ) %>%
      gt::tab_style(
        style = gt::cell_borders(
          sides = "left",
          color = "#4CA64C",
          weight = gt::px(7)
        ),
        locations = gt::cells_body(
          columns = gt::vars(i),
          rows = units == n_pass
        )
      ) %>%
      gt::tab_style(
        style = gt::cell_borders(
          sides = "left",
          color = "#4CA64C66",
          weight = gt::px(5)
        ),
        locations = gt::cells_body(
          columns = gt::vars(i),
          rows = units != n_pass
        )
      ) %>%
      gt::tab_style(
        style = gt::cell_borders(
          sides = "left",
          color = "#FFBF00",
          weight = gt::px(7)
        ),
        locations = gt::cells_body(
          columns = gt::vars(i),
          rows = W_val
        )
      ) %>%
      gt::tab_style(
        style = gt::cell_borders(
          sides = "left",
          color = "#CF142B",
          weight = gt::px(7)
        ),
        locations = gt::cells_body(
          columns = gt::vars(i),
          rows = S_val
        )
      ) %>%
      gt::tab_style(
        style = gt::cell_text(size = gt::px(20)),
        locations = gt::cells_title(groups = "title")
      ) %>%
      gt::tab_style(
        style = gt::cell_text(size = gt::px(12)),
        locations = gt::cells_title(groups = "subtitle")
      )
    
    if (!has_agent_intel(agent)) {

      gt_agent_report <-
        gt_agent_report %>%
        gt::text_transform(
          locations = gt::cells_body(
            columns = gt::vars(eval_sym, units, f_pass, f_fail, n_pass, n_fail, W, S, N, extract)
            ),
          fn = function(x) {
            ""
          }
        ) %>%
        gt::tab_style(
          style = gt::cell_fill(color = "#F2F2F2"),
          locations = gt::cells_body(
            columns = gt::vars(eval_sym, units, f_pass, f_fail, n_pass, n_fail, W, S, N, extract)
          )
        ) %>%
        gt::tab_header(
          title = gt::md(
            paste0(
              "<div>",
              "<span style=\"float: left;\">", pointblank_validation_plan_text[lang], "</span>",
              "<span style=\"float: right; text-decoration-line: underline; ",
              "font-size: 16px; text-decoration-color: #008B8B;",
              "padding-top: 0.1em; padding-right: 0.4em;\">",
              no_interrogation_performed_text[lang], "</span>",
              "</div>"
            )
          ),
          subtitle = gt::md(paste0("`", agent_name, "`<br><br>"))
        )
    }
    
    if (email_table) {

      gt_agent_report <- 
        gt_agent_report %>%
        gt::cols_hide(gt::vars(columns, eval_sym, precon, extract)) %>%
        gt::cols_width(
          gt::vars(i) ~ gt::px(30),
          gt::vars(type) ~ gt::px(170),
          gt::vars(values) ~ gt::px(130),
          gt::vars(precon) ~ gt::px(30),
          gt::vars(units) ~ gt::px(50),
          gt::vars(n_pass) ~ gt::px(50),
          gt::vars(n_fail) ~ gt::px(50),
          gt::vars(W) ~ gt::px(30),
          gt::vars(S) ~ gt::px(30),
          gt::vars(N) ~ gt::px(30),
          TRUE ~ gt::px(20)
        ) %>%
        gt::tab_options(data_row.padding = gt::px(4)) %>%
        gt::tab_style(
          style = gt::cell_text(size = gt::px(10), weight = "bold", color = "#666666"),
          locations = gt::cells_column_labels(columns = TRUE)
        )
      
    } else {
      
      gt_agent_report <- 
        gt_agent_report %>%
        gt::cols_width(
          gt::vars(i) ~ gt::px(50),
          gt::vars(type) ~ gt::px(170),
          gt::vars(columns) ~ gt::px(120),
          gt::vars(values) ~ gt::px(120),
          gt::vars(precon) ~ gt::px(35),
          gt::vars(extract) ~ gt::px(65),
          gt::vars(W) ~ gt::px(30),
          gt::vars(S) ~ gt::px(30),
          gt::vars(N) ~ gt::px(30),
          TRUE ~ gt::px(50)
        ) %>%
        gt::tab_style(
          style = gt::cell_text(weight = "bold", color = "#666666"),
          locations = gt::cells_column_labels(columns = TRUE)
        )
    }

    return(gt_agent_report)
  }
  
  # nocov end
  
  report_tbl
}
