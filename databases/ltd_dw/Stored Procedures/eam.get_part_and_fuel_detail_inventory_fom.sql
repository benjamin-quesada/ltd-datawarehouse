SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE   PROCEDURE [eam].[get_part_and_fuel_detail_inventory_fom] 

AS



------------------LTD_GLOSSARY---------------
-- created by:	b.eichberger
-- created dt:  9/27/2022
-- purpose	 :  build up a base of detail monthly data for parts and fuel inventory in dw
-- use       :  exec [eam].[get_part_and_fuel_detail_inventory_fom]

---- from history legacy table or view, selects 
---- the last measured amounts FOR each part in 
---- each month and year

-- modify dt: 09/20/2023
-- modify by: Sopheap Suy
-- purpose	: replace eam.stage_parts_on_hand with eam.plo_main_on_hand_history 
--			  replace eam.stage_fuel_on_hand with eam.fuel_main_on_hand_history


/*
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

declare @lastdt date = (select isnull(dateadd(day, -5, max([Inv Date])),'7/1/2019') from [eam].[parts_fuel_inventory_eom])

declare @yrmonth table (rn int, yn int, mn int)
insert @yrmonth
select rn = row_number() over (order by c.year, c.Month) ,
						c.year yn, c.month mn from tm.DW_CALENDAR c
					left join [eam].[parts_fuel_inventory_fom] i on i.calendar_id = c.CALENDAR_ID
					where c.CALENDAR_DATE >= @lastdt and c.CALENDAR_DATE <= dateadd(day, -1, getdate())
					and i.calendar_id is null
					group by c.year, c.month 
--select * from @yrmonth

delete from [eam].[parts_fuel_inventory_fom] where [InvYear] >= year(@lastdt) and [InvMonth] >= month(@lastdt)	


declare @i int = 1
declare @r int = (select max(rn) from @yrmonth)
declare @currYr smallint
declare @currMo smallint

WHILE @i <= @r
BEGIN
select @currMo = (select mn from @yrmonth where rn = @i)
select @currYr = (select yn from @yrmonth where rn = @i)


-- truncate table [eam].[parts_fuel_inventory_fom]
INSERT [eam].[parts_fuel_inventory_fom]
([Calendar_Id]
,[InvYear]
,[InvMonth]
,[InvGroup]
,[InvSortOrder]
,[Fiscal Year]
,[Fiscal Year Name]
,[Fiscal Period]
,[Inv Date]
,[rn]
,[part_no_and_suffix]
,[part_part_no]
,[part_suffix]
,[description_keyword]
,[description_short]
,[product_category]
,[product_category_description]
,[part_val_oh]
,[qty_on_hand]
,[cur_issue_price]
,extended) 
SELECT b.CALENDAR_ID
	,b.yrInv InvYear
	,b.mnthInv InvMonth
	,b.[InvGroup]
	,b.InvGroupSortOrder
	,b.FiscalYear [Fiscal Year]
	,b.[Fiscal Year Name]
	,b.FiscalPeriod [Fiscal Period]
	,b.[date] AS [Inv Date]
	,b.rn
	,CONVERT(VARCHAR(65), b.part_no_and_suffix) part_no_and_suffix
	,CONVERT(VARCHAR(32), b.part_part_no) part_part_no
	,CONVERT(VARCHAR(32), b.part_suffix ) part_suffix
	,CONVERT(VARCHAR(32), b.description_keyword) description_keyword
	,CONVERT(VARCHAR(32), b.description_short) description_short
	,b.product_category
	,b.product_category_description
	,b.part_val_oh
	,b.qty_on_hand
	,b.cur_issue_price
	,b.extended 
FROM (	
SELECT c.calendar_id,c.year, LEFT(c.monthname,6) mnthName, c.FiscalYear, c.[Fiscal Year Name], c.FiscalPeriod
	,o.yrInv
	,o.mnthInv
	,[InvGroup] = 'PART AND FLUID'
	,[InvGroupSortOrder] = 1
	,o.[date]
	,rn = ROW_NUMBER() OVER (PARTITION BY part_part_no, part_suffix,o.yrInv, o.mnthInv
					ORDER BY o.[date] ASC)
	,o.part_no_and_suffix COLLATE SQL_Latin1_General_CP850_CI_AS part_no_and_suffix
	,o.part_part_no COLLATE SQL_Latin1_General_CP850_CI_AS part_part_no
	,o.part_suffix COLLATE SQL_Latin1_General_CP850_CI_AS part_suffix
	,o.description_keyword COLLATE SQL_Latin1_General_CP850_CI_AS description_keyword
	,o.description_short COLLATE SQL_Latin1_General_CP850_CI_AS description_short
	,UPPER(o.product_category COLLATE SQL_Latin1_General_CP850_CI_AS) product_category
	,UPPER(o.prd_product_category_description COLLATE SQL_Latin1_General_CP850_CI_AS) product_category_description
	,o.part_val_oh
	,o.qty_on_hand
	,o.cur_issue_price 
	,extended = o.qty_on_hand * o.cur_issue_price
	FROM tm.DW_CALENDAR c 
	LEFT JOIN 
		(SELECT 
		YEAR(ploh.insert_datetime) yrInv
		,MONTH(ploh.insert_datetime) mnthInv
				,[date] = CAST(ploh.insert_datetime AS DATE)
				,part_no_and_suffix = ploh.part_part_no COLLATE SQL_Latin1_General_CP850_CI_AS + ':'+ CAST( ploh.part_suffix AS VARCHAR(10))
				,ploh.part_part_no COLLATE SQL_Latin1_General_CP850_CI_AS AS part_part_no
				,CAST(ploh.part_suffix AS VARCHAR(10)) COLLATE SQL_Latin1_General_CP850_CI_AS AS part_suffix
				,plom.description_keyword            
				,plom.description_short                      
				,ploh.prd_product_category product_category
				,prdm.[description] prd_product_category_description
				,ploh.value_on_hand part_val_oh
				,ploh.qty_on_hand
				,ploh.cur_issue_price  -- select *  
			FROM eam.plo_main_on_hand_history ploh WITH (NOLOCK) -- replace [eam].[stage_parts_on_hand]
			INNER JOIN -- select * from 
					[LTD-EAM].proto.emsdba.plo_main plom WITH (NOLOCK) 
						ON     plom.part_part_no COLLATE SQL_Latin1_General_CP850_CI_AS = ploh.part_part_no COLLATE SQL_Latin1_General_CP850_CI_AS 
						   AND plom.part_suffix = ploh.part_suffix
			INNER JOIN [LTD-EAM].proto.emsdba.prd_main prdm WITH (NOLOCK) 
						ON prdm.prd_product_category  COLLATE SQL_Latin1_General_CP850_CI_AS = plom.prd_product_category COLLATE SQL_Latin1_General_CP850_CI_AS 
			WHERE ploh.insert_datetime IS NOT NULL 
				   AND YEAR(ploh.insert_datetime) = @currYr
				   AND MONTH(ploh.insert_datetime) = @currMo 

	) o
	ON o.date = c.CALENDAR_DATE
	WHERE c.year = @currYr AND c.Month = @currMo
				   

UNION ALL

SELECT c.calendar_id,c.year, LEFT(c.monthname,6) mnthName, c.FiscalYear, c.[Fiscal Year Name], c.FiscalPeriod
	,a.yrInv
	,a.mnthInv
	,[InvGroup] = 'FUEL'
	,[InvGroupSortOrder] = 2
	,[Inv Date]
	,rn = ROW_NUMBER() OVER (PARTITION BY fuel_type, tank_tank_no,a.yrInv, a.mnthInv
				ORDER BY [Inv Date] ASC)
	,a.part_no_with_suffix
	,a.fuel_type 
	,a.tank_tank_no COLLATE SQL_Latin1_General_CP850_CI_AS
	,a.keyword
	,desc_short
	,a.prd_product_category product_category
	,a.prd_product_category_description product_category_description
	,a.fuel_val_oh 
	,a.qty_on_hand
	,a.cur_price 
	,extended = a.qty_on_hand * a.cur_price
	FROM tm.DW_CALENDAR c 
	LEFT JOIN 
		(SELECT
			YEAR(ploh.insert_datetime) yrInv
			,MONTH(ploh.insert_datetime) mnthInv
			,[Inv Date] = CAST(ploh.insert_datetime AS DATE)
			,part_no_with_suffix = ploh.fuel_type COLLATE SQL_Latin1_General_CP850_CI_AS +':TANK '+ CAST(ploh.tank_tank_no AS VARCHAR(32))
			,CAST(ploh.fuel_type AS VARCHAR(32)) COLLATE SQL_Latin1_General_CP850_CI_AS AS fuel_type
			,ploh.tank_tank_no COLLATE SQL_Latin1_General_CP850_CI_AS AS tank_tank_no
			,'FUEL' keyword
			,CAST(ploh.fuel_type AS VARCHAR(32)) desc_short
			,[prd_product_category]             = UPPER(CAST(ploh.fuel_type AS VARCHAR(32)) ) 
			,[prd_product_category_description] = UPPER(plom.[description])      
			,ploh.value_on_hand fuel_val_oh 
			,ploh.qty_on_hand
			,ploh.cur_price  -- select *                
		FROM [eam].[fuel_main_on_hand_history] ploh WITH (NOLOCK) 
		INNER JOIN -- select * from 
		[LTD-EAM].proto.emsdba.FUE_TYPES plom WITH (NOLOCK) 
				ON plom.fuel_type  COLLATE SQL_Latin1_General_CP850_CI_AS = ploh.fuel_type COLLATE SQL_Latin1_General_CP850_CI_AS 
		WHERE ploh.insert_datetime IS NOT NULL 
				AND YEAR(ploh.insert_datetime) =  @currYr
				AND MONTH(ploh.insert_datetime) = @currMo
		AND CAST(tank_tank_no AS VARCHAR(32)) <> 'KW-1' 
		) a ON a.[Inv Date] = c.CALENDAR_DATE
	WHERE c.year = @currYr AND c.Month = @currMo
	--where a.rn = 1 -- this is set at 1 for monthly values
) b
WHERE [b].[yrInv] IS NOT NULL AND b.mnthInv IS NOT NULL AND ISNULL(b.rn,0) <> 0
--where not exists (select 1 from [eam].[parts_fuel_inventory_fom] i where
--					b.CALENDAR_ID = i.CALENDAR_ID
--					and b.part_no_and_suffix = i.part_no_and_suffix
--					and b.qty_on_hand = i.qty_on_hand
--					and b.cur_issue_price = i.cur_issue_price)

SELECT @i = @i + 1
IF @i > @r 
BREAK
	ELSE CONTINUE

END



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
