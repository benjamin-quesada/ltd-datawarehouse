SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ops].[merge_dailyPiece]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  B. Eichberger
 created dt	:  2024-10-10
 purpose	:  merge ops.dailyPiece from ltd-ops.midas.dbo.dailyPiece
 use		:  exec ops.merge_dailyPiece

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
DECLARE @yearStop INT = (SELECT YEAR(GETDATE()-1))
DECLARE @outputTbl TABLE (actionNm VARCHAR(32) NOT null);


DECLARE @dailyPiecePrep TABLE (
	[blockRoute] [varchar](6) NOT NULL,
	[blockID] [varchar](6) NOT NULL,
	[division] [varchar](4) NOT NULL,
	[schDrivBegTime] [int] NOT NULL,
	[opDate] [smalldatetime] NOT NULL,
	[workClass] [varchar](4) NOT NULL,
	[keyTime] [int] NOT NULL,
	[schVehBegTime] [int] NOT NULL,
	[emp_SID] [int] NULL,
	[schdVehEndTime] [int] NOT NULL,
	[actDriveEndPlace] [varchar](8) NULL,
	[actMiles] [int] NULL,
	[actReliefBeg] [char](1) NULL,
	[schDrivEndTime] [int] NOT NULL,
	[actReliefEnd] [char](1) NULL,
	[actVehBegTime] [int] NULL,
	[actVehEndTime] [int] NULL,
	[actDrivBegTime] [int] NULL,
	[actDrivEndTime] [int] NULL,
	[schVehBegPlace] [varchar](8) NOT NULL,
	[actWorkTime] [int] NULL,
	[schVehEndPlace] [varchar](8) NOT NULL,
	[actVehBegPlace] [varchar](8) NULL,
	[comments] [varchar](255) NULL,
	[actVehEndPlace] [varchar](8) NULL,
	[cutPriority] [char](1) NULL,
	[payMethod] [varchar](4) NULL,
	[dailyPieceFlags] [smallint] NOT NULL,
	[baseRunNumber] [varchar](6) NULL,
	[boardID] [varchar](4) NULL,
	[runNumber] [varchar](6) NULL,
	[vehicleType] [varchar](4) NULL,
	[appOrigin] [char](1) NOT NULL,
	[pieceFlags] [smallint] NOT NULL,
	[whoAssigned] [char](1) NULL,
	[whoPaid] [char](1) NULL,
	[schReliefBeg] [char](1) NOT NULL,
	[schMiles] [int] NULL,
	[schReliefEnd] [char](1) NOT NULL,
	[runExceptions] [varchar](12) NULL,
	[schDrivBegPlace] [varchar](8) NOT NULL,
	[schDrivEndPlace] [varchar](8) NOT NULL,
	[actDrivBegPlace] [varchar](8) NULL,
	[schWorkTime] [int] NOT NULL,
	[dayType] [varchar](4) NULL,
	[whoCreated] [char](1) NULL,
	[opDays] [smallint] NULL,
	[workAccount] [varchar](4) NULL,
	[payReason] [varchar](4) NULL,
	[coverPaid] [int] NULL,
	[vehicleID] [varchar](5) NULL,
	[callStatus] [varchar](4) NULL,
	[equipment] [smallint] NOT NULL,
	[consist] [smallint] NULL,
	[taxiIDStart] [varchar](4) NULL,
	[taxiIDEnd] [varchar](4) NULL,
	[pieceRoute] [varchar](6) NULL,
	[breakReason] [varchar](4) NULL,
	[block_SID] [int] NULL,
	[fareCardSequence] [int] NULL,
	[notRunReason] [varchar](4) NULL,
	[assignPhase] [varchar](4) NULL,
	[workBoard] [varchar](4) NULL,
	[dailyPieceFlags2] [smallint] NOT NULL,
	[actingEmp_SID] [int] NULL)

