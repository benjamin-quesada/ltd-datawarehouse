SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE	 [ops].[z get_employee_contact_with_pds]
AS

BEGIN TRY

-- exec [ops].[get_employee_contact_with_pds]
set nocount on;

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

DROP TABLE IF EXISTS -- select * from 
Wrk.temployee_contact_with_pds
CREATE TABLE Wrk.temployee_contact_with_pds(
	[SourceSystem] [varchar](5) NULL,
	[personnelid] [varchar](12) NULL,
	[emp_SID] [int] NULL,
	[contact_seq] [smallint] NULL,
	[beginDate] [datetime2](7) NULL,
	[contactRelation] [varchar](16) NULL,
	[contactName] [varchar](90) NULL,
	--[streetAddress] [varchar](90) NULL,
	--[city] [varchar](25) NULL,
	--[state] [varchar](2) NULL,
	--[zipCode] [varchar](15) NULL,
	[phoneNum1] [varchar](14) NULL,
	[phoneType1] [varchar](8) NULL,
	[phoneNum2] [varchar](14) NULL,
	[phoneType2] [varchar](8) NULL,
	[phoneNum3] [varchar](14) NULL,
	[phoneType3] [varchar](8) NULL,
	[phoneNum4] [varchar](14) NULL,
	[phoneType4] [varchar](8) NULL,
	[comments] [varchar](255) NULL,
	[contactFlags] [smallint] NULL
)
INSERT Wrk.temployee_contact_with_pds([SourceSystem]
      ,[personnelid]
      ,[emp_SID]
      ,[contact_seq]
      ,[beginDate]
      ,[contactRelation]
      ,[contactName]
      --,[streetAddress]
      --,[city]
      --,[state]
      --,[zipCode]
      ,[phoneNum1]
      ,[phoneType1]
      ,[phoneNum2]
      ,[phoneType2]
      ,[phoneNum3]
      ,[phoneType3]
      ,[phoneNum4]
      ,[phoneType4]
      ,[comments]
      ,[contactFlags])
SELECT 'Midas' AS SourceSystem
      ,e.personnelid
	  ,e.emp_SID --, e.personnelID, e.lastName
	  ,c.contact_seq
	  ,CAST(c.beginDate AS DATETIME2) beginDate
	  ,c.contactRelation
	  ,CASE WHEN RTRIM(c.contactName) LIKE '% [A-Z]' THEN c.contactName+'.' ELSE c.contactName END contactName
	  --,c.streetAddress
	  --,c.city
	  --,c.[state]
	  --,c.zipCode
	  ,c.phoneNum1
	  ,c.phoneType1
	  ,c.phoneNum2
	  ,c.phoneType2
	  ,c.phoneNum3
	  ,c.phoneType3
	  ,c.phoneNum4
	  ,c.phoneType4
	  ,c.comments
	  ,c.contactFlags 
FROM  [ltd-ops].midas.dbo.employeeContact c
JOIN [ltd-ops].midas.dbo.employee e ON e.emp_SID = c.emp_SID
join ( select * FROM [ltd_dw].[pds].[Integration_EmpPerson]
		  where termination_date is null or termination_date = '1900-01-01 00:00:00.0000000'
		  and hr_is_active = 'Y'
		  and emp_person_status = 'Current'
		  and organization_code = 'OPS') i on i.employee_id collate SQL_Latin1_General_CP1_CI_AS = e.personnelid collate SQL_Latin1_General_CP1_CI_AS
where c.contactRelation <> 'PERF'
--and e.personnelID = 839

