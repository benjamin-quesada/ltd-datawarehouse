SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tm].[merge_ALL_MILE_ACTIVITY]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  B. Eichberger
 created dt	:  2024-09-18
 purpose	:  merge TransitMaster (Vontas) tm.ALL_MILE_ACTIVITY from tmdatamart
			   for use in all miles activity details with EAM miles for overview
			   reporting
 use		:  exec tm.merge_ALL_MILE_ACTIVITY

 truncate table [tm].[ALL_MILE_ACTIVITY]
 select distinct * from  [tm].[ALL_MILE_ACTIVITY] 
 where the_date = '11/7/2025' 
*/


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

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

DECLARE @calStart datetime = (SELECT CAST(GETDATE()-30 AS date) )
declare @tdy INT = (SELECT [dbo].[F_DATE_TO_CALENDAR_ID](CAST(GETDATE() AS DATE)) AS tdy)

drop table if exists #calstart
SELECT CALENDAR_ID
into #calstart
from [LTD-TMDATA].tmdatamart.dbo.CALENDAR
WHERE CAST(CALENDAR_DATE AS DATE) >= CAST(GETDATE() - 31 AS DATE)

drop table if exists #prep
SELECT LABEL_NAME = 'TMDATAMART;VEHICLE_DISTANCE;' + CAST(ISNULL(d.REVENUE_ID, 'N') AS VARCHAR(21)) + ';' + ISNULL(t.REVENUE_DESCRIPTION, 'OTHER') + +CASE WHEN IS_GARAGE = 1 THEN ';IS_GARAGE' ELSE '' END
   ,the_date = d.CALENDAR_ID
   ,TOTAL_MILES = ISNULL(TOTAL_DISTANCE, 0) 
   ,TOTAL_HOURS = ISNULL(TOTAL_HOURS, 0)
   ,PROPERTY_TAG
   ,d.ROUTE_ID
into #prep
	FROM [LTD-TMDATA].tmdatamart.dbo.VEHICLE_DISTANCE d
		 INNER JOIN #calStart C ON C.CALENDAR_ID = d.CALENDAR_ID
		 LEFT JOIN [LTD-TMDATA].tmdatamart.dbo.REVENUE t ON t.REVENUE_ID = d.REVENUE_ID
	WHERE d.TOTAL_DISTANCE > 0
		  AND TOTAL_DISTANCE > 0
		
drop table if exists #ALL_MILE_ACTIVITY_STAGE
SELECT x.LABEL_NAME
,the_date = [dbo].[F_CALENDAR_ID_TO_DATE](x.the_date)
,miles_value = SUM(x.miles_value)
,hours_value = SUM(x.hours_value)
,x.PROPERTY_TAG
into #ALL_MILE_ACTIVITY_STAGE
FROM
(
	SELECT m.LABEL_NAME
   ,m.ROUTE_ID
   ,m.the_date
   ,SUM(m.TOTAL_MILES) miles_value
   ,SUM(m.TOTAL_HOURS) hours_value
   ,m.PROPERTY_TAG
	FROM #prep m
	GROUP BY m.LABEL_NAME
   ,m.the_date
   ,m.PROPERTY_TAG
   ,ROUTE_ID
) x
GROUP BY x.LABEL_NAME
,x.the_date
,x.PROPERTY_TAG
UNION
SELECT LABEL_NAME = 'LOGGED_MESSAGES;VEHICLE_DISTANCE'
,the_date = [dbo].[F_CALENDAR_ID_TO_DATE](calendar_id)
,SUM(odometer) / 100.0
,0
,veh
FROM [tm].[logged_messages] l
WHERE l.route IS NOT null and l.calendar_id = @tdy
GROUP BY calendar_id
,veh;


MERGE [tm].[ALL_MILE_ACTIVITY] AS t
USING #ALL_MILE_ACTIVITY_STAGE AS s
ON  t.label_name = s.label_name
AND t.the_date = s.the_date
AND t.eq_equip_no = s.property_tag
WHEN MATCHED AND ISNULL(t.miles_value, 0) <> ISNULL(s.miles_value, 0)
	OR ISNULL(t.hours_value, 0) <> ISNULL(s.hours_value, 0)
THEN UPDATE SET t.miles_value = s.miles_value
,t.hours_value = s.hours_value
,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET
THEN INSERT
(
label_name
,the_date
,miles_value
,hours_value
,eq_equip_no
)
VALUES
(s.label_name, s.the_date, s.miles_value, s.hours_value, s.property_tag)
WHEN NOT MATCHED BY SOURCE 
	AND t.the_date >= @calStart
	THEN DELETE
OUTPUT $action INTO @outputTbl
;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.tm.merge_ALL_MILE_ACTIVITY'

insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'TMMILE',
'ltd_dw.tm.ALL_MILE_ACTIVITY',
'TM',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
sysdatetime()


	
END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
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

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'data@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
