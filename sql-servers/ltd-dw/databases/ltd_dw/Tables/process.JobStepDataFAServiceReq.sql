CREATE TABLE [process].[JobStepDataFAServiceReq]
(
[FASR_Key] [bigint] NOT NULL,
[Job_Name] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[veh] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reason] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[busExchanged] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[describeService] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[VariableName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[VariableValue] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[VariableValDate] [datetime2] NOT NULL CONSTRAINT [DF__JobStepDa__Varia__6FAC381D] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
ALTER TABLE [process].[JobStepDataFAServiceReq] ADD CONSTRAINT [PK_JobStepDataFAServiceReq] PRIMARY KEY CLUSTERED ([FASR_Key]) ON [PRIMARY]
GO
GRANT SELECT ON  [process].[JobStepDataFAServiceReq] TO [public]
GO