INSERT Wrk.temployee_contact_with_pds([SourceSystem]
      ,[personnelid]
      ,[emp_SID]
      ,[contact_seq]
      ,[beginDate]
      ,[contactRelation]
      ,[contactName]
      --,[streetAddress]
      --,[city]
      --,[state]
      --,[zipCode]
      ,[phoneNum1]
      ,[phoneType1]
      ,[phoneNum2]
      ,[phoneType2]
      ,[phoneNum3]
      ,[phoneType3]
      ,[phoneNum4]
      ,[phoneType4]
      ,[comments]
      ,[contactFlags])
	 SELECT 'PDS', t.employee_id 
	 ,t.employee_id  
	 ,t.[priority] 
	 ,t.record_created_date
	 ,upper(t.relationship)
		,t.contact_name
		--,t.address_line1 
		--		+ ' ' + t.address_line2
		--		+ ' ' + t.address_line3
		--		+ ' ' + t.address_line4
		--,t.city
		--,t.[state]
		--,t.zip 
		,t.phone_number1
		,null
		,t.phone_number2
		,null
		,t.phone_number3
		,NULL
        ,NULL 
		,NULL
		,NULL 
		,NULL
	FROM -- select * from 
	pds.Integration_EmpContact t 
	JOIN pds.Integration_EmpPerson p ON p.person_id = t.person_id
	WHERE p.organization_code = 'OPS'
	AND p.emp_person_status = 'Current'
	and p.hr_is_active = 'Y'
	--and p.employee_id = 839

INSERT Wrk.temployee_contact_with_pds
(SourceSystem, personnelid, emp_SID, contact_seq, beginDate, contactRelation, contactName
--streetAddress, city, state, zipCode
, phoneNum1, phoneType1, phoneNum2, phoneType2)
SELECT 'PDS' , e.employee_id
,e.employee_id
,0 
,e.emp_status_date
,'SELF'
,dbo.[fn_GetFullName_LastFirstM](e.first_name,e.middle_initial, e.last_name)  fullname
--,a.[address_lines]
--,a.city
--,a.[state]
--,a.zip_code
,c.phone_number
,c.phone_code
,h.phone_number
,h.phone_code
FROM pds.Integration_EmpPerson e
--JOIN pds.Integration_EmpAddress a ON a.person_id = e.person_id
LEFT JOIN pds.Integration_EmpPhone c WITH (NOLOCK) ON c.person_id = e.person_id
LEFT JOIN pds.Integration_EmpPhone h WITH (NOLOCK) ON h.person_id = e.person_id
WHERE c.emp_phone_status = 'Current'
and h.emp_phone_status = 'Current'
AND e.emp_person_status = 'Current'
and c.phone_code = 'CELL'
and h.phone_code = 'HOME'
and e.hr_is_active = 'Y'
AND e.organization_code = 'OPS'	
and c.emp_phone_status = 'Current'
--and e.employee_id = 839
GROUP BY 
e.employee_id
,e.emp_status_date
,dbo.[fn_GetFullName_LastFirstM](e.first_name,e.middle_initial, e.last_name)
--,a.[address_lines]
--,a.city
--,a.[state]
--,a.zip_code
,c.phone_number
,c.phone_code
,h.phone_number
,h.phone_code

--SELECT SourceSystem
--	  ,personnelid
--	  ,emp_SID
--	  ,contact_seq
--	  ,beginDate
--	  ,contactRelation
--	  ,contactName
--	  ,streetAddress
--	  ,city
--	  ,state
--	  ,zipCode
--	  ,phoneNum1
--	  ,phoneType1
--	  ,phoneNum2
--	  ,phoneType2
--	  ,phoneNum3
--	  ,phoneType3
--	  ,phoneNum4
--	  ,phoneType4
--	  ,comments
----	  ,contactFlags 

--delete from Wrk.temployee_contact_with_pds where contactRelation = 'SELF' and contactName is null
--select * 
--FROM Wrk.temployee_contact_with_pds --where contactName is not null
--order by personnelid
----truncate table ops.employee_contact_with_pds
	  
END TRY	  


BEGIN CATCH

       DECLARE @profile VARCHAR(255) = (
                    SELECT NAME
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
             ,@recipients = 'barb.eichberger@ltd.org'--;servicedesk@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH
GO
