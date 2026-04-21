SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [pds].[z EmployeeRolesHistory]
AS

/*******************************
CREATED ON	: 20250324
CREATED BY	: B. Eichberger
PURPOSE		: Output data spanning abra and current dates/current HR system PDS
			  Report output only. Used by BI in Power BI reports.
USE			: exec pds.EmployeeRolesHistory (no parameters)
REFERENCE	: 34731 PDS Employee Dates

*/

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

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



DROP TABLE IF EXISTS #jobcleaner
CREATE TABLE #jobcleaner (old_job VARCHAR(255), new_job VARCHAR(255))
INSERT INTO #jobcleaner(old_job,new_job)

VALUES ('Trans Ops Supervisor','Transit Operations Supervisor'),
('Trans Ops Supervi','Transit Operations Supervisor'),
('Trans Ops Supervisor','Transit Operations Supervisor'),
('General Serv Worker','General Service Worker'),
('Journey Mechanic','Journeyman Mechanic'),
('Sustainability Prog Mgr','Sustainability Program Manager'),
('Inventory Tech','Inventory Technician'),
('Lead Inventory Tech','Lead Inventory Technician'),
('Access Svcs Specialist','Accessible Services Specialist'),
('Business Proc Associate','Applications Administrator'),
('Customer Serv Rep','Customer Service Representative'),
('Trans Pub Sfty Officer','Public Safety Officer'),
('Trans Pub Sfty Lieutenant','Transit Public Safety Lieutenant'),
('Fare Inspector','Transit Fare Inspector'),
('Rideshare Prgm As','Rideshare Prgm Assist'),
('Fac Maint Generalist I','Facilities Maintenance Generalist I'),
('Facilities Project Mgr','Facilities Project Manager'),
('Intell. Trans. Syst. Mgr','Intelligent Transportation System Manager'),
('General Serv Work','General Service Worker'),
('Fare Inspector','Transit Fare Inspector'),
('Accounting Techni','Accounting Technician'),
('Actg Tech','Accounting Technician'),
('Admin Services AS','Admin Services Assistant'),
('Administrative Se','Administrative Secretary'),
('General Service W','General Service Worker'),
('Human Resources T','Human Resources Tech'),
('Inventory Sprvr','Inventory Supervisor'),
('Inventory Supervi','Inventory Supervisor'),
('Inventory Technic','Inventory Technician'),
('Journeyman Mechan','Journeyman Mechanic'),
('Lead CSC Rep','Lead CSC Representative'),
('Lead Equip Detail Tech','Lead Equipment Detail Technician'),
('Lead Inside Clean','Lead Inside Cleaner'),
('Lead Inventory Te','Lead Inventory Technician'),
('Marketing Rep','Marketing Representative'),
('Marketing Represe','Marketing Representative'),
('Marketing Technic','Marketing Technician'),
('Materials Mgmt Supervisor','Materials Management Supervisor'),
('Accounting Assist','Accounting Assistant'),
('Business Proc Assistant','Business Process Associate'),
('Business Proc Associate','Business Process Associate'),
('Business Process Mgr','Business Process Manager'),
('CSC Representativ','Customer Service Representative'),
('Database Admin/So','Database Admin/SoftEnginr'),
('Equipment Detail Tech','Equipment Detail Technician'),
('EugSta/Security M','EugSta/Security Mngr'),
('Fleet Svcs Mngr','Fleet Svcs Manager'),
('Fleet Svcs Manage','Fleet Svcs Manager'),
('Transit Developmt Planner','Transit Development Planner'),
('SP&M Manager','Service Planning Manager'),
('Transit Planner-S','Sr Service Planner'),
('Sr Service Planne','Sr Service Planner'),
('Customer Service','Customer Service Representative'),
('Admin Secretary','Administrative Secretary'),
('Admin Services Co','Admin Services Coordinator'),
('Admin Services Coordinatr','Admin Services Coordinator'),
('Transit Planner-P','Transit Planner'),
('Transit Svcs Admn','Transit Services'),
('Admin Sec 1','Administrative Secretary'),
('Assistant General','Assistant General Manager'),
('Asst General Mngr','Assistant General Manager'),
('C.S.C. Supervisor','CSC Supervisor'),
('Executive Secreta','Executive Secretary'),
('C.S.C. Supervisor','CSC Supervisor'),
('Computer Sys Anal','Computer Sys Analyst'),
('Graphics Designer','Graphic Designer'),
('Instructnl Prgms','Human Resources Training Specialist') ,     
('Instructional Coo','Human Resources Training Specialist'),     
('Training Speciali','Human Resources Training Specialist' ),       
('Transit Ops Train','Operations Training Specialist' )  , 
('Fleet Svcs Sprvr','Fleet Services Supervisor')

