SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ops].[merge_employeeStatus]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-02-26
 purpose	:  merge ops.employee[status] from ltd-ops.midas.dbo.employeeStatus
 use		:  exec ops.merge_employeeStatus

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


MERGE ltd_dw.ops.employeestatus AS t
USING [LTD-OPS].midas.[dbo].[employeeStatus] AS s
ON (t.[emp_SID] = s.[emp_SID]
AND t.[dateEffective] = s.[dateEffective]
AND t.[recType] = s.[recType]
	)
WHEN MATCHED AND (
   ISNULL(t.badge,'') <> ISNULL(s.badge,'')
OR ISNULL(t.division,'') <> ISNULL(s.division,'')
OR ISNULL(t.employeePosition,'') <> ISNULL(s.employeePosition,'')
OR ISNULL(t.employeeClass,'') <> ISNULL(s.employeeClass,'')
OR ISNULL(t.[status],'') <> ISNULL(s.[status],'')
OR ISNULL(t.dateEnd,'1/1/1900') <> ISNULL(s.dateEnd,'1/1/1900')
OR ISNULL(t.stampDate,'1/1/1900') <> ISNULL(s.stampDate,'1/1/1900')
OR ISNULL(t.stampUser,'') <> ISNULL(s.stampUser,'')
OR ISNULL(t.dateSeniority,'1/1/1900') <> ISNULL(s.dateSeniority,'1/1/1900')
OR ISNULL(t.lottery,0) <> ISNULL(s.lottery,0)
OR ISNULL(t.proximity,'') <> ISNULL(s.proximity,'')
OR ISNULL(t.statusFlags,0) <> ISNULL(s.statusFlags,0)
OR ISNULL(t.craft,'') <> ISNULL(s.craft,'')
OR ISNULL(t.jobTitle,'') <> ISNULL(s.jobTitle,'')
OR ISNULL(t.subDivision,'') <> ISNULL(s.subDivision,'')
OR ISNULL(t.followUpDate,'1/1/1900') <> ISNULL(s.followUpDate,'1/1/1900')
OR ISNULL(t.statusDetail,'') <> ISNULL(s.statusDetail,'')
OR ISNULL(t.comment,'') <> ISNULL(s.comment,'')
OR ISNULL(t.department,'') <> ISNULL(s.department,''))
THEN UPDATE SET t.emp_SID = s.emp_SID
	,t.dateEffective = s.dateEffective
	,t.recType = s.recType
	,t.badge = s.badge
	,t.division = s.division
	,t.employeePosition = s.employeePosition
	,t.employeeClass = s.employeeClass
	,t.[status] = s.status
	,t.dateEnd = s.dateEnd
	,t.stampDate = s.stampDate
	,t.stampUser = s.stampUser
	,t.dateSeniority = s.dateSeniority
	,t.lottery = s.lottery
	,t.proximity = s.proximity
	,t.statusFlags = s.statusFlags
	,t.craft = s.craft
	,t.jobTitle = s.jobTitle
	,t.subDivision = s.subDivision
	,t.followUpDate = s.followUpDate
	,t.statusDetail = s.statusDetail
	,t.comment = s.comment
	,t.department = s.department
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
emp_SID
,dateEffective
,recType
,badge
,division
,employeePosition
,employeeClass
,status
,dateEnd
,stampDate
,stampUser
,dateSeniority
,lottery
,proximity
,statusFlags
,craft
,jobTitle
,subDivision
,followUpDate
,statusDetail
,comment
,department
)
VALUES
(s.emp_SID, s.dateEffective, s.recType, s.badge, s.division, s.employeePosition, s.employeeClass, s.status, s.dateEnd, s.stampDate, s.stampUser, s.dateSeniority, s.lottery, s.proximity, s.statusFlags, s.craft, s.jobTitle, s.subDivision, s.followUpDate, s.statusDetail, s.comment, s.department)
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action INTO @outputTbl;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_employeeStatus'

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
'ltd_dw.ops.employeeStatus',
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
