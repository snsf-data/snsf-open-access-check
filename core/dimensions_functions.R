# Functions to query Dimensions (https://app.dimensions.ai/) via
# Dimensions DSL (https://docs.dimensions.ai/dsl/)

# Function to get the Dimensions authentification token
get_dimensions_auth_token <- function() {
  
  # Authentification URL
  auth_url <- "https://app.dimensions.ai/api/auth.json"
  
  # The credentials to be used
  dim_cred <- readLines(here("core", "dimensions_credentials.key"))
  dim_username <- dim_cred[1]
  dim_password <- dim_cred[2]
  
  # Authentificate on Dimensions to get DSL access token
  auth_req <- POST(
    url = auth_url,
    body = list(
      username = URLencode(dim_username),
      password = URLencode(dim_password)
    ),
    encode = "json"
  )
  
  # Parse the authentification request response
  auth_response <- fromJSON(content(auth_req, as = "text", encoding = "UTF-8"))
  
  # Extract and return authentification token
  return(auth_response$token)
}

# Get and store Dimensions token
dim_token <- get_dimensions_auth_token()

# Function to query Dimension API with DSL query
query_dimensions <- function(query) {
  
  # DSL URL
  dsl_url <- "https://app.dimensions.ai/api/dsl.json"
  
  # Create POST request
  dsl_req <- POST(
    url = dsl_url,
    body =  enc2utf8(query),
    add_headers(Authorization = paste("JWT", dim_token))
  )
  
  # Throw error message when the request status code is not 'OK'
  if (dsl_req$status_code != 200) {
    # Convert hex error content to character
    error_message <- rawToChar(dsl_req$content) %>%
      # Extract error message in title tag
      str_extract("(?<=<title>)[A-Za-z0-9 ]*(?=<\\/title>)") 
    
    # Throw error with the message
    stop(paste0("Dimensions API request failed: ", error_message))
  }
  
  # Parse the DSL request response
  dsl_response <- fromJSON(content(dsl_req, as = "text", encoding = "UTF-8"))
  
  # Return successful response
  return(dsl_response)
}

# Function to return a vector of Dimensions researcher IDs formatted for 
# the Dimensions query, which were separated by the character ';' before
split_researcher_ids <- function(researcher_ids) {
  # Take all researcher Dimensions ID
  return(researcher_ids %>%
           str_split(";") %>%
           unlist() %>%
           paste(collapse = "\", \""))
}

# Get publications since a specific year of the chosen researcher from
# Dimensions
get_researcher_publications <- function(researcher_ids, years_to_examine = NULL, 
                                        limit = 1000) {
  publications <- query_dimensions(
    paste0(
      "search publications ",
      " where researchers.id in [\"",
      paste(split_researcher_ids(researcher_ids), collapse = "\", \""),
      "\"]",
      if_else(!is.null(years_to_examine),
              paste0(
                " and year in [",
                paste(years_to_examine, collapse = ", "),
                "]",
                ""
              ), ""),
      " return publications [id + type + doi + date + title + journal]",
      " limit ", limit
    )
  )
  
  if (length(publications$publications) > 0) {
    return(as_tibble(publications$publications))
  }
  
  return(tibble())
}

# Function to get number of publications of a researcher since a given year
get_number_publications <- function(researcher_id, since_year) {
  
  limit <- 1000
  publications <- query_dimensions(
    paste0(
      "search publications ",
      " where researchers.id = \"", researcher_id, "\"",
      if_else(!is.null(since_year), paste0(" and year >= ", since_year), ""),
      " return publications [id]",
      " limit ", limit
    )
  )
  
  if (length(publications$publications) > 0) {
    return(nrow(publications$publications))
  }
  
  return(0)
}

# Get the Dimensions IDs from active researchers in the Dimensions 
# "Researcher Source" 
# and at least one publication 
# (https://docs.dimensions.ai/dsl/language.html#using-researchers-source)
get_researchers <- function(researcher_name) {
  
  researchers <- query_dimensions(
    paste0(
      "search researchers for ",
      "\"\\\"",
      str_trim(researcher_name),
      "\\\"\" where obsolete != 1 and total_publications > 0",
      # Add filter: Current or past research organization in Switzerland
      # " and research_orgs.country_name = \"Switzerland\"",
      " return researchers [all]"
    )
  )
  
  if (length(researchers$researchers) > 0) {
    # Extract researchers as tibble
    researchers <- as_tibble(researchers$researchers)
    
    # Update 2021-10-07: Removal of filter to current/past Swiss researchers
    # # Remove entries with no connection to Switzerland (current or past)
    # # This has to be done here and not in the query, as Dimensions discourages
    # # the use of entity filters (like research_orgs.country_name), as they can 
    # # lead to incomplete results
    # researchers <- researchers %>% 
    #   mutate(past_swiss = map_lgl(research_orgs, function(x) {
    #     if (is.null(x))
    #       return(FALSE)
    #     x <- x %>% 
    #       select(country_name) %>% 
    #       pull()
    #     if ("Switzerland" %in% x)
    #       return(TRUE)
    #     return(FALSE)
    #   }), 
    #   present_swiss = current_research_org$country_name == "Switzerland") %>%  
    #   # Only keep the researchers with past or present CH research organization
    #   filter(present_swiss | past_swiss)
    
    if (nrow(researchers) == 0)
      return(tibble())
    
    return(researchers)
  }
  return(tibble())
}
