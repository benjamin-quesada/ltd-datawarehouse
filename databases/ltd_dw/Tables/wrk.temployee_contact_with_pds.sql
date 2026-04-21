CREATE TABLE [wrk].[temployee_contact_with_pds]
(
[SourceSystem] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[personnelid] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[emp_SID] [int] NULL,
[contact_seq] [smallint] NULL,
[beginDate] [datetime2] NULL,
[contactRelation] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contactName] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phoneNum1] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phoneType1] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phoneNum2] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phoneType2] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phoneNum3] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phoneType3] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phoneNum4] [varchar] (14) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phoneType4] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contactFlags] [smallint] NULL
) ON [PRIMARY]
GO
