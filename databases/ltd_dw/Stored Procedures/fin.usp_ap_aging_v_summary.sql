SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jil Shah
-- Create date: 07292020
-- Description: Export data to Excel from SQL server for Finance team.


-- Example:		exec fin.usp_ap_aging_v_summary '6/30/2020'

-- =============================================


CREATE   PROC [fin].[usp_ap_aging_v_summary]

@docdate date NULL
AS
BEGIN
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

;
WITH owepayto as (select vendor_id,sum(ev.INV_AMT ) amtOwed 
	FROM [LTD-FINANCE].GoldStandard.dbo.ESAOTINV ev WITH (NOLOCK)
	INNER JOIN [LTD-FINANCE].GoldStandard.dbo.ESXACCTR x WITH (NOLOCK) ON ev.ACCT_ID = x.ACCT_ID
			AND ev.FISCAL_YEAR = x.ACCT_YEAR
			AND ev.ACCT_TYPE = x.ACCT_TYPE
			group by vendor_id
			having sum(ev.INV_AMT) > 0)

select * from (

SELECT isnull(rtrim(ltrim(v.FIRST_NAME)),'') + case when len(isnull(rtrim(ltrim(v.FIRST_NAME)),'')) > 0 then ' ' else '' end + isnull(rtrim(ltrim(v.LAST_NAME)),'') VendorName
		,v.VEND_CODE
	,sum(ev.INV_AMT ) as amount_owed
	,case		  when datediff(Day, ev.due_date,getdate() )  > 89  then 'Overdue 90+ Days'
	     		  when datediff(Day, ev.due_date,getdate() ) between 50 and 89  then 'Overdue 50-89 Days'
	     		  when datediff(Day, ev.due_date,getdate() ) between 15 and 49  then 'Overdue 15-49 Days'
	     		  when datediff(Day, ev.due_date,getdate() ) between 0 and 14  then 'Overdue 0-14 Days'
				  when datediff(Day, ev.due_date,getdate() )between 0 and -14  then 'Current'
				  when datediff(Day, ev.due_date,getdate()) between -16 and -49 then 'Due in 16-49 Days'
				  when datediff(Day, ev.due_date,getdate()) between -50 and -89 then 'Due in 50-89 Days'
				  when datediff(Day, ev.due_date,getdate()) between -90 and -119 then 'Due in 90-119 Days'
				  when datediff(Day, ev.due_date,getdate()) <= -120 then 'Due in 120+ Days' end  aging_bucket

FROM [LTD-FINANCE].GoldStandard.dbo.ESAOTINV ev WITH (NOLOCK) 
INNER JOIN owepayto o on o.vendor_id = ev.Vendor_id
	INNER JOIN [LTD-FINANCE].GoldStandard.dbo.ESXACCTR x WITH (NOLOCK) ON ev.ACCT_ID = x.ACCT_ID
			AND ev.FISCAL_YEAR = x.ACCT_YEAR
			AND ev.ACCT_TYPE = x.ACCT_TYPE
	INNER JOIN 	[LTD-FINANCE].GoldStandard.dbo.ESAVENDR v WITH (NOLOCK) ON ev.VENDOR_ID = v.VENDOR_ID
WHERE (ev.DOC_DATE <=@docdate
and ev.CHK_DATE > @docdate)
 or ev.[STATUS]='A' 
 group by
 isnull(rtrim(ltrim(v.FIRST_NAME)),'') + case when len(isnull(rtrim(ltrim(v.FIRST_NAME)),'')) > 0 then ' ' else '' end + isnull(rtrim(ltrim(v.LAST_NAME)),'') 
	,v.VEND_CODE
	,case		  when datediff(Day, ev.due_date,getdate() )  > 89  then 'Overdue 90+ Days'
	     		  when datediff(Day, ev.due_date,getdate() ) between 50 and 89  then 'Overdue 50-89 Days'
	     		  when datediff(Day, ev.due_date,getdate() ) between 15 and 49  then 'Overdue 15-49 Days'
	     		  when datediff(Day, ev.due_date,getdate() ) between 0 and 14  then 'Overdue 0-14 Days'
				  when datediff(Day, ev.due_date,getdate() )between 0 and -14  then 'Current'
				  when datediff(Day, ev.due_date,getdate()) between -16 and -49 then 'Due in 16-49 Days'
				  when datediff(Day, ev.due_date,getdate()) between -50 and -89 then 'Due in 50-89 Days'
				  when datediff(Day, ev.due_date,getdate()) between -90 and -119 then 'Due in 90-119 Days'
				  when datediff(Day, ev.due_date,getdate()) <= -120 then 'Due in 120+ Days' end 
having SUM(ev.INV_AMT )>0
) t
	PIVOT(
		sum(amount_owed) 
		FOR aging_bucket IN (
		[Overdue 90+ Days],
	     		 [Overdue 50-89 Days],
	     		 [Overdue 15-49 Days],
	     		 [Overdue 0-14 Days],
				 [Current],
				 [Due In 16-49 Days],
				 [Due In 50-89 Days],
				 [Due In 90-119 Days],
				 [Due In 120+ Days]
			)
	) AS p

		
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
