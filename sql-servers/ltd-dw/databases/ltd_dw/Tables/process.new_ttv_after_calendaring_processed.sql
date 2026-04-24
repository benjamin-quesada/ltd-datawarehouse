CREATE TABLE [process].[new_ttv_after_calendaring_processed]
(
[new_ttv_key] [int] NOT NULL,
[requestedBid] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[requestedBy] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stepName] [varchar] (42) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[stepDt] [datetime2] NOT NULL,
[stepOutput] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
