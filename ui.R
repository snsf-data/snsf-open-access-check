# User interface component of the SNSF Open Access Check Shiny app

# Define UI for application that draws a histogram
ui <- fluidPage(
  
  # Load Bootstrap CSS and JS
  bootstrapPage(
    
    # Reference custom stylesheet (www/shinytheme.css)
    theme = "shinytheme.css",
    
    # Add SNSF favicon
    tags$head(tags$link(rel = "shortcut icon", href = "favicon.ico")),
    
    # Set up shinyjs
    useShinyjs(),  
    
    # Include JS script to trigger researcher search on return key press
    tags$head(includeScript(here("include", "script", "return-click.js"))),
    
    br(), 
    
    # Logos
    tags$a(
      img(src = "logo/snsf.png", height = 40, width = 160), 
      href = "https://www.snf.ch/en", 
      class = "no-hover", 
      target = "_blank"
    ),
    tags$a(
      img(src = "logo/unpaywall.png", height = 40, width = 160), 
      href = "https://unpaywall.org/", 
      class = "no-hover", 
      target = "_blank"
    ),
    tags$a(
      img(src = "logo/dimensions.png", height = 40, width = 160), 
      href = "https://app.dimensions.ai/", 
      class = "no-hover", 
      target = "_blank"
    ),
    
    hr(),
    
    # App title
    h1("SNSF Open Access Check (Prototype)"),
    
    # Info text in Bootstrap style
    HTML("
    <button class='btn alert-info plusminus-button plusminus-open' type='button' data-toggle='collapse' data-target='.multi-collapse'>-</button>
    <div class='alert alert-info collapse in multi-collapse no-spacing big-box'>
      <div class='simple-spacing'>
        <h3 class='media-heading'>Welcome!</h3>
        <br/>
        <p>
          There is no shortage of explanations, definitions, regulations and guidelines on the topic of open access. For researchers and authors,  finding out how open access works in their field can be a challenge. So can learning how to comply with the rules set by a research funder, such as the SNSF.
        </p>
        <p>
          The aim of this tool is to support you in reflecting on your own publishing practices: what percentage of your scholarly articles is available in an open-access format? Under what conditions? Have those articles been published in an open-access or in a hybrid journal, are they available in a repository? Which currently closed articles could be legally made open access right now?
        </p>
        <p>
          The tool was developed by the SNSF as a prototype. Using data from Dimensions and Unpaywall, this prototype amounts to a first step and is limited for the time being to researchers based in Switzerland. Our goal is to continue developing the tool in cooperation with Dimensions so that it can eventually become part of their openly available services.
        </p>
        <p>
          The workflow is as follows:
          <ul>
            <li>Dimensions is used to procure a list of articles to process (other publication formats are currently not considered, see <a href='", paste0(host_location_url, "?page=limitations"), "'>limitations</a>)</li>
            <li>Unpaywall data is used to gather open access specific metadata of every article on the list</li>
            <li>Results are evaluated according to the SNSF’s definitions of open access</li>
            <li>A report is generated, providing an overview and a complete list of all articles and their individual open-access status</li>
          </ul>
        </p>
        <p>
          <strong>Please bear in mind that the reports may contain errors or suffer from missing data. Have a look at the <a href='", paste0(host_location_url, "?page=limitations"), "'>limitations</a> of the tool and consider providing <a href='", paste0(host_location_url, "?page=feedback"), "'>feedback</a>.</strong>
        </p>
        <p>
          SNSF Open Access Check is only available for researchers at a Swiss research institution.<br/>
          This is an open source tool published under the <a href='https://opensource.org/licenses/MIT' target='_blank'>MIT license</a>, click <a href='https://github.com/snsf-data/snsf-open-access-check' target='_blank'>here</a> to visit the Github page.
        </p>
      </div>
    </div>
    <div class='gray-text collapse multi-collapse no-spacing'>
      <br/>
      <p>
        There is no shortage of explanations, definitions, regulations and guidelines on the topic of open access. For researchers and authors,  finding out how open access works in their field can be a challenge. So can learning how to comply with the rules set by a research funder, such as the SNSF.
      </p>
      <p>
        The aim of this tool is to support you in reflecting on your own publishing practices: what percentage of your scholarly articles is available in an open-access format? Under what conditions? Have those articles been published in an open-access or in a hybrid journal, are they available in a repository? Which currently closed articles could be legally made open access right now?
      </p>
      <p>
          <strong>Please bear in mind that the reports may contain errors or suffer from missing data. Have a look at the <a href='", paste0(host_location_url, "?page=limitations"), "'>limitations</a> of the tool and consider providing <a href='", paste0(host_location_url, "?page=feedback"), "'>feedback</a>.</strong>
      </p>
      <p>
        SNSF Open Access Check is only available for researchers at a Swiss research institution.<br/>
        This is an open source tool published under the <a href='https://opensource.org/licenses/MIT' target='_blank'>MIT license</a>, click <a href='https://github.com/snsf-data/snsf-open-access-check' target='_blank'>here</a> to visit the Github page.
      </p>
    </div>"), 
    
    br(), 
    
    # Add the script to change the button symbol
    tags$script(HTML(
      "$('button').click(function() {
        $(this).attr('class', function(i, old) {
            return old == 'btn alert-info plusminus-button plusminus-open' ? 
            'btn alert-info plusminus-button plusminus-closed' : 
            'btn alert-info plusminus-button plusminus-open';
        });
        
        $(this).text(function(i, old) {
            return old == '+' ? '-' : '+';
        });
    });"
    )),
    
    # Output: Tabset w/ plot, summary, and table ----
    tabsetPanel(type = "tabs",
                id = "tabset", 
                # Tab: The OA Status UI
                tabPanel("OA Status", br(),
                         tags$div(id = "researcher_textfield", 
                                  # Draw grid layout
                                  fluidRow(column(1,
                                                  h1("1.")), 
                                           column(
                                             11,
                                             textInput("researcher_name", label = "Enter researcher name (must be affiliated with a Swiss research institution):", value = ""), 
                                             actionButton("search_researcher", label = "Search researcher", icon = icon("search")), br(), br(), 
                                             hidden(
                                               tags$div(
                                                 id = "researcher_notfound", 
                                                 HTML("<span class='red-text'>No researcher at a Swiss research institution found for the name entered.</span>"),
                                                 br(), br()
                                               )
                                             )
                                           )
                                  )
                         ),
                         hidden(
                           tags$div(id = "researcher_selection", 
                                    fluidRow(column(12,
                                                    hr())), 
                                    fluidRow(
                                      column(1,
                                             h1("2.")), 
                                      column(
                                        11,
                                        br(),
                                        HTML("<div style='margin-bottom:20px;'><strong>Choose correct researcher(s):</strong></div>"),
                                        tags$div(id = "loading_researchers", HTML("<span class='gray-text-italic'>Loading researchers...</span><br/><br/>")),
                                        checkboxGroupInput("researcher_checkboxes", 
                                                           label = NULL, 
                                                           width = "100%"), 
                                        HTML("<div class='gray-text-italic'>The same researcher might be listed several times.</div>"),
                                        br()
                                      )
                                    )
                           )
                         ),
                         hidden(tags$div(id = "report_selection",
                                         fluidRow(
                                           column(12,
                                                  hr(
                                                  ))),
                                         fluidRow(
                                           column(1,
                                                  h1(
                                                    "3."
                                                  )), 
                                           column(11,
                                                  br(),
                                                  # User mail address
                                                  textInput("user_mail", label = "Mail address to send the report to:"),
                                                  hidden(
                                                    tags$div(
                                                      id = "mailaddress_invalid", 
                                                      HTML("<span class='red-text'>Please enter a valid mail address.</span><br/>"),
                                                      br()
                                                    )
                                                  ),
                                                  # Permanent loading screen, showed/hidden when generate PDF clicked
                                                  actionButton("request_report", label = "Request report", icon = icon("file-pdf")), 
                                                  br(),
                                                  br(), 
                                                  HTML("<span class='gray-text-italic'>We do not log your mail address. Creating and sending the report can take up to an hour.</span>") 
                                           )
                                         )
                         )), 
                         hidden(
                           tags$div(id = "report_requested", 
                                    fluidRow(
                                      column(1,
                                             h1("✓")), 
                                      column(
                                        11,
                                        br(),
                                        HTML("<strong>OA report was requested successfully. The report is automatically sent to the specified mail address. This can take up to an hour - thank you for your patience.</strong><br/><br/><strong>If you want to request another report, you are welcome to do so.</strong>"), 
                                        br(),
                                        br(),
                                        actionButton("new_report", label = "Request another report", icon = icon("undo-alt"))
                                      )
                                    ), 
                                    fluidRow(column(12,
                                                    hr()))
                           )
                         ),
                ), 
                # Tab: Data & Methods
                tabPanel("Data & Methods", br(), 
                         includeMarkdown(here("text", "methods.md"))), 
                
                # Tab: Limitations
                tabPanel("Limitations", br(), 
                         includeMarkdown(here("text", "limitations.md"))),
                
                # Tab: FAQs
                tabPanel("FAQs", br(),
                         includeMarkdown(here("text", "faq.md"))), 
                
                # Tab: Feedback
                tabPanel("Feedback", br(),
                         tags$div(id = "feedback_area", 
                                  h2("Feedback"), 
                                  HTML("<p class='gray-text'>Please keep in mind that this service is a prototype. The SNSF does not provide or own any of the data used. Shortcomings in completeness or timeliness of this data are inevitable due to the complex nature of scholarly publishing. If you have any feedback regarding this service itself, please use the form below or write to <a href='mailto:", mailaddress_feedback, "'>", mailaddress_feedback, "</a>.</p><p class='gray-text'>Should your report include articles from other authors, there might be an issue with author disambiguation. The best thing to do is to file a request to correct your profile at <a href='https://app.dimensions.ai/' target='_blank'>Dimensions: Support &rarr; Send Feedback.</a></p>"), br(),
                                  radioButtons("feedback_type", "Feedback type", choices = c("Bugs", "Questions", "Comments"), 
                                               selected = NULL, inline = TRUE, width = "100%"), 
                                  tags$div(class = "full-width", 
                                           textAreaInput("feedback_text", "Your feedback:", height = "220"), 
                                           hidden(
                                             tags$div(
                                               id = "feedback_text_invalid", 
                                               HTML("<span class='red-text'>Please enter a feedback text, max. length is 6'000 characters.</span><br/>"),
                                               br()
                                             )
                                           ),
                                           textInput("feedback_mail", "Your mail address:"), 
                                           hidden(
                                             tags$div(
                                               id = "feedback_mailaddress_invalid",
                                               HTML("<span class='red-text'>Please enter a valid mail address.</span><br/>"),
                                               br()
                                             )
                                           )),
                                  actionButton("feedback_submit", "Submit feedback", icon = icon("envelope")), 
                                  br(), br()
                         ),
                         hidden(
                           tags$div(id = "feedback_submitted",
                                    fluidRow(
                                      column(1,
                                             br(),
                                             h1("✓")),
                                      column(
                                        11,
                                        br(), br(),
                                        HTML("<strong>Thank you for your feedback!</strong>")
                                      )
                                    )
                           )
                         )
                )
    )
  )
)