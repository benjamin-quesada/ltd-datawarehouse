SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   view [process].[Models_Processed_Last]
as
/*******LTD_GLOSSARY*******
created by	: b. eichberger
created on	: 2024-03-27
purpose		: centralize last processed times to use in reporting headers
			  indicating the recency of the data

*/

select dateadd(MI, datediff(MI, getutcdate(), getdate()), last_data_update) as last_date_processed
	--,CAST(last_data_update AS DATETIME) last_date_processed
	,cast(catalog_name as varchar(90)) model_name
	from openquery([TM_ANALYSIS], 'SELECT [LAST_DATA_UPDATE],[catalog_name]
FROM $System.MDSCHEMA_CUBES
ORDER BY [LAST_DATA_UPDATE] DESC
')
group by dateadd(MI, datediff(MI, getutcdate(), getdate()), last_data_update)
	--,CAST(last_data_update AS DATETIME)
	,cast(catalog_name as varchar(90))
union
select dateadd(MI, datediff(MI, getutcdate(), getdate()), last_data_update) as last_date_processed
	--,CAST(last_data_update AS DATETIME) last_date_processed
	,cast(catalog_name as varchar(90)) model_name
	from openquery([EAM_ANALYSIS], 'SELECT [LAST_DATA_UPDATE],[catalog_name]
FROM $System.MDSCHEMA_CUBES
ORDER BY [LAST_DATA_UPDATE] DESC
')
group by dateadd(MI, datediff(MI, getutcdate(), getdate()), last_data_update)
	--,CAST(last_data_update AS DATETIME)
	,cast(catalog_name as varchar(90))
union
select dateadd(MI, datediff(MI, getutcdate(), getdate()), last_data_update) as last_date_processed
	--,CAST(last_data_update AS DATETIME) last_date_processed
	,cast(catalog_name as varchar(90)) model_name
	from openquery([UMO_ANALYSIS], 'SELECT [LAST_DATA_UPDATE],[catalog_name]
FROM $System.MDSCHEMA_CUBES
ORDER BY [LAST_DATA_UPDATE] DESC
')
group by dateadd(MI, datediff(MI, getutcdate(), getdate()), last_data_update)
	--,CAST(last_data_update AS DATETIME)
	,cast(catalog_name as varchar(90))
UNION
SELECT DATEADD(MI, DATEDIFF(MI, GETUTCDATE(), GETDATE()), last_data_update) AS last_date_processed
	--,CAST(last_data_update AS DATETIME) last_date_processed
	,CAST(catalog_name AS VARCHAR(90)) model_name
	FROM OPENQUERY([EAMR_ANALYSIS], 'SELECT [LAST_DATA_UPDATE],[catalog_name]
FROM $System.MDSCHEMA_CUBES
ORDER BY [LAST_DATA_UPDATE] DESC
')
GROUP BY DATEADD(MI, DATEDIFF(MI, GETUTCDATE(), GETDATE()), last_data_update)
	--,CAST(last_data_update AS DATETIME)
	,CAST(catalog_name AS VARCHAR(90))

GO
