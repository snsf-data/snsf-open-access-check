CREATE TABLE `OAReportMailing` (
  `OAReportMailingId` int(11) NOT NULL AUTO_INCREMENT,
  `UserMailAddress` varchar(250) NOT NULL,
  `ResearcherDimensionsIds` varchar(500) NOT NULL,
  `ResearcherName` varchar(250) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  `ExaminationYears` varchar(250) NOT NULL,
  `CreateDate` datetime NOT NULL,
  PRIMARY KEY (`OAReportMailingId`),
  UNIQUE KEY `OAReportMailingId_UNIQUE` (`OAReportMailingId`)
) ENGINE=InnoDB AUTO_INCREMENT=50 DEFAULT CHARSET=utf8;
