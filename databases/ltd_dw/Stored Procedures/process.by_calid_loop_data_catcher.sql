SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [process].[by_calid_loop_data_catcher]
@calDateIn int
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


declare @lastdt date 
select @lastdt = (select isnull(calid,'7/1/2020') from (select CONVERT(date,cast((max(calendar_id)-100000000) as char(10)),120) calid from [fact].[new_flyer_TM_Table]) o )

DECLARE @StartDate  date = @lastdt ;

DECLARE @CutoffDate date = DATEADD(DAY, -2, getdate())

;WITH seq(n) AS 
(
  SELECT 0 UNION ALL SELECT n + 1 FROM seq
  WHERE n < DATEDIFF(DAY, @StartDate, @CutoffDate)
),
d(d) AS 
(
  SELECT DATEADD(DAY, n, @StartDate) FROM seq
),
src AS
(
  SELECT
    TheDate         = CONVERT(date, d),
    calendar_id	 = convert(varchar(32),d,112)+100000000
  FROM d
)
SELECT rn = row_number() over (order by thedate),
* 
into #dttable
FROM src
  ORDER BY TheDate
  OPTION (MAXRECURSION 0);
--select * from #dttable order by rn
  declare @i int 
  declare @r int
  declare @currdt int
  select @i = 1
  select @r = (select max(rn) from #dttable)

while @i <= @r
BEGIN
select @currdt = (select calendar_id from #dttable where rn = @i)
--print cast(@currdt as varchar(32))

exec fact.new_flyer_tm_info @currdt ;

select @i = @i + 1

if @i > @r
BREAK
	ELSE CONTINUE

END
GO
