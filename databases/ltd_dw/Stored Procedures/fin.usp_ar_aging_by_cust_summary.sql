SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Jil Shah
-- Create date: 07292020
-- Description: Export data to Excel from SQL server for Finance team.


-- Example:		exec fin.usp_ar_aging_by_cust_summary '6/30/2020'
-- =============================================


CREATE   PROC [fin].[usp_ar_aging_by_cust_summary]
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

select  isnull(rtrim(ltrim(r.FIRST_NAME)),'') + case when len(isnull(rtrim(ltrim(r.FIRST_NAME)),'')) > 0 then ' ' else '' end + isnull(ltrim(rtrim(r.LAST_NAME)),'') as CustomerName
,o.* ,  sum(case when r.ON_ACCT_AMT = 0 then null else r.on_acct_amt end) ON_ACCT_AMT
	from (
	select * from (
		SELECT 
			cast(c.CUST_NO as varchar(32)) CUST_NO
			,case when datediff(Day, DUE_DATE,getdate()) < 30 then 'Current'
				  when datediff(Day, DUE_DATE,getdate()) between 30 and 59 then '30-59 Days'
				  when datediff(Day, DUE_DATE,getdate()) between 60 and 89 then '60-89 Days'
				  when datediff(Day, DUE_DATE,getdate()) between 90 and 119 then '90-119 Days'
				  when datediff(Day, DUE_DATE,getdate()) >= 120 then 'Over 120 Days' end aging_bucket
			,sum(X.AMT_OWED) amount_owed -- select top 100  *  
		FROM [LTD-FINANCE].GoldStandard.dbo.ESXOPENH X WITH (NOLOCK)
		INNER JOIN (select d.cust_no , d.tran_doc_no
			from [LTD-FINANCE].GoldStandard.dbo.esrtrand d WITH (NOLOCK)
			--where cust_no in ('0836','1234')
				group by doc_no, cust_no,d.tran_doc_no
				--order by 2
				) c on c.tran_doc_no = x.tran_doc_no
		WHERE X.MODULE_ABBR = 'ar' 
		and cast(X.DOC_DATE as date)<=@docdate--Addition Jil Shah
		group by cast(c.CUST_NO as varchar(32)) 
			,case when datediff(Day, DUE_DATE,getdate()) < 30 then 'Current'
				  when datediff(Day, DUE_DATE,getdate()) between 30 and 59 then '30-59 Days'
				  when datediff(Day, DUE_DATE,getdate()) between 60 and 89 then '60-89 Days'
				  when datediff(Day, DUE_DATE,getdate()) between 90 and 119 then '90-119 Days'
				  when datediff(Day, DUE_DATE,getdate()) >= 120 then 'Over 120 Days' end
		) t
			 
	PIVOT(
		sum(amount_owed) 
		FOR aging_bucket IN ([Current],[30-59 Days],[60-89 Days],[90-119 Days],[Over 120 Days]
			)
	) AS p
) o
 join [LTD-FINANCE].GoldStandard.dbo.esrcustr r WITH (NOLOCK) 
 on r.CUST_NO = o.CUST_NO  
group by 
isnull(rtrim(ltrim(r.FIRST_NAME)),'') + case when len(isnull(rtrim(ltrim(r.FIRST_NAME)),'')) > 0 then ' ' else '' end + isnull(ltrim(rtrim(r.LAST_NAME)),'')
,o.CUST_NO,o.[Current], o.[30-59 Days], o.[60-89 Days], o.[90-119 Days], o.[Over 120 Days]


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
