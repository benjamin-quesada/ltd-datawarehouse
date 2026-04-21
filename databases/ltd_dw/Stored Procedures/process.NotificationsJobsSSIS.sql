SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [process].[NotificationsJobsSSIS]
 @me smallint

as

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


DECLARE @Full_ssis_command VARCHAR(4000)
	,@job_step_id INT
	,@job_step_name varchar(132)
	,@Package_name VARCHAR(4000)
	,@EMailBody NVARCHAR(2000)
	,@EMailSubject VARCHAR(150)
	,@Job_name VARCHAR(100)
	,@Job_id UNIQUEIDENTIFIER
	,@sp_sess smallint
	 
select @sp_sess = (select @@spid)

select @Job_name = (
SELECT  j.name
FROM   master.dbo.sysprocesses p
JOIN   msdb.dbo.sysjobs j ON
   master.dbo.fn_varbintohexstr(convert(varbinary(16), job_id)) COLLATE Latin1_General_CI_AI =
   substring(replace(program_name, 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34)
   where p.spid = @sp_sess)

select @Job_id = (
SELECT  j.job_id
FROM   master.dbo.sysprocesses p
JOIN   msdb.dbo.sysjobs j ON
   master.dbo.fn_varbintohexstr(convert(varbinary(16), job_id)) COLLATE Latin1_General_CI_AI =
   substring(replace(program_name, 'SQLAgent - TSQL JobStep (Job ', ''), 1, 34)
where p.spid = @sp_sess)


select @job_step_name = (
SELECT Step
FROM msdb.dbo.sysjobs j
INNER JOIN (
	SELECT DISTINCT Job_Id = left(intr1, charindex(':', intr1) - 1)
		,Step = substring(intr1, charindex(':', intr1) + 1, charindex(')', intr1) - charindex(':', intr1) - 1)
		,SessionId = @sp_sess
	-- select * 
	FROM master.dbo.sysprocesses x
	CROSS APPLY (
		SELECT replace(x.program_name, 'SQLAgent - TSQL JobStep (Job ', '')
		) cs(intr1)
	WHERE spid > @sp_sess
		--AND x.program_name LIKE 'SQLAgent - TSQL JobStep (Job %'
	) jd ON jd.Job_Id = convert(VARCHAR(max), convert(BINARY (16), j.job_id), 1)
	)
--SELECT @Job_id = Job_id , @Job_name = [name]
--FROM msdb.sys.dm_exec_sessions AS i
--INNER JOIN msdb.dbo.sysjobs AS jobs ON jobs.job_id = Cast(Convert(BINARY (16), SUBSTRING(i.[program_name], CHARINDEX('(Job 0x', i.[program_name], 1) + 5, 34), 1) AS UNIQUEIDENTIFIER)
--WHERE 1 = 1
--	AND i.session_id = @sp_sess --63
--	--AND [program_name] IS NOT NULL
--	--AND CHARINDEX('(Job 0x', i.[program_name], 1) > 0

----print @Job_name
--IF @Job_id IS NOT NULL
--BEGIN
	

--	IF @Full_ssis_command LIKE '%.dtsx%'
--	BEGIN
--		SELECT @Package_name = RIGHT(LEFT(@Full_ssis_command, Charindex('.dtsx', @Full_ssis_command)), Charindex('\', Reverse(LEFT(@Full_ssis_command, Charindex('.dtsx', @Full_ssis_command) - 1)))) + 'dtsx'

--	SELECT TOP 1 @Job_step_id = Step_id
--	FROM msdb.dbo.sysjobhistory WITH (NOLOCK)
--	WHERE Run_status <> 1
--		AND Step_id > 0
--		AND Job_id = @Job_id
--	ORDER BY Instance_id DESC

--	SELECT @Full_ssis_command = Command
--	FROM msdb.dbo.sysjobsteps(NOLOCK)
--	WHERE Job_id = @Job_id
--		AND Step_id = @Job_step_id

--	--PRINT @Full_ssis_command

--	SELECT @EMailBody = STUFF(
--			   (SELECT ',' + LEFT(isnull(cast([Message] as nvarchar(max)),''), 2000) + ' ' 
--			   FROM SSISDB.[catalog].[Event_messages]  t1 WITH (NOLOCK)
--				WHERE t1.Package_name = t2.Package_name
--				FOR XML PATH (''))
--				, 1, 1, '') from SSISDB.[catalog].[Event_messages] t2 WITH (NOLOCK) 
--	WHERE Event_name = 'OnError'
--	AND [Package_name] = @Package_name
--	AND cast(message_time as date) >=  cast(GETDATE()-1 as date)
--	group by Package_name;

--	SELECT @emailSubject = 'Package : ' + Package_name + ' failed on :' + CONVERT(VARCHAR, Message_time) 
--		FROM SSISDB.[catalog].[Event_messages] WITH (NOLOCK)
--		WHERE 1=1
--			AND [Package_name] = @Package_name
--			AND Event_name = 'OnError'
--			AND cast(message_time as date) >=  cast(GETDATE()-1 as date)
--			AND Operation_id IN (
--				SELECT Max(Operation_id)
--				FROM SSISDB.[catalog].[Event_messages](NOLOCK)
--				WHERE [Package_name] = @Package_name
--				)
--		ORDER BY Message_time ASC

--	  	  DECLARE @profile VARCHAR(255) = (
--                    	SELECT NAME
--                    	FROM msdb.dbo.sysmail_profile
--                    	)
		
		
--		if len(isnull(@emailBody,'')) > 1
--		BEGIN
--			EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
--				,@subject = @EMailSubject
--				,@body = @EMailBody
--				,@recipients = 'barb.eichberger@ltd.org' ;
		
--		END
--		END

--ELSE
--	BEGIN
--		SELECT @Package_name = 'Other'

--	SELECT TOP 1 @Job_step_id = Step_id
--	FROM msdb.dbo.sysjobhistory WITH (NOLOCK)
--	WHERE Run_status <> 1
--		AND Step_id > 0
--		AND Job_id = @Job_id
--	ORDER BY Instance_id DESC
--	declare @full_command nvarchar(max)
--	SELECT @Full_command = Command
--	FROM msdb.dbo.sysjobsteps(NOLOCK)
--	WHERE Job_id = @Job_id
--		AND Step_id = @Job_step_id

	DECLARE @jname NVARCHAR(128)
	DECLARE @jid nvarchar(120)
	select @jid = @Job_id
	SELECT @jname =  @Job_name --(SELECT [name] FROM msdb.dbo.sysjobs WHERE job_id = @jid)
	declare @srv varchar(90) = (select @@servername)
	declare @dbname varchar(90) = (select db_name())
	declare @step varchar(90) = (select CONVERT(uniqueidentifier, '$(ESCAPE_SQUOTE(STEPNAME))'))
	declare @sub varchar(120) = 'Error Notification: ' + @jname 
	declare @msg varchar(max) =  'Server: '+  QUOTENAME(@srv,'''') + '
DB: '+@dbname+', 
Job Name: ' +isnull(@jname,'')+'
Step Name: ' +isnull(@step,'')

	EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'SQLData',
			@recipients = 'barb.eichberger@ltd.org',
			@subject = @sub,
			@body = @msg ;
	--END

--END

GO
