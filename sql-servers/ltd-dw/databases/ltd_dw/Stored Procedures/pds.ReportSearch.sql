SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [pds].[ReportSearch] @searchTerms varchar(max)=NULL

as
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



declare @sqlcmd nvarchar(max)

if @searchTerms is null 
BEGIN
select @sqlcmd = '
select [report_id]
      ,[report_status]
      ,[report_name_extracted]
      ,[report_template]
      ,[report_type]
      ,[long_description]
      ,[long_description_text]
      ,[record_created_date] 
FROM pds.[SystemReportList]
'


END

 
if @searchTerms is not null 
BEGIN
select @sqlcmd = '
select [report_id]
      ,[report_status]
      ,[report_name_extracted]
      ,[report_template]
      ,[report_type]
      ,[long_description]
      ,[long_description_text]
      ,[record_created_date] 
FROM pds.[SystemReportList]
WHERE CONTAINS(long_description_text, '''+ @searchTerms + ''')'
END

--print @sqlcmd
exec sp_executesql @sqlcmd
GO
GRANT EXECUTE ON  [pds].[ReportSearch] TO [public]
GO
