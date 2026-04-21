CREATE TABLE [wrk].[ExportEdenFinancialLog]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[runDateTime] [datetime] NOT NULL CONSTRAINT [DF__ExportEde__runDa__430ECD9A] DEFAULT (getdate()),
[runUser] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__ExportEde__runUs__4402F1D3] DEFAULT (suser_sname()),
[sourceModule] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[loPostNo] [int] NOT NULL,
[hiPostNo] [int] NOT NULL,
[errorStatus] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[errorText] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [wrk].[ExportEdenFinancialLog] ADD CONSTRAINT [PK__ExportEd__3214EC27F0B850ED] PRIMARY KEY CLUSTERED ([ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [i1_ModuleDateTime] ON [wrk].[ExportEdenFinancialLog] ([sourceModule], [errorStatus], [runDateTime] DESC) INCLUDE ([loPostNo], [hiPostNo]) ON [PRIMARY]
GO
