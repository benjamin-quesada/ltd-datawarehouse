SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [eam].[fueling_sheet_prep] AS

/************LTD_GLOSSARY*********

CREATED ON	: 20240307
CREATED BY	: B. Eichberger
Purpose		: Support crystal report conversions "Fueling Sheet"
			  Has technical debt to unravel - sourcing data from many places/dbs
			  Runs way to slow - needs more optimization

USE			: exec [eam].[fueling_sheet_prep]

CHANGED ON	: 20240322
CHANGE BY	: B. Eichberger
Purpose		: Remove reliance on table functions - optimize


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

DROP TABLE IF EXISTS  eam.temp_mpg
DROP TABLE IF EXISTS  eam.temp_miles
DROP TABLE IF EXISTS  eam.temp_lastf
DROP TABLE IF EXISTS #ftk
DROP TABLE IF EXISTS #lastftk
DROP TABLE IF EXISTS #busAct


SELECT eq_equip_no AS bus,max_fuel
	,fueling_date
	,ftk_date
	,ftk_fuel_qty
	,ftk_fuel_value
	,fuel_type
	,eam.fueling_date(ftk_date) mr_datetime 
	,rnk =RANK() OVER (partition BY eq_equip_no ORDER BY ftk_date DESC)
	INTO #ftk
	FROM [ltd-eam].ltd_db.dbo.fuel_tickets gt WITH (NOLOCK) 
	JOIN tm.t_buses_active_today bt ON bt.bus COLLATE DATABASE_DEFAULT = gt.eq_equip_no
              where  fuel_type IN('uls')
	
SELECT [bus]                  = bus
      ,[mr_fueling_date]      = fueling_date
	  ,[mr_fueling_datetime]  = ftk_date
	  ,[mr_fueling_age_hours] = DATEDIFF(HOUR, mr_datetime, GETDATE())
      ,[mr_fueling_date_qty]  = CAST(ROUND(ftk_fuel_qty, 1) AS NUMERIC(5,1))
INTO #lastftk
  FROM #ftk dt -- ON dt.bus = q.bus
  WHERE rnk = 1
  ORDER BY bus

SELECT [class]     = CAST(bc.veh_class AS INT)
      ,[bus]       = ba.bus
	  ,[miles]     = ba.miles
	  ,[last_blk]  = ba.last_block
	  ,[miles_est] = ba.miles_total_est
	  ,[pull_in]   = ba.pull_in
	  ,[at_ltd]    = ba.at_ltd
 INTO #busAct
 FROM tm.t_buses_active_today ba
  JOIN [LTD-TMDATA].ltd_db.dbo.ltd_bus_classes_from_tmmain bc ON bc.veh = ba.bus

TRUNCATE TABLE ltd_dw.eam.fueling_sheet_hold
;
INSERT ltd_dw.eam.fueling_sheet_hold (
[class]
,[bus]
,[miles]
,[last_blk]
,[miles_est]
,[pull_in]
,[at_ltd]
,[mf_fuel_dt]
,[mf_fuel_date]
,[mr_tm_date]
,[mr_tm_miles]
,[mr_fuel_qty]
,[comp_fuel_qty]
,[artic]
,[rpt_group]
,[rpt_order_by_bus]
,[rpt_order_by_at_ltd_and_pullin]
,[rpt_order_by_block])
SELECT 
[class]
,[bus]
,[miles]
,[last_blk]
,[miles_est]
,[pull_in]
,[at_ltd]
,[mf_fuel_dt]
,[mf_fuel_date]
,[mr_tm_date]
,[mr_tm_miles]
,[mr_fuel_qty]
,[comp_fuel_qty]
,[artic]
,[rpt_group]
,[rpt_order_by_bus]
,[rpt_order_by_at_ltd_and_pullin]
,[rpt_order_by_block] FROM eam.fueling_sheet WITH (NOLOCK);

IF (SELECT COUNT(*) FROM sys.tables WHERE name = 'temp_mpg') = 0
BEGIN
CREATE TABLE [eam].[temp_mpg](
	[ltd_bus_class] [varchar](11) NOT NULL,
	[mpg_avg] [numeric](5, 1) NULL
) ON [PRIMARY]
END

IF (SELECT COUNT(*) FROM sys.tables WHERE name = 'temp_miles') = 0
BEGIN
CREATE TABLE [eam].[temp_miles](
	[bus] [varchar](20) NOT NULL,
	[mr_date] [date] NULL,
	[mr_miles] [numeric](38, 2) NULL
) ON [PRIMARY]
END

INSERT  eam.temp_mpg (ltd_bus_class,mpg_avg)
SELECT ltd_bus_class,mpg_avg
FROM [LTD-EAM].ltd_db.dbo.bus_class_last_year_mpg;

INSERT eam.temp_miles (bus,mr_date,mr_miles)
SELECT bus,mr_date,mr_miles
FROM [LTD-EAM].ltd_db.dbo.bus_most_recent_tm_miles;

SELECT bus,mr_fueling_date,mr_fueling_datetime,mr_fueling_age_hours,mr_fueling_date_qty
INTO -- SELECT * FROM 
eam.temp_lastf
FROM #lastftk;


TRUNCATE TABLE eam.fueling_sheet;

INSERT eam.fueling_sheet
(
	[class]
   ,[bus]
   ,[miles]
   ,[last_blk]
   ,[miles_est]
   ,[pull_in]
   ,[at_ltd]
   ,[mf_fuel_dt]
   ,[mf_fuel_date]
   ,[mr_tm_date]
   ,[mr_tm_miles]
   ,[mr_fuel_qty]
   ,[comp_fuel_qty]
   ,[artic]
   ,[rpt_group]
   ,[rpt_order_by_bus]
   ,[rpt_order_by_at_ltd_and_pullin]
   ,[rpt_order_by_block]
)
SELECT [class] = bc.ltd_bus_class
,[bus] = tb.bus
,[miles] = tb.miles
,[last_blk] = tb.last_block
,[miles_est] = tb.miles_total_est
,[pull_in] = tb.pull_in
,[at_ltd] = tb.at_ltd
,[mf_fuel_dt] = rf.mr_fueling_datetime
,[mf_fuel_date] = CAST(DATEADD(DAY, CASE WHEN DATEPART(HOUR, rf.mr_fueling_datetime) >= 4 THEN 0 ELSE -1 END, rf.mr_fueling_datetime) AS DATE) -- see eam.fueling_date funciton for reference
,[mr_tm_date] = mrtm.mr_date
,[mr_tm_miles] = mrtm.mr_miles
,[mr_fuel_qty] = rf.mr_fueling_date_qty
,[comp_fuel_qty] = CAST(ROUND(CASE WHEN mpg.ltd_bus_class IS NULL THEN NULL ELSE CASE tb.at_ltd WHEN 1 THEN tb.miles ELSE ISNULL(tb.miles_total_est, tb.miles)END / mpg.mpg_avg END, 1) AS NUMERIC(5, 1))
,[artic] = bc.artic
,[rpt_group] = CASE
	WHEN bc.artic = 0 AND bc.electric = 0 THEN '1-diesel'
	WHEN bc.artic = 0 AND bc.electric = 1 THEN '2-electric'
	WHEN bc.artic = 1 AND bc.emx_bus = 0 THEN '3-non-Emx'
	WHEN bc.artic = 1 AND bc.emx_bus = 1 THEN '4-Emx' ELSE '9-?????' END
,[rpt_order_by_bus] = RIGHT('0000' + CAST(tb.class AS VARCHAR(5)), 5) + RIGHT('0000' + tb.bus, 5)
,[rpt_order_by_at_ltd_and_pullin] = CASE tb.at_ltd WHEN 1 THEN 'a' ELSE 'z' END + tb.pull_in + RIGHT('0000' + CAST(tb.class AS VARCHAR(5)), 5) + RIGHT('0000' + tb.bus, 5)
,[rpt_order_by_block] = RIGHT('000' + CAST(tb.last_block AS VARCHAR(4)), 4) -- select * 
FROM ltd_dw.tm.t_buses_active_today tb
	 JOIN ltd_dw.model.Vehicle_v bc ON bc.EQ_equip_no = tb.bus
	 LEFT JOIN eam.temp_lastf rf ON rf.bus COLLATE SQL_Latin1_General_CP1_CI_AS = tb.bus
	 LEFT JOIN  eam.temp_mpg mpg ON CAST(mpg.ltd_bus_class AS INT) = tb.class
	 LEFT JOIN  eam.temp_miles mrtm ON mrtm.bus COLLATE SQL_Latin1_General_CP1_CI_AS = tb.bus
OPTION (MAXDOP 2)

TRUNCATE TABLE eam.fueling_sheet_hold;
;


DROP TABLE IF EXISTS  eam.temp_mpg
DROP TABLE IF EXISTS  eam.temp_miles
DROP TABLE IF EXISTS  eam.temp_lastf
DROP TABLE IF EXISTS #ftk
DROP TABLE IF EXISTS #lastftk
DROP TABLE IF EXISTS #busAct





END TRY
BEGIN CATCH

	DECLARE @profile VARCHAR(255) =
			(SELECT name FROM msdb .dbo.sysmail_profile)  ;
	DECLARE @errormsg VARCHAR(MAX)
		   ,@error INT
		   ,@message VARCHAR(MAX)
		   ,@xstate INT
		   ,@errsev INT
		   ,@sub VARCHAR(255) ;

	SELECT	@error = ERROR_NUMBER()
		   ,@errsev = ERROR_SEVERITY()
		   ,@message = ERROR_MESSAGE()
		   ,@xstate = XACT_STATE() ;

	SELECT	@errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32)) ;

	SELECT	@sub = 'ERROR: ' + @SPROC ;

	EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
								,@recipients = 'barb.eichberger@ltd.org'
								,@subject = @sub
								,@body = @errormsg ;

	RAISERROR(@errormsg, @errsev, 1) ;
END CATCH ;


GO
