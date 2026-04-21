CREATE TABLE [ops].[employeeStatus]
(
[employeeStatusKey] [int] NOT NULL IDENTITY(1, 1),
[emp_SID] [int] NOT NULL,
[dateEffective] [smalldatetime] NOT NULL,
[recType] [char] (1) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[badge] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[division] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[employeePosition] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[employeeClass] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[status] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NOT NULL,
[dateEnd] [smalldatetime] NOT NULL,
[stampDate] [smalldatetime] NULL,
[stampUser] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[dateSeniority] [smalldatetime] NOT NULL,
[lottery] [int] NULL,
[proximity] [char] (1) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[statusFlags] [smallint] NOT NULL,
[craft] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[jobTitle] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[subDivision] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[followUpDate] [smalldatetime] NULL,
[statusDetail] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[comment] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[department] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__employeeS__recor__7D956EED] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ops].[employeeStatus] ADD CONSTRAINT [PK_employeeStatus] PRIMARY KEY CLUSTERED ([employeeStatusKey]) ON [PRIMARY]
GO
