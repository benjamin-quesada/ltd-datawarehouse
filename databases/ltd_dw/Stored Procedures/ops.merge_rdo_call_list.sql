SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [ops].[merge_rdo_call_list]
AS
/*-----------LTD_GLOSSARY---------------
created by	:  b. eichberger
created dt	:  2024-04-09
purpose	:  merge ltd_dw.ops.rdo_call_list_full from [LTD-OPS].midas.dbo.ltd_rdo_call_list_full
use		:  exec ops.merge_rdo_call_list

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

DROP TABLE IF EXISTS wrk.temp_rdoCall;

CREATE TABLE [wrk].[temp_rdoCall](
	[operator] [varchar](67) NULL,
	[opdate] [date] NULL,
	[sen_date] [smalldatetime] NOT NULL,
	[sen_lot] [int] NULL,
	[fone1] [varchar](14) NULL,
	[fonehome] [varchar](20) NOT NULL,
	[fonecell] [varchar](20) NOT NULL,
	[work] [varchar](4) NOT NULL,
	[absence] [char](1) NULL,
	[worked] [char](1) NULL,
	[week] [varchar](4) NOT NULL,
	[dnc] [varchar](4) NOT NULL,
	[opdate_m13] [date] NULL,
	[work_m13] [varchar](4) NOT NULL,
	[opdate_m12] [date] NULL,
	[work_m12] [varchar](4) NOT NULL,
	[opdate_m11] [date] NULL,
	[work_m11] [varchar](4) NOT NULL,
	[opdate_m10] [date] NULL,
	[work_m10] [varchar](4) NOT NULL,
	[opdate_m09] [date] NULL,
	[work_m09] [varchar](4) NOT NULL,
	[opdate_m08] [date] NULL,
	[work_m08] [varchar](4) NOT NULL,
	[opdate_m07] [date] NULL,
	[work_m07] [varchar](4) NOT NULL,
	[opdate_m06] [date] NULL,
	[work_m06] [varchar](4) NOT NULL,
	[opdate_m05] [date] NULL,
	[work_m05] [varchar](4) NOT NULL,
	[opdate_m04] [date] NULL,
	[work_m04] [varchar](4) NOT NULL,
	[opdate_m03] [date] NULL,
	[work_m03] [varchar](4) NOT NULL,
	[opdate_m02] [date] NULL,
	[work_m02] [varchar](4) NOT NULL,
	[opdate_m01] [date] NULL,
	[work_m01] [varchar](4) NOT NULL,
	[opdate_p01] [date] NULL,
	[work_p01] [varchar](4) NOT NULL,
	[opdate_p02] [date] NULL,
	[work_p02] [varchar](4) NOT NULL,
	[opdate_p03] [date] NULL,
	[work_p03] [varchar](4) NOT NULL
) ON [PRIMARY]
;

INSERT wrk.temp_rdoCall([operator]
      ,[opdate]
      ,[sen_date]
      ,[sen_lot]
      ,[fone1]
      ,[fonehome]
      ,[fonecell]
      ,[work]
      ,[absence]
      ,[worked]
      ,[week]
      ,[dnc]
      ,[opdate_m13]
      ,[work_m13]
      ,[opdate_m12]
      ,[work_m12]
      ,[opdate_m11]
      ,[work_m11]
      ,[opdate_m10]
      ,[work_m10]
      ,[opdate_m09]
      ,[work_m09]
      ,[opdate_m08]
      ,[work_m08]
      ,[opdate_m07]
      ,[work_m07]
      ,[opdate_m06]
      ,[work_m06]
      ,[opdate_m05]
      ,[work_m05]
      ,[opdate_m04]
      ,[work_m04]
      ,[opdate_m03]
      ,[work_m03]
      ,[opdate_m02]
      ,[work_m02]
      ,[opdate_m01]
      ,[work_m01]
      ,[opdate_p01]
      ,[work_p01]
      ,[opdate_p02]
      ,[work_p02]
      ,[opdate_p03]
      ,[work_p03])
SELECT [operator]
      ,[opdate]
      ,[sen_date]
      ,[sen_lot]
      ,[fone1]
      ,[fonehome]
      ,[fonecell]
      ,[work]
      ,[absence]
      ,[worked]
      ,[week]
      ,[dnc]
      ,[opdate_m13]
      ,[work_m13]
      ,[opdate_m12]
      ,[work_m12]
      ,[opdate_m11]
      ,[work_m11]
      ,[opdate_m10]
      ,[work_m10]
      ,[opdate_m09]
      ,[work_m09]
      ,[opdate_m08]
      ,[work_m08]
      ,[opdate_m07]
      ,[work_m07]
      ,[opdate_m06]
      ,[work_m06]
      ,[opdate_m05]
      ,[work_m05]
      ,[opdate_m04]
      ,[work_m04]
      ,[opdate_m03]
      ,[work_m03]
      ,[opdate_m02]
      ,[work_m02]
      ,[opdate_m01]
      ,[work_m01]
      ,[opdate_p01]
      ,[work_p01]
      ,[opdate_p02]
      ,[work_p02]
      ,[opdate_p03]
      ,[work_p03]
  FROM [LTD-OPS].midas.dbo.ltd_rdo_call_list_full WITH (NOLOCK)

MERGE ltd_dw.ops.rdo_call_list_full AS t
USING wrk.temp_rdoCall AS s
ON (t.operator = s.operator COLLATE SQL_Latin1_General_CP850_CI_AS
 AND t.opdate = s.opdate)
WHEN MATCHED AND (
ISNULL(t.sen_date,'1/1/1900') <> ISNULL(s.sen_date,'1/1/1900')
OR ISNULL(t.sen_lot,0) <> ISNULL(s.sen_lot,0)
OR ISNULL(t.fone1,'') <> ISNULL(s.fone1 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.fonehome,'') <> ISNULL(s.fonehome,'')
OR ISNULL(t.fonecell,'') <> ISNULL(s.fonecell,'')
OR ISNULL(t.work,'') <> ISNULL(s.work COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.absence,'') <> ISNULL(s.absence COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.week,'') <> ISNULL(s.[week] COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.dnc,'') <> ISNULL(s.dnc COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m13,'1/1/1900') <> ISNULL(s.opdate_m13,'1/1/1900')
OR ISNULL(t.work_m13,'1/1/1900') <> ISNULL(s.work_m13 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m12,'1/1/1900') <> ISNULL(s.opdate_m12,'1/1/1900')
OR ISNULL(t.work_m12,'1/1/1900') <> ISNULL(s.work_m12 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m11,'1/1/1900') <> ISNULL(s.opdate_m11,'1/1/1900')
OR ISNULL(t.work_m11,'1/1/1900') <> ISNULL(s.work_m11 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m10,'1/1/1900') <> ISNULL(s.opdate_m10,'1/1/1900')
OR ISNULL(t.work_m10,'1/1/1900') <> ISNULL(s.work_m10 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m09,'1/1/1900') <> ISNULL(s.opdate_m09,'1/1/1900')
OR ISNULL(t.work_m09,'1/1/1900') <> ISNULL(s.work_m09 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m08,'1/1/1900') <> ISNULL(s.opdate_m08,'1/1/1900')
OR ISNULL(t.work_m08,'1/1/1900') <> ISNULL(s.work_m08 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m07,'1/1/1900') <> ISNULL(s.opdate_m07,'1/1/1900')
OR ISNULL(t.work_m07,'1/1/1900') <> ISNULL(s.work_m07 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m06,'1/1/1900') <> ISNULL(s.opdate_m06,'1/1/1900')
OR ISNULL(t.work_m06,'1/1/1900') <> ISNULL(s.work_m06 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m05,'1/1/1900') <> ISNULL(s.opdate_m05,'1/1/1900')
OR ISNULL(t.work_m05,'1/1/1900') <> ISNULL(s.work_m05 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m04,'1/1/1900') <> ISNULL(s.opdate_m04,'1/1/1900')
OR ISNULL(t.work_m04,'1/1/1900') <> ISNULL(s.work_m04 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m03,'1/1/1900') <> ISNULL(s.opdate_m03,'1/1/1900')
OR ISNULL(t.work_m03,'1/1/1900') <> ISNULL(s.work_m03 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m02,'1/1/1900') <> ISNULL(s.opdate_m02,'1/1/1900')
OR ISNULL(t.work_m02,'1/1/1900') <> ISNULL(s.work_m02 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_m01,'1/1/1900') <> ISNULL(s.opdate_m01,'1/1/1900')
OR ISNULL(t.work_m01,'1/1/1900') <> ISNULL(s.work_m01 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_p01,'1/1/1900') <> ISNULL(s.opdate_p01,'1/1/1900')
OR ISNULL(t.work_p01,'1/1/1900') <> ISNULL(s.work_p01 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_p02,'1/1/1900') <> ISNULL(s.opdate_p02,'1/1/1900')
OR ISNULL(t.work_p02,'1/1/1900') <> ISNULL(s.work_p02 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
OR ISNULL(t.opdate_p03,'1/1/1900') <> ISNULL(s.opdate_p03,'1/1/1900')
OR ISNULL(t.work_p03,'1/1/1900') <> ISNULL(s.work_p03 COLLATE SQL_Latin1_General_CP850_CI_AS,'')
)
THEN  UPDATE SET t.operator = s.operator,
               t.opdate = s.opdate,
               t.sen_date = s.sen_date,
               t.sen_lot = s.sen_lot,
               t.fone1 = s.fone1,
               t.fonehome = s.fonehome,
               t.fonecell = s.fonecell,
               t.work = s.work,
               t.absence = s.absence,
               t.week = s.week,
               t.dnc = s.dnc,
               t.opdate_m13 = s.opdate_m13,
               t.work_m13 = s.work_m13,
               t.opdate_m12 = s.opdate_m12,
               t.work_m12 = s.work_m12,
               t.opdate_m11 = s.opdate_m11,
               t.work_m11 = s.work_m11,
               t.opdate_m10 = s.opdate_m10,
               t.work_m10 = s.work_m10,
               t.opdate_m09 = s.opdate_m09,
               t.work_m09 = s.work_m09,
               t.opdate_m08 = s.opdate_m08,
               t.work_m08 = s.work_m08,
               t.opdate_m07 = s.opdate_m07,
               t.work_m07 = s.work_m07,
               t.opdate_m06 = s.opdate_m06,
               t.work_m06 = s.work_m06,
               t.opdate_m05 = s.opdate_m05,
               t.work_m05 = s.work_m05,
               t.opdate_m04 = s.opdate_m04,
               t.work_m04 = s.work_m04,
               t.opdate_m03 = s.opdate_m03,
               t.work_m03 = s.work_m03,
               t.opdate_m02 = s.opdate_m02,
               t.work_m02 = s.work_m02,
               t.opdate_m01 = s.opdate_m01,
               t.work_m01 = s.work_m01,
               t.opdate_p01 = s.opdate_p01,
               t.work_p01 = s.work_p01,
               t.opdate_p02 = s.opdate_p02,
               t.work_p02 = s.work_p02,
               t.opdate_p03 = s.opdate_p03,
               t.work_p03 = s.work_p03,
               t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN
    INSERT
    (
        operator,
        opdate,
        sen_date,
        sen_lot,
        fone1,
        fonehome,
        fonecell,
        work,
        absence,
        week,
        dnc,
        opdate_m13,
        work_m13,
        opdate_m12,
        work_m12,
        opdate_m11,
        work_m11,
        opdate_m10,
        work_m10,
        opdate_m09,
        work_m09,
        opdate_m08,
        work_m08,
        opdate_m07,
        work_m07,
        opdate_m06,
        work_m06,
        opdate_m05,
        work_m05,
        opdate_m04,
        work_m04,
        opdate_m03,
        work_m03,
        opdate_m02,
        work_m02,
        opdate_m01,
        work_m01,
        opdate_p01,
        work_p01,
        opdate_p02,
        work_p02,
        opdate_p03,
        work_p03
    )
    VALUES
    (s.operator, s.opdate, s.sen_date, s.sen_lot, s.fone1, s.fonehome, s.fonecell, s.work,
     s.absence, s.week, s.dnc, s.opdate_m13, s.work_m13, s.opdate_m12, s.work_m12, s.opdate_m11, s.work_m11,
     s.opdate_m10, s.work_m10, s.opdate_m09, s.work_m09, s.opdate_m08, s.work_m08, s.opdate_m07, s.work_m07,
     s.opdate_m06, s.work_m06, s.opdate_m05, s.work_m05, s.opdate_m04, s.work_m04, s.opdate_m03, s.work_m03,
     s.opdate_m02, s.work_m02, s.opdate_m01, s.work_m01, s.opdate_p01, s.work_p01, s.opdate_p02, s.work_p02,
     s.opdate_p03, s.work_p03)
WHEN NOT MATCHED BY SOURCE THEN
    DELETE
OUTPUT $action INTO @outputTbl;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_rdo_call_list'

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
SELECT 'OPSC',
'ltd_dw.ops.rdo_call_list_full',
'MIDAS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()

DROP TABLE IF EXISTS wrk.temp_rdoCall

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
