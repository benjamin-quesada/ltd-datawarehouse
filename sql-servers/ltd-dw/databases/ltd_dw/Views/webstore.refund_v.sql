SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [webstore].[refund_v]
as


SELECT 
       ID,
       ParentID,
       DateCreated,
       Amount,
       Reason,
       RefundedBy,
       RefundedPayment,
       MetaData,
       EtlProcessActivityID,
       ApiRequestID,
       RecordCreatedDate,
       RecordUpdatedDate 
       FROM staging.webstore.Refund
GO
