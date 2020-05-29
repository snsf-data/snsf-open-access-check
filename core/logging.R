# Function to get a MySQL connection to the Logging database on AWS
fetch_connection_mysql <- function() {
  
  # The credentials to be used
  mysql_cred <- readLines(here::here("core", "mysql_credentials.key"))
  
  # Set options for MySQL
  options(
    mysql = list(
      "host" = mysql_cred[1],
      "port" = as.numeric(mysql_cred[2]),
      "user" =  mysql_cred[3],
      "password" = mysql_cred[4]
    )
  )
  
  # Connect to the database
  con <-
    DBI::dbConnect(
      RMySQL::MySQL(),
      dbname = "oa",
      host = options()$mysql$host,
      port = options()$mysql$port,
      user = options()$mysql$user,
      password = options()$mysql$password
    )
}

# Function to create a new mailing log entry
log_mailing <- function(researcher_ids, 
                        researcher_name, 
                        examination_years) {
  
  # Get a MySQL connection
  con <- fetch_connection_mysql()
  
  # Create query to insert new mailing log entry
  query <- sprintf(
    paste0("INSERT INTO OAReportMailing (ResearcherDimensionsIds,", 
    " ResearcherName, ExaminationYears, CreateDate)", 
    " VALUES ('%s', now())"),
    paste(c(researcher_ids, 
            researcher_name, 
            paste(examination_years, collapse = ";")), 
          collapse = "', '")
  )
  
  # Submit the query and close connection
  DBI::dbGetQuery(con, query)
  DBI::dbDisconnect(con)
}

# Function to create a new error log entry
log_error <- function(error_type, 
                      error_message, 
                      researcher_ids, 
                      researcher_name, 
                      examination_years) {
  
  # Get a MySQL connection
  con <- fetch_connection_mysql()
  
  # Create query to insert new mailing log entry
  query <- sprintf(
    paste0("INSERT INTO OAReportError (Type, Message, ResearcherDimensionsIds,",
           " ResearcherName, ExaminationYears,CreateDate)", 
           " VALUES ('%s', now())"),
    paste(c(error_type, 
            error_message,
            researcher_ids, 
            researcher_name, 
            paste(examination_years, collapse = ";")), 
          collapse = "', '")
  )
  
  # Submit the query and close connection
  DBI::dbGetQuery(con, query)
  DBI::dbDisconnect(con)
}

# Function to create a new feedback log entry
log_feedback <- function(feedback_type, 
                         feedback_text, 
                         user_mailaddress, 
                         recipient_mailaddress) {
  
  # Get a MySQL connection
  con <- fetch_connection_mysql()
  
  # Create query to insert new mailing log entry
  query <- sprintf(
    paste0("INSERT INTO OAReportFeedback (Type, Feedback, UserMailAddress,", 
           " RecipientMailaddress, CreateDate)", 
           " VALUES ('%s', now())"),
    paste(c(feedback_type, 
            feedback_text, 
            user_mailaddress, 
            recipient_mailaddress), 
          collapse = "', '")
  )
  
  # Submit the query and close connection
  DBI::dbGetQuery(con, query)
  DBI::dbDisconnect(con)
}

# Select all columns and their contents of a MySQL table
load_data <- function(table_name) {
  
  # Get a MySQL connection
  con <- fetch_connection_mysql()
  
  # Construct the fetching query
  query <- sprintf("SELECT * FROM %s", table_name)
  
  # Submit the query and close connection
  data <- DBI::dbGetQuery(con, query)
  DBI::dbDisconnect(con)
  
  # Return data
  dplyr::as_tibble(data)
}