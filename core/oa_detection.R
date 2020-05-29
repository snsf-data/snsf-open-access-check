# Function to query Unpaywall for a set of publications and to classify the 
# publication result into the SNSF OA categories
determine_oa_status <- function(publications, unpaywall_email) {
  
  # DOI vector to provide to Unpaywall
  dois <- publications$doi
  
  # Call the Unpaywall API and catch errors and warnings quietly
  unpay_result <- map(
    # HTML encode DOI for white spaces etc.
    dois %>% map_chr(function(doi) 
      URLencode(doi)),
    # Catch warnings too with safely
    safely(function(dois) {
      oadoi_fetch(dois, email = unpaywall_email)
    })
  ) %>%
    # Map through the Unpaywall list result, pluck the data out of list if OK
    # and save it in tibble format. If not OK, note error and save message
    map_df(function(x) {
      if (!is.null(pluck(x, "result")))
        tibble(unpaywall_status = "OK", message = "") %>% 
        # Add the roadoi result to the return tibble
        bind_cols(pluck(x, "result"))
      else if (!is.null(pluck(x, "warnings")))
        # There were no results (error) and at least one warning, log it
        tibble(unpaywall_status = "ERROR", message = pluck(x, "warnings"))
      else
        # There were no results (error) but no warnings, log this
        tibble(unpaywall_status = "ERROR", message = "no reported warnings")
    }) %>%
    # Overwrite the Unpaywall result list with original DOIs, 
    # as DOIs returning errors are lost otherwise
    mutate(doi = dois) 
  
  # Join the Dimensions publication data with the Unpaywall results
  publications <- publications %>% 
    left_join(unpay_result, by = "doi")
  
  # Extract some variables out of the Unpaywall result to classify publications
  # into the SNSF OA typology
  publications <- publications %>%
    mutate(
      # If it is OA, get host_type
      host_type = ifelse(!is.na(is_oa) & is_oa,
                         best_oa_location %>%
                           # Extract host_type of the best OA location list
                           map(function(x) {
                             x %>%
                               extract2("host_type") 
                           }),
                         ""),
      # If it is OA, get version
      version = ifelse(!is.na(is_oa) & is_oa,
                       best_oa_location %>%
                         # Extract version of the best OA location list
                         map(function(x) {
                           x %>%
                             extract2("version")
                         }),
                       "")
    
    ) %>%
    # Convert these one entry lists to characters
    mutate(
      host_type = as.character(host_type),
      version = as.character(version)
    ) %>%
    # Recode NA cases
    mutate(
      host_type = ifelse(host_type == "", NA, host_type),
      version = ifelse(version == "", NA, version)
    )
  
  # Classify the publications into the SNSF OA statuses
  publications <- publications %>%
    mutate(
      is_oa = ifelse(is.na(is_oa), "unknown", is_oa),
      oa_status = ifelse(is_oa == "unknown", "unknown", "known"),
      oa_status = ifelse(is_oa == FALSE, "closed", oa_status),
      oa_status = ifelse(is_oa == TRUE & host_type == "publisher" & 
                           journal_is_oa == TRUE, "gold", oa_status),
      oa_status = ifelse(is_oa == TRUE & host_type == "publisher" & 
                           journal_is_oa == FALSE, "hybrid", oa_status),
      oa_status = ifelse(is_oa == TRUE & host_type == "repository" & 
                           version %in% c(
                             "publishedVersion",
                             "acceptedVersion",
                             "updatedVersion" # Needed?
                           ), "green", oa_status),
      oa_status = ifelse(is_oa == TRUE & !(oa_status %in% c(
        "gold",
        "hybrid",
        "green"
      )), "other OA", oa_status)
    )
  
  # Recoding special cases according to specific rules defined
  publications <- publications %>%
    mutate(
      oa_status = ifelse(
        (str_detect("book", type) | 
           str_detect("monograph", type)) &  is_oa == TRUE & 
          host_type == "publisher",
        "gold",
        oa_status
      )
    )
  
  return(publications)
}


