CREATE TABLE [hastus].[avl_tst]
(
[avl_tst_key] [int] NOT NULL IDENTITY(1, 1),
[filedate] [date] NOT NULL,
[rte_version] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rte_identifier] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rte_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trp_number] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trp_int_number] [int] NOT NULL,
[trp_note_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trp_second_note_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trppt_place] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trppt_stop_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trppt_arrival_time] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trppt_tp_note_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trppt_tstp_note_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trppt_is_timing_point] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trppt_place_description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trp_oper_days_12] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__avl_tst__record___16EA5D16] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
