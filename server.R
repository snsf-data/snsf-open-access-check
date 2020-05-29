# Server component of the SNSF Open Access Check Shiny application

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  # Redirect user to specific tab according to query string parameter
  observe({
    
    # Get the GET query string
    query_string <- getQueryString(session = getDefaultReactiveDomain()) %>%  
      unlist()
    
    # Redirect when valid
    if (length(query_string)) {
      if (query_string == "data-methods")
        updateTabsetPanel(session, "tabset", selected = "Data & Methods")
      else if (query_string == "limitations")
        updateTabsetPanel(session, "tabset", selected = "Limitations")
      else if (query_string == "faq")
        updateTabsetPanel(session, "tabset", selected = "FAQ")
      else if (query_string == "feedback")
        updateTabsetPanel(session, "tabset", selected = "Feedback")
    }
  })
  
  # Create a reactive value to store information about the found researchers
  researchers_proposed <- reactiveVal(value = NULL)
  
  # Initialize async task queue to collect and run OA report generate/send jobs
  report_jobs <- task_q$new()
  
  # Action when a researcher in the checkboxlist was chosen
  observeEvent(input$researcher_checkboxes, 
               # When clearing all CBs, the observe event should still fire
               ignoreNULL = FALSE, {
                 if (length(input$researcher_checkboxes) == 0) {
                   # Hide the report selection controls
                   hide("report_selection")
                 } else {
                   # Show the report selection controls
                   show("report_selection")
                   
                   # Smoothly scroll down to the bottom of the page
                   runjs("window.scrollTo({
                            top: document.body.scrollHeight, behavior: 'smooth'
                          });")
                 }
               })
  
  # Action when the researcher search button is clicked
  observeEvent(input$search_researcher, {
    
    # Hide previously found researchers
    hide("researcher_checkboxes")
    
    # Show researcher loading text
    show("loading_researchers")
    
    # Hide error message if it was visible
    hide("researcher_notfound")
    
    # Hide previously found researchers if they were visible
    hide("researcher_selection")
    
    # Hide download selection if it was visible
    hide("report_selection")
    
    # Hide message for requested report, if already a report was requested
    hide("report_requested")
    
    # Get all Swiss researchers with this name 
    researchers <- get_swiss_researchers(input$researcher_name)
    
    # If researchers were found, display them
    if (nrow(researchers) > 0) {
      
      # Select only needed variables (for being able to bind rows)
      if ("current_research_org" %in% names(researchers)) {
        researchers <- researchers %>%
          mutate(
            ro_name = extract2(current_research_org, "name"),
            ro_country_name = extract2(current_research_org, "country_name")
          )
      } else {
        researchers <- researchers %>%
          mutate(
            ro_name = "",
            ro_country_name = "without current research organization"
          )
      }
      
      # Subset
      researchers <- researchers %>%
        select(last_name,
               first_name,
               total_publications,
               id,
               ro_name,
               ro_country_name)
      
      # At least one researcher was found
      
      # Show the researcher selection controls
      show("researcher_selection")
      
      # Bind together the current research organization as character to display
      current_research_org <-
        paste0(if_else(
          !is.na(researchers$ro_name),
          paste0(
            researchers$ro_name,
            " (",
            researchers$ro_country_name,
            ")"
          ),
          "without current research organization in Dimensions"
        ))
      
      if (length(current_research_org) == 0)
        current_research_org <- ""
      
      # Create result tibble of researchers found 
      researchers <- tibble(first_name = researchers$first_name, 
                            last_name = researchers$last_name,
                            name = paste0(researchers$last_name, ", ", 
                                          researchers$first_name), 
                            current_institution = current_research_org, 
                            id = researchers$id, 
                            tot_pub = researchers$total_publications)
      
      
      # Distinct on certain fields to display this researcher only once, 
      # although he/she may have multiple Dimensions IDs
      researchers_distinct <- researchers %>%
        group_by(last_name, first_name, name, current_institution, tot_pub) %>% 
        summarise(ids = paste(id, collapse = ";")) %>%  
        ungroup()
      
      # Call Dimensions API to get publication count since 2015 for researchers
      researchers_distinct <- researchers_distinct %>%  
        mutate(pub_since_2015 = map_dbl(ids, function(x) 
          get_number_publications(x, 2015)))
      
      
      # Create the named vector for the Shiny input
      user_choices <- researchers_distinct$ids
      names(user_choices) <- paste0(researchers_distinct$name,
                                    " - ",
                                    researchers_distinct$current_institution, 
                                    " - ", 
                                    researchers_distinct$pub_since_2015, 
                                    " publications found (since 2015)")
      
      # Hide researcher loading text
      hide("loading_researchers")
      
      # Update the values of the researcher checkbox list 
      updateCheckboxGroupInput(
        session,
        "researcher_checkboxes",
        choices = user_choices
      )
      
      # Show the researcher checkbox only when its filled
      show("researcher_checkboxes")
      
      # Store the found researcher data as reactive value to be able to 
      # access it later (for the report generation / mailing)
      researchers_proposed(paste(paste(researchers_distinct$first_name,  
                                       researchers_distinct$last_name), 
                                 researchers_distinct$ids, 
                                 sep = ":", collapse = "|"))
      
      # Subset the researchers that do not have any publications since 2015
      without_recent_publications <- researchers_distinct %>% 
        filter(pub_since_2015 == 0)
      
      # If there were any, disable them
      if (nrow(without_recent_publications) > 0) {
        # Wait until the checkbox group has updated, then deactivate researchers
        # with 0 publications since 2015
        delay(0, disable(selector = paste0("input[value='", 
                                           without_recent_publications$ids, 
                                           "'", "]"))) 
      }
      
      # Smoothly scroll down to the bottom of the page
      runjs("window.scrollTo({
                   top: document.body.scrollHeight, behavior: 'smooth'
            });")
    }
    
    else {
      # No researcher was found, show error message
      show("researcher_notfound")
    }
  })
  
  # Action when the feedback send button is clicked
  observeEvent(input$feedback_submit, {
    
    # Mail address validation
    valid_mail <- str_detect(input$feedback_mail, mail_regex)
    
    # Feedback text validation
    feedback_length <- nchar(str_trim(input$feedback_text))
    valid_feedback <- ifelse(feedback_length > 0 & feedback_length <= 6000, 
                             TRUE, FALSE)
    
    # Show/remove mail address error message
    if (!valid_mail) 
      show("feedback_mailaddress_invalid")
    else hide("feedback_mailaddress_invalid")
    
    # Show/remove feedback text error message
    if (!valid_feedback) 
      show("feedback_text_invalid")
    else hide("feedback_text_invalid")
    
    # Continue only when the provided inputs are correctly filled
    req(valid_mail, valid_feedback)
    
    # Save the feedback to the logging database
    if (logging) {
      log_feedback(input$feedback_type, 
                   input$feedback_text, 
                   input$feedback_mail, 
                   mailaddress_feedback)
    }
    
    # Send the feedback as mail to the feedback mail address
    
    # Prepare and send mail message
    blastula::compose_email(
      body = blastula::md(paste0("## Hello! 
A new feedback entry has been registered.  
  
__From__: ", input$feedback_mail, "  
__Type__: ", input$feedback_type, "  

\"", input$feedback_text, "\"")),
      footer = blastula::md("Swiss National Science Foundation")) %>% 
      # Send over SMTP
      blastula::smtp_send(
        from = mailaddress_noreply,
        to = mailaddress_feedback,
        subject = paste0("New OA App Feedback (Type ", input$feedback_type, 
                         ") from ", input$feedback_mail),
        credentials = here("core", "mail_creds")
      )
    
    
    # Hide the feedback input controls
    hide("feedback_area")
    
    # Show message that feedback has been submitted
    show("feedback_submitted")
  })
  
  # Action when the new report button is clicked
  observeEvent(input$new_report, {
    # Show status message for user, hide all user inputs/areas
    show("researcher_textfield")
    hide("report_requested")
  })
  
  # Action on button click (PDF)
  observeEvent(input$request_report, {
    
    # Get the proposed researchers 
    prop_split <- researchers_proposed() %>%  
      str_split("\\|") %>% 
      unlist()
    
    # Convert it to a tibble
    proposed_researchers <- 
      tibble(full_name = str_split(prop_split, ":") %>%  
               map_chr(extract(1)), 
             ids = str_split(prop_split, ":") %>%  
               map_chr(extract(2)))
    
    # Extract the name of the chosen researcher (take first occurrence, when 
    # multiple checkboxes have been checked)
    chosen_researcher_name <- proposed_researchers %>%
      # Select all rows that were selected
      filter(ids %in% input$researcher_checkboxes) %>%  
      # Get the name of the first row
      pull(full_name) %>% 
      first()
    
    # Mail address validation
    valid_mail <- str_detect(input$user_mail, mail_regex)
    
    # Show/remove mail address error message
    if (!valid_mail) 
      show("mailaddress_invalid")
    else hide("mailaddress_invalid")
    
    # Continue only when the provided mail address is correct
    req(valid_mail)
    
    # Show status message for user, hide all user inputs/areas
    hide("researcher_textfield")
    hide("researcher_selection")
    hide("report_selection")
    show("report_requested")
    
    # Generate unique researcher ID for filenames
    researcher_uuid <- UUIDgenerate()
    
    # Push the generating/sending this OA job to the async job queue
    # Explicitly call every package for every function for remote R session
    report_jobs$push(
      function(input,
               output_file,
               parameters,
               envir,
               cred_path, 
               host_location_url, 
               mailaddress_noreply, 
               logging) {
        
        # Load the mailing functions
        source(here::here("core", "logging.R"))
        
        # Try to render the OA report PDF with the provided arguments
        pdf_location <- tryCatch({
          rmarkdown::render(
            input = input,
            output_format = "pdf_document",
            output_file = output_file,
            params = parameters,
            envir = envir,
            quiet = FALSE
          )
        },
        # When there was an error while rendering, log it
        error = function(e) {
          if (logging) {
            log_error(
              error_type = "Rendering Markdown",
              error_message = as.character(e),
              researcher_ids = parameters$researcher_ids,
              researcher_name = parameters$researcher_name,
              examination_years = parameters$examination_years
            )
          }
          
          return(NULL)
        })
        
        # If a PDF was generated without errors, try to send it to the user
        if (!is.null(pdf_location)) {
          # Try to send the mail to the user, log in case of success/failure
          tryCatch({
            # Prepare and send mail message
            blastula::compose_email(
              body = blastula::md(paste0("## Hello! 
Attached to this mail you will find the OA report for ", parameters$researcher_name, ", generated on ", format(lubridate::now(), "%d %B %Y."), 
                                         
                                         "

Please note that this a prototype report and therefore __the data provided may still contain errors__ (see [Limitations](", host_location_url, "?page=limitations)) – you can help us improve by [providing feedback](", host_location_url, "?page=feedback). You may also want to take a look at the [FAQs](", host_location_url, "?page=faq).


 

For more information about OA visit the [SNSF OA website](https://oa100.snf.ch/), to generate more reports please click [here](", host_location_url, ").")),
              footer = blastula::md("Swiss National Science Foundation")) %>%  
              # Add the generated PDF as attachment to the mail
              blastula::add_attachment(
                file = pdf_location,
                filename = paste0("OA-Report ", parameters$researcher_name, 
                                  ".pdf")
              ) %>%
              # Send over SMTP
              blastula::smtp_send(
                from = mailaddress_noreply,
                to = parameters$user_mailaddress,
                subject = paste0("OA-Report for ", parameters$researcher_name),
                credentials = cred_path
              )
            
            # Log this succesful OA report mailing
            if (logging) {
              log_mailing(
                researcher_ids = parameters$researcher_ids,
                researcher_name = parameters$researcher_name,
                examination_years = parameters$examination_years
              )
            }
            
          },
          # When there was an error while sending the mail, log it
          error = function(e) {
            if (logging) {
              log_error(
                error_type = "Sending Mail",
                error_message = as.character(e),
                researcher_ids = parameters$researcher_ids,
                researcher_name = parameters$researcher_name,
                examination_years = parameters$examination_years
              )
            }
            return(NULL)
          })
          
          # Cleanup
          file_stem <-
            magrittr::extract(magrittr::extract2(
              stringr::str_split(pdf_location, "\\."), 1), 1)
          if (file.exists(paste0(file_stem, ".log")))
            file.remove(paste0(file_stem, ".log"))
          if (file.exists(paste0(file_stem, ".tex")))
            file.remove(paste0(file_stem, ".tex"))
          if (file.exists(paste0(file_stem, ".aux")))
            file.remove(paste0(file_stem, ".aux"))
          if (file.exists(paste0(file_stem, ".out")))
            file.remove(paste0(file_stem, ".out"))
          if (file.exists(paste0(file_stem, ".pdf")))
            file.remove(paste0(file_stem, ".pdf"))
        }
      },
      args = list(
        # Arguments for .Rmd rendering...
        input = here("report", "oa_researcher_check_pdf.Rmd"),
        output_file = paste0(researcher_uuid, ".pdf"),
        parameters = list(
          researcher_ids = input$researcher_checkboxes %>%
            unlist() %>%
            paste(collapse = ";"),
          # Examine all years 2015+
          examination_years = seq(2015, year(today()), 1),
          user_mailaddress = input$user_mail,
          researcher_name = chosen_researcher_name
        ),
        envir = new.env(),
        # Arguments for mailing...
        cred_path = here("core", "mail_creds"),
        mailaddress_noreply = mailaddress_noreply,
        host_location_url = host_location_url, 
        logging = logging
      )
    )
    
    # Launch the job in the queue
    report_jobs$pop(timeout = 1)
  })
}
