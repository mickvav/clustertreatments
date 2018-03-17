DROP DATABASE patients;
CREATE DATABASE patients;
USE patients;
CREATE TABLE `Patient` (
  `Id` int(11) not null,
  `Gender` varchar(10),
  `BirthDate` DATE,
  PRIMARY KEY (`Id`) ) ENGINE=InnoDB CHARSET=utf8;

CREATE TABLE `Visit` (
  `VisitID` int(11) not null,
  `PatientID` int(11) not null,
  `Goal` varchar(100),
  `CompletionAttribute` varchar(100),
  `RepeatedAttribute` varchar(100),
  `DiagnosResult` varchar(100),
  `CaseResult` varchar(100),
  `HelpType` varchar(100),
  `BeginDate` DATE,
  `EndDate` DATE,
  PRIMARY KEY (`VisitID`) ) ENGINE=InnoDB CHARSET=utf8;

CREATE TABLE `Diagnos` (
  `DiagnosID` int(11) not null auto_increment,
  `VisitID` int(11) not null,
  `Code` varchar(20),
  `DiseaseType` varchar(200),
  `DiagnosType` varchar(200),
  `TraumaType`  varchar(200),
  `TraumaReasonCode` varchar(200),
  PRIMARY KEY(`DiagnosID`) ) ENGINE=InnoDB CHARSET=utf8;

CREATE TABLE `EhrInspection` (
  `EhrInspectionID` int(11) not null auto_increment,
  `VisitID` int(11) not null,
  `Date` DATE,
  `Place` varchar(20),
  `ComplaintsRTF` TEXT(40000),
  `AnamnesisRTF` text(40000),
  `ObjectiveFindingsRTF` text(40000),
  `TreatmentRTF` text(40000),
  `DiagnosRTF` text(5000),
  PRIMARY KEY(`EhrInspectionID`) ) ENGINE=InnoDB CHARSET=utf8;
