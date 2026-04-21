SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [eam].[get_eam_mile_activity]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  B. Eichberger
 created dt	:  2024-09-11
 purpose	:  get new data from [LTD-EAM].[ltd_db].dbo.[EAM_ALL_MILE_ACTIVITY_STAGE]
 use		:  exec [eam].[get_eam_mile_activity]

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


SELECT label_name = s.label_name COLLATE SQL_Latin1_General_CP1_CI_AS
		, s.the_date
		, s.meter_value
		, eq_equip_no = s.eq_equip_no  COLLATE SQL_Latin1_General_CP1_CI_AS
	  INTO #loadValues
	  FROM [LTD-EAM].[ltd_db].dbo.[EAM_ALL_MILE_ACTIVITY_STAGE] AS s 
WHERE NOT EXISTS (SELECT 1 FROM eam.[EAM_ALL_MILE_ACTIVITY]
				  WHERE label_name=s.label_name COLLATE SQL_Latin1_General_CP1_CI_AS 
				  AND the_date=s.the_date 
				  AND meter_value = s.meter_value
				  AND eq_equip_no=s.eq_equip_no COLLATE SQL_Latin1_General_CP1_CI_AS )

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));
		  
INSERT eam.[EAM_ALL_MILE_ACTIVITY]
(label_name
,the_date
,meter_value
,eq_equip_no)
OUTPUT 'INSERT' INTO @outputTbl
SELECT label_name
	  ,the_date
	  ,meter_value
	  ,eq_equip_no FROM #loadValues

DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.eam.get_eam_mile_activity'

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
select 'EAMM',
'ltd_dw.eam.EAM_ALL_MILE_ACTIVITY',
'EAM',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
sysdatetime()

DROP TABLE IF EXISTS #loadValues

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
