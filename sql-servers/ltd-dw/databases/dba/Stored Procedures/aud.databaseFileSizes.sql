SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [aud].[databaseFileSizes]
@fileSizeChange INT, @logFileSizeChange INT
AS


/*
  CREATED: 20210329
   AUTHOR: B EICHBERGER
  PURPOSE: Collect files sizes for priority linked servers 
CHANGEDON: 
 CHANGEBY: Sopheap Suy
   CHANGE: comment out a small section because it's not reaching the end of the list

NOTES: read priority database sizes and alert on out of range growth
-- exec dba.aud.databaseFileSizes  60, 60

------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 
UPDATED BY:	Sopheap Suy
UPDATED DT:  04/02/2026
purpose	 :  call LTD-EAM instead of LTD-EAMV22, comment out LTD-HASTUS2
			
			
			*/


SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO [aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;


BEGIN TRY



declare @workdate datetime2
select @workdate = SYSDATETIME()

IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%tmpDBList%') > 0
BEGIN
drop table ##tmpDBList
END 

DECLARE @srvValues TABLE (svid INT IDENTITY(1,1), servername VARCHAR(90))

INSERT INTO @srvValues (servername)
VALUES 
--('LTD-AMAG'), retired
('LTD-EAM'),
('LTD-FINANCE'),
--('LTD-HASTUS2'),
('LTD-ITDB2'),
('LTD-ITRAK'),
('LTD-OPS'),
--('LTD-REPORTS'), retired
('LTD-TMDATA'),
('LTD-DW2'),
('LTD-DW'),
('LTD-ORDATA')
--('LTD-ORODS') --renamed to ltd-tmdata

;

--select * from @srvvalues

declare @i int = 1
declare @r int = (select max(svid) from @srvValues)
declare @sqlcmd2 nvarchar(max)
declare @sqlcmd nvarchar (max)

WHILE @i <= @r
BEGIN

declare @currSVR varchar(90)
select @currSVR = (select servername from @srvValues where svid = @i)


if (select count(*) from tempdb.sys.tables where name like '%tmpDBList%') > 0
BEGIN
drop table ##tmpDBList
END 

if (select count(*) from tempdb.sys.tables where name like '%tmpDBList%') = 0
BEGIN
create table ##tmpDBList (
databaseName varchar(90),
database_id varchar(90),
[type] varchar(90),
size decimal(32, 6) )
END

select @sqlcmd = 
'INSERT ##tmpDBList
select d.name, database_id, type, size * 8.0 / 1024 size
from ['+@currSVR + '].master.sys.master_files mf
INNER JOIN  ['+@currSVR + '].master.sys.sysdatabases d ON mf.database_id = d.dbid'
--print @sqlcmd


exec sp_executesql @sqlcmd

select @sqlcmd2 = '
insert dba.aud.file_size_history (
[serverName]
,[databaseName]
,[dataFileSizeMB]
,[logFileSizeMB])
select distinct ''[' +@currSVR + ']'' serverName,
    databaseName,
    (select sum(size) from ##tmpDBList fs where type = 0 and fs.database_id = db.database_id) dataFileSizeMB,
    (select sum(size) from ##tmpDBList fs where type = 1 and fs.database_id = db.database_id) logFileSizeMB
from ##tmpDBList db
--group by databaseName
'
--print @sqlcmd
--print @sqlcmd2
exec sp_executesql @sqlcmd2	
/*
IF @i = @r
BEGIN
SELECT * FROM ##tmpDBList
END
*/
if (select count(*) from tempdb.sys.tables where name like '%tmpDBList%') > 0
BEGIN
drop table ##tmpDBList
END

SELECT @i = @i + 1

--comment out because it's not reaching the end of the list ssuy
--IF @i <= @r
--continue
--	ELSE BREAK

	END

	
--select distinct serverName from aud.file_size_history
select * 
into ##reportoutput98
from (
select serverName,databaseName,dataFileSizeMB
, lag(dataFileSizeMB,1) OVER (partition by serverName, [databaseName] order by record_created_date desc) lastDBSize
,deltaDataSize = dataFileSizeMB
	- lag(dataFileSizeMB,1) OVER (partition by serverName, [databaseName] order by record_created_date desc) 
 , lag(logFileSizeMB,1) OVER (partition by serverName, [databaseName] order by record_created_date desc) lastLogSize
,deltaLogSize = logFileSizeMB
	- lag(logFileSizeMB,1) OVER (partition by serverName, [databaseName] order by record_created_date desc) 
from aud.file_size_history
where record_created_date < @workdate
and record_created_date >= (select max(record_created_date) from aud.file_size_history
						   where record_created_date < @workdate)
) o
where deltaLogSize > @fileSizeChange
or deltaDataSize > @logFileSizeChange

IF (SELECT COUNT(*) FROM ##reportoutput98) > 0
BEGIN
DECLARE @profile VARCHAR(255) = (
                    SELECT top 1 NAME
                    FROM msdb.dbo.sysmail_profile
                    )
  EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org;Sopheap.suy@ltd.org' 
             ,@subject = 'Alert: Possible high growth factor: Attachment'
			 ,@query = 'select * from ##reportoutput98'
			 ,@attach_query_result_as_file = 1
             ,@body = 'Alert: Possible high growth factor. Attachment(1)


'
END

IF (SELECT COUNT(*) FROM tempdb.sys.tables WHERE name LIKE '%reportoutput98%') > 0
BEGIN
DROP TABLE ##reportoutput98
END

END TRY	  

BEGIN CATCH

       DECLARE @profile2 VARCHAR(255) = (
                    SELECT TOP 1 NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(MAX)
             ,@error INT
             ,@message VARCHAR(MAX)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile2
             ,@recipients = 'barb.eichberger@ltd.org;support@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
