SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    PROCEDURE [ops].[merge_codes]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  2024-02-26
 purpose	:  merge ops.code from ltd-ops.midas.dbo.code
 use		:  exec ops.merge_codes

 updated by : Sopheap Suy
 updated dt : 2024-09-05
 purpose	: update collation to SQL_Latin1_General_CP1_CI_AS for ops.codes table

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

DROP TABLE IF EXISTS #opscodes

SELECT codeType  COLLATE SQL_Latin1_General_CP1_CI_AS codeType
	,codeSet   COLLATE SQL_Latin1_General_CP1_CI_AS codeSet
	,codeValue COLLATE SQL_Latin1_General_CP1_CI_AS codeValue
	,[description] COLLATE SQL_Latin1_General_CP1_CI_AS  [description]
	,basicflags		
	,flagset1
	,flagset2
	,flagset3
	,flagset4
	,smallint1
	,smallint2
	,smallint3
	,smallint4
	,smallint5
	,smallint6
	,smallint7
	,smallint8
	,int1
	,int2
	,onechar1	COLLATE SQL_Latin1_General_CP1_CI_AS onechar1
	,onechar2	COLLATE SQL_Latin1_General_CP1_CI_AS onechar2
	,onechar3	COLLATE SQL_Latin1_General_CP1_CI_AS onechar3
	,onechar4	COLLATE SQL_Latin1_General_CP1_CI_AS onechar4
	,fourchar1	COLLATE SQL_Latin1_General_CP1_CI_AS fourchar1
	,fourchar2	COLLATE SQL_Latin1_General_CP1_CI_AS fourchar2
	,fourchar3	COLLATE SQL_Latin1_General_CP1_CI_AS fourchar3
	,fourchar4	COLLATE SQL_Latin1_General_CP1_CI_AS fourchar4
	,fourchar5	COLLATE SQL_Latin1_General_CP1_CI_AS fourchar5
	,fourchar6	COLLATE SQL_Latin1_General_CP1_CI_AS fourchar6
	,fourchar7	COLLATE SQL_Latin1_General_CP1_CI_AS fourchar7
	,fourchar8	COLLATE SQL_Latin1_General_CP1_CI_AS fourchar8
	,codevarchar COLLATE SQL_Latin1_General_CP1_CI_AS codevarchar
	,modStampUser COLLATE SQL_Latin1_General_CP1_CI_AS  modStampUser
INTO #opscodes
FROM [LTD-OPS].midas.[dbo].[codes]


