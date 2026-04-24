SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [rpt].[PASSENGER_COUNT_SUMMARY_old]
@yrfrom varchar(20) ,
@yrthru varchar(20) ,
@rte varchar(20) ,
--@rtedir varchar(20),
@exrte varchar(20) 
as 
/* 
  PURPOSE: used to output data for summary analysis of passenger counts by route
		   and route direction.

   AUTHOR: beichberger
     DATE: 20200211
CHANGEDON: 20210412
 CHANGEBY: B Eichberger
   CHANGE: Made to point directly at the legacy passenger view so data sets match to 
		   other reports.

   exec [rpt].[PASSENGER_COUNT_SUMMARY] 2021,NULL,'11',NULL
*/


SET FMTONLY OFF; 

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
-------- TEST DECLARES
--declare @yrfrom varchar(20) = '2021'
--declare @yrthru varchar(20) = NULL
--declare @rte varchar(20) = '11'
--declare @rtedir varchar(20) = 'I'
--declare @exrte varchar(20) = NULL

declare @yrsstr nvarchar(255)
declare @yrtstr nvarchar(255)
declare @rtstr nvarchar(255)
--declare @rdstr nvarchar(255) 
declare @exstr nvarchar(255)



select @yrsstr = case when @yrfrom is null then ' and b.[calendar_id] > ''120070000''' else ' and b.[calendar_id] > '''+'1' + @yrfrom + '0101''' end
select @yrtstr = case when @yrthru is null then ' and b.[calendar_id] < ''1'+cast(year(getdate()) as varchar(20)) + '9999''' 
													else ' and b.[calendar_id] < ''1'' + '''+@yrthru +'9999''' end

--select @rte = replace(@rte,' ',''',''')

select @rtstr = case when @rte like '% %' then ' and b.route in ('''+ replace(@rte,' ',''',''') +''')'
					 when @rte is null then '' 
					 when @rte = '' then '' 
					 when @rte not like '%,%' and @rte is not null then ' and b.route in ( '''+ @rte +''')' end
--select @rdstr = case when @rdstr is null then '' else ' and left(rd.[ROUTE_DIRECTION_NAME],1) = '''+ @rtedir + '''' end
select @exstr = case when @exrte like '% %' then ' and b.route not in ('''+ replace(@exrte,' ',''',''') +''')'
					 when @exrte is null then '' 
					 when @exrte = '' then ''
					 when @exrte not like '%,%' and @exrte is not null then ' and b.route not in ( '''+ @exrte +''')
					 ' end
 
--select @yrsstr
--select @yrtstr
--select @rtstr
--select @rdstr
--select @exstr
 
declare @sqlcmd nvarchar(max) = ''
select @sqlcmd = @sqlcmd + '
SELECT b.route --, b.dir
	,substring(cast(b.calendar_id as varchar(32)),2,4) the_year
	,substring(cast(b.calendar_id as varchar(32)),6,2) the_month
	,sum(board) as ons
FROM [LTD-TMDATA].ltd_db.dbo.passenger_count_v b
WHERE rev_rte = ''y''
   and stop <> ''garage''
   and trip_end is not null
'
+@yrsstr+'
'+@yrtstr+'
'+@rtstr+
--''+@rdstr+
+'
'+@exstr
+'group by b.route --, b.dir
	,substring(cast(b.calendar_id as varchar(32)),2,4) 
	,substring(cast(b.calendar_id as varchar(32)),6,2)  
	ORDER BY b.route --, b.dir
	,cast(substring(cast(b.calendar_id as varchar(32)),2,4) as INT)
	,cast(substring(cast(b.calendar_id as varchar(32)),6,2) as INT)'

--print @sqlcmd
exec sp_executesql @sqlcmd

END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org' --;servicedesk@ltd.org
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
