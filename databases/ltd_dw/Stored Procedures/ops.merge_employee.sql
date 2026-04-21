SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ops].[merge_employee]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-02-23
 purpose	:  merge ops.absence from ltd-ops.midas.dbo.absence
 use		:  exec ops.merge_employee

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

SELECT * INTO #empOps FROM [LTD-OPS].midas.dbo.employee WITH (NOLOCK)

MERGE ltd_dw.ops.employee AS t
USING #empOps AS s
ON (t.emp_SID = s.emp_SID)
WHEN MATCHED AND 
( ISNULL(t.lastName,'') <> ISNULL(s.lastName COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.firstName,'') <> ISNULL(s.firstName COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.mi,'') <> ISNULL(s.mi COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.stampDate,0) <> ISNULL(s.stampDate,0)
OR ISNULL(t.stampUser,'') <> ISNULL(s.stampUser COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.vacationSenDate,0) <> ISNULL(s.vacationSenDate,0)
OR ISNULL(t.vacationSenLottery,0) <> ISNULL(s.vacationSenLottery,0)
OR ISNULL(t.personnelID,'') <> ISNULL(s.personnelID  COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.empFlags,0) <> ISNULL(s.empFlags,0)
OR ISNULL(t.lastDayWorked,0) <> ISNULL(s.lastDayWorked,0)
OR ISNULL(t.lastPlatformWorked,0) <> ISNULL(s.lastPlatformWorked,0)
OR ISNULL(t.clientDate1,0) <> ISNULL(s.clientDate1,0)
OR ISNULL(t.clientDate2,0) <> ISNULL(s.clientDate2,0)
OR ISNULL(t.systemUserID,'') <> ISNULL(s.systemUserID COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.vacGroup,'') <> ISNULL(s.vacGroup COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.clientCode1,'') <> ISNULL(s.clientCode1 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.clientCode2,'') <> ISNULL(s.clientCode2  COLLATE SQL_Latin1_General_CP850_CI_AS,''))
THEN 
UPDATE SET t.emp_SID = s.emp_SID
		,t.lastName = s.lastName
		,t.firstName = s.firstName
		,t.mi = s.mi
		,t.stampDate = s.stampDate
		,t.stampUser = s.stampUser
		,t.vacationSenDate = s.vacationSenDate
		,t.vacationSenLottery = s.vacationSenLottery
		,t.personnelID = s.personnelID
		,t.empFlags = s.empFlags
		,t.lastDayWorked = s.lastDayWorked
		,t.lastPlatformWorked = s.lastPlatformWorked
		,t.clientDate1 = s.clientDate1
		,t.clientDate2 = s.clientDate2
		,t.systemUserID = s.systemUserID
		,t.vacGroup = s.vacGroup
		,t.clientCode1 = s.clientCode1
		,t.clientCode2 = s.clientCode2
		,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
emp_SID
,lastName
,firstName
,mi
,stampDate
,stampUser
,vacationSenDate
,vacationSenLottery
,personnelID
,empFlags
,lastDayWorked
,lastPlatformWorked
,clientDate1
,clientDate2
,systemUserID
,vacGroup
,clientCode1
,clientCode2
)
VALUES
(s.emp_SID, s.lastName, s.firstName, s.mi, s.stampDate, s.stampUser, s.vacationSenDate, s.vacationSenLottery, s.personnelID, s.empFlags, s.lastDayWorked, s.lastPlatformWorked, s.clientDate1, s.clientDate2, s.systemUserID, s.vacGroup, s.clientCode1, s.clientCode2)
WHEN NOT MATCHED BY SOURCE THEN DELETE	
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_employee'

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
select 'OPSE',
'ltd_dw.ops.employee',
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
