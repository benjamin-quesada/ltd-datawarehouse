SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ops].[merge_dailyPieceDetail]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-05-28
 purpose	:  merge ops.dailyPieceDetail from ltd-ops.midas.dbo.dailyPieceDetail
 use		:  exec ops.merge_dailyPieceDetail

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
DECLARE @yearStop INT = (SELECT YEAR(GETDATE()-7))
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

DROP TABLE IF EXISTS #dPiece
SELECT * INTO #dPiece
FROM ltd_dw.[ops].[dailyPieceDetail_v] WHERE YEAR(opDate) >= @yearStop

MERGE ltd_dw.[ops].[dailyPieceDetail] AS t
USING #dPiece AS s
ON (t.division = s.division COLLATE SQL_Latin1_General_CP850_CI_AS 
	AND CAST(t.opDate AS DATE) = CAST(s.opDate AS DATE)
	AND t.blockRoute = s.blockRoute COLLATE SQL_Latin1_General_CP850_CI_AS
	AND t.blockID = s.blockID COLLATE SQL_Latin1_General_CP850_CI_AS
	AND t.timeCode = s.timeCode COLLATE SQL_Latin1_General_CP850_CI_AS
	AND t.workClass = s.workClass COLLATE SQL_Latin1_General_CP850_CI_AS
	AND t.schWorkTime = s.schWorkTime 
	AND t.schAllowedTime = s.schAllowedTime 
	AND t.keyTime = s.keyTime
)
WHEN MATCHED AND ( 
   ISNULL(t.actWorkTime,0) <> ISNULL(s.actWorkTime,0) 
OR ISNULL(t.actAllowedTime,0) <> ISNULL(s.actAllowedTime,0) 
OR ISNULL(t.pieceDtFlag,0) <> ISNULL(s.pieceDtFlag,0)
)
THEN UPDATE SET 
	 t.actWorkTime = s.actWorkTime
	,t.actAllowedTime = s.actAllowedTime
	,t.pieceDtFlag = s.pieceDtFlag
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
division
,timeCode
,opDate
,blockRoute
,schWorkTime
,actWorkTime
,blockID
,workClass
,keyTime
,schAllowedTime
,actAllowedTime
,pieceDtFlag
)
VALUES
(s.division, s.timeCode, s.opDate, s.blockRoute, s.schWorkTime, s.actWorkTime, s.blockID, s.workClass, s.keyTime, s.schAllowedTime, s.actAllowedTime, s.pieceDtFlag)
WHEN NOT MATCHED BY SOURCE AND YEAR(opDate) >= @yearStop THEN DELETE
OUTPUT $action INTO @outputTbl;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_dailyPieceDetail'

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
SELECT 'OPSD',
'ltd_dw.ops.dailyPieceDetail',
'MIDAS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()


DROP TABLE IF EXISTS #dPiece

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