insert @dailyPiecePrep(
[blockRoute]
      ,[blockID]
      ,[division]
      ,[schDrivBegTime]
      ,[opDate]
      ,[workClass]
      ,[keyTime]
      ,[schVehBegTime]
      ,[emp_SID]
      ,[schdVehEndTime]
      ,[actDriveEndPlace]
      ,[actMiles]
      ,[actReliefBeg]
      ,[schDrivEndTime]
      ,[actReliefEnd]
      ,[actVehBegTime]
      ,[actVehEndTime]
      ,[actDrivBegTime]
      ,[actDrivEndTime]
      ,[schVehBegPlace]
      ,[actWorkTime]
      ,[schVehEndPlace]
      ,[actVehBegPlace]
      ,[comments]
      ,[actVehEndPlace]
      ,[cutPriority]
      ,[payMethod]
      ,[dailyPieceFlags]
      ,[baseRunNumber]
      ,[boardID]
      ,[runNumber]
      ,[vehicleType]
      ,[appOrigin]
      ,[pieceFlags]
      ,[whoAssigned]
      ,[whoPaid]
      ,[schReliefBeg]
      ,[schMiles]
      ,[schReliefEnd]
      ,[runExceptions]
      ,[schDrivBegPlace]
      ,[schDrivEndPlace]
      ,[actDrivBegPlace]
      ,[schWorkTime]
      ,[dayType]
      ,[whoCreated]
      ,[opDays]
      ,[workAccount]
      ,[payReason]
      ,[coverPaid]
      ,[vehicleID]
      ,[callStatus]
      ,[equipment]
      ,[consist]
      ,[taxiIDStart]
      ,[taxiIDEnd]
      ,[pieceRoute]
      ,[breakReason]
      ,[block_SID]
      ,[fareCardSequence]
      ,[notRunReason]
      ,[assignPhase]
      ,[workBoard]
      ,[dailyPieceFlags2]
      ,[actingEmp_SID])
SELECT [blockRoute]
      ,[blockID]
      ,[division]
      ,[schDrivBegTime]
      ,[opDate]
      ,[workClass]
      ,[keyTime]
      ,[schVehBegTime]
      ,[emp_SID]
      ,[schdVehEndTime]
      ,[actDriveEndPlace]
      ,[actMiles]
      ,[actReliefBeg]
      ,[schDrivEndTime]
      ,[actReliefEnd]
      ,[actVehBegTime]
      ,[actVehEndTime]
      ,[actDrivBegTime]
      ,[actDrivEndTime]
      ,[schVehBegPlace]
      ,[actWorkTime]
      ,[schVehEndPlace]
      ,[actVehBegPlace]
      ,[comments]
      ,[actVehEndPlace]
      ,[cutPriority]
      ,[payMethod]
      ,[dailyPieceFlags]
      ,[baseRunNumber]
      ,[boardID]
      ,[runNumber]
      ,[vehicleType]
      ,[appOrigin]
      ,[pieceFlags]
      ,[whoAssigned]
      ,[whoPaid]
      ,[schReliefBeg]
      ,[schMiles]
      ,[schReliefEnd]
      ,[runExceptions]
      ,[schDrivBegPlace]
      ,[schDrivEndPlace]
      ,[actDrivBegPlace]
      ,[schWorkTime]
      ,[dayType]
      ,[whoCreated]
      ,[opDays]
      ,[workAccount]
      ,[payReason]
      ,[coverPaid]
      ,[vehicleID]
      ,[callStatus]
      ,[equipment]
      ,[consist]
      ,[taxiIDStart]
      ,[taxiIDEnd]
      ,[pieceRoute]
      ,[breakReason]
      ,[block_SID]
      ,[fareCardSequence]
      ,[notRunReason]
      ,[assignPhase]
      ,[workBoard]
      ,[dailyPieceFlags2]
      ,[actingEmp_SID]  
FROM [LTD-OPS].midas.[dbo].[dailyPiece] WITH (NOLOCK) 
WHERE YEAR(opDate) >= @yearStop

MERGE [ops].[dailyPiece] AS t
USING @dailyPiecePrep AS s
ON (t.[division] = s.[division] AND 
	t.[opDate] = s.[opDate] AND 
	t.[blockRoute] = s.[blockRoute] AND 
	t.[blockID] = s.[blockID] AND 
	t.[workClass] = s.[workClass] AND 
	t.[keyTime] = s.[keyTime])
