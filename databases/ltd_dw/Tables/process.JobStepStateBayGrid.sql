CREATE TABLE [process].[JobStepStateBayGrid]
(
[Job_Name] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[VariableName] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[VariableValue] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[VariableValDate] [datetime2] NOT NULL CONSTRAINT [DF__JobStepSt__Varia__0E8A213F] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
GRANT SELECT ON  [process].[JobStepStateBayGrid] TO [public]
GO
