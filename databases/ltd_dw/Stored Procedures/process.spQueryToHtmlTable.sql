SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   proc [process].[spQueryToHtmlTable] 
(
  @query NVARCHAR(MAX), --A query to turn into HTML format. It should not include an ORDER BY clause.
  @orderBy NVARCHAR(MAX) = NULL, --An optional ORDER BY clause. It should contain the words 'ORDER BY'.
  @header NVARCHAR(MAX) = NULL, -- The header greetings and information for the specific table being sent.
  @html NVARCHAR(MAX) = NULL OUTPUT --The HTML output of the procedure.
)
AS

/*
-- Description: Turns a query into a formatted HTML table. Useful for emails. 
-- An ORDER BY clause needs to be passed in the separate ORDER BY parameter, if not
--     ordering you still have to add " Order By 1" (with the space, line 25 and 42)

-- CREATED BY	: B. Eichberger
-- PURPOSE		: To centralize a procedure that converts simple query results to HTML
				  usually for sending in emails.
-- example		  exec [process].[spQueryToHtmlTable] 'select top(100) * from pds.Integration_EmpPerson','order by 1'			

-- =============================================
*/

BEGIN   
  
/*---------------------------------
UPDATED BY	: Sopheap Suy
UPDATED DT	: 10/31/2024
purpose		: Add object activities on who, what, when call this object
			  write this data to aud.object_activity table everytime it's called 
			
			*/

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



  SELECT @orderBy = ISNULL( @orderBy, ' Order by 1'  )
  SELECT @header = ISNULL(@header,'No Header')

  SET @orderBy = REPLACE(@orderBy, '''', '''''');
 

  DECLARE @realQuery nvarchar(MAX) = '
    DECLARE @headerRow nvarchar(MAX);
    DECLARE @cols nvarchar(MAX);    

    SELECT * INTO #dynSql FROM (' + @query + ') sub;

    SELECT @cols = COALESCE(@cols + '', '''''''', '', '''') + ''['' + name + ''] AS ''''td''''''
    FROM tempdb.sys.columns 
    WHERE object_id = object_id(''tempdb..#dynSql'')
    ORDER BY column_id;

    SET @cols = ''SET @html = CAST(( SELECT '' + @cols + '' FROM #dynSql ' + @orderBy + ' FOR XML PATH(''''tr''''), ELEMENTS XSINIL) AS nvarchar(max))''    

    EXEC sys.sp_executesql @cols, N''@html nvarchar(MAX) OUTPUT'', @html=@html OUTPUT

    SELECT @headerRow = COALESCE(@headerRow + '''', '''') + ''<th>'' + name + ''</th>'' 
    FROM tempdb.sys.columns 
    WHERE object_id = object_id(''tempdb..#dynSql'')
    ORDER BY column_id;

    SET @headerRow = ''<tr>'' + @headerRow + ''</tr>'';

    SET @html = ''<table border="1">'' + @headerRow + @html + ''</table>'';    
    ';
	--print @realQuery
  EXEC sys.sp_executesql @realQuery, N'@html nvarchar(MAX) OUTPUT', @html=@html OUTPUT

  --SELECT @html
END


GO
