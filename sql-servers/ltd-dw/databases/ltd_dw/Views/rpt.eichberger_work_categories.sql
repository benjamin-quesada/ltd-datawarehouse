SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE view [rpt].[eichberger_work_categories]
as
--select * from (
select [ID]
      ,[Title]
      ,[Request_Description]
      ,[Requester]
      ,[Department]
      ,[Status]
      ,[Time Spent]
      ,[created]
      ,[opened]
      ,[closed]	 
      ,[created_dt] = cast(created as date)
      ,[opened_dt]	= cast(opened as date)
      ,[closed_dt]	  = cast(closed as date)
,[Wwork Category] = isnull(case when title like '%crystal%' or request_description like '%crystal%' then 'Reports - Crystal'
	  when title like '%SSRS%' or request_description like '%SSRS%' then 'Reports - SSRS'
	  when replace(title,' ','') like '%powerbi%' or replace(request_description,' ','') like '%powerbi%' then 'Reports - Power BI'
	  when title like '%BI Min Max%' or request_description like '%BI Min Max%' then 'Reports - SSRS' 
	  when title like '%bay grid%' or request_description like '%bay grid%' then 'Reports - SSRS'  
	  when title like '%bay use%' or request_description like '%bay use%' then 'Reports - SSRS'  
	  when title like '%CITS %' or request_description like '%CITS %' then 'Applications - CITS' 
	  when title like '%message on CITS%' or request_description like '%CITS %' then 'Applications - CITS' 
	  when title like '%dataedo%' or request_description like '%dataedo%' then 'Data Warehouse' 
	  when title like '%integration%' or request_description like '%integration%' then 'Integrations - Internal' 
	  when title like '%iTRAK%' or request_description like '%iTRAK%' then 'Integrations - Internal' 
	  when title like '%model%' or request_description like '%model%data%' then 'Tabular Model' 
	  when title like '%tab model%' or request_description like '%tab model%' then 'Tabular Model' 
	  when title like '%ltd-test-ordata%' or request_description like '%ltd-test-ordata%' then 'Data Warehouse' 
	  when title like '%merge[_]%' or request_description like '%merge[_]%' then 'Data Warehouse' 
	  when title like '%ltd-DW2%' or request_description like '%ltd-DW2%' then 'Data Warehouse'  
	  when title like '%ltd-%bi%' or request_description like '%ltd-%bi%' then 'Reports - PBIRS' 
	  when title like '%pbirs%' or request_description like '%pbirs%' then 'Reports - PBIRS' 
	  when title like '%[_]model%' or request_description like '%[_]model%' then 'Tabular Model' 
	  when title like '%dev model%' or request_description like '%dev model%' then 'Tabular Model' 
	  when title like '%PDS%' or request_description like '%PDS%' then 'Integrations - External'
	  when title like '%emx qualifications%' or request_description like '%emx qualifications%' then 'Reports - SSRS'  
	  when title like '%station%bay%' or request_description like '%station%bay%' then 'Reports - SSRS'  
	  when title like '%pass sales%' or request_description like '%pass sales%' then 'Data Warehouse' 
	  when title like '%efare%' or request_description like '%efare%' then 'Data Warehouse' 
	  when title like '%ltd_db%' or request_description like '%ltd_db%' then 'Data Warehouse' 
	  when title like '%DW%' or request_description like '%DW%' then 'Data Warehouse' 
	  when title like '%Automat%' or request_description like '%Automat%' then 'Automation - Programming' 
	  when title like '%gtfs%' or request_description like '%gtfs%' then 'GTFS Support - Programming'
	  when title like '%Missing%Data%' or request_description like '%missing%data%' then 'SQL Data Research' 
	  when title like '%Extract%' or request_description like '%extract%' then 'SQL Development' 
	  when title like '%OIG%' or request_description like '%OIG%' then 'Hastus or Giro Development or Support' 
	  when title like '%hastus%' or request_description like '%hastus%' then 'Hastus or Giro Development or Support' 
	  when title like '%Cubic%' or title like '%Umo%' or request_description like '%Umo%' or request_description like '%efare%' then 'Umo Cubic eFare Development' 
	  when title like '%API %' or request_description like '%API %' then 'Data Warehouse'
	  when title like '%Centene%' or request_description like '%Centene%'
	    or title like '%newflyer%' or request_description like '%newflyer%'
		or title like '%new flyer%' or request_description like '%new flyer%'
		or title like '%weather%' or request_description like '%weather%'
		or title like '%touchpass%' or request_description like '%touchpass%'
		or title like '%touch pass%' or request_description like '%touch pass%'
		then 'Integrations - External' 
	  when title like '%access%' or request_description like '%access%' or title like '%password' or request_description like '%password%' then 'Administrivia'
	  when title like '%batch%' or request_description like '%batch%' or title like '%.hta' or request_description like '%.hta%' then 'Applications - Programming'
	  when title like '%find the table%' or request_description like '%find the table%' then 'Other Data Delivery Services'
	  when title like '%835%' or request_description like '%835%' then 'Other Data Delivery Services'
	  when title like '%837%' or request_description like '%837%' then 'Other Data Delivery Services'
	  when title like '%dtsx%' or request_description like '%dtsx%' then 'Integrations - Internal'
	  when title like '%LTD-ETL%' or request_description like '%LTD-ETL%' then 'Integrations - Internal'
	  when title like '%flat file%' or request_description like '%flat file%' then 'Integrations - External'
	  when title like '%road call%' or request_description like '%road call%' or title like '%MBRC%' or request_description like '%MBRC%' then 'Data Delivery Services'
	  when title like '%BI Team%' or request_description like '%BI Team%' then 'Data Delivery Services'
	  when title like '%novus%' or request_description like '%novus%' then 'Data Warehouse'
	  when title like '%PCard%' or request_description like '%PCard%' then 'Applications - Programming'
	  when title like '%abra%' or request_description like '%abra%' then 'Data Warehouse'
	  when title like '%PII%' or request_description like '%PII%' then 'Data Warehouse'
	  when title like '%sql%upgrade%' or request_description like '%sql%upgrade%' then 'Database Adminstrative Services'
	  when title like '%VIEWs to check%ltd-orods%' or request_description like '%VIEWs to check%ltd-orods%' then 'Database Adminstrative Services'
	  when title like '%dba%' or request_description like '%dba%' then 'Database Adminstrative Services'
	  when title like '%scripts%' or request_description like '%scripts%' then 'Applications - Programming'
	  when (title like '%create%' and title like '%view%') or (request_description like '%view%' and request_description like '%create%') then 'Data Delivery Services'
	  when (title like '%backup%' or title like '%back-up%') or (request_description like '%backup%'  or request_description like '%back-up%' ) then 'Database Adminstrative Services'
	  when (title like '%backup%' or title like '%back-up%') or (request_description like '%backup%'  or request_description like '%back-up%' ) then 'Database Adminstrative Services'
	  when (title like '%Giro%' and title like '%upgrade%') or (request_description like '%Giro%'  or request_description like '%upgrade%' ) then 'Database Adminstrative Services'
	  when title like '%OSU Project%' or request_description like '%OSU Project%'  then 'Database Adminstrative Services'
	  when (title like '%field%' or title like '%clean%') or (request_description like '%field%' or request_description like '%clean%') then 'Data Delivery Services'
	  when title like '%POS%' or request_description like '%POS%' then 'Integrations - Internal'
	  when title like '%crumb%' or request_description like '%crumb%' then 'Integrations - Internal'
	  when title like '%dashboard%' or request_description like '%dashboard%' then 'Reports - Power BI'
	  when title like '%.rpt%' or request_description like '%.rpt%' then 'Reports - General'
	  when title like '%BSI%' or request_description like '%BSI%' then 'Reports - SSRS'
	  when title like '%pbix%' or request_description like '%pbix%' then 'Reports - Power BI'
	  when title like '%on time perf%' or request_description like '%on time perf%' then 'Reports - Power BI'
	  when title like '%APC %' or request_description like '%APC %' or title like '%APC/%' or request_description like '%APC/%' then 'Reports - Regulatory'
	  when title like '%VOMS%' or request_description like '%VOMS%' then 'Reports - Regulatory'
	  when title like '%NTD %' or request_description like '%NTD %' then 'Reports - Regulatory'
	  when title like '%TMDATAMART%' or request_description like '%TMDATAMART%' then 'Data Warehouse'
	  when title like '%view_store%' or request_description like '%view_store%' then 'Data Warehouse'
	  when title like '%Sign out sheets%' or request_description like '%Sign out sheets%' then 'Reports - SSRS'
	  when title like '%Fare Inspection%' or request_description like '%Fare Inspection%' then 'Reports - General'
	  when title like '%could not use view or function%' or request_description like '%could not use view or function%' then 'Data Warehouse'
	  when title like '%census.gov%' or request_description like '%census.gov%' then 'Data Warehouse'
	  when (title like '%legacy%' and title like '%data%') or (request_description like '%legacy%' and request_description like '%data%') then 'Data Warehouse'
	  when (title like '%CPU%' and title like '%redgate%') or (request_description like '%redgate%' and request_description like '%CPU%') then 'Database Adminstrative Services'
	  when title like '%polygon%' or request_description like '%polygon%' then 'Data Warehouse'
	  when title like '%data flow%' or request_description like '%data flow%' then 'Data Warehouse'
	  when (title like '%upgrade%' and title like '%sql%') or  (request_description like '%upgrade%' and request_description like '%sql%') then 'Database Adminstrative Services'
	  when (title like '%permission%' and title like '%midas%') or  (request_description like '%permission%' and request_description like '%midas%') then 'Database Adminstrative Services'
	  when (title like '%CAD/AVL%' and title like '%upgrade%') or  (request_description like '%CAD/AVL%' and request_description like '%upgrade%') then 'Database Adminstrative Services'
	  when (title like '%midas_test%' ) or  (request_description like '%midas_test%' ) then 'Database Adminstrative Services'
	  when (title like '%perform%' and title like '%data%') or (request_description like '%perform%' and request_description like '%data%') then 'Database Adminstrative Services'
	  when title like '%query%' or request_description like '%query%' or title like '%queries%' or request_description like '%queries%'  then 'Other Data Delivery Services'
	  when title like '%role back%' or request_description like '%roll back%' or 
				title like '%backup%' or request_description like '%backup%' or
				title like '%restore%' or request_description like '%restore%' 
				then 'Database Adminstrative Services'
	  when title like '%report%' or request_description like '%report%' then 'Reports - General'
	  when title like '%do not reply%' or request_description like '%do not reply%' then 'Data Warehouse'
	  when title like '%ERror in:%' or request_description like '%error in:%' then 'Data Warehouse'
	  when title like '%DOR%' or request_description like '%DOR%' or title like '%Department of Rev%' or request_description like '%Department of Rev%'  then 'Data Delivery Services'
	  when title like '%kWh%' or request_description like '%kWh%' or title like '%electric fuel%' or request_description like '%electric fuel%'  then 'Applications - Programming'
	  when (title like '%excel%' and title like '%data%') or (request_description like '%excel%' and request_description like '%data%') then 'Reports - Excel'
	  when (title like '%spreadsheet%') or (request_description like '%spreadsheet%' ) then 'Reports - Excel'
	  end,'Other')
from [rpt].[serivicedesk_detailed_requestsOnly_desc]
  where [Time Spent Technician] like '%eichberger%'
--) q
--where q.[Wwork Category] = 'Other'


GO
