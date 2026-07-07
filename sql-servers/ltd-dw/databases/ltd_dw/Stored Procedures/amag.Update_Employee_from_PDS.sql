SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [amag].[Update_Employee_from_PDS]
as


/*
  CREATED: 20210326
   AUTHOR: B EICHBERGER
  PURPOSE: Collect updates for Amag MultimaxImport dateimporttable 
CHANGEDON: 
 CHANGEBY: 
   CHANGE: 

NOTES: linked server login requires RPC and RPCout = TRUE on linked server configuration/server options
	   Needs INSERT permission on the object 'DataImportTable', database 'multiMAXImport', schema 'dbo'
	   Needs EXECUTE permission on the object 'xp_g4BCPLaunchAppWaitAndHide', database 'master', schema 'dbo'
exec [amag].[Update_Employee_from_PDS]

*/

SET NOCOUNT ON;

  DECLARE @SPROC VARCHAR(100)
  SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)


BEGIN TRY


EXEC [LTD-AMAG].[multiMAXImport].sys.sp_executesql N'TRUNCATE TABLE dbo.DataImportTable'

declare @startdt datetime = sysdatetime()


update [process].[MergeLogs] 
set [MergeEndDatetime] = sysdatetime()
   where mergecode = 'AMAE'
     and [ObjectDestination] = '[LTD-AMAG].[multiMAXImport].dbo.DataImportTable'
	 AND [ObjectSource] = 'AMAG'
	 AND [ObjectProgram] = 'LTD_DW.amag.Update_Employee_from_PDS'
	 AND [MergeEndDatetime] is null
	 AND recInsert = 0
	 AND recUpdate = 0
	 AND recDelete = 0

declare @tbl_emps table (LastName varchar(40), FirstName varchar(40), CompanyID int, 
	EmployeeReference varchar(12), PersonalData1 varchar(60), PersonalData2 varchar(40), 
	RecordRequest int, RecordStatus int, ImportNow bit)

DECLARE @OutputTbl TABLE (forcedInactive smallint)


--AddModify new employees	
insert @tbl_emps (LastName, FirstName, CompanyID, EmployeeReference, PersonalData1, PersonalData2, 
	RecordRequest, RecordStatus, ImportNow)
select p_lname, p_nickname, 1, ltrim(p_empno), left(p_jobname,40), dist_code, 0, 0, 1
from [pds].[Integration_AMAG_Employee] p 
where p_active = 'Y' 
OPTION (MAXDOP 1)

-- Modify existing employees)
insert @tbl_emps (LastName, FirstName, CompanyID, EmployeeReference, PersonalData1, PersonalData2, 
	RecordRequest, RecordStatus, ImportNow)
select p_lname, p_nickname, 1, ltrim(p_empno), left(p_jobname,40), 
	dist_code, 1, 0, 1
from [pds].[Integration_AMAG_Employee] p
where p_active = 'Y' 
OPTION (MAXDOP 1)

-- Make Inactive terminated employees
insert @tbl_emps (LastName, FirstName, CompanyID, EmployeeReference, PersonalData1, PersonalData2, 
	RecordRequest, RecordStatus, ImportNow)
select p_lname, p_nickname, 1 as compCode, ltrim(p_empno), left(p.last_job_name,40)
,last_distribution_code, 2, 0, 1
	from [pds].[Integration_AMAG_Employee] p
	where p_active = 'N' and last_job_name is not null --and p_lname in ('Bradley','Minton')
	and cast(isnull([most_recent_term_date],'1/1/1900') as date) >= cast('7/1/2006' as date)
	and  cast(isnull([most_recent_term_date],'1/1/1900') as date)  <= cast(getdate() as date)
OPTION (MAXDOP 1)
	

insert into [LTD-AMAG].[multiMAXImport].dbo.DataImportTable 
(LastName, FirstName, CompanyID, EmployeeReference, PersonalData1, PersonalData2, RecordRequest, RecordStatus, ImportNow)
select LastName, FirstName, CompanyID, EmployeeReference, PersonalData1, PersonalData2, RecordRequest, RecordStatus, ImportNow from 
(select t.LastName, t.FirstName, t.CompanyID, t.EmployeeReference, t.PersonalData1, t.PersonalData2, 
		t.RecordRequest, t.RecordStatus, t.ImportNow 
		,rn = rank() over (PARTITION BY t.EmployeeReference, t.RecordRequest 
		order by t.PersonalData1 desc) 
		from @tbl_emps t
group by t.LastName, t.FirstName, t.CompanyID, t.EmployeeReference, t.PersonalData1, t.PersonalData2, 
		t.RecordRequest, t.RecordStatus, t.ImportNow ) g
where rn = 1
OPTION (MAXDOP 1)

-- Make Inactive invalid employees
declare @tbl_empnos table (p_empno varchar(15))
insert @tbl_empnos (p_empno)
select distinct [p_empno] from [pds].[Integration_AMAG_Employee] where p_active = 'Y' 


declare @dataforcedChg int = 0 + 
(select count(*) from (
select ch.CardID 
	from [LTD-AMAG].[Multimax].[dbo].CardHolderTable ch 
	inner join [LTD-AMAG].[Multimax].[dbo].CardInfoTable ci ON ch.CardID = ci.CardID
	where ch.companyid = 1 and ci.Inactive = 0
		and rtrim(ch.EmployeeNumber) not in (select ltrim(p_empno) from @tbl_empnos)
		) i
		)

update [LTD-AMAG].[multiMAX].dbo.CardInfoTable 
set Inactive = 1, ForcedInactive = 1
where CardID in
	(
	select ch.CardID 
	from [LTD-AMAG].[Multimax].[dbo].CardHolderTable ch 
	inner join [LTD-AMAG].[Multimax].[dbo].CardInfoTable ci ON ch.CardID = ci.CardID
	where ch.companyid = 1 and ci.Inactive = 0
		and rtrim(ch.EmployeeNumber) not in (select ltrim(p_empno) from @tbl_empnos)
		)

declare @datamove int
select @datamove = 0 + 
	(select count(distinct EmployeeReference) from @tbl_emps)

declare @prgmcount varchar(255) = 'LTD_DW.amag.Update_Employee_from_PDS - '+ cast(isnull(@datamove,0) as varchar(32))+ ' Employees'
insert [process].[MergeLogs] (
	   [MergeCode]
      ,[ObjectDestination]
      ,[ObjectSource]
      ,[ObjectProgram]
      ,[recInsert]
      ,[recUpdate]
      ,[recDelete]
      ,[MergeBeginDatetime]
	  ,MergeEndDatetime)
	  Values(
	  'AMAE', '[LTD-AMAG].[multiMAXImport].dbo.DataImportTable','AMAG',@prgmcount, isnull(@datamove,0), isnull(@dataforcedChg,0), 0, @startdt, sysdatetime())



END TRY	  

BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
                    FROM msdb.dbo.sysmail_profile
                    )
       DECLARE @errormsg VARCHAR(max)
             ,@error INT
             ,@message VARCHAR(max)
             ,@xstate INT
             ,@errsev INT
             ,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER()
             ,@errsev = ERROR_SEVERITY()
             ,@message = ERROR_MESSAGE()
             ,@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + isnull(@SPROC, '') + ': ' + cast(isnull(@error, '') AS NVARCHAR(32)) + '|' + coalesce(@message, '') + '|' + cast(isnull(@xstate, '') AS NVARCHAR(32)) + '|' +cast(isnull(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'barb.eichberger@ltd.org;support@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