WHEN MATCHED AND (
	ISNULL(t.schDrivBegTime, 0) <> ISNULL(s.schDrivBegTime, 0)
	OR ISNULL(t.schVehBegTime, 0) <> ISNULL(s.schVehBegTime, 0)
	OR ISNULL(t.emp_SID, 0) <> ISNULL(s.emp_SID, 0)
	OR ISNULL(t.schdVehEndTime, 0) <> ISNULL(s.schdVehEndTime, 0)
	OR ISNULL(t.actDriveEndPlace, '') <> ISNULL(s.actDriveEndPlace, '')
	OR ISNULL(t.actMiles, 0) <> ISNULL(s.actMiles, 0)
	OR ISNULL(t.actReliefBeg, '') <> ISNULL(s.actReliefBeg, '')
	OR ISNULL(t.schDrivEndTime, 0) <> ISNULL(s.schDrivEndTime, 0)
	OR ISNULL(t.actReliefEnd, '') <> ISNULL(s.actReliefEnd, '')
	OR ISNULL(t.actVehBegTime, 0) <> ISNULL(s.actVehBegTime, 0)
	OR ISNULL(t.actVehEndTime, 0) <> ISNULL(s.actVehEndTime, 0)
	OR ISNULL(t.actDrivBegTime, 0) <> ISNULL(s.actDrivBegTime, 0)
	OR ISNULL(t.actDrivEndTime, 0) <> ISNULL(s.actDrivEndTime, 0)
	OR ISNULL(t.schVehBegPlace, '') <> ISNULL(s.schVehBegPlace, '')
	OR ISNULL(t.actWorkTime, 0) <> ISNULL(s.actWorkTime, 0)
	OR ISNULL(t.schVehEndPlace, '') <> ISNULL(s.schVehEndPlace, '')
	OR ISNULL(t.actVehBegPlace, '') <> ISNULL(s.actVehBegPlace, '')
	OR ISNULL(t.comments, '') <> ISNULL(s.comments, '')
	OR ISNULL(t.actVehEndPlace, '') <> ISNULL(s.actVehEndPlace, '')
	OR ISNULL(t.cutPriority, '') <> ISNULL(s.cutPriority, '')
	OR ISNULL(t.payMethod, '') <> ISNULL(s.payMethod, '')
	OR ISNULL(t.dailyPieceFlags, 0) <> ISNULL(s.dailyPieceFlags, 0)
	OR ISNULL(t.baseRunNumber, '') <> ISNULL(s.baseRunNumber, '')
	OR ISNULL(t.boardID, '') <> ISNULL(s.boardID, '')
	OR ISNULL(t.runNumber, '') <> ISNULL(s.runNumber, '')
	OR ISNULL(t.vehicleType, '') <> ISNULL(s.vehicleType, '')
	OR ISNULL(t.appOrigin, '') <> ISNULL(s.appOrigin, '')
	OR ISNULL(t.pieceFlags, 0) <> ISNULL(s.pieceFlags, 0)
	OR ISNULL(t.whoAssigned, '') <> ISNULL(s.whoAssigned, '')
	OR ISNULL(t.whoPaid, '') <> ISNULL(s.whoPaid, '')
	OR ISNULL(t.schReliefBeg, '') <> ISNULL(s.schReliefBeg, '')
	OR ISNULL(t.schMiles, 0) <> ISNULL(s.schMiles, 0)
	OR ISNULL(t.schReliefEnd, '') <> ISNULL(s.schReliefEnd, '')
	OR ISNULL(t.runExceptions, '') <> ISNULL(s.runExceptions, '')
	OR ISNULL(t.schDrivBegPlace, '') <> ISNULL(s.schDrivBegPlace, '')
	OR ISNULL(t.schDrivEndPlace, '') <> ISNULL(s.schDrivEndPlace, '')
	OR ISNULL(t.actDrivBegPlace, '') <> ISNULL(s.actDrivBegPlace, '')
	OR ISNULL(t.schWorkTime, '') <> ISNULL(s.schWorkTime, '')
	OR ISNULL(t.dayType, '') <> ISNULL(s.dayType, '')
	OR ISNULL(t.whoCreated, '') <> ISNULL(s.whoCreated, '')
	OR ISNULL(t.opDays, 0) <> ISNULL(s.opDays, 0)
	OR ISNULL(t.workAccount, '') <> ISNULL(s.workAccount, '')
	OR ISNULL(t.payReason, '') <> ISNULL(s.payReason, '')
	OR ISNULL(t.coverPaid, 0) <> ISNULL(s.coverPaid, 0)
	OR ISNULL(t.vehicleID, '') <> ISNULL(s.vehicleID, '')
	OR ISNULL(t.callStatus, '') <> ISNULL(s.callStatus, '')
	OR ISNULL(t.equipment, 0) <> ISNULL(s.equipment, 0)
	OR ISNULL(t.consist, 0) <> ISNULL(s.consist, 0)
	OR ISNULL(t.taxiIDStart, '') <> ISNULL(s.taxiIDStart, '')
	OR ISNULL(t.taxiIDEnd, '') <> ISNULL(s.taxiIDEnd, '')
	OR ISNULL(t.pieceRoute, '') <> ISNULL(s.pieceRoute, '')
	OR ISNULL(t.breakReason, '') <> ISNULL(s.breakReason, '')
	OR ISNULL(t.block_SID, 0) <> ISNULL(s.block_SID, 0)
	OR ISNULL(t.fareCardSequence, 0) <> ISNULL(s.fareCardSequence, 0)
	OR ISNULL(t.notRunReason, '') <> ISNULL(s.notRunReason, '')
	OR ISNULL(t.assignPhase, '') <> ISNULL(s.assignPhase, '')
	OR ISNULL(t.workBoard, '') <> ISNULL(s.workBoard, '')
	OR ISNULL(t.dailyPieceFlags2, 0) <> ISNULL(s.dailyPieceFlags2, 0)
	OR ISNULL(t.actingEmp_SID, 0) <> ISNULL(s.actingEmp_SID, 0)
	)
