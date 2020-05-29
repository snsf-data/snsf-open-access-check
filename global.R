# Loaded before the Shiny components ui.R / server.R are loaded - contains
# package initialization, sourcing of R script components

# Load/install required packages
library(shiny) # Shiny framework
library(tidyverse) # What else?
library(here) # Directory path management
library(roadoi) # Unpaywall querying
library(magrittr) # Additional operators
library(httr) # Dimensions calls
library(jsonlite) # Dimensions calls
library(kableExtra) # Extended kable framework
library(lubridate) # Tidy date processing
library(scales) # Percentage scales in ggplot
library(shinyjs) # JS in Shiny
library(conflicted) # Resolve package conflicts
library(shinycustomloader) # Load animations
library(uuid) # UUID generation
library(callr) # Call separate R instances async
library(blastula) # Send mails
library(RMySQL) # Logging in external MySQL database

# Package conflict preferences
conflict_prefer("here", "here")
conflict_prefer("filter", "dplyr")
conflict_prefer("extract", "magrittr")
conflict_prefer("show", "shinyjs")
conflict_prefer("render", "rmarkdown")

# Set locale to English for date formats
Sys.setlocale(locale = "English")

# Configure the Shiny host location (used in mails)
host_location_url <- "http://www.snsf-oa-check.ch/"

# Set the no-reply mail address (mails are sent from this address)
mailaddress_noreply <- "no-reply@snsf-oa-check.ch"

# Set the no-reply mail address (address to receive feedback)
mailaddress_feedback <- "contact@snsf-oa-check.ch"

# Whether errors and generated reports should be logged 
logging <- FALSE

# Regex to validate mail addresses
mail_regex <- "^([a-zA-Z0-9_\\-\\.]+)@([a-zA-Z0-9_\\-\\.]+)\\.([a-zA-Z]{2,5})$"

# Load scripts for the OA recognition, report generation and Unpaywall querying
source(here("core", "dimensions_functions.R"))
source(here("core", "oa_detection.R"))
source(here("core", "logging.R"))
source(here("core", "report_generation_functions.R"))
source(here("core", "task_queue.R")) # Multi Process Task Queue
