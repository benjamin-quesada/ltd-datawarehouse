SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE     PROCEDURE [ops].[merge_operators_summarized_paycode_info]
AS
/***********LTD_GLOSSARY***********
CREATED ON	: 2024-05-29
CREATED BY	: B. Eichberger
PURPOSE		: create data source optimize performance
		      for SSRS Summarized Pay Code Info Report
			  exec [ops].[merge_operators_summarized_paycode_info]

UPDATED ON	: 2024-09-05
UPDATED BY	: Sopheap Suy
Purpose		: remove employee data from this table

UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called 
			
UPDATED BY:	Sopheap Suy
UPDATED DT:  02/26/2026
purpose	  :  change merge on clause to include t.opDate >= @lastProcess
			*/

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@procid) + '.' + OBJECT_NAME(@@procid)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@servername, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@spid ;

BEGIN TRY

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @lastProcess smalldatetime = (SELECT DATEADD(DAY,-30,MAX([MergeBeginDatetime])) FROM process.MergeLogs WHERE [ObjectDestination] = 'ltd_dw.ops.operatorPayCodeSummary')
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));
DROP TABLE IF EXISTS wrk.opsPayCodeSumm;

drop table if exists #fcode
	SELECT cast(codeType COLLATE SQL_Latin1_General_CP1_CI_AS as varchar(4)) AS codeType, 
		   cast(codeValue COLLATE SQL_Latin1_General_CP1_CI_AS as varchar(4)) AS codeValue, 
		   feeds_attendance 
		   into #fcode
	FROM [LTD-OPS].midas.dbo.ltd_feeds_attendance_codes with (nolock) 
	WHERE feeds_attendance = 0 

create index ix_temp_fcode on #fcode (codeType, codeValue)

SELECT
    CAST(d.opDate AS DATE) opDate,
	opYearDiff = YEAR(GETDATE()) - YEAR(opdate),
	d.payType, 
	c.codeType , 
	c.codeValue , 
	c.[description]  [Description],
    ff_projectCode = ' ' + d.payType  + ' - ' + c.[description]  ,
	ff_groupby = '', 
	lastName = '', firstname = '',
	e.personnelID,
	operator_lastfirst = '', 
    f.feeds_attendance,
	SUM(d.calcTime) calcTime,
	SUM(CASE WHEN d.calcTime < 0 THEN 1 ELSE 0 END) ff_negative_calc_times ,
	ff_formattedCalcTime = SUM(d.calcTime)/3600.0
INTO wrk.opsPayCodeSumm
FROM
    ltd_dw.ops.dailyEmployeeTimeDetail d WITH (NOLOCK)
	INNER JOIN ltd_dw.ops.codes c WITH (NOLOCK) ON
        d.payType = c.codeValue 
     INNER JOIN ltd_dw.ops.employee e WITH (NOLOCK) ON
        d.emp_SID = e.emp_SID
     INNER JOIN #fcode f ON
        c.codeType  = f.codeType AND
    c.codeValue  = f.codeValue
WHERE (c.codeValue <> 'RTB' AND c.codeValue <> 'W/EO') AND
    (c.codeType <> 'RPAY' OR c.codeValue <> 'EMX') AND
    (c.codeType = 'ABAT' OR c.codeType = 'RPAY')
AND d.opdate >= @lastProcess
GROUP BY 
	CAST(d.opDate AS DATE) ,
	YEAR(GETDATE()) - YEAR(opdate),
	d.payType, 
	c.codeType, c.codeValue, c.[description],
    ' ' + d.payType  + ' - ' + c.[description],
	e.personnelID,
    f.feeds_attendance

create index ix_temp_opsPayCodeSumm 
	ON wrk.opsPayCodeSumm (personnelId,payType,codeType,codeValue,feeds_attendance,opYearDiff,[description],ff_projectCode, opDate)


MERGE ltd_dw.[ops].[operatorPayCodeSummary] AS t
USING wrk.opsPayCodeSumm as s
ON (t.opDate = s.opDate
	AND t.personnelID = s.personnelID
	AND t.payType = s.payType
	AND t.codeType = s.codeType 
	AND t.codeValue = s.codeValue 
	AND t.feeds_attendance = s.feeds_attendance
	AND t.opYearDiff = s.opYearDiff
	AND t.[description] = s.[description] 
	AND t.ff_projectCode = s.ff_projectCode 
	AND t.opDate >= @lastProcess
)
WHEN MATCHED AND (
   ISNULL(t.calcTime,0) <> ISNULL(s.calcTime,0) 
OR ISNULL(t.ff_negative_calc_times,0) <> ISNULL(s.ff_negative_calc_times,0)
OR ISNULL(t.ff_formattedCalcTime,0) <> ISNULL(s.ff_formattedCalcTime,0) 
)
THEN UPDATE SET t.calcTime = s.calcTime
	,t.ff_negative_calc_times = s.ff_negative_calc_times
	,t.ff_formattedCalcTime = s.ff_formattedCalcTime
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
opDate
,opYearDiff
,payType
,calcTime
,ff_negative_calc_times
,ff_formattedCalcTime
,codeType
,codeValue
,[description]
,ff_projectCode
,ff_groupby
,lastName
,firstName
,personnelID
,operator_lastfirst
,feeds_attendance
)
VALUES
(s.opDate, s.opYearDiff, s.payType, s.calcTime,s.ff_negative_calc_times, s.ff_formattedCalcTime, s.codeType, s.codeValue, s.description, s.ff_projectCode, s.ff_groupby, s.lastName, s.firstName, s.personnelID, s.operator_lastfirst, s.feeds_attendance)
WHEN NOT MATCHED BY SOURCE AND t.opDate >= @lastProcess THEN DELETE
OUTPUT $action INTO @outputTbl;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_operators_summarized_paycode_info'

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
SELECT 'OPSP',
'ltd_dw.ops.operatorPayCodeSummary',
'MIDAS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()

DROP TABLE IF EXISTS wrk.opsPayCodeSumm;

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
