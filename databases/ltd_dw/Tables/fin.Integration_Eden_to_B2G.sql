CREATE TABLE [fin].[Integration_Eden_to_B2G]
(
[sent_rec_key] [int] NOT NULL IDENTITY(1, 1),
[BOUNDARYSTART] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AMOUNTPAID] [numeric] (14, 2) NULL,
[DATEPAID] [int] NULL,
[CONTRACTNUMBER] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DATEINVOICED] [int] NULL,
[INVOICENUMBER] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CHECKNUMBER] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PURCHASEORDERNUMBER] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BOUNDARYEND] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[record_created_date] [datetime2] NULL CONSTRAINT [DF__Integrati__recor__2E31B632] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NULL
) ON [PRIMARY]
GO
