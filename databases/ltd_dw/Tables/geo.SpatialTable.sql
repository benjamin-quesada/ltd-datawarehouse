CREATE TABLE [geo].[SpatialTable]
(
[geogKey] [int] NOT NULL IDENTITY(1, 1),
[geogName] [varchar] (90) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[geogCol1] [sys].[geography] NULL,
[geogCol2] AS ([GeogCol1].[STAsText]())
) ON [PRIMARY]
GO
