SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [ops].[merge_dailyEmployeeTimeDetail]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  B. Eichberger
 created dt	:  2024-05-28
 purpose	:  merge ops.dailyEmployeeTimeDetail from ltd-ops.midas.dbo.dailyEmployeeTimeDetail
 use		:  exec ops.merge_dailyEmployeeTimeDetail

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
DECLARE @yearStop date = (SELECT DATEFROMPARTS(YEAR(dateadd(year, -7,getdate())),1,1))


DROP TABLE IF EXISTS wrk.ops_dETD
SELECT * INTO wrk.ops_dETD
FROM [ops].[dailyEmployeeTimeDetail_v] WHERE opDate >= @yearStop


merge [ops].[dailyEmployeeTimeDetail] AS t
USING wrk.ops_dETD AS s
ON (t.opDate = s.opDate
	AND t.division = s.division COLLATE SQL_Latin1_General_CP850_CI_AS
	AND t.emp_SID = s.emp_SID
	AND t.detailSequence = s.detailSequence
	AND t.paySource = s.paySource COLLATE SQL_Latin1_General_CP850_CI_AS
	AND t.payType = s.payType COLLATE SQL_Latin1_General_CP850_CI_AS
	AND t.payDate = s.payDate
)
WHEN MATCHED 
AND ( ISNULL(t.originalTime,0) <> ISNULL(s.originalTime,0) 
OR ISNULL(t.paidTime,0) <> ISNULL(s.paidTime,0) 
OR ISNULL(t.calcTime,0) <> ISNULL(s.calcTime,0) 
OR ISNULL(t.timeAtStraight,0) <> ISNULL(s.timeAtStraight,0) 
OR ISNULL(t.timeAtOT,0) <> ISNULL(s.timeAtOT,0) 
OR ISNULL(t.dailyTKDetailFlags,0) <> ISNULL(s.dailyTKDetailFlags,0) 
OR ISNULL(t.userID,'') <> ISNULL(s.userID,'') COLLATE SQL_Latin1_General_CP850_CI_AS 
OR ISNULL(t.userTime,'1/1/1900') <> ISNULL(s.userTime,'1/1/1900') 
OR ISNULL(t.comment,'') <> ISNULL(s.comment,'') COLLATE SQL_Latin1_General_CP850_CI_AS 
OR ISNULL(t.workDivision,'') <> ISNULL(s.workDivision,'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.runNumber,'') <> ISNULL(s.runNumber,'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.blockRoute,'') <> ISNULL(s.blockRoute,'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.blockID,'') <> ISNULL(s.blockID,'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.workClass,'') <> ISNULL(s.workClass,'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.workAccount,'') <> ISNULL(s.workAccount,'') COLLATE SQL_Latin1_General_CP850_CI_AS
OR ISNULL(t.recType,'') <> ISNULL(s.recType,'') COLLATE SQL_Latin1_General_CP850_CI_AS 
OR ISNULL(t.keyTime,'') <> ISNULL(s.keyTime,'') 
)
THEN UPDATE SET 
	 t.originalTime = s.originalTime
	,t.paidTime = s.paidTime
	,t.calcTime = s.calcTime
	,t.timeAtStraight = s.timeAtStraight
	,t.timeAtOT = s.timeAtOT
	,t.dailyTKDetailFlags = s.dailyTKDetailFlags
	,t.userID = s.userID
	,t.userTime = s.userTime 
	,t.comment = s.comment  
	,t.workDivision = s.workDivision 
	,t.runNumber = s.runNumber 
	,t.blockRoute = s.blockRoute 
	,t.blockID = s.blockID 
	,t.workClass = s.workClass 
	,t.workAccount = s.workAccount 
	,t.recType = s.recType  
	,t.keyTime = s.keyTime
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
 opDate
,division
,emp_SID
,detailSequence
,paySource
,payType
,payDate
,workDivision
,runNumber
,blockRoute
,blockID
,workClass
,keyTime
,originalTime
,paidTime
,calcTime
,timeAtStraight
,timeAtOT
,dailyTKDetailFlags
,workAccount
,recType
,userID
,userTime
,comment
)
VALUES
(s.opDate, s.division, s.emp_SID, s.detailSequence, s.paySource, s.payType, s.payDate, s.workDivision, s.runNumber, s.blockRoute, s.blockID, s.workClass, s.keyTime, s.originalTime, s.paidTime, s.calcTime, s.timeAtStraight, s.timeAtOT, s.dailyTKDetailFlags, s.workAccount, s.recType, s.userID, s.userTime, s.comment)
WHEN NOT MATCHED BY SOURCE AND opDate >= @yearStop THEN delete
OUTPUT $action INTO @outputTbl
option (maxdop 2)
;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_dailyEmployeeTimeDetail'

INSERT PROCESS.mergeLogs
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
'ltd_dw.ops.dailyEmployeeTimeDetail',
'MIDAS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()

DROP TABLE IF EXISTS wrk.ops_dETD


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
