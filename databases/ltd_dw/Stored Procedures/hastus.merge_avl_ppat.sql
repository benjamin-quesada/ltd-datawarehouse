SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [hastus].[merge_avl_ppat]
as
/*-----------LTD_GLOSSARY---------------
created by	:  B Eichberger
created dt	:  2026-03-19
purpose		:  merge hastus avl files for ppat
use			:  exec hastus.merge_avl_ppat

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

begin try


declare @sdt datetime2 = sysdatetime()
declare @outputTbl table (actionNm varchar(32));


drop table if exists #ppat_setup     
create table #ppat_setup(
	[filedate] [date] null,
	[file_row_id] [int] null,
	[trp_route] [nvarchar](5) null,
	[trp_direction] [nvarchar](10) null,
	[trp_direction2] [nvarchar](2) null,
	[oa_rte_main_ppat_dir] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded6] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded7] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded8] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded9] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded10] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded11] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded12] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded13] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded14] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded15] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded16] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded17] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded18] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded19] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded20] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded21] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded22] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded23] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded24] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded25] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded26] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded27] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded28] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded29] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded30] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded31] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded32] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded33] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded34] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded35] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded36] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded37] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded38] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded39] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded40] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded41] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded42] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded43] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded44] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded45] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded46] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded47] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded48] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded49] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded50] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded51] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded52] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded53] [nvarchar](10) null,
	[oa_rte_main_ppat_plc_padded54] [nvarchar](10) null
) 

Declare @i int = 1
declare @r int = (select max(id) from hastus.avl_ppat_raw)

while @i <= @r
BEGIN

DECLARE @rawline NVARCHAR(MAX) = (select rawline from hastus.avl_ppat_raw where id = @i) --  'RTE;11;Thurston;Urban;60;Bus2;2';
declare @fdate date = (select filedate from hastus.avl_ppat_raw where id = @i) --  'RTE;11;Thurston;Urban;60;Bus2;2';
insert #ppat_setup 
SELECT @fdate filedate,@i as file_row_id,
  MAX(case when [key] = 1 THEN TRIM(isnull(value,'')) END) AS trp_route,	
MAX(case when [key] = 2 THEN TRIM(isnull(value,'')) END) AS trp_direction,	
MAX(case when [key] = 3 THEN TRIM(isnull(value,'')) END) AS trp_direction2,	
MAX(case when [key] = 4 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_dir	,
MAX(case when [key] = 5 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded6	,
MAX(case when [key] = 6 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded7	,
MAX(case when [key] = 7 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded8	,
MAX(case when [key] = 8 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded9	,
MAX(case when [key] = 9 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded10	,
MAX(case when [key] = 10 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded11	,
MAX(case when [key] = 11 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded12	,
MAX(case when [key] = 12 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded13	,
MAX(case when [key] = 13 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded14	,
MAX(case when [key] = 14 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded15	,
MAX(case when [key] = 15 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded16	,
MAX(case when [key] = 16 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded17	,
MAX(case when [key] = 17 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded18	,
MAX(case when [key] = 18 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded19	,
MAX(case when [key] = 19 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded20	,
MAX(case when [key] = 20 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded21	,
MAX(case when [key] = 21 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded22	,
MAX(case when [key] = 22 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded23	,
MAX(case when [key] = 23 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded24	,
MAX(case when [key] = 24 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded25	,
MAX(case when [key] = 25 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded26	,
MAX(case when [key] = 26 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded27	,
MAX(case when [key] = 27 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded28	,
MAX(case when [key] = 28 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded29	,
MAX(case when [key] = 29 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded30	,
MAX(case when [key] = 30 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded31	,
MAX(case when [key] = 31 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded32	,
MAX(case when [key] = 32 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded33	,
MAX(case when [key] = 33 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded34	,
MAX(case when [key] = 34 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded35	,
MAX(case when [key] = 35 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded36	,
MAX(case when [key] = 36 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded37	,
MAX(case when [key] = 37 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded38	,
MAX(case when [key] = 38 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded39	,
MAX(case when [key] = 39 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded40	,
MAX(case when [key] = 40 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded41	,
MAX(case when [key] = 41 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded42	,
MAX(case when [key] = 42 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded43	,
MAX(case when [key] = 43 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded44	,
MAX(case when [key] = 44 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded45	,
MAX(case when [key] = 45 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded46	,
MAX(case when [key] = 46 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded47	,
MAX(case when [key] = 47 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded48	,
MAX(case when [key] = 48 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded49	,
MAX(case when [key] = 49 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded50	,
MAX(case when [key] = 50 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded51	,
MAX(case when [key] = 51 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded52	,
MAX(case when [key] = 52 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded53	,
MAX(case when [key] = 53 THEN TRIM(isnull(value,'')) END) AS oa_rte_main_ppat_plc_padded54	
FROM OPENJSON('["' + REPLACE(@rawline, ';', '","') + '"]');

select @i = @i + 1

if @i > @r
BREAK
else continue


END


merge -- truncate table -- select * from 
[hastus].[avl_ppat] t
using #ppat_setup s on (
t.[filedate] = s.filedate and
t.file_row_id = s.file_row_id and
t.trp_route = s.trp_route and
t.trp_direction = s.trp_direction and
t.oa_rte_main_ppat_dir = s.oa_rte_main_ppat_dir
)
when matched and (
   isnull(t.oa_rte_main_ppat_plc_padded6,'') <>  isnull(s.oa_rte_main_ppat_plc_padded6,'')
OR isnull(t.oa_rte_main_ppat_plc_padded7,'') <>  isnull(s.oa_rte_main_ppat_plc_padded7,'')
OR isnull(t.oa_rte_main_ppat_plc_padded8,'') <>  isnull(s.oa_rte_main_ppat_plc_padded8,'')
OR isnull(t.oa_rte_main_ppat_plc_padded9,'') <>  isnull(s.oa_rte_main_ppat_plc_padded9,'')
OR isnull(t.oa_rte_main_ppat_plc_padded10,'') <>  isnull(s.oa_rte_main_ppat_plc_padded10,'')
OR isnull(t.oa_rte_main_ppat_plc_padded11,'') <>  isnull(s.oa_rte_main_ppat_plc_padded11,'')
OR isnull(t.oa_rte_main_ppat_plc_padded12,'') <>  isnull(s.oa_rte_main_ppat_plc_padded12,'')
OR isnull(t.oa_rte_main_ppat_plc_padded13,'') <>  isnull(s.oa_rte_main_ppat_plc_padded13,'')
OR isnull(t.oa_rte_main_ppat_plc_padded14,'') <>  isnull(s.oa_rte_main_ppat_plc_padded14,'')
OR isnull(t.oa_rte_main_ppat_plc_padded15,'') <>  isnull(s.oa_rte_main_ppat_plc_padded15,'')
OR isnull(t.oa_rte_main_ppat_plc_padded16,'') <>  isnull(s.oa_rte_main_ppat_plc_padded16,'')
OR isnull(t.oa_rte_main_ppat_plc_padded17,'') <>  isnull(s.oa_rte_main_ppat_plc_padded17,'')
OR isnull(t.oa_rte_main_ppat_plc_padded18,'') <>  isnull(s.oa_rte_main_ppat_plc_padded18,'')
OR isnull(t.oa_rte_main_ppat_plc_padded19,'') <>  isnull(s.oa_rte_main_ppat_plc_padded19,'')
OR isnull(t.oa_rte_main_ppat_plc_padded20,'') <>  isnull(s.oa_rte_main_ppat_plc_padded20,'')
OR isnull(t.oa_rte_main_ppat_plc_padded21,'') <>  isnull(s.oa_rte_main_ppat_plc_padded21,'')
OR isnull(t.oa_rte_main_ppat_plc_padded22,'') <>  isnull(s.oa_rte_main_ppat_plc_padded22,'')
OR isnull(t.oa_rte_main_ppat_plc_padded23,'') <>  isnull(s.oa_rte_main_ppat_plc_padded23,'')
OR isnull(t.oa_rte_main_ppat_plc_padded24,'') <>  isnull(s.oa_rte_main_ppat_plc_padded24,'')
OR isnull(t.oa_rte_main_ppat_plc_padded25,'') <>  isnull(s.oa_rte_main_ppat_plc_padded25,'')
OR isnull(t.oa_rte_main_ppat_plc_padded26,'') <>  isnull(s.oa_rte_main_ppat_plc_padded26,'')
OR isnull(t.oa_rte_main_ppat_plc_padded27,'') <>  isnull(s.oa_rte_main_ppat_plc_padded27,'')
OR isnull(t.oa_rte_main_ppat_plc_padded28,'') <>  isnull(s.oa_rte_main_ppat_plc_padded28,'')
OR isnull(t.oa_rte_main_ppat_plc_padded29,'') <>  isnull(s.oa_rte_main_ppat_plc_padded29,'')
OR isnull(t.oa_rte_main_ppat_plc_padded30,'') <>  isnull(s.oa_rte_main_ppat_plc_padded30,'')
OR isnull(t.oa_rte_main_ppat_plc_padded31,'') <>  isnull(s.oa_rte_main_ppat_plc_padded31,'')
OR isnull(t.oa_rte_main_ppat_plc_padded32,'') <>  isnull(s.oa_rte_main_ppat_plc_padded32,'')
OR isnull(t.oa_rte_main_ppat_plc_padded33,'') <>  isnull(s.oa_rte_main_ppat_plc_padded33,'')
OR isnull(t.oa_rte_main_ppat_plc_padded34,'') <>  isnull(s.oa_rte_main_ppat_plc_padded34,'')
OR isnull(t.oa_rte_main_ppat_plc_padded35,'') <>  isnull(s.oa_rte_main_ppat_plc_padded35,'')
OR isnull(t.oa_rte_main_ppat_plc_padded36,'') <>  isnull(s.oa_rte_main_ppat_plc_padded36,'')
OR isnull(t.oa_rte_main_ppat_plc_padded37,'') <>  isnull(s.oa_rte_main_ppat_plc_padded37,'')
OR isnull(t.oa_rte_main_ppat_plc_padded38,'') <>  isnull(s.oa_rte_main_ppat_plc_padded38,'')
OR isnull(t.oa_rte_main_ppat_plc_padded39,'') <>  isnull(s.oa_rte_main_ppat_plc_padded39,'')
OR isnull(t.oa_rte_main_ppat_plc_padded40,'') <>  isnull(s.oa_rte_main_ppat_plc_padded40,'')
OR isnull(t.oa_rte_main_ppat_plc_padded41,'') <>  isnull(s.oa_rte_main_ppat_plc_padded41,'')
OR isnull(t.oa_rte_main_ppat_plc_padded42,'') <>  isnull(s.oa_rte_main_ppat_plc_padded42,'')
OR isnull(t.oa_rte_main_ppat_plc_padded43,'') <>  isnull(s.oa_rte_main_ppat_plc_padded43,'')
OR isnull(t.oa_rte_main_ppat_plc_padded44,'') <>  isnull(s.oa_rte_main_ppat_plc_padded44,'')
OR isnull(t.oa_rte_main_ppat_plc_padded45,'') <>  isnull(s.oa_rte_main_ppat_plc_padded45,'')
OR isnull(t.oa_rte_main_ppat_plc_padded46,'') <>  isnull(s.oa_rte_main_ppat_plc_padded46,'')
OR isnull(t.oa_rte_main_ppat_plc_padded47,'') <>  isnull(s.oa_rte_main_ppat_plc_padded47,'')
OR isnull(t.oa_rte_main_ppat_plc_padded48,'') <>  isnull(s.oa_rte_main_ppat_plc_padded48,'')
OR isnull(t.oa_rte_main_ppat_plc_padded49,'') <>  isnull(s.oa_rte_main_ppat_plc_padded49,'')
OR isnull(t.oa_rte_main_ppat_plc_padded50,'') <>  isnull(s.oa_rte_main_ppat_plc_padded50,'')
OR isnull(t.oa_rte_main_ppat_plc_padded51,'') <>  isnull(s.oa_rte_main_ppat_plc_padded51,'')
OR isnull(t.oa_rte_main_ppat_plc_padded52,'') <>  isnull(s.oa_rte_main_ppat_plc_padded52,'')
OR isnull(t.oa_rte_main_ppat_plc_padded53,'') <>  isnull(s.oa_rte_main_ppat_plc_padded53,'')
OR isnull(t.oa_rte_main_ppat_plc_padded54,'') <>  isnull(s.oa_rte_main_ppat_plc_padded54,'')
)
then update
set 
  t.oa_rte_main_ppat_plc_padded6 = s.oa_rte_main_ppat_plc_padded6
, t.oa_rte_main_ppat_plc_padded7 = s.oa_rte_main_ppat_plc_padded7
, t.oa_rte_main_ppat_plc_padded8 = s.oa_rte_main_ppat_plc_padded8
, t.oa_rte_main_ppat_plc_padded9 = s.oa_rte_main_ppat_plc_padded9
, t.oa_rte_main_ppat_plc_padded10 = s.oa_rte_main_ppat_plc_padded10
, t.oa_rte_main_ppat_plc_padded11 = s.oa_rte_main_ppat_plc_padded11
, t.oa_rte_main_ppat_plc_padded12 = s.oa_rte_main_ppat_plc_padded12
, t.oa_rte_main_ppat_plc_padded13 = s.oa_rte_main_ppat_plc_padded13
, t.oa_rte_main_ppat_plc_padded14 = s.oa_rte_main_ppat_plc_padded14
, t.oa_rte_main_ppat_plc_padded15 = s.oa_rte_main_ppat_plc_padded15
, t.oa_rte_main_ppat_plc_padded16 = s.oa_rte_main_ppat_plc_padded16
, t.oa_rte_main_ppat_plc_padded17 = s.oa_rte_main_ppat_plc_padded17
, t.oa_rte_main_ppat_plc_padded18 = s.oa_rte_main_ppat_plc_padded18
, t.oa_rte_main_ppat_plc_padded19 = s.oa_rte_main_ppat_plc_padded19
, t.oa_rte_main_ppat_plc_padded20 = s.oa_rte_main_ppat_plc_padded20
, t.oa_rte_main_ppat_plc_padded21 = s.oa_rte_main_ppat_plc_padded21
, t.oa_rte_main_ppat_plc_padded22 = s.oa_rte_main_ppat_plc_padded22
, t.oa_rte_main_ppat_plc_padded23 = s.oa_rte_main_ppat_plc_padded23
, t.oa_rte_main_ppat_plc_padded24 = s.oa_rte_main_ppat_plc_padded24
, t.oa_rte_main_ppat_plc_padded25 = s.oa_rte_main_ppat_plc_padded25
, t.oa_rte_main_ppat_plc_padded26 = s.oa_rte_main_ppat_plc_padded26
, t.oa_rte_main_ppat_plc_padded27 = s.oa_rte_main_ppat_plc_padded27
, t.oa_rte_main_ppat_plc_padded28 = s.oa_rte_main_ppat_plc_padded28
, t.oa_rte_main_ppat_plc_padded29 = s.oa_rte_main_ppat_plc_padded29
, t.oa_rte_main_ppat_plc_padded30 = s.oa_rte_main_ppat_plc_padded30
, t.oa_rte_main_ppat_plc_padded31 = s.oa_rte_main_ppat_plc_padded31
, t.oa_rte_main_ppat_plc_padded32 = s.oa_rte_main_ppat_plc_padded32
, t.oa_rte_main_ppat_plc_padded33 = s.oa_rte_main_ppat_plc_padded33
, t.oa_rte_main_ppat_plc_padded34 = s.oa_rte_main_ppat_plc_padded34
, t.oa_rte_main_ppat_plc_padded35 = s.oa_rte_main_ppat_plc_padded35
, t.oa_rte_main_ppat_plc_padded36 = s.oa_rte_main_ppat_plc_padded36
, t.oa_rte_main_ppat_plc_padded37 = s.oa_rte_main_ppat_plc_padded37
, t.oa_rte_main_ppat_plc_padded38 = s.oa_rte_main_ppat_plc_padded38
, t.oa_rte_main_ppat_plc_padded39 = s.oa_rte_main_ppat_plc_padded39
, t.oa_rte_main_ppat_plc_padded40 = s.oa_rte_main_ppat_plc_padded40
, t.oa_rte_main_ppat_plc_padded41 = s.oa_rte_main_ppat_plc_padded41
, t.oa_rte_main_ppat_plc_padded42 = s.oa_rte_main_ppat_plc_padded42
, t.oa_rte_main_ppat_plc_padded43 = s.oa_rte_main_ppat_plc_padded43
, t.oa_rte_main_ppat_plc_padded44 = s.oa_rte_main_ppat_plc_padded44
, t.oa_rte_main_ppat_plc_padded45 = s.oa_rte_main_ppat_plc_padded45
, t.oa_rte_main_ppat_plc_padded46 = s.oa_rte_main_ppat_plc_padded46
, t.oa_rte_main_ppat_plc_padded47 = s.oa_rte_main_ppat_plc_padded47
, t.oa_rte_main_ppat_plc_padded48 = s.oa_rte_main_ppat_plc_padded48
, t.oa_rte_main_ppat_plc_padded49 = s.oa_rte_main_ppat_plc_padded49
, t.oa_rte_main_ppat_plc_padded50 = s.oa_rte_main_ppat_plc_padded50
, t.oa_rte_main_ppat_plc_padded51 = s.oa_rte_main_ppat_plc_padded51
, t.oa_rte_main_ppat_plc_padded52 = s.oa_rte_main_ppat_plc_padded52
, t.oa_rte_main_ppat_plc_padded53 = s.oa_rte_main_ppat_plc_padded53
, t.oa_rte_main_ppat_plc_padded54 = s.oa_rte_main_ppat_plc_padded54
, t.record_updated_date = sysdatetime()
when not matched by target then
INSERT ( filedate
, file_row_id
, trp_route
, trp_direction
, trp_direction2
, oa_rte_main_ppat_dir
, oa_rte_main_ppat_plc_padded6
, oa_rte_main_ppat_plc_padded7
, oa_rte_main_ppat_plc_padded8
, oa_rte_main_ppat_plc_padded9
, oa_rte_main_ppat_plc_padded10
, oa_rte_main_ppat_plc_padded11
, oa_rte_main_ppat_plc_padded12
, oa_rte_main_ppat_plc_padded13
, oa_rte_main_ppat_plc_padded14
, oa_rte_main_ppat_plc_padded15
, oa_rte_main_ppat_plc_padded16
, oa_rte_main_ppat_plc_padded17
, oa_rte_main_ppat_plc_padded18
, oa_rte_main_ppat_plc_padded19
, oa_rte_main_ppat_plc_padded20
, oa_rte_main_ppat_plc_padded21
, oa_rte_main_ppat_plc_padded22
, oa_rte_main_ppat_plc_padded23
, oa_rte_main_ppat_plc_padded24
, oa_rte_main_ppat_plc_padded25
, oa_rte_main_ppat_plc_padded26
, oa_rte_main_ppat_plc_padded27
, oa_rte_main_ppat_plc_padded28
, oa_rte_main_ppat_plc_padded29
, oa_rte_main_ppat_plc_padded30
, oa_rte_main_ppat_plc_padded31
, oa_rte_main_ppat_plc_padded32
, oa_rte_main_ppat_plc_padded33
, oa_rte_main_ppat_plc_padded34
, oa_rte_main_ppat_plc_padded35
, oa_rte_main_ppat_plc_padded36
, oa_rte_main_ppat_plc_padded37
, oa_rte_main_ppat_plc_padded38
, oa_rte_main_ppat_plc_padded39
, oa_rte_main_ppat_plc_padded40
, oa_rte_main_ppat_plc_padded41
, oa_rte_main_ppat_plc_padded42
, oa_rte_main_ppat_plc_padded43
, oa_rte_main_ppat_plc_padded44
, oa_rte_main_ppat_plc_padded45
, oa_rte_main_ppat_plc_padded46
, oa_rte_main_ppat_plc_padded47
, oa_rte_main_ppat_plc_padded48
, oa_rte_main_ppat_plc_padded49
, oa_rte_main_ppat_plc_padded50
, oa_rte_main_ppat_plc_padded51
, oa_rte_main_ppat_plc_padded52
, oa_rte_main_ppat_plc_padded53
, oa_rte_main_ppat_plc_padded54
)
values( s.filedate
,s.file_row_id
,s.trp_route
,s.trp_direction
,s.trp_direction2
,s.oa_rte_main_ppat_dir
,s.oa_rte_main_ppat_plc_padded6
,s.oa_rte_main_ppat_plc_padded7
,s.oa_rte_main_ppat_plc_padded8
,s.oa_rte_main_ppat_plc_padded9
,s.oa_rte_main_ppat_plc_padded10
,s.oa_rte_main_ppat_plc_padded11
,s.oa_rte_main_ppat_plc_padded12
,s.oa_rte_main_ppat_plc_padded13
,s.oa_rte_main_ppat_plc_padded14
,s.oa_rte_main_ppat_plc_padded15
,s.oa_rte_main_ppat_plc_padded16
,s.oa_rte_main_ppat_plc_padded17
,s.oa_rte_main_ppat_plc_padded18
,s.oa_rte_main_ppat_plc_padded19
,s.oa_rte_main_ppat_plc_padded20
,s.oa_rte_main_ppat_plc_padded21
,s.oa_rte_main_ppat_plc_padded22
,s.oa_rte_main_ppat_plc_padded23
,s.oa_rte_main_ppat_plc_padded24
,s.oa_rte_main_ppat_plc_padded25
,s.oa_rte_main_ppat_plc_padded26
,s.oa_rte_main_ppat_plc_padded27
,s.oa_rte_main_ppat_plc_padded28
,s.oa_rte_main_ppat_plc_padded29
,s.oa_rte_main_ppat_plc_padded30
,s.oa_rte_main_ppat_plc_padded31
,s.oa_rte_main_ppat_plc_padded32
,s.oa_rte_main_ppat_plc_padded33
,s.oa_rte_main_ppat_plc_padded34
,s.oa_rte_main_ppat_plc_padded35
,s.oa_rte_main_ppat_plc_padded36
,s.oa_rte_main_ppat_plc_padded37
,s.oa_rte_main_ppat_plc_padded38
,s.oa_rte_main_ppat_plc_padded39
,s.oa_rte_main_ppat_plc_padded40
,s.oa_rte_main_ppat_plc_padded41
,s.oa_rte_main_ppat_plc_padded42
,s.oa_rte_main_ppat_plc_padded43
,s.oa_rte_main_ppat_plc_padded44
,s.oa_rte_main_ppat_plc_padded45
,s.oa_rte_main_ppat_plc_padded46
,s.oa_rte_main_ppat_plc_padded47
,s.oa_rte_main_ppat_plc_padded48
,s.oa_rte_main_ppat_plc_padded49
,s.oa_rte_main_ppat_plc_padded50
,s.oa_rte_main_ppat_plc_padded51
,s.oa_rte_main_ppat_plc_padded52
,s.oa_rte_main_ppat_plc_padded53
,s.oa_rte_main_ppat_plc_padded54
     )
OUTPUT $action INTO @outputTbl;



drop table if exists #rte_setup


DECLARE @ins INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'INSERT')
DECLARE @upd INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'UPDATE')
DECLARE @del INT = (SELECT COUNT(*) FROM @outputTbl WHERE actionNm = 'DELETE')
DECLARE @prg varchar(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_avl_ppat ' --+ CAST(@allCount AS VARCHAR(12))

INSERT process.mergeLogs
([MergeCode]
           ,[ObjectDestination]
           ,[ObjectSource]
           ,[ObjectProgram]
           ,[recInsert]
           ,[recUpdate]
           ,[recDelete]
           ,[MergeBeginDatetime]
           ,[MergeEndDatetime])
SELECT 'PPAT',
'ltd_dw.hastus.avl_ppat',
'HASTUS',
@prg,
ISNULL(@ins,0) ,ISNULL(@upd,0),ISNULL(@del,0),
@sdt,
SYSDATETIME()


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
             ,@recipients = 'data@ltd.org' 
             ,@subject = @sub
             ,@body = @errormsg;

       RAISERROR (
                    @errormsg
                    ,@errsev
                    ,1
                    )
END CATCH;
GO
