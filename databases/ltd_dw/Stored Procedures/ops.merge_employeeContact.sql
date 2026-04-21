SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [ops].[merge_employeeContact]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-02-26
 purpose	:  merge ops.employeeContact from ltd-ops.midas.dbo.employeeContact
 use		:  exec ops.merge_employeeContact


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


MERGE ltd_dw.ops.employeeContact AS t
USING [LTD-OPS].midas.[dbo].[employeeContact] AS s
ON (t.emp_SID = s.emp_SID
AND t.contact_seq = s.contact_seq)
WHEN MATCHED AND 
(  ISNULL(t.beginDate,'1900-01-01') <> ISNULL(s.beginDate,'1900-01-01')
OR ISNULL(t.endDate,'1900-01-01') <> ISNULL(s.endDate,'1900-01-01')
OR ISNULL(t.contactRelation,'') <> ISNULL(s.contactRelation COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.contactName,'') <> ISNULL(s.contactName COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.streetAddress,'') <> ISNULL(s.streetAddress COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.state,'') <> ISNULL(s.state COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.zipCode,'') <> ISNULL(s.zipCode COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.phoneNum1,'') <> ISNULL(s.phoneNum1 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.phoneType1,'') <> ISNULL(s.phoneType1 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.phoneNum2,'') <> ISNULL(s.phoneNum2 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.phoneType2,'') <> ISNULL(s.phoneType2 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.phoneNum3,'') <> ISNULL(s.phoneNum3 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.phoneType3,'') <> ISNULL(s.phoneType3 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.phoneNum4,'') <> ISNULL(s.phoneNum4 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.phoneType4,'') <> ISNULL(s.phoneType4 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.comments,'') <> ISNULL(s.comments COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.contactFlags,0) <> ISNULL(s.contactFlags,0)
OR ISNULL(t.city,'') <> ISNULL(s.city COLLATE SQL_Latin1_General_CP850_CI_AS,'')
	) 
THEN UPDATE SET t.beginDate = s.beginDate
		,t.endDate = s.endDate
		,t.contactRelation = s.contactRelation
		,t.contactName = s.contactName
		,t.streetAddress = s.streetAddress
		,t.state = s.state
		,t.zipCode = s.zipCode
		,t.phoneNum1 = s.phoneNum1
		,t.phoneType1 = s.phoneType1
		,t.phoneNum2 = s.phoneNum2
		,t.phoneType2 = s.phoneType2
		,t.phoneNum3 = s.phoneNum3
		,t.phoneType3 = s.phoneType3
		,t.phoneNum4 = s.phoneNum4
		,t.phoneType4 = s.phoneType4
		,t.comments = s.comments
		,t.contactFlags = s.contactFlags
		,t.city = s.city
		,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
emp_SID
,contact_seq
,beginDate
,endDate
,contactRelation
,contactName
,streetAddress
,state
,zipCode
,phoneNum1
,phoneType1
,phoneNum2
,phoneType2
,phoneNum3
,phoneType3
,phoneNum4
,phoneType4
,comments
,contactFlags
,city
)
VALUES
(s.emp_SID, s.contact_seq, s.beginDate, s.endDate, s.contactRelation, s.contactName, s.streetAddress, s.state, s.zipCode, s.phoneNum1, s.phoneType1, s.phoneNum2, s.phoneType2, s.phoneNum3, s.phoneType3, s.phoneNum4, s.phoneType4, s.comments, s.contactFlags, s.city)
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action INTO @outputTbl;


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_employeeContact'

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
'ltd_dw.ops.employeeContact',
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
