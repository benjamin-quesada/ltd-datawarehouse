SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [process].[SEND_DICTIONARY_TERMS_UPDATE]
as
/*



-- exec  process.SEND_DICTIONARY_TERMS_UPDATE

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


 declare @sqlcmd nvarchar(MAX)
 declare @orderBy nvarchar(MAX)
 declare @headercmd nvarchar(max)

Select @headercmd = N'As a member of the Data Governance Committee, and/or an SME Team member selected by a Committee member, you are receiving a list of TERMS from the Data Dictionary which is part of the LTD Data Governance Initiative. These TERMS are assigned to you (and/or the receiving email group) as Subject Matter Expert(s). Please review the data dictionary <a href= "file:///Q:/IS/Public/Data%20Dictionary/dataedo-data-dictionary/index.local.html#/doc/bg14/lane-transit-district-ltd-business-glossary">here</a>.
	<br><br>
	This is your intermittent email notification related to Data Governance Terms and Modules. Please share feedback about the form, ask questions of the SME, and feel free also to email barb.eichberger@ltd.org with questions, updates or data dictionary TERMS suggested additions.
	<br><br>
	The Next Steps Are: '+'
	<ol>
  <li>Evaluate the Business Terms listed here keeping in mind their specific relevance, purpose and value to LTD Business</li>
  <li>Copy the table out and paste it into Excel to add description, links to other data or departments, lists of people that are most relevant or SMEs. If this list is incorrect or incomplete, please add or change details.</li>
  <li><strong>In all cases</strong> -- email the completed spreadsheet, or updated text in columns, to barb.eichbegrer@ltd.org at your earliest convenience!</li>
</ol><br><i> ---easy peasy--- </i>
	<br><br>'

create table #smelist (
rwnbr INT identity(1,1) NOT NULL, SME varchar(255), emailreadySME varchar(255))

INSERT #smelist ( sme, emailreadySME)
select distinct field3 as SME , replace(field3, ',',';')
from [dataedo].[dbo].[glossary_terms] where len(rtrim(ltrim(field3))) > 1
--and field3 = 'barb.eichberger@ltd.org'

-- select * from #smelist

declare @i INT = 1
declare @r INT = (select max(rwnbr) from #smelist)
declare @smes varchar(255)
While @i <= @r
BEGIN

declare @emailsme varchar(255) = (select emailreadySME from #smelist where rwnbr = @i)
Select @smes = (select sme from #smelist where rwnbr = @i);

select @sqlcmd = N'
SELECT  [title] as [Term Title]
       ,[field1] as [AKA]
       ,[field4] as Domain
    ,[field3] as SME
	 ,field7 as [SME Team]
     ,[description_plain] Described
      ,[field2] as [Term Status]
       ,[field5] as isKPI
      ,cast([creation_date] as date) [Created On]
      ,[created_by] as [Created By]
      ,cast([last_modification_date] as date) as [Last Modified]
      ,[modified_by] as [Last Modified By]
  FROM [dataedo].[dbo].[glossary_terms]
	  where field3 = '''+@smes+'''', @orderBy = N'ORDER BY [Created On] DESC, [Last Modified] DESC';
	  --print @sqlcmd
	  --print @headercmd

DECLARE @html nvarchar(MAX);
EXEC process.spQueryToHtmlTable @html = @html OUTPUT
,@query = @sqlcmd, @header = @headercmd

EXEC msdb.dbo.sp_send_dbmail
    @profile_name = 'SQLData',
	@from_address = 'Data Governance News <barb.eichberger@ltd.org>',
    @recipients =  @emailsme,
    @subject = 'Dataedo Data Dictionary Updates',
    @body = @html,
    @body_format = 'HTML',
    @query_no_truncate = 1,
    @attach_query_result_as_file = 0

select @i = @i + 1

if @i > @r
BREAK
	ELSE CONTINUE

END
GO