--SELECT distinct role_name FROM pds.Integration_EmpRoleHistory WHERE role_name LIKE '%Fleet%'
-- get the abra header level details
DROP TABLE IF EXISTS #prepAbrapeople
SELECT p_empno = RTRIM(LTRIM(p_empno))
,p_lname = RTRIM(LTRIM(p_lname))
,p_fname = RTRIM(LTRIM(p_fname))
,p_orighire
,p_termdate AS termdate
INTO #prepAbrapeople
FROM [LTD-FINANCE].[abra_dw].[dbo].[hrpersnl]
GROUP BY 
RTRIM(LTRIM(p_empno))
,RTRIM(LTRIM(p_lname))
,RTRIM(LTRIM(p_fname))
,p_orighire, p_termdate;

--SELECT * FROM #prepAbrapeople ORDER by [p_lname]

-- get all the jobs for the abra people
DROP TABLE IF EXISTS #prepabrajobs
SELECT j_empno = CAST(RTRIM(LTRIM(s.j_empno)) AS INT)
--,j_level2 = RTRIM(LTRIM(s.j_level2))
,j_jobtitle =  RTRIM(LTRIM(s.j_jobtitle))
,new_jobtitle = COALESCE(c.new_job, s.j_jobtitle)
,[start_date] = MIN(s.j_jobdate)
--,end_date = MAX(j_effdate)
INTO #prepabrajobs 
FROM [LTD-FINANCE].[abra_dw].[dbo].hjobhis s 
JOIN #prepAbrapeople p ON p.p_empno = RTRIM(LTRIM(s.j_empno))
LEFT JOIN #jobcleaner c ON c.old_job = RTRIM(LTRIM(s.j_jobtitle))
WHERE s.j_jobdate IS NOT NULL
	  AND RTRIM(LTRIM(s.j_jobtitle)) NOT LIKE '%unclass%'
	  AND s.j_jobdate IS not null 
	  --AND (s.j_termdate IS NOT NULL -- anyone that continued on past abra days will have terms in pds
			--OR dbo.block_trips_end_spm_today
	  AND RTRIM(LTRIM(s.j_jobtitle)) <> '[None]'
	  AND RTRIM(LTRIM(s.j_jobtitle)) <> ''
GROUP BY COALESCE(c.new_job, s.j_jobtitle)
,RTRIM(LTRIM(j_empno)), RTRIM(LTRIM(s.j_jobtitle))
ORDER BY j_empno,  start_date

--select * from #prepabrajobs order by j_jobtitle

-- put people and jobs together from abra
DROP TABLE IF EXISTS #abrajobs
SELECT DISTINCT a.p_empno
	  ,a.p_lname
	  ,a.p_fname
	  ,a.p_orighire
	  ,a.j_jobtitle
	  ,a.start_dt
	  --,a.end_dt
	  ,a.termdate
INTO #abrajobs 
FROM (
SELECT p_empno= CAST(p.p_empno AS INT)
	  ,p.p_lname
	  ,p.p_fname
	  ,p_orighire = CAST(p_orighire as date)
	  --,b.j_level2
	  ,b.new_jobtitle AS j_jobtitle
	  ,MIN(b.start_date) start_dt
	  --,MAX(b.end_date) end_dt
	  ,p.termdate 
FROM #prepAbrapeople p
JOIN #prepabrajobs b ON b.j_empno = p.p_empno
--WHERE b.start_date <> b.end_date
--AND p_empno IN (1052,1074)
GROUP BY 
p.p_empno
	  ,p.p_lname
	  ,p.p_fname
	  ,CAST(p.p_orighire AS DATE)
	  ,b.new_jobtitle
	  ,p.termdate
	) a
WHERE 1=1
--and a.p_empno IN (1052,1074)
ORDER BY a.p_empno, a.p_orighire, a.start_dt

drop table if EXISTS #abrajobsList
-- get the dates corrected so no overlap or duplication
select j.p_empno
	  ,j.p_lname
	  ,j.p_fname
	  ,j.p_orighire
	  ,j.j_jobtitle
	  ,j.start_dt
	  ,end_dt = CASE when j.end_dt IS NULL AND j.termdate IS NOT NULL THEN j.termdate ELSE end_dt END
	  --,MAX(j.termdate) OVER (PARTITION BY j.p_empno ORDER by j.start_dt, j.end_dt,j.termdate) max_term_date
into #abrajobsList
FROM (
SELECT p_empno, p_lname, p_fname, p_orighire, j_jobtitle, start_dt
,end_dt = dateadd(DAY,-1,LEAD(start_dt, 1) OVER (PARTITION BY p_empno ORDER by start_dt)), termdate
FROM #abrajobs ) j
ORDER by p_lname,start_dt



DROP TABLE IF EXISTS #pdsjobs
-- get all the pds jobs that are not rehires, those are handled separately
 SELECT p.person_id,employee_id, last_name, first_name, hire_date = CAST(hire_date as date)
 ,h.role_name, CAST(h.start_date AS DATE) start_date
 ,new_end_date = DATEADD(DAY,-1,LEAD(h.start_date,1) over (PARTITION BY p.person_id ORDER by p.hire_date, h.start_date, h.end_date))
 ,end_date = CASE when cast(h.end_date as DATE) = '1/1/1900' then null ELSE CAST(h.end_date as DATE) END
into #pdsjobs
FROM ltd_dw.pds.Integration_EmpPerson p
 LEFT JOIN ltd_dw.pds.Integration_EmpRoleHistory h ON h.person_id = p.person_id
			WHERE CAST(rehire_date AS DATE) = '1/1/1900' 
and RTRIM(LTRIM(p.organization)) <> '' AND p.organization <> 'Any Organization'
GROUP by p.person_id,employee_id, last_name, first_name, hire_date
 ,h.role_name, h.start_date, h.end_date 
ORDER by last_name, start_date, end_date

--SELECT * FROM  #pdsjobs ORDER by last_name,hire_date, start_date

DROP TABLE if EXISTS #crossComplete
SELECT r.employee_id
	  ,r.last_name
	  ,r.first_name
	  ,r.hire_date
	  ,r.role_name
	  ,r.start_date as start_dt
	  ,r.end_date AS end_dt
into #crossComplete
FROM (
SELECT t.employee_id
	  ,t.last_name
	  ,t.first_name
	  ,t.hire_date
	  ,t.role_name
	  ,t.start_date
	  ,t.end_date
	  ,CASE WHEN t.next_role_name = role_name AND t.end_date IS NULL THEN 0 ELSE 1 END AS rowkeeper
FROM (
SELECT employee_id
	  ,last_name
	  ,first_name
	  ,hire_date
	  ,role_name
	  ,start_date
	  ,end_date 
	  ,next_role_name = LEAD(role_name,1) OVER (PARTITION BY employee_id ORDER BY start_date, end_date)
FROM (
		SELECT CAST(employee_id AS INT) employee_id
			  ,last_name
			  ,first_name
			  ,hire_date
			  ,role_name
			  ,start_date
			  ,end_date
			  	FROM #pdsjobs
	
		UNION

		SELECT p_empno
			  ,p_lname
			  ,p_fname
			  ,p_orighire
			  ,j_jobtitle
			  ,start_dt
			  ,end_dt = CASE when termdate IS null THEN DATEADD(DAY,-1,LEAD(start_dt,1) OVER (PARTITION BY p_empno ORDER by start_dt))
							ELSE termdate end
			   
			 FROM #abrajobs  
		) k
	) t
) r WHERE r.rowkeeper = 1
AND NOT (r.role_name IS NULL AND r.start_date IS NULL AND r.end_date IS NULL )
ORDER BY last_name,first_name,start_date, end_date

--SELECT * FROM #crossComplete ORDER BY last_name, start_dt, end_dt

-- grab all rehires and add them to the mix
drop TABLE IF EXISTS #rehires
select rn = ROW_NUMBER() OVER (ORDER by i.last_name, i.first_name, hire_date)
, i.person_id, i.employee_id, i.last_name, i.first_name, i.hire_date 
INTO #rehires 
FROM (SELECT DISTINCT 
		person_id,employee_id, last_name, first_name, hire_date
		FROM ltd_dw.pds.Integration_EmpPerson p
					WHERE CAST(rehire_date as DATE) > '1/1/1900' 
		) i
ORDER BY i.last_name, i.hire_date
--SELECT * from #rehires 

DECLARE @i INT = 1
DECLARE @r INT = (select MAX(rn) from #rehires)

DECLARE @currEmp INT
DECLARE @currhireDt DATE

WHILE @i <= @r
BEGIN

-- SELECT * FROM #rehires order by person_id,employee_id, hire_date

SELECT @currEmp = (SELECT employee_id from #rehires where rn = @i)
SELECT @currhireDt = (SELECT hire_date from #rehires WHERE rn = @i)

INSERT #crossComplete
(
	employee_id
   ,last_name
   ,first_name
   ,hire_date
   ,role_name
   ,start_dt
   ,end_dt
   --,termination_date
   --,source_flag
)

SELECT v.employee_id
	  ,v.last_name
	  ,v.first_name
	  ,v.hire_date
	  ,v.role_name
	  ,v.start_dt
	  ,v.end_dt
	  --,termination_date = CASE WHEN v.termination_date < hire_date THEN NULL ELSE v.termination_date end 
	  --,source_flag = 'R'
FROM (
SELECT DISTINCT h.person_id,m.employee_id,m.last_name
	  ,m.first_name
	  ,hire_date = cast(m.hire_date AS date)
	  ,h.role_name
	  ,h.start_date AS start_dt
	  ,end_dt = CASE WHEN h.end_date = '1/1/1900' THEN NULL ELSE h.end_date END 
	  ,termination_date = MAX(CASE WHEN m.termination_date = '1/1/1900' THEN NULL 
								   ELSE m.termination_date END)
FROM ltd_dw.pds.Integration_EmpRoleHistory h
JOIN (SELECT DISTINCT person_id,employee_id, last_name, first_name, hire_date, termination_date FROM ltd_dw.pds.Integration_EmpPerson 
			WHERE employee_id = @currEmp AND hire_date = @currhireDt  ) m ON m.person_id = h.person_id AND m.hire_date = h.start_date and m.termination_date >= h.end_date
GROUP by 
h.person_id,m.employee_id,m.last_name
	  ,m.first_name
	  ,cast(m.hire_date AS date)
	  ,h.role_name
	  ,h.start_date 
	  ,CASE WHEN h.end_date = '1/1/1900' THEN NULL ELSE h.end_date END 
) v


SELECT @i = @i + 1

IF @i > @r BREAK
ELSE
	CONTINUE 

END



SELECT DISTINCT employee_id
			   ,last_name
			   ,first_name
			   ,hire_date
			   ,role_name
			   ,start_dt
			   ,end_dt 
FROM #crossComplete 
--WHERE employee_id = 1074
ORDER BY last_name, hire_date , start_dt


END TRY	 

BEGIN CATCH
       DECLARE @profile VARCHAR(255) = (
                    SELECT [NAME]
                    FROM msdb.dbo.sysmail_profile )
       DECLARE @errormsg VARCHAR(MAX),@error INT,@message VARCHAR(MAX),@xstate INT,@errsev INT,@sub VARCHAR(255);

       SELECT @error = ERROR_NUMBER(),@errsev = ERROR_SEVERITY(),@message = ERROR_MESSAGE(),@xstate = XACT_STATE();

       SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') 
+ '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' +CAST(ISNULL(@errsev, '') AS NVARCHAR(32))

       SELECT @sub = 'ERROR: ' + @SPROC

       EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
             ,@recipients = 'data@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg, @errsev
                    ,1
                    )
END CATCH

GO
GRANT EXECUTE ON  [pds].[z EmployeeRolesHistory] TO [public]
GO
