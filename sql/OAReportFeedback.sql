CREATE TABLE `OAReportFeedback` (
  `OAReportFeedbackId` int(11) NOT NULL AUTO_INCREMENT,
  `Type` varchar(45) NOT NULL,
  `Feedback` varchar(6000) NOT NULL,
  `UserMailAddress` varchar(250) NOT NULL,
  `RecipientMailAddress` varchar(250) NOT NULL,
  `CreateDate` datetime NOT NULL,
  PRIMARY KEY (`OAReportFeedbackId`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;