THEN UPDATE SET 
 t.schDrivBegTime = s.schDrivBegTime
,t.keyTime = s.keyTime
,t.schVehBegTime = s.schVehBegTime
,t.emp_SID = s.emp_SID
,t.schdVehEndTime = s.schdVehEndTime
,t.actDriveEndPlace = s.actDriveEndPlace
,t.actMiles = s.actMiles
,t.actReliefBeg = s.actReliefBeg
,t.schDrivEndTime = s.schDrivEndTime
,t.actReliefEnd = s.actReliefEnd
,t.actVehBegTime = s.actVehBegTime
,t.actVehEndTime = s.actVehEndTime
,t.actDrivBegTime = s.actDrivBegTime
,t.actDrivEndTime = s.actDrivEndTime
,t.schVehBegPlace = s.schVehBegPlace
,t.actWorkTime = s.actWorkTime
,t.schVehEndPlace = s.schVehEndPlace
,t.actVehBegPlace = s.actVehBegPlace
,t.comments = s.comments
,t.actVehEndPlace = s.actVehEndPlace
,t.cutPriority = s.cutPriority
,t.payMethod = s.payMethod
,t.dailyPieceFlags = s.dailyPieceFlags
,t.baseRunNumber = s.baseRunNumber
,t.boardID = s.boardID
,t.runNumber = s.runNumber
,t.vehicleType = s.vehicleType
,t.appOrigin = s.appOrigin
,t.pieceFlags = s.pieceFlags
,t.whoAssigned = s.whoAssigned
,t.whoPaid = s.whoPaid
,t.schReliefBeg = s.schReliefBeg
,t.schMiles = s.schMiles
,t.schReliefEnd = s.schReliefEnd
,t.runExceptions = s.runExceptions
,t.schDrivBegPlace = s.schDrivBegPlace
,t.schDrivEndPlace = s.schDrivEndPlace
,t.actDrivBegPlace = s.actDrivBegPlace
,t.schWorkTime = s.schWorkTime
,t.dayType = s.dayType
,t.whoCreated = s.whoCreated
,t.opDays = s.opDays
,t.workAccount = s.workAccount
,t.payReason = s.payReason
,t.coverPaid = s.coverPaid
,t.vehicleID = s.vehicleID
,t.callStatus = s.callStatus
,t.equipment = s.equipment
,t.consist = s.consist
,t.taxiIDStart = s.taxiIDStart
,t.taxiIDEnd = s.taxiIDEnd
,t.pieceRoute = s.pieceRoute
,t.breakReason = s.breakReason
,t.block_SID = s.block_SID
,t.fareCardSequence = s.fareCardSequence
,t.notRunReason = s.notRunReason
,t.assignPhase = s.assignPhase
,t.workBoard = s.workBoard
,t.dailyPieceFlags2 = s.dailyPieceFlags2
,t.actingEmp_SID = s.actingEmp_SID
WHEN NOT MATCHED BY TARGET
THEN INSERT
(
blockRoute
,blockID
,division
,schDrivBegTime
,opDate
,workClass
,keyTime
,schVehBegTime
,emp_SID
,schdVehEndTime
,actDriveEndPlace
,actMiles
,actReliefBeg
,schDrivEndTime
,actReliefEnd
,actVehBegTime
,actVehEndTime
,actDrivBegTime
,actDrivEndTime
,schVehBegPlace
,actWorkTime
,schVehEndPlace
,actVehBegPlace
,comments
,actVehEndPlace
,cutPriority
,payMethod
,dailyPieceFlags
,baseRunNumber
,boardID
,runNumber
,vehicleType
,appOrigin
,pieceFlags
,whoAssigned
,whoPaid
,schReliefBeg
,schMiles
,schReliefEnd
,runExceptions
,schDrivBegPlace
,schDrivEndPlace
,actDrivBegPlace
,schWorkTime
,dayType
,whoCreated
,opDays
,workAccount
,payReason
,coverPaid
,vehicleID
,callStatus
,equipment
,consist
,taxiIDStart
,taxiIDEnd
,pieceRoute
,breakReason
,block_SID
,fareCardSequence
,notRunReason
,assignPhase
,workBoard
,dailyPieceFlags2
,actingEmp_SID
)
VALUES
(s.blockRoute, s.blockID, s.division, s.schDrivBegTime, s.opDate, s.workClass, s.keyTime, s.schVehBegTime, s.emp_SID, s.schdVehEndTime, s.actDriveEndPlace, s.actMiles, s.actReliefBeg, s.schDrivEndTime, s.actReliefEnd, s.actVehBegTime, s.actVehEndTime, s.actDrivBegTime, s.actDrivEndTime, s.schVehBegPlace, s.actWorkTime, s.schVehEndPlace, s.actVehBegPlace, s.comments, s.actVehEndPlace, s.cutPriority, s.payMethod, s.dailyPieceFlags, s.baseRunNumber, s.boardID, s.runNumber, s.vehicleType, s.appOrigin, s.pieceFlags, s.whoAssigned, s.whoPaid, s.schReliefBeg, s.schMiles, s.schReliefEnd, s.runExceptions, s.schDrivBegPlace, s.schDrivEndPlace, s.actDrivBegPlace, s.schWorkTime, s.dayType, s.whoCreated, s.opDays, s.workAccount, s.payReason, s.coverPaid, s.vehicleID, s.callStatus, s.equipment, s.consist, s.taxiIDStart, s.taxiIDEnd, s.pieceRoute, s.breakReason, s.block_SID, s.fareCardSequence, s.notRunReason, s.assignPhase, s.workBoard, s.dailyPieceFlags2, s.actingEmp_SID)
WHEN NOT MATCHED BY SOURCE AND YEAR(opDate) >= @yearStop
	THEN DELETE	
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_dailyPiece'

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
select 'OPSDP',
'ltd_dw.ops.dailyPiece',
'MIDAS',
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
