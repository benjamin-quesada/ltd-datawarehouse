CREATE TABLE [hastus].[avl_pnm]
(
[avl_pnm_key] [int] NOT NULL IDENTITY(1, 1),
[filedate] [date] NOT NULL,
[ppat_id] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ppat_direction] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ppat_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ppat_public_access] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ppat_owner] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[excluded] [date] NULL,
[record_created_date] [datetime2] NOT NULL DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
)
GO
