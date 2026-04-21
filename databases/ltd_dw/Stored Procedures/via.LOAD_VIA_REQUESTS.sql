SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [via].[LOAD_VIA_REQUESTS]
AS
/*
CREATED BY:		B. Eichberger
CREATED ON:		20230526
PURPOSE   :		Populate a table of Via Requests
				Read Request files, create needed objects
				Import to the new standard view table
				This isn't going to work long term
				Need to find a way to load new files with old data each month.

exec via.LOAD_VIA_REQUESTS
	
------------------LTD_GLOSSARY---------------
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

EXECUTE sp_configure 'show advanced options', 1; 
RECONFIGURE;

EXEC sp_configure 'xp_cmdshell', 1; 
RECONFIGURE;

EXEC sp_configure 'Ole Automation Procedures' , 1;
RECONFIGURE;


DROP TABLE IF EXISTS ##tempVals
CREATE TABLE ##tempVals (rn INT IDENTITY(1,1), cmd nvarchar(MAX))

DROP TABLE IF EXISTS ##tmpLoadLines
CREATE TABLE ##tmpLoadLines (rn INT IDENTITY(1,1),cmd NVARCHAR(MAX))

DROP TABLE IF EXISTS via.stage_REQUESTS_TABLES
CREATE table via.stage_REQUESTS_TABLES (filesource nvarchar(90),tblMaker nvarchar(90),columnDetails nvarchar(MAX))

DROP TABLE IF EXISTS #fileList
CREATE table #filelist (rn INT IDENTITY(1,1),fileSource NVARCHAR(255))
INSERT #filelist (fileSource) EXEC master..xp_cmdshell 'dir /B E:\filedrop\via\*requests_new.csv'
DELETE FROM #filelist WHERE fileSource IS NULL
-- select * from #filelist
DECLARE @i INT = 1
DECLARE @r INT = (SELECT MAX(rn) FROM #filelist  )
DECLARE @currFile NVARCHAR(255)
DECLARE @insertListCols NVARCHAR(MAX) 

WHILE @i <= @r 
BEGIN

SELECT @currFile = (SELECT fileSource FROM #filelist WHERE rn = @i)
DECLARE @sqlcmd NVARCHAR(MAX) = ''

DROP TABLE IF EXISTS #tempHeaders
CREATE table #tempHeaders (filesource varchar(120),headers nvarchar(MAX))
INSERT #tempHeaders (filesource,headers)
SELECT @currFile, @insertListCols +' SELECT ' + line AS cmd
FROM (
SELECT REPLACE(REPLACE(REPLACE(REPLACE(line,'","','"|"'),',',''),'"|"',''','''),'"','''') line
FROM dbo.uftreadfileastable('E:\filedrop\via',''+@currFile+'') ) j
WHERE line LIKE '%REQUEST%'

--SELECT @sqlcmd = @sqlcmd + ' INSERT via.stage_REQUESTS ([fileSource],[BulkColumn])
--SELECT f.fileSource,BulkColumn 
--FROM  (
--SELECT '''+ @currFile+''' fileSource,
--BulkColumn 
--FROM OPENROWSET (BULK ''E:\filedrop\via\'+@currFile+''', SINGLE_CLOB) ViaFile  ) f'
--EXEC sp_executesql @sqlcmd

DROP TABLE IF EXISTS [via].[stage_REQUESTS_HEADERS]
CREATE TABLE [via].[stage_REQUESTS_HEADERS](fileSource VARCHAR(255),headers NVARCHAR(MAX) NULL)
 ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
;

DECLARE @bcol NVARCHAR(MAX) = (select replace(headers,'''','') headers from #tempHeaders where filesource = @currFile)
select @sqlcmd = ''
select @sqlcmd = @sqlcmd + 'DROP TABLE IF EXISTS via.VIA_'+REPLACE(@currFile,'_requests_new.csv','')+' CREATE TABLE via.VIA_'+REPLACE(@currFile,'_requests_new.csv','')+'(' +@bcol +' varchar(max))'
--print @bcol
EXEC sp_executesql @sqlcmd


DECLARE @newTableName nvarchar(255) = REPLACE( 'via.VIA_'+(SELECT top(1) RTRIM(LTRIM(LEFT(REPLACE(REPLACE(fileSource,'DROP TABLE IF EXISTS',''), 'CREATE TABLE ',''),19))) from #tempHeaders ),'_requests','')
DECLARE @newTableCols nvarchar(MAX) = (SELECT TOP(1) REPLACE(REPLACE(REPLACE(SUBSTRING(headers,1,CHARINDEX(CHAR(10),headers)),'"',''),' ',''), ' varchar(255)','') FROM #tempHeaders )
DECLARE @makeCols NVARCHAR(MAX) = '('+REPLACE(REPLACE(@newTableCols,CHAR(10),''),'varchar(max)',' varchar(MAX)')+' varchar(max))'
DECLARE @listCols NVARCHAR(MAX) = REPLACE(@makeCols,' varchar(max)','')
select @insertListCols = 'INSERT '+@newTableName+' '+@listCols

INSERT ##tempVals (cmd)
SELECT  @insertListCols +' SELECT ' + line AS cmd
FROM (
SELECT REPLACE(REPLACE(REPLACE(REPLACE(line,'","','"|"'),',',''),'"|"',''','''),'"','''') line
FROM dbo.uftreadfileastable('E:\filedrop\via',''+@currFile+'') ) j
WHERE line NOT LIKE '%REQUEST%'






SELECT @i = @i + 1
IF @i > @r
BREAK
	ELSE CONTINUE

END

DECLARE @insertCmd NVARCHAR(MAX) = ''
DECLARE @c INT = 1
DECLARE @rc INT = (SELECT MAX(rn) FROM ##tempVals)

WHILE @c <= @rc
BEGIN

SELECT @insertCmd = (SELECT cmd FROM ##tempVals WHERE rn = @c)

EXEC sp_executesql @insertCmd

SELECT @c = @c + 1

IF @c > @rc
BREAK
	ELSE CONTINUE

END

;


EXEC sp_configure 'Ole Automation Procedures' , 0; 
RECONFIGURE;

EXEC sp_configure 'xp_cmdshell', 0; 
RECONFIGURE;

EXECUTE sp_configure 'show advanced options', 0; 
RECONFIGURE;

DROP TABLE IF EXISTS #tblList
SELECT table_name, COUNT(DISTINCT column_name) columnCount
INTO #tblList
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME LIKE 'VIA_2%'
GROUP BY TABLE_NAME

DECLARE @r2 INT = (SELECT MAX(columnCount) FROM #tblList)

DROP TABLE IF EXISTS #tempColumnBuilder
SELECT s.table_name,s.COLUMN_NAME, ISNULL(t.COLUMN_NAME,NULL) colCollate
INTO -- select * from 
#tempColumnBuilder
FROM INFORMATION_SCHEMA.COLUMNS s
LEFT JOIN (
	select DISTINCT COLUMN_NAME
	FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = (SELECT TOP(1) table_name FROM #tblList where columnCount = @r2 )
	) t ON s.column_name = t.column_name
WHERE s.TABLE_NAME LIKE 'VIA_2%'

DROP TABLE IF EXISTS #colTableCols
SELECT rn = ROW_NUMBER() over (ORDER BY o.TABLE_NAME DESC)
	  ,o.TABLE_NAME
	  ,o.ColNames 
	  INTO-- select * from 
	   #colTableCols 
	   --ORDER by rn 
	  FROM (
SELECT table_name, ColNames = STUFF(
             (SELECT ',' + colCollate 
              FROM #tempColumnBuilder t1
              WHERE t1.table_name = t2.table_name
              FOR XML PATH (''))
             , 1, 1, '') from #tempColumnBuilder t2
		GROUP by table_name) o

DROP TABLE IF EXISTS via.VIA_CGV_REQUESTS		
DECLARE @sqlcmdt NVARCHAR(MAX) = ''
SELECT @sqlcmdt = @sqlcmdt + 'SELECT ' + (SELECT ColNames from #colTableCols WHERE rn = 1) +'
' + 'INTO via.VIA_CGV_REQUESTS from via.' + (SELECT TABLE_NAME from #colTableCols WHERE rn = 1)
EXECUTE sp_executesql @sqlcmdt

DECLARE @i3 INT = 2
declare @r3 INT = (select count(distinct table_name) from #tempColumnBuilder )


WHILE @i3 <= @r3
BEGIN


DECLARE @sqlcmdo NVARCHAR(MAX) = ''
SELECT @sqlcmdo = @sqlcmdo + 'INSERT via.VIA_CGV_REQUESTS (' + (SELECT REPLACE(ColNames,',,',',') from #colTableCols WHERE rn = @i3) + ')
SELECT ' + (SELECT REPLACE(ColNames,',,',',') from #colTableCols WHERE rn = @i3) +'
 from via.' + (SELECT TABLE_NAME from #colTableCols WHERE rn = @i3)
--PRINT @sqlcmd

EXECUTE sp_executesql @sqlcmdo

SELECT @i3 = @i3 + 1

IF @i3 > @r3
BREAK
	ELSE CONTINUE

END


END TRY
BEGIN CATCH

	DECLARE @profile VARCHAR(255) =
			(SELECT name FROM msdb .dbo.sysmail_profile)  ;
	DECLARE @errormsg VARCHAR(MAX)
		   ,@error INT
		   ,@message VARCHAR(MAX)
		   ,@xstate INT
		   ,@errsev INT
		   ,@sub VARCHAR(255) ;

	SELECT	@error = ERROR_NUMBER()
		   ,@errsev = ERROR_SEVERITY()
		   ,@message = ERROR_MESSAGE()
		   ,@xstate = XACT_STATE() ;

	SELECT	@errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32)) ;

	SELECT	@sub = 'ERROR: ' + @SPROC ;

	EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
								,@recipients = 'barb.eichberger@ltd.org'
								,@subject = @sub
								,@body = @errormsg ;

	RAISERROR(@errormsg, @errsev, 1) ;
END CATCH ;

GO
