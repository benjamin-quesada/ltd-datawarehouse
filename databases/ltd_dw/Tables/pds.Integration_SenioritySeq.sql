CREATE TABLE [pds].[Integration_SenioritySeq]
(
[seniority_id] [int] NOT NULL IDENTITY(1, 1),
[seniority_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[person_id] [int] NULL,
[employee_id] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[field_description] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alpha_value] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_value] [datetime2] NULL,
[integer_value] [int] NULL,
[decimal_value] [decimal] (14, 6) NULL,
[text_value] [varchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__53E25DCE] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [pds].[Integration_SenioritySeq] ADD CONSTRAINT [PK_Integration_SenioritySeq] PRIMARY KEY CLUSTERED ([seniority_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_Integration_SenioritySeq_seniority_status_Includes] ON [pds].[Integration_SenioritySeq] ([seniority_status]) INCLUDE ([person_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_pds_Integration_SenioritySeq_97] ON [pds].[Integration_SenioritySeq] ([seniority_status]) INCLUDE ([person_id], [integer_value]) ON [PRIMARY]
GO
