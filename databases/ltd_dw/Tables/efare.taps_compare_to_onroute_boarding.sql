CREATE TABLE [efare].[taps_compare_to_onroute_boarding]
(
[tap_compare_key] [bigint] NOT NULL IDENTITY(1, 1),
[Calendar_ID] [varchar] (56) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Route_ABBR] [varchar] (56) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Stop_ABBR] [varchar] (56) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TM_Boarding] [varchar] (56) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FareTaps] [varchar] (56) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__taps_comp__recor__3B759D38] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [efare].[taps_compare_to_onroute_boarding] ADD CONSTRAINT [PK_taps_compare_to_onroute_boarding] PRIMARY KEY CLUSTERED ([tap_compare_key]) ON [PRIMARY]
GO
