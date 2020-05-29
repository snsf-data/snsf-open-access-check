# SNSF Open Access Check

The application `Researcher Open Access Status` was developed by the SNSF with [R Shiny](https://shiny.rstudio.com/) as a prototype. Using data from Dimensions and Unpaywall, this prototype is limited for the time being to researchers based in Switzerland. It is available [here](http://www.snsf-oa-check.ch/). 

## Local installation

If you want to run the application locally using the code in this repository, you need: 

* An account for the bibliometric service [Dimensions](https://app.dimensions.ai/) that allows API requests. Create a file `dimensions_credentials.key` in `core` that consists of your Dimensions username (first line) and your Dimensions password (second line).
* To configure the mailings correctly (when mails should be sent): 
	* Enter the mail address you want the reports to be sent out from in variable `mailaddress_noreply` in `global.R`. 
	* Create a file containing the credentials and server information of the mail address provided in `mailaddress_noreply` with `blastula::create_smtp_creds_file()`. Save the file as `mail_creds` in the directory `core`.
	* Enter a mail address as variable `mailaddress_feedback` in `global.R`. This is the mail address feedback from the feedback form is sent to.
* If you would want to enable the logging mechanism, set the variable `logging` in `global.R` to `TRUE`, create a MySQL server instance and the three tables `OAReportMailing`, `OAReportError` and `OAReportFeedback` according to the scripts in directory `sql`. Save the server connection information as `mysql_credentials.key` in the directory `core`: 
	* Host and port (1st and 2nd line)
	* Username and password (3rd and 4th line)
	
After these steps, you should be able to run the project in RStudio.
	
## Contact

If you have questions regarding the application code, please contact [julius.mattern@snf.ch](mailto:julius.mattern@snf.ch). For more general questions about the app please use the feedback form in the application user interface.
	
## License

MIT © Swiss National Science Foundation