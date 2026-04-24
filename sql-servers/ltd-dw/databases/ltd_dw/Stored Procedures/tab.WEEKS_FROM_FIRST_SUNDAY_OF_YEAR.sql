SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [tab].[WEEKS_FROM_FIRST_SUNDAY_OF_YEAR]
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


DECLARE @Year INT

SET @Year = (select year(dateadd(year,-2,getdate())));

WITH Months
AS (
	SELECT 1 AS MonthNumber
	UNION ALL
	SELECT 2
	UNION ALL
	SELECT 3
	UNION ALL
	SELECT 4
	UNION ALL
	SELECT 5
	UNION ALL
	SELECT 6
	UNION ALL
	SELECT 7
	UNION ALL
	SELECT 8
	UNION ALL
	SELECT 9
	UNION ALL
	SELECT 10
	UNION ALL
	SELECT 11
	UNION ALL
	SELECT 12
	UNION ALL
	SELECT 13
	)
	,Dates
AS (
	-- Find first day of month
	SELECT monthNumber
		,firstDayOfMonth = DATEADD(month, monthNumber - 1, CONVERT(DATETIME, CAST(@Year AS CHAR(4)) + '0101', 112))
	FROM Months
	)
	,MonthRange
AS (
	-- Find last day of month
	SELECT *
		,lastDayOfMonth = (
			SELECT TOP 1 DATEADD(day, - 1, firstDayOfMonth)
			FROM Dates
			WHERE MonthNumber = D.MonthNumber + 1
			)
	FROM Dates AS D
	WHERE monthNumber <= 12
	)
SELECT
firstSunday = (
		SELECT TOP 1 DATEADD(day, monthNumber - 1, firstDayOfMonth)
		FROM Months
		WHERE DATEPART(weekday, DATEADD(day, monthNumber - 1, firstDayOfMonth)) = 1
		ORDER BY monthNumber
		),
	lastSaturday = (
		SELECT TOP 1 DATEADD(day, (- 1) * (monthNumber - 1), lastDayOfMonth)
		FROM Months
		WHERE DATEPART(weekday, DATEADD(day, (- 1) * (monthNumber - 1), lastDayOfMonth)) = 7
		ORDER BY monthNumber
		)
into #monthrng
FROM MonthRange

declare @datestbl table (rn INT identity(1,1),week_number INT,calendar_date date, sevenDayWeekYear INT,sevenDayWeekYearText varchar(32))
declare @firstSunday date = (Select min(firstSunday) firstSunday from #monthrng)
declare @nextSunday date
declare @endDate date = getdate()-1
declare @i date = @firstSunday
declare @c INT = 1
declare @yr INT = (select datepart(year,@firstSunday))


while  @i <= @endDate
BEGIN



declare @yri INT = (select datepart(year,@i))
if (@yri <> @yr) 
BEGIN
select @c = 1
END

insert @datestbl (week_number,calendar_date,sevenDayWeekYear,sevenDayWeekYearText)
select @c,dateadd(day,0,@i ) ,@yri,cast(@c as varchar(8))+ '-' + cast(@yri as varchar(8))
insert @datestbl (week_number,calendar_date,sevenDayWeekYear,sevenDayWeekYearText)
select @c,dateadd(day,1,@i ),@yri ,cast(@c as varchar(8))+ '-' + cast(@yri as varchar(8))
insert @datestbl (week_number,calendar_date,sevenDayWeekYear,sevenDayWeekYearText)
select @c,dateadd(day,2,@i ),@yri ,cast(@c as varchar(8))+ '-' + cast(@yri as varchar(8))
insert @datestbl (week_number,calendar_date,sevenDayWeekYear,sevenDayWeekYearText)
select @c,dateadd(day,3,@i ),@yri ,cast(@c as varchar(8))+ '-' + cast(@yri as varchar(8))
insert @datestbl (week_number,calendar_date,sevenDayWeekYear,sevenDayWeekYearText)
select @c,dateadd(day,4,@i ),@yri ,cast(@c as varchar(8))+ '-' + cast(@yri as varchar(8))
insert @datestbl (week_number,calendar_date,sevenDayWeekYear,sevenDayWeekYearText)
select @c,dateadd(day,5,@i ),@yri ,cast(@c as varchar(8))+ '-' + cast(@yri as varchar(8))
insert @datestbl (week_number,calendar_date,sevenDayWeekYear,sevenDayWeekYearText)
select @c,dateadd(day,6,@i ),@yri ,cast(@c as varchar(8))+ '-' + cast(@yri as varchar(8))

select @yr = (select datepart(year,@i))
select @c = @c + 1
select @i = dateadd(day,7,@i)

if @i > @endDate
BREAK
	ELSE CONTINUE

END

select * from @datestbl
GO
