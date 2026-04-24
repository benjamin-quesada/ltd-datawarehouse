SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [fin].[usp_ar_aging_detail]
@docdate date NULL
AS
BEGIN
-- =============================================
-- Author:		Jil Shah
-- Create date: 07292020
-- Description: Export data to Excel from SQL server for Finance team.


-- Example:		exec fin.usp_ar_aging_detail '6/30/2020'
-- =============================================

/*------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;

BEGIN TRY


select r.CUST_NO,
 isnull(rtrim(ltrim(r.FIRST_NAME)),'') + case when len(isnull(rtrim(ltrim(r.FIRST_NAME)),'')) > 0 then ' ' else '' end + isnull(ltrim(rtrim(r.LAST_NAME)),'') as CustomerName
 ,cust_type_code,coalesce(r.CONTACT_NAME, r.Biller_Name,r.care_of) ContactName
, coalesce(r.PHONE, r.biller_phone) ContactPhone, lower(r.EMAIL_ADDRESS) ContactEmail,o.* 
	from (
	select * from (
		SELECT 
			cast(X.TRAN_DOC_NO as varchar(32)) DOC_NO, cast(X.DOC_DATE as date) as InvoiceDate, X.DOC_DESC as MainDescription
			,datediff(Day, DUE_DATE,getdate()) [Days]
			,case when datediff(Day, DUE_DATE,getdate()) < 30 then 'Current'
				  when datediff(Day, DUE_DATE,getdate()) between 30 and 59 then '30-59 Days'
				  when datediff(Day, DUE_DATE,getdate()) between 60 and 89 then '60-89 Days'
				  when datediff(Day, DUE_DATE,getdate()) between 90 and 119 then '90-119 Days'
				  when datediff(Day, DUE_DATE,getdate()) >= 120 then 'Over 120 Days' end aging_bucket
			,sum(X.AMT_OWED) amount_owed 
		FROM [LTD-FINANCE].GoldStandard.dbo.ESXOPENH X WITH (NOLOCK) 
		WHERE X.MODULE_ABBR = 'ar'
		and cast(X.DOC_DATE as date)<=@docdate
		group by cast(X.TRAN_DOC_NO as varchar(32)), X.DOC_DATE,X.DOC_DESC
			,datediff(Day, DUE_DATE,getdate()) 
			,case when datediff(Day, DUE_DATE,getdate()) < 30 then 'Current'
				  when datediff(Day, DUE_DATE,getdate()) between 30 and 59 then '30-59 Days'
				  when datediff(Day, DUE_DATE,getdate()) between 60 and 89 then '60-89 Days'
				  when datediff(Day, DUE_DATE,getdate()) between 90 and 119 then '90-119 Days'
				  when datediff(Day, DUE_DATE,getdate()) >= 120 then 'Over 120 Days' end
			having sum(X.AMT_OWED)>0
			) t
	PIVOT(
		sum(amount_owed) 
		FOR aging_bucket IN ([Current],[30-59 Days],[60-89 Days],[90-119 Days],[Over 120 Days]
			)
	) AS p
) o
inner join (select distinct tran_doc_no, cust_id 
			from [LTD-FINANCE].GoldStandard.dbo.esrtrand WITH (NOLOCK)) d on d.tran_doc_no = o.DOC_NO 
inner join [LTD-FINANCE].GoldStandard.dbo.esrcustr r WITH (NOLOCK) on r.CUST_ID = d.CUST_ID

end try

BEGIN CATCH
 
       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);
 
       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();
 
       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))
 
       SELECT @sub = 'ERROR: ' + @SPROC
 
       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'jil.shah@ltd.org;barb.eichberger@ltd.org' --; (and/or) servicedesk@ltd.org (in the past I’ve had this automated – a notification set of tables/dba data so it’s easier to change than hard coding. Maybe we can do that again someday).
             ,@subject = @sub
             ,@body = @errormsg;
 
       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH



end


GO
