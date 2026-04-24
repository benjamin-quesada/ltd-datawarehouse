SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [eam].[get_eam_date_activity]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-02-26
 purpose	:  get new data from [LTD-EAM].[ltd_db].dbo.[EAM_ALL_DATE_ACTIVITY_STAGE]
 use		:  exec [eam].[get_eam_date_activity]

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
	
SELECT s.work_order_yr 
	  ,s.work_order_no 
	  ,label_name = s.label_name COLLATE SQL_Latin1_General_CP1_CI_AS 
	  ,s.the_date 
	  ,task_task_code = s.task_task_code COLLATE SQL_Latin1_General_CP1_CI_AS 
	  ,part_part_no
	  ,part_suffix
	  ,eq_equip_no = s.eq_equip_no  COLLATE SQL_Latin1_General_CP1_CI_AS 
	  INTO #loadValues
	  FROM [LTD-EAM].[ltd_db].dbo.[EAM_ALL_DATE_ACTIVITY_STAGE] AS s 
WHERE NOT EXISTS (SELECT 1 FROM eam.[EAM_ALL_DATE_ACTIVITY]
				  WHERE work_order_yr = s.work_order_yr 
				  AND work_order_no = s.work_order_no 
				  AND label_name = s.label_name COLLATE SQL_Latin1_General_CP1_CI_AS 
				  AND the_date = s.the_date 
				  AND ISNULL(task_task_code,'') = ISNULL(s.task_task_code,'') COLLATE SQL_Latin1_General_CP1_CI_AS 
				  AND ISNULL(part_part_no,'') = ISNULL(s.part_part_no,'') COLLATE SQL_Latin1_General_CP1_CI_AS 
				  AND ISNULL(part_suffix,'') = ISNULL(s.part_suffix,'') COLLATE SQL_Latin1_General_CP1_CI_AS 
				  AND eq_equip_no = s.eq_equip_no COLLATE SQL_Latin1_General_CP1_CI_AS )
	  
INSERT eam.[EAM_ALL_DATE_ACTIVITY]
(work_order_yr
,work_order_no
,label_name
,the_date
,task_task_code
,part_part_no
,part_suffix
,eq_equip_no)
OUTPUT 'INSERT' INTO @outputTbl
SELECT DISTINCT work_order_yr
	  ,work_order_no
	  ,label_name
	  ,the_date
	  ,task_task_code
	  ,part_part_no
	  ,part_suffix
	  ,eq_equip_no FROM #loadValues

DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.eam.get_eam_date_activity'

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
select 'EAMA',
'ltd_dw.eam.EAM_ALL_DATE_ACTIVITY',
'EAM',
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
