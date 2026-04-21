CREATE TABLE [efare].[radius_views_efare_patrons]
(
[radius_key] [bigint] NOT NULL IDENTITY(1, 1),
[accountId] [bigint] NOT NULL,
[lat] [decimal] (18, 15) NULL,
[lon] [decimal] (18, 15) NULL,
[radius] [float] NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__radius_vi__recor__504CC5DA] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
