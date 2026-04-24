SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [pds].[merge_employee_service_age_and_years]
as
/*



CREATED ON	: 20260112
CREATED BY	: B Eichberger
PURPOSE		: enable calculation of average age and/or years of service
			  for analysis against accident rates, length of service at 
			  accident dates and/or retention as examples - and with this
			  procedure optimize the development of the data and store
			  it in a table
USE           exec [pds].[merge_employee_service_age_and_years]

*/

set nocount on

declare @SPROC varchar(100)
set @SPROC = object_schema_name(@@procid) + '.' + object_name(@@procid)

insert into DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
select distinct @@servername, db_name(),host_name(),system_user, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, current_timestamp as [Timestamp], 'PROC'
from sys.dm_exec_connections 
where session_id = @@spid ;

BEGIN TRY

drop table if exists #empAgeService;

DECLARE @sdt DATETIME2 = SYSDATETIME()
DECLARE @outputTbl TABLE (actionNm VARCHAR(32));

declare @lstdate date = (select dateadd(day,-30,max(dt)) from (
                            select max(record_created_date) dt from pds.employee_service_age_and_years
                                union
                            select isnull(max(record_updated_date),'1/1/1900') from pds.employee_service_age_and_years) j ) 
;
with pdsDates as (
select distinct u.emp_employee_id, u.last_name, u.first_name, u.bdt
              , u.emp_person_status
              , hire_date = case when u.hire_date is null then null
								 else cast(u.hire_date as date) end 
              , next_hire = case when u.next_hire is null then null
								 else cast(u.next_hire as date) end
              , termination_date = cast(isnull(u.termination_date, getdate()+1) as date) 
from (
	select distinct p.[employee_id]  emp_employee_id, p.last_name, p.first_name
	,p.emp_person_status,x.bdt
	,[hire_date] = cast(p.[hire_date] as date)
	,next_hire = cast(lead(p.hire_date,1) over (partition by p.employee_id order by p.hire_date,case when p.hire_date = '1/1/1900' then '11/11/2111' else p.[termination_date] end) as date)
	,[termination_date] = cast(case when p.[termination_date] = '1/1/1900' or p.termination_date < p.rehire_date then null 
							else p.[termination_date] end as date)
	from [ltd_dw].[pds].[Integration_EmpPerson] p
	join [ltd_dw].[pds].[Integration_EmpExtended] x on p.person_id = x.person_id
    --where p.employee_id in (1002, 1053) 
) u
where not (isnull(u.next_hire,getdate()+1) = u.hire_date)
)
,pdb as  (
		 select d.emp_employee_id
              , d.emp_person_status
              , d.hire_date
              , d.next_hire
              , d.termination_date
			  , dateOfBirth = coalesce(cast(d.bdt as date),cast(e.dateOfBirth as date))
			from pdsDates d
			  left join [LTD-OPS].midas.dbo.employee e on e.personnelID collate SQL_Latin1_General_CP1_CI_AS = d.emp_employee_id
		 )
select c.CALENDAR_DATE
,e.emp_employee_id 
,age_at_cal_date = round(datediff(month,e.dateOfBirth,c.CALENDAR_DATE)/12,0)
,age_at_hire_date = datediff(month,e.dateOfBirth,e.hire_date)/12
,e.hire_date
,termination_date = case when e.termination_date = cast(dateadd(day,1,getdate()) as date) then null else e.termination_date end
,start_years_of_service = min(datepart(year,c.CALENDAR_DATE)) over (partition by e.emp_employee_id, hire_date order by e.hire_date)
,end_years_of_service = max(datepart(year,c.CALENDAR_DATE)) over (partition by e.emp_employee_id, hire_date order by e.hire_date)
into #empAgeService
from tm.DW_CALENDAR c
	 left join pdb e on c.CALENDAR_DATE between e.hire_date and e.termination_date
	 where c.CALENDAR_DATE >= @lstdate

;	
-- truncate table pds.employee_service_age_and_years 
merge pds.employee_service_age_and_years t
using #empAgeService s
on (s.CALENDAR_DATE = t.calendar_date
and s.emp_employee_id = t.emp_employee_id
and s.hire_date = t.hire_date)
when matched and (
   isnull(s.[age_at_cal_date],0) <> isnull(t.[age_at_cal_date],0)
OR isnull(s.[age_at_hire_date],0) <> isnull(t.[age_at_hire_date],0)
OR isnull(s.[termination_date],'1/1/1900') <> isnull(t.[termination_date],'1/1/1900')
OR isnull(s.[start_years_of_service],0) <> isnull(t.[start_years_of_service],0)
OR isnull(s.[end_years_of_service],0) <> isnull(t.[end_years_of_service],0)
)
then update set
t.[age_at_cal_date] = s.[age_at_cal_date]
, t.[age_at_hire_date] = s.[age_at_hire_date]
, t.[termination_date] = s.[termination_date]
, t.[start_years_of_service] = s.[start_years_of_service]
, t.[end_years_of_service] = s.[end_years_of_service]
, t.record_updated_date = sysdatetime()
when not matched by target
then insert 
([CALENDAR_DATE]
      ,[emp_employee_id]
      ,[age_at_cal_date]
      ,[age_at_hire_date]
      ,[hire_date]
      ,[termination_date]
      ,[start_years_of_service]
      ,[end_years_of_service])
	values (
	s.[CALENDAR_DATE]
      ,s.[emp_employee_id]
      ,s.[age_at_cal_date]
      ,s.[age_at_hire_date]
      ,s.[hire_date]
      ,s.[termination_date]
      ,s.[start_years_of_service]
      ,s.[end_years_of_service]
      )
when not matched by source and calendar_date >= @lstdate then delete
OUTPUT $action INTO @outputTbl
;


DECLARE @ins INT = (SELECT isnull(count(*),0) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT isnull(count(*),0) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT isnull(count(*),0) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ops.merge_employee_service_age_and_years'

insert process.mergeLogs
(		[MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
select 'PDSE',
'ltd_dw.pds.employee_service_age_and_years',
'PDS',
@prg,
isnull(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
sysdatetime()



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
