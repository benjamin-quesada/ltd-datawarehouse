CREATE TABLE [ops].[Operator_Absence]
(
[ops_dailyOperatorAbsence_Key] [int] NOT NULL IDENTITY(1, 1),
[operator] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[badge] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_status_pds] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[current_status] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sup_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sup_initial] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[supervisor] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[absdatebegin] [smalldatetime] NOT NULL,
[abstimebegin] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[absdateend] [smalldatetime] NOT NULL,
[abscode] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[abscode_absence_or_late] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[absencereason] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[opdate] [smalldatetime] NOT NULL,
[formatOpDt] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[abspaycode] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[paidtime] [char] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__Operator___recor__3510BE2A] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[Operator_Absence] ADD CONSTRAINT [PK_Operator_Absence] PRIMARY KEY CLUSTERED ([ops_dailyOperatorAbsence_Key]) ON [PRIMARY]
GO
GRANT SELECT ON  [ops].[Operator_Absence] TO [public]
GO
