CREATE TABLE `OAReportError` (
  `OAReportErrorId` int(11) NOT NULL AUTO_INCREMENT,
  `Type` varchar(250) NOT NULL,
  `Message` varchar(1000) DEFAULT NULL,
  `UserMailAddress` varchar(250) NOT NULL,
  `ResearcherDimensionsIds` varchar(500) NOT NULL,
  `ResearcherName` varchar(250) NOT NULL,
  `ExaminationYears` varchar(250) NOT NULL,
  `CreateDate` datetime NOT NULL,
  PRIMARY KEY (`OAReportErrorId`),
  UNIQUE KEY `OAReportErrorId_UNIQUE` (`OAReportErrorId`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;
