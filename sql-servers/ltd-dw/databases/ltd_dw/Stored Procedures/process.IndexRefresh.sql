SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [process].[IndexRefresh]
as
-- exec process.IndexRefresh

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


DECLARE @objectid int;  
DECLARE @indexid int;  
DECLARE @partitioncount bigint;  
DECLARE @schemaname nvarchar(130);   
DECLARE @objectname nvarchar(130);   
DECLARE @indexname nvarchar(130);   
DECLARE @partitionnum bigint;  
DECLARE @partitions bigint;  
DECLARE @frag float;  
DECLARE @command nvarchar(4000);   
-- Conditionally select tables and indexes from the sys.dm_db_index_physical_stats function   
-- and convert object and index IDs to names.  
select * into #work_to_do from (
SELECT  
    object_id AS objectid,  object_name(object_id) ObjectName,
    index_id AS indexid,  
    partition_number AS partitionnum,  
    avg_fragmentation_in_percent AS frag  
--INTO -- select * from #work_to_do  
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, 'LIMITED')  
WHERE avg_fragmentation_in_percent > 25.0 AND index_id > 0
and object_name(object_id) not like 'PK%') P
;  

--Truncate table process.[IndexOptimization] ;
if (select count(*) from #work_to_do ) > 0 
BEGIN



DECLARE @sessionkey BIGINT
select @sessionkey = isnull((select max(sessionkey) from [process].[IndexOptimization]),0)
	

INSERT INTO [process].[IndexOptimization]
           (SessionKey
		   ,[Timing]
           ,[objectid]
           ,[ObjectName]
           ,[indexid]
           ,[partitionnum]
           ,[frag]
           ,[name])

  select @sessionkey + 1,'BEFORE' as Timing,w.objectid,w.objectname,w.indexid,w.partitionnum,w.frag , i.name  
  from #work_to_do w
  join sys.indexes i on i.object_id = w.objectid and i.index_id = w.indexid
  where [name] not like 'PK%'
 


-- Declare the cursor for the list of partitions to be processed.  
DECLARE partitions CURSOR FOR SELECT objectid,indexid,partitionnum,frag FROM #work_to_do;  
  
-- Open the cursor.  
OPEN partitions;  
  
-- Loop through the partitions.  
WHILE (1=1)  
    BEGIN;  
        FETCH NEXT  
           FROM partitions  
           INTO @objectid, @indexid, @partitionnum, @frag;  
        IF @@FETCH_STATUS < 0 BREAK;  
        SELECT @objectname = QUOTENAME(o.name), @schemaname = QUOTENAME(s.name)  
        FROM sys.objects AS o  
        JOIN sys.schemas as s ON s.schema_id = o.schema_id  
        WHERE o.object_id = @objectid;  
        SELECT @indexname = QUOTENAME(name)  
        FROM sys.indexes  
        WHERE  object_id = @objectid AND index_id = @indexid;  
        SELECT @partitioncount = count (*)  
        FROM sys.partitions  
        WHERE object_id = @objectid AND index_id = @indexid;  
  
-- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding.  
        IF @frag < 35.0  
            SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REORGANIZE';  
        IF @frag >= 35.0  
            SET @command = N'ALTER INDEX ' + @indexname + N' ON ' + @schemaname + N'.' + @objectname + N' REBUILD  WITH (FILLFACTOR = 56)';  
        IF @partitioncount > 1  
            SET @command = @command + N' PARTITION=' + CAST(@partitionnum AS nvarchar(10));  
        EXEC (@command);  
        --PRINT N'Executed: ' + @command;  
    END;  
  
-- Close and deallocate the cursor.  
CLOSE partitions;  
DEALLOCATE partitions;  
  
select * 
INTO #work_done 
from (
SELECT  
    object_id AS objectid,  object_name(object_id) objectname,
    index_id AS indexid,  
    partition_number AS partitionnum,  
    avg_fragmentation_in_percent AS frag  

FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, 'LIMITED')  
) t
 join sys.indexes i on i.object_id = t.objectid and i.index_id = t.indexid
WHERE exists (select name from [process].[IndexOptimization] d
				where d.indexid = t.indexid and d.ObjectName = t.objectname and d.name = i.name and sessionkey = @sessionkey+1 )
--and object_name(object_id) = 'ClaimVersion'
;  
  


INSERT INTO [process].[IndexOptimization]
           (Sessionkey
		   ,[Timing]
           ,[objectid]
           ,[ObjectName]
           ,[indexid]
           ,[partitionnum]
           ,[frag]
           ,[name])

select @sessionkey + 1,'AFTER' as Timing,w.objectid,w.objectname,w.indexid,w.partitionnum,w.frag , i.name 
  from #work_done w
  join sys.indexes i on i.object_id = w.objectid and i.index_id = w.indexid
 
  
  -- Drop the temporary tables.  
DROP TABLE #work_to_do;   
DROP TABLE #work_done;  

END
GO