MERGE ltd_dw.ops.codes AS t
USING #opscodes AS s
ON (t.codeType   = s.codeType 
AND t.codeSet    = s.codeSet  
AND t.codeValue  = s.codeValue  )
WHEN MATCHED AND 
(ISNULL(t.[description],'') <> ISNULL(s.[description] ,'')
OR ISNULL(t.basicflags,0) <> ISNULL(s.basicflags,0)
OR ISNULL(t.flagset1,0) <> ISNULL(s.flagset1,0)
OR ISNULL(t.flagset2,0) <> ISNULL(s.flagset2,0)
OR ISNULL(t.flagset3,0) <> ISNULL(s.flagset3,0)
OR ISNULL(t.flagset4,0) <> ISNULL(s.flagset4,0)
OR ISNULL(t.smallint1,0) <> ISNULL(s.smallint1,0)
OR ISNULL(t.smallint2,0) <> ISNULL(s.smallint2,0)
OR ISNULL(t.smallint3,0) <> ISNULL(s.smallint3,0)
OR ISNULL(t.smallint4,0) <> ISNULL(s.smallint4,0)
OR ISNULL(t.smallint5,0) <> ISNULL(s.smallint5,0)
OR ISNULL(t.smallint6,0) <> ISNULL(s.smallint6,0)
OR ISNULL(t.smallint7,0) <> ISNULL(s.smallint7,0)
OR ISNULL(t.smallint8,0) <> ISNULL(s.smallint8,0)
OR ISNULL(t.int1,0) <> ISNULL(s.int1,0)
OR ISNULL(t.int2,0) <> ISNULL(s.int2,0)
OR ISNULL(t.onechar1,'') <> ISNULL(s.onechar1 ,'')
OR ISNULL(t.onechar2,'') <> ISNULL(s.onechar2 ,'')
OR ISNULL(t.onechar3,'') <> ISNULL(s.onechar3 ,'')
OR ISNULL(t.onechar4,'') <> ISNULL(s.onechar4 ,'')
OR ISNULL(t.fourchar1,'') <> ISNULL(s.fourchar1 ,'')
OR ISNULL(t.fourchar2,'') <> ISNULL(s.fourchar2 ,'')
OR ISNULL(t.fourchar3,'') <> ISNULL(s.fourchar3 ,'')
OR ISNULL(t.fourchar4,'') <> ISNULL(s.fourchar4 ,'')
OR ISNULL(t.fourchar5,'') <> ISNULL(s.fourchar5 ,'')
OR ISNULL(t.fourchar6,'') <> ISNULL(s.fourchar6 ,'')
OR ISNULL(t.fourchar7,'') <> ISNULL(s.fourchar7 ,'')
OR ISNULL(t.fourchar8,'') <> ISNULL(s.fourchar8 ,'')
OR ISNULL(t.codevarchar,'') <> ISNULL(s.codevarchar  ,'')
OR ISNULL(t.modStampUser,'') <> ISNULL(s.modStampUser,''))
THEN UPDATE SET t.[description] = s.[description]
	,t.basicflags = s.basicflags
	,t.flagset1 = s.flagset1
	,t.flagset2 = s.flagset2
	,t.flagset3 = s.flagset3
	,t.flagset4 = s.flagset4
	,t.smallint1 = s.smallint1
	,t.smallint2 = s.smallint2
	,t.smallint3 = s.smallint3
	,t.smallint4 = s.smallint4
	,t.smallint5 = s.smallint5
	,t.smallint6 = s.smallint6
	,t.smallint7 = s.smallint7
	,t.smallint8 = s.smallint8
	,t.int1 = s.int1
	,t.int2 = s.int2
	,t.onechar1 = s.onechar1
	,t.onechar2 = s.onechar2
	,t.onechar3 = s.onechar3
	,t.onechar4 = s.onechar4
	,t.fourchar1 = s.fourchar1
	,t.fourchar2 = s.fourchar2
	,t.fourchar3 = s.fourchar3
	,t.fourchar4 = s.fourchar4
	,t.fourchar5 = s.fourchar5
	,t.fourchar6 = s.fourchar6
	,t.fourchar7 = s.fourchar7
	,t.fourchar8 = s.fourchar8
	,t.codevarchar = s.codevarchar
	,t.modStampUser = s.modStampUser
	,t.record_updated_date = SYSDATETIME()
WHEN NOT MATCHED BY TARGET THEN INSERT (
codeType
,codeSet
,codeValue
,[description]
,basicflags
,flagset1
,flagset2
,flagset3
,flagset4
,smallint1
,smallint2
,smallint3
,smallint4
,smallint5
,smallint6
,smallint7
,smallint8
,int1
,int2
,onechar1
,onechar2
,onechar3
,onechar4
,fourchar1
,fourchar2
,fourchar3
,fourchar4
,fourchar5
,fourchar6
,fourchar7
,fourchar8
,codevarchar
,modStampUser
)
VALUES
(s.codeType, s.codeSet, s.codeValue, s.[description], s.basicflags, s.flagset1, s.flagset2, s.flagset3, s.flagset4, s.smallint1, s.smallint2, s.smallint3, s.smallint4, s.smallint5, s.smallint6, s.smallint7, s.smallint8, s.int1, s.int2, s.onechar1, s.onechar2, s.onechar3, s.onechar4, s.fourchar1, s.fourchar2, s.fourchar3, s.fourchar4, s.fourchar5, s.fourchar6, s.fourchar7, s.fourchar8, s.codevarchar, s.modStampUser)
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action INTO @outputTbl;



DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.ops.merge_codes'

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
'ltd_dw.ops.codes',
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
