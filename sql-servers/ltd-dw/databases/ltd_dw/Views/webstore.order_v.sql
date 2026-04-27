SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [webstore].[order_v]
as

SELECT ID,
       Status,
       DateCreated,
       DateModified,
       ShippingTotal,
       Total,
       CustomerID,
       PaymentMethodTitle,
       TransactionID,
       CreatedVia,
       CustomerNote,
       DateCompleted,
       DatePaid,
       Number,
       LineItems,
       ShippingLines,
       Refunds,
       NeedsPayment,
       NeedsProcessing,
       EtlProcessActivityID,
       ApiRequestID,
       RecordCreatedDate,
       RecordUpdatedDate   
       FROM staging.webstore.[order]
GO
