CREATE TABLE [wrk].[steppedInserts]
(
[SourceSystem] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[personnelid] [varchar] (12) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[emp_SID] [int] NOT NULL,
[contact_seq] [smallint] NOT NULL,
[beginDate] [datetime2] NULL,
[contactRelation] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[contactName] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[streetAddress] [varchar] (40) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[city] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[state] [varchar] (2) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[zipCode] [varchar] (9) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[phoneNum1] [varchar] (14) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[phoneType1] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[phoneNum2] [varchar] (14) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[phoneType2] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[phoneNum3] [varchar] (14) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[phoneType3] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[phoneNum4] [varchar] (14) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[phoneType4] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[contactFlags] [smallint] NOT NULL
) ON [PRIMARY]
GO
