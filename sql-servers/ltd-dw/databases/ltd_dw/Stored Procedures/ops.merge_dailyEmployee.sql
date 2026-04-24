SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE     PROCEDURE [ops].[merge_dailyEmployee]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-02-23
 purpose	:  merge DW ops.dailyEmployee from ltd-ops.midas.dbo.dailyEmployee
 use		:  exec ops.merge_dailyEmployee

UPDATED BY:	   Sopheap Suy
UPDATED DT:    2024-10-31
purpose	 :     Add object activities on who, what, when call this object
			   write this data to aud.object_activity table everytime it's called 
            
UPDATED BY:	   Sopheap Suy
UPDATED DT:    2026-01-29
purpose	 :     add date limit to process data based on time and hours of day
			   

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

BEGIN TRY

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));
DECLARE @hour INT, @minute INT, @opDate DATE
SET @hour = DATEPART(HOUR, GETDATE())
SET @minute = DATEPART(MINUTE, GETDATE())


SELECT @hour, @minute

IF (  @hour IN (3, 8, 13, 18, 23)  AND @minute < 29) --during this hour, we are pulling the entire dataset
BEGIN 
    
    SET @opDate = (SELECT MIN(opDate) FROM ops.dailyEmployee)
    
END
ELSE 
BEGIN 
    --out side above hours and minute we are pulling 15 days dataset
    SET @opDate = (SELECT DATEADD(DAY, -15, MAX(opDate) )FROM ops.dailyEmployee)
    
END

DROP TABLE IF EXISTS #dEmp2

SELECT division COLLATE SQL_Latin1_General_CP1_CI_AS division,
       opDate,
       emp_SID,
       ISNULL(workStatus COLLATE SQL_Latin1_General_CP1_CI_AS,'') workStatus,
       ISNULL(timeBegin,0) timeBegin,
       ISNULL(timeEnd,0) timeEnd,
       ISNULL(timeWorked,0) timeWorked,
       ISNULL(workWeek COLLATE SQL_Latin1_General_CP1_CI_AS,'') workWeek ,
       ISNULL(dailyGenFlags,0) dailyGenFlags,
       ISNULL(otherDiv COLLATE SQL_Latin1_General_CP1_CI_AS,'') otherDiv,
       ISNULL(noteText COLLATE SQL_Latin1_General_CP1_CI_AS,'') noteText,
       ISNULL(dailyWorkFlags,0) dailyWorkFlags,
       ISNULL(dailyTKFlags,0) dailyTKFlags,
       ISNULL(OTafterTime,0) OTafterTime,
       ISNULL(section15Rate,0) section15Rate,
       ISNULL(timeWorkedSleep,0) timeWorkedSleep,
       ISNULL(timeBeginSleep,0) timeBeginSleep,
       ISNULL(timeEndSleep,0) timeEndSleep,
       ISNULL(actingForEmp_SID,0) actingForEmp_SID,
       ISNULL(boardRating,0) boardRating,
       ISNULL(dailyPayRules COLLATE SQL_Latin1_General_CP1_CI_AS,'') dailyPayRules ,
       isnull(clientFlags,0) clientFlags,
       isnull(boardStatus COLLATE SQL_Latin1_General_CP1_CI_AS,'') boardStatus,
       isnull(weeklyPayRules COLLATE SQL_Latin1_General_CP1_CI_AS,'') weeklyPayRules,
       isnull(tradeEmp_SID,0) tradeEmp_SID
INTO #dEmp2 
FROM [LTD-OPS].midas.dbo.dailyEmployee WITH (NOLOCK)
WHERE opDate >= @opDate



CREATE INDEX ix_dEmp2  ON #dEmp2
    (division, opDate, emp_SID)
    INCLUDE( workStatus, timeBegin, timeEnd, timeWorked, workWeek,dailyGenFlags,
     otherDiv, noteText, dailyWorkFlags, dailyTKFlags, OTafterTime, section15Rate, timeWorkedSleep,
     timeBeginSleep, timeEndSleep, actingForEmp_SID, boardRating,dailyPayRules, clientFlags, 
     boardStatus, weeklyPayRules, tradeEmp_SID)

--SELECT * INTO #dEmp FROM [LTD-OPS].midas.dbo.dailyEmployee WITH (NOLOCK)

