SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [cits].[merge_cits_input]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  B. Eichberger
 created dt	:  2024-12-16
 purpose	:  merge cits staging data into cits_input
 use		:  exec cits.merge_cits_input

 */

SET NOCOUNT ON;

DECLARE @SPROC VARCHAR(100);
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID);


INSERT INTO dba.[aud].[Object_Activity]([server_name], [database_name], [host_name], [System_User], [object_name], [client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write], [most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(), HOST_NAME(), SYSTEM_USER, @SPROC, client_net_address, local_net_address, auth_scheme, last_read, last_write, most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections
WHERE session_id=@@SPID;


BEGIN TRY

DECLARE @sdt DATETIME2 = SYSDATETIME();
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

DROP TABLE IF EXISTS #citsload

SELECT [ID]
      ,[Received by Number]
      ,[Type]
      ,[Customer Last Name]
      ,[Customer First Name]
      ,[Home Phone]
      ,CASE WHEN ISDATE([Date Of Incident])=1 THEN CAST([Date Of Incident] AS DATETIME2) END [Date Of Incident]
      ,CASE WHEN ISDATE([Time of Incident])=1 THEN CAST([Time of Incident] AS DATETIME) END [Time of Incident]
      ,[Direction of Travel]
      ,[Location Street]
      ,[Location Cross Street]
      ,[Route Number]
      ,[Bus Number]
      ,[Employee Number]
      ,[Department Code]
      ,[Staff Number]
      ,[Call Back]
      ,[Nature of Incident]
      ,CAST([Employee Description] AS NVARCHAR(max)) [Employee Description]
      ,CAST([Customer Comments] AS NVARCHAR(max)) [Customer Comments]
      ,CAST([Employee Comments] AS NVARCHAR(max)) [Employee Comments]
      ,CAST([Staff Comments] AS NVARCHAR(max)) [Staff Comments]
      ,CASE WHEN ISDATE([Date of Staff Comments])=1 THEN CAST([Date of Staff Comments] AS DATETIME) end [Date of Staff Comments]
      ,CASE WHEN ISDATE([Date Entered])=1 THEN CAST([Date Entered] AS DATETIME) END [Date Entered]
      ,CASE WHEN ISDATE([Given to Supervisor])=1 THEN CAST([Given to Supervisor] AS DATETIME) END [Given to Supervisor]
      ,[NOC]
	  ,[Ridesource]
	  ,[FileSource]
	  ,[record_updated_by]
	  ,[record_updated_dt] = CAST(CASE WHEN [record_updated_dt] = '1753-01-01 00:00:00.000' THEN NULL ELSE [record_updated_dt] END AS DATETIME)
INTO #citsload
FROM [ltd_dw].[cits].[stage_CITS_Input]
order by record_updated_dt

MERGE cits.[CITS_Input] AS t
USING #citsload AS s
ON (t.[ID] = s.[ID]
)
WHEN MATCHED AND (
		ISNULL(t.[Received by Number], '') <> ISNULL(s.[Received by Number], '')
		OR ISNULL(t.[Type], '') <> ISNULL(s.[Type], '')
		OR ISNULL(t.[Customer Last Name], '') <> ISNULL(s.[Customer Last Name], '')
		OR ISNULL(t.[Customer First Name], '') <> ISNULL(s.[Customer First Name], '')
		OR ISNULL(t.[Home Phone], '') <> ISNULL(s.[Home Phone], '')
		OR ISNULL(t.[Date Of Incident], '1/1/1900') <> ISNULL(s.[Date Of Incident], '1/1/1900')
		OR ISNULL(t.[Time of Incident], '1/1/1900') <> ISNULL(s.[Time of Incident], '1/1/1900')
		OR ISNULL(t.[Direction of Travel], '') <> ISNULL(s.[Direction of Travel], '')
		OR ISNULL(t.[Location Street], '') <> ISNULL(s.[Location Street], '')
		OR ISNULL(t.[Location Cross Street], '') <> ISNULL(s.[Location Cross Street], '')
		OR ISNULL(t.[Route Number], '') <> ISNULL(s.[Route Number], '')
		OR ISNULL(t.[Bus Number], 0) <> ISNULL(s.[Bus Number], 0)
		OR ISNULL(t.[Employee Number], '') <> ISNULL(s.[Employee Number], '')
		OR ISNULL(t.[Department Code], '') <> ISNULL(s.[Department Code], '')
		OR ISNULL(t.[Staff Number], '') <> ISNULL(s.[Staff Number], '')
		OR ISNULL(t.[Call Back], 0) <> ISNULL(s.[Call Back], 0)
		OR ISNULL(t.[Nature of Incident], '') <> ISNULL(s.[Nature of Incident], '')
		OR ISNULL(t.[Employee Description], '') <> ISNULL(s.[Employee Description], '')
		OR ISNULL(t.[Customer Comments], '') <> ISNULL(s.[Customer Comments], '')
		OR ISNULL(t.[Employee Comments], '') <> ISNULL(s.[Employee Comments], '')
		OR ISNULL(t.[Staff Comments], '') <> ISNULL(s.[Staff Comments], '')
		OR ISNULL(t.[Date of Staff Comments], '1/1/1900') <> ISNULL(s.[Date of Staff Comments], '1/1/1900')
		OR ISNULL(t.[Date Entered], '1/1/1900') <> ISNULL(s.[Date Entered], '1/1/1900')
		OR ISNULL(t.[Given to Supervisor], '1/1/1900') <> ISNULL(s.[Given to Supervisor], '1/1/1900')
		OR ISNULL(t.[NOC], 0) <> ISNULL(s.[NOC], 0)
		OR ISNULL(t.[Ridesource], 0) <> ISNULL(s.Ridesource,0)
		OR ISNULL(t.cits_last_updated_dt, '1/1/2199') <> ISNULL(s.record_updated_dt, '1/1/2199')
		OR ISNULL(t.cits_last_updated_by, '') <> ISNULL(s.record_updated_by, '')
	)
THEN UPDATE SET 
 t.[Received by Number] = s.[Received by Number]
,t.[Type] = s.[Type]
,t.[Customer Last Name] = s.[Customer Last Name]
,t.[Customer First Name] = s.[Customer First Name]
,t.[Home Phone] = s.[Home Phone]
,t.[Date Of Incident] = s.[Date Of Incident]
,t.[Time of Incident] = s.[Time of Incident]
,t.[Direction of Travel] = s.[Direction of Travel]
,t.[Location Street] = s.[Location Street]
,t.[Location Cross Street] = s.[Location Cross Street]
,t.[Route Number] = s.[Route Number]
,t.[Bus Number] = s.[Bus Number]
,t.[Employee Number] = s.[Employee Number]
,t.[Department Code] = s.[Department Code]
,t.[Staff Number] = s.[Staff Number]
,t.[Call Back] = s.[Call Back]
,t.[Nature of Incident] = s.[Nature of Incident]
,t.[Employee Description] = s.[Employee Description]
,t.[Customer Comments] = s.[Customer Comments]
,t.[Employee Comments] = s.[Employee Comments]
,t.[Staff Comments] = s.[Staff Comments]
,t.[Date of Staff Comments] = s.[Date of Staff Comments]
,t.[Date Entered] = s.[Date Entered]
,t.[Given to Supervisor] = s.[Given to Supervisor]
,t.[NOC] = s.[NOC]
,t.[Ridesource] = s.[Ridesource]
,t.[FileSource] = s.[FileSource]
,t.cits_last_updated_dt = s.record_updated_dt
,t.cits_last_updated_by = s.record_updated_by
,t.record_updated_date = SYSDATETIME()
,t.record_update_count = ISNULL(record_update_count,0) + 1
WHEN NOT MATCHED BY TARGET
	THEN INSERT
		 (   [ID]
			,[Received by Number]
			,[Type]
			,[Customer Last Name]
			,[Customer First Name]
			,[Home Phone]
			,[Date Of Incident]
			,[Time of Incident]
			,[Direction of Travel]
			,[Location Street]
			,[Location Cross Street]
			,[Route Number]
			,[Bus Number]
			,[Employee Number]
			,[Department Code]
			,[Staff Number]
			,[Call Back]
			,[Nature of Incident]
			,[Employee Description]
			,[Customer Comments]
			,[Employee Comments]
			,[Staff Comments]
			,[Date of Staff Comments]
			,[Date Entered]
			,[Given to Supervisor]
			,FileSource
			,NOC
			,Ridesource
			,cits_last_updated_dt
			,cits_last_updated_by
		 )
VALUES
(s.ID, s.[Received by Number], s.[Type], s.[Customer Last Name], s.[Customer First Name], s.[Home Phone], s.[Date Of Incident], s.[Time of Incident], s.[Direction of Travel], s.[Location Street], s.[Location Cross Street], s.[Route Number], s.[Bus Number], s.[Employee Number], s.[Department Code], s.[Staff Number], s.[Call Back], s.[Nature of Incident]
, s.[Employee Description], s.[Customer Comments], s.[Employee Comments], s.[Staff Comments], s.[Date of Staff Comments], s.[Date Entered], s.[Given to Supervisor],s.FileSource, s.NOC, s.Ridesource, s.record_updated_dt, s.record_updated_by)
OUTPUT $action INTO @outputTbl;

DECLARE @ins INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'INSERT');
DECLARE @upd INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'UPDATE');
DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.cits.merge_cits_input';



	
INSERT process.MergeLogs
(
	[MergeCode]
   ,[ObjectDestination]
   ,[ObjectSource]
   ,[ObjectProgram]
   ,[recInsert]
   ,[recUpdate]
   ,[recDelete]
   ,[MergeBeginDatetime]
   ,[MergeEndDatetime]
)
SELECT 'CIIN'
,'ltd_dw.cits.cits_input'
,'CITS'
,@prg
,ISNULL(@ins, 0)
,ISNULL(@upd, 0)
,0
,@sdt
,SYSDATETIME();



END TRY
BEGIN CATCH

DECLARE @profile VARCHAR(255) =
		(
			SELECT [name] FROM msdb.dbo.sysmail_profile
		);
DECLARE @errormsg VARCHAR(MAX)
,@error INT
,@message VARCHAR(MAX)
,@xstate INT
,@errsev INT
,@sub VARCHAR(255);

SELECT @error = ERROR_NUMBER()
,@errsev = ERROR_SEVERITY()
,@message = ERROR_MESSAGE()
,@xstate = XACT_STATE();

SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

SELECT @sub = 'ERROR: ' + @SPROC;

EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
,@recipients = 'barb.eichberger@ltd.org'
,@subject = @sub
,@body = @errormsg;

RAISERROR(@errormsg, @errsev, 1);
END CATCH;
GO
