CREATE TABLE [hastus].[avl_pnm_raw]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[filedate] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ppat_id] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ppat_direction] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ppat_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ppat_public_access] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ppat_owner] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