MERGE ltd_dw.ops.dailyEmployee AS t
USING #dEmp2 AS s
--ON (t.division COLLATE SQL_Latin1_General_CP1_CI_AS = s.division --COLLATE SQL_Latin1_General_CP1_CI_AS  
ON (t.division  = s.division --COLLATE SQL_Latin1_General_CP1_CI_AS  
AND t.opDate = s.opDate
AND t.emp_SID = s.emp_SID
AND t.opDate >= @opDate)
WHEN MATCHED AND (
ISNULL(t.workStatus,'')  <> s.workStatus 
OR ISNULL(t.timeBegin,0) <> s.timeBegin
OR ISNULL(t.timeEnd,0)   <> s.timeEnd
OR ISNULL(t.timeWorked,0) <> s.timeWorked
OR ISNULL(t.workWeek,'')  <> s.workWeek 
OR ISNULL(t.dailyGenFlags,0) <> s.dailyGenFlags
OR ISNULL(t.otherDiv,'') <> s.otherDiv 
OR ISNULL(t.noteText,'') <> s.noteText 
OR ISNULL(t.dailyWorkFlags,0) <> s.dailyWorkFlags
OR ISNULL(t.dailyTKFlags,0) <> s.dailyTKFlags
OR ISNULL(t.OTafterTime,0)  <> s.OTafterTime
OR ISNULL(t.section15Rate,0)<> s.section15Rate
OR ISNULL(t.timeWorkedSleep,0) <> s.timeWorkedSleep
OR ISNULL(t.timeBeginSleep,0) <> s.timeBeginSleep
OR ISNULL(t.timeEndSleep,0) <>   s.timeEndSleep
OR ISNULL(t.actingForEmp_SID,0) <> s.actingForEmp_SID
OR ISNULL(t.boardRating,0) <> s.boardRating
OR ISNULL(t.dailyPayRules,'') <> s.dailyPayRules 
OR ISNULL(t.clientFlags,0) <> s.clientFlags
OR ISNULL(t.boardStatus,'') <> s.boardStatus 
OR ISNULL(t.weeklyPayRules,'') <> s.weeklyPayRules 
OR ISNULL(t.tradeEmp_SID,0) <> s.tradeEmp_SID )
THEN UPDATE SET 
t.workStatus = s.workStatus 
	,t.timeBegin = s.timeBegin
	,t.timeEnd = s.timeEnd
	,t.timeWorked = s.timeWorked
	,t.workWeek = s.workWeek
	,t.dailyGenFlags = s.dailyGenFlags
	,t.otherDiv = s.otherDiv
	,t.noteText = s.noteText
	,t.dailyWorkFlags = s.dailyWorkFlags
	,t.dailyTKFlags = s.dailyTKFlags
	,t.OTafterTime = s.OTafterTime
	,t.section15Rate = s.section15Rate
	,t.timeWorkedSleep = s.timeWorkedSleep
	,t.timeBeginSleep = s.timeBeginSleep
	,t.timeEndSleep = s.timeEndSleep
	,t.actingForEmp_SID = s.actingForEmp_SID
	,t.boardRating = s.boardRating
	,t.dailyPayRules = s.dailyPayRules
	,t.clientFlags = s.clientFlags
	,t.boardStatus = s.boardStatus
	,t.weeklyPayRules = s.weeklyPayRules
	,t.tradeEmp_SID = s.tradeEmp_SID
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
division
,opDate
,emp_SID
,workStatus
,timeBegin
,timeEnd
,timeWorked
,workWeek
,dailyGenFlags
,otherDiv
,noteText
,dailyWorkFlags
,dailyTKFlags
,OTafterTime
,section15Rate
,timeWorkedSleep
,timeBeginSleep
,timeEndSleep
,actingForEmp_SID
,boardRating
,dailyPayRules
,clientFlags
,boardStatus
,weeklyPayRules
,tradeEmp_SID
)
VALUES
(s.division, s.opDate, s.emp_SID, s.workStatus, s.timeBegin, s.timeEnd, s.timeWorked, s.workWeek, s.dailyGenFlags, s.otherDiv, s.noteText, s.dailyWorkFlags, s.dailyTKFlags, s.OTafterTime, s.section15Rate, s.timeWorkedSleep, s.timeBeginSleep, s.timeEndSleep, s.actingForEmp_SID, s.boardRating, s.dailyPayRules, s.clientFlags, s.boardStatus, s.weeklyPayRules, s.tradeEmp_SID)
WHEN NOT MATCHED BY SOURCE AND opDate >= @opDate THEN DELETE
OUTPUT $action INTO @outputTbl
;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_dailyEmployee '+ CONVERT( VARCHAR(12),@opDate)

--SELECT @ins, @upd, @del, @prg, @opDate

INSERT process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
SELECT 'OPSE',
'ltd_dw.ops.dailyEmployee',
'MIDAS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()



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
             ,@recipients = 'barb.eichberger@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
