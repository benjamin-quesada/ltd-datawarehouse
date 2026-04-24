SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [itk].[Update_iTRAKEmployee_from_PDS]
as


/*
  CREATED: 20210226
   AUTHOR: B EICHBERGER
  PURPOSE: Collect updates for iTRAK Employee Table.
CHANGEDON: 
 CHANGEBY: 
   CHANGE: 

exec itk.Update_iTRAKEmployee_from_PDS

------------------LTD_GLOSSARY---------------
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

declare @startdt datetime = sysdatetime()
declare @propGUID uniqueidentifier 
select @propGUID = '49CCFD6A-F79A-4631-934E-AEE8B9FF01C7' 

--DECLARE @id uniqueidentifier
--SET @id =  '49CCFD6A-F79A-4631-934E-AEE8B9FF01C7' 
--Create Table #temp1(AppId uniqueidentifier)



update [process].[MergeLogs] 
set [MergeEndDatetime] = sysdatetime()
   where mergecode = 'EMP'
     and [ObjectDestination] = 'LTD_DW.itk.Employee'
	 AND [ObjectSource] = 'ITRAK'
	 AND [ObjectProgram] = 'LTD_DW.itk.Update_iTRAKEmployee_from_PDS'
	 AND [MergeEndDatetime] is null
	 AND recInsert = 0
	 AND recUpdate = 0
	 AND recDelete = 0

	-- CONVERT(VARCHAR(255), id) = 'd65cafc-1435-45d3-acce-dc464f02c4b1' 

CREATE TABLE #setupEmployee(
	[PropertyGUID] [uniqueidentifier] NULL,
	[FirstName] [varchar](30) NULL,
	[MiddleName] [varchar](30) NULL,
	[LastName] [varchar](30) NULL,
	[StreetAddress] [varchar](120) NULL,
	[City] [varchar](30) NULL,
	[State] [varchar](8) NULL,
	[ZipCode] [varchar](15) NULL,
	[PhoneNumber] [varchar](50) NULL,
	[EmployeeID] [varchar](9) NULL,
	[DateHired] [date] NOT NULL,
	[DateFired] [date] NULL,
	[DateOfSeniority] [date] NULL,
	[Department] [varchar](12) NULL,
	[JobPosition] [varchar](80) NULL,
	[SupervisorGUID] [uniqueidentifier] NULL,
	[Division] [varchar](15) NULL,
	[CellPhoneNumber] [varchar](50) NULL,
	[Gender] [varchar](1) NULL
) ON [PRIMARY]
INSERT #setupEmployee

SELECT [PropertyGUID] = @propGUID
      ,[FirstName]		= v.p_fname 
      ,[MiddleName]		= v.p_mi
      ,[LastName]		= v.p_lname
      ,[StreetAddress]	= v.street
      ,[City]			= v.city
      ,[State]			= v.[state]
      ,[ZipCode]		= v.zip
      ,[PhoneNumber]	= v.telephone_number
      ,[EmployeeID]		= v.p_empno
      ,[DateHired]		= v.most_recent_hire_date  
      ,[DateFired]		= case when c.DateFired is null and v.most_recent_term_date > '1900-01-01' then v.most_recent_term_date else null end
      ,[DateOfSeniority]= case when y.[DateOfSeniority] is null and v.seniority_date > '1900-01-01' then v.seniority_date else null end  
      ,[Department]		= v.p_department
      ,[JobPosition]	= v.p_jobname
      ,[SupervisorGUID]	=  CONVERT(uniqueidentifier, s.EmployeeGUID)
      ,[Division]		= v.dist_abbreviation
      ,[CellPhoneNumber]= v.mobile_phone_number
      ,[Gender]			= v.gender_code 
  FROM [pds].[Integration_iTRAK_Employee] v
  left join  (
		select  e1.empno_supervisor,e1.p_empno
		, k.EmployeeGUID
		from [pds].[Integration_iTRAK_Employee] e1
		left join [itk].[Employee] k WITH (NOLOCK) on k.EmployeeID = e1.empno_supervisor
		where empno_supervisor is not null
		) s on s.p_empno = v.p_empno
  left join  (
		select  k.EmployeeID, k.DateFired
		from [itk].[Employee] k WITH (NOLOCK) 
		where DateFired is not null and EmployeeID is not null
		) c on c.EmployeeID = v.p_empno
  left join  (
		select  EmployeeID, DateOfSeniority
		from [itk].[Employee] WITH (NOLOCK) 
		where DateOfSeniority is not null and EmployeeID is not null
		) y on y.EmployeeID = v.p_empno


 --select * from #setupEmployee


DECLARE @OutputTbl TABLE (ActionName varchar(32))

MERGE [itk].[Employee] t
using #setupEmployee s
ON t.employeeid = s.employeeid
WHEN NOT MATCHED THEN INSERT
(PropertyGUID
,FirstName
,MiddleName
,LastName
,StreetAddress
,City
,[State]
,ZipCode
,PhoneNumber
,EmployeeID
,DateHired
,DateFired
,DateOfSeniority
,Department
,JobPosition
,SupervisorGUID
,Division
,CellPhoneNumber
,Gender
,[DateCreated]	
,[DateModified]	
,[ModifiedBy]
,supervisorLevel
,[MondayOff]
,[TuesdayOff]
,[WednesdayOff]
,[ThursdayOff]
,[FridayOff]
,[SaturdayOff]
,[SundayOff]
,[GamingRelated]
)
VALUES
(s.PropertyGUID
,s.FirstName
,s.MiddleName
,s.LastName
,s.StreetAddress
,s.City
,s.[State]
,s.ZipCode
,s.PhoneNumber
,s.EmployeeID
,s.DateHired
,s.DateFired
,s.DateOfSeniority
,s.Department
,s.JobPosition
,s.SupervisorGUID
,s.Division
,s.CellPhoneNumber
,s.Gender
,getdate()
,getdate()
,'dba'
,0
,0
,0
,0
,0
,0
,0
,0
,0)
WHEN MATCHED AND 
(   ISNULL(t.[FirstName],'') <> ISNULL(s.[FirstName],'')
OR  ISNULL(t.[MiddleName],'') <> ISNULL(s.[MiddleName],'')
OR  ISNULL(t.[LastName],'') <> ISNULL(s.[LastName],'')
OR  ISNULL(t.[StreetAddress],'') <> ISNULL(s.[StreetAddress],'')
OR  ISNULL(t.[City],'') <> ISNULL(s.[City],'')
OR  ISNULL(t.[State],'') <> ISNULL(s.[State],'')
OR  ISNULL(t.[ZipCode],'') <> ISNULL(s.[ZipCode],'')
OR  ISNULL(t.[PhoneNumber],'') <> ISNULL(s.[PhoneNumber],'')
OR  ISNULL(t.[EmployeeID],'') <> ISNULL(s.[EmployeeID],'')
OR  t.[DateHired] <> s.[DateHired]
OR  isnull(t.[DateFired],'1900-01-01') <> s.[DateFired]
OR  ISNULL(t.[DateOfSeniority],'1900-01-01') <> s.[DateOfSeniority]
OR  ISNULL(t.[Department],'') <> ISNULL(s.[Department],'')
OR  ISNULL(t.[JobPosition],'') <> ISNULL(s.[JobPosition],'')
OR  ISNULL(cast(t.[SupervisorGUID] as varchar(255)),'') <> ISNULL(cast(s.[SupervisorGUID] as varchar(255)),'')
OR  ISNULL(t.[Division],'') <> ISNULL(s.[Division],'')
OR  ISNULL(t.[CellPhoneNumber],'') <> ISNULL(s.[CellPhoneNumber],'')
OR  ISNULL(t.[Gender],'') <> ISNULL(s.[Gender],''))
THEN UPDATE
SET 
t.[FirstName] = s.[FirstName],
t.[MiddleName] = s.[MiddleName],
t.[LastName] = s.[LastName],
t.[StreetAddress] = s.[StreetAddress],
t.[City] = s.[City],
t.[State] = s.[State],
t.[ZipCode] = s.[ZipCode],
t.[PhoneNumber] = s.[PhoneNumber],
t.[EmployeeID] = s.[EmployeeID],
t.[DateHired] = s.[DateHired],
t.[DateFired] = replace(s.[DateFired],'1900-01-01',null),
t.[DateOfSeniority] = replace(s.[DateOfSeniority],'1900-01-01',null),
t.[Department] = s.[Department],
t.[JobPosition] = s.[JobPosition],
t.[SupervisorGUID] = s.[SupervisorGUID],
t.[Division] = s.[Division],
t.[CellPhoneNumber] = s.[CellPhoneNumber],
t.[Gender] = s.[Gender],
t.[DateModified] = getdate(),
t.[ModifiedBy] = 'dba'
OUTPUT $action INTO @outputtbl;

declare @i int = (select isnull(count(*),0) from @OutputTbl where ActionName = 'Insert' group by ActionName )
declare @u int = (select isnull(count(*),0) from @OutputTbl where ActionName = 'Update' group by ActionName )


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
	  'EMP', 'LTD_DW.itk.Employee','ITRAK','LTD_DW.itk.Update_iTRAKEmployee_from_PDS',isnull(@i,0), isnull(@u,0), 0, @startdt, sysdatetime())



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
