CREATE TABLE [wrk].[identifierTest]
(
[PropertyGUID] [uniqueidentifier] NULL,
[FirstName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MiddleName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastName] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StreetAddress] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[City] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[State] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ZipCode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PhoneNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmployeeID] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateHired] [date] NULL,
[DateFired] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateOfSeniority] [date] NULL,
[Department] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[JobPosition] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SupervisorGUID] [uniqueidentifier] NULL,
[Division] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CellPhoneNumber] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Gender] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
