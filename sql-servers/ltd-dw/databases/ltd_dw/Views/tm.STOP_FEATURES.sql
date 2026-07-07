SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [tm].[STOP_FEATURES]
AS

/*----------------LTD_GLOSSARY-----------
CREATED ON: 2021-07-15
PURPOSE	  : Is the source for the dimension loader STOP FEATURES OVER TIME
			The package is in LTD-DW ISC and is run by the SQL Agent Job
			"DW Dimension Maintenance - STOP FEATURES"
AUTHOR	  : B. Eichberger

CHANGE	  : 2023-09-19 Point to LTD-HASTUS2, add the new joins required for columns

*/

SELECT o.STOP_ABBR
	  ,o.STOP_ID
	  ,o.GEO_NODE_NAME
	  ,o.STOP_FEATURE_ID
	  ,o.STOP_FEATURE_TEXT
	  ,o.bus_shelter
	  ,o.ud_shelter_type
	  ,o.bench
	  ,o.physical
	  ,o.layby
	  ,o.info_booth
	  ,o.accessible
	  ,o.parking
	  ,o.parking_size
	  ,o.parking_fare
	  ,o.allow_boarding
	  ,o.allow_debarking
	  ,o.ud_deactivation
	  ,o.ud_access
	  ,o.ud_parking
	  ,o.desc_scode, 
STOP_BUSINESS_KEY = CAST([STOP_ABBR] AS VARCHAR(8)) +'-'+CAST(ISNULL([STOP_FEATURE_ID],0) AS VARCHAR(22)) 
FROM (SELECT 
CAST(COALESCE(g.GEO_NODE_ABBR,s.stop_id COLLATE SQL_Latin1_General_CP850_CI_AS) AS VARCHAR(9)) AS [STOP_ABBR]
	,ISNULL(g.GEO_NODE_ID,0) AS STOP_ID
	,ISNULL(g.GEO_NODE_NAME,'') GEO_NODE_NAME
	,[STOP_FEATURE_ID] = ISNULL(f.[STOP_FEATURE_ID],0)
	,[STOP_FEATURE_TEXT] = ISNULL(f.[STOP_FEATURE_TEXT], '') 
	,bus_shelter = ISNULL(s.bus_shelter, 0)
	,ud_shelter_type = ISNULL(s.ud_shelter_type, '')
	,bench = ISNULL(s.bench, 0)
	,physical = 0 -- deprecated hastus2021
	,layby = ISNULL(s.layby, 0)
	,info_booth = ISNULL(s.info_booth, 0)
	,accessible = ISNULL(s.accessible, 0)
	,parking = ISNULL(s.parking, 0)
	,parking_size = ISNULL(s.parking_size, 0)
	,parking_fare = ISNULL(s.parking_fare, '0')
	,allow_boarding = ISNULL(s.allow_boarding, 0)
	,allow_debarking = ISNULL(s.allow_debarking, 0)
	,ud_deactivation = ISNULL(s.ud_deactivation, DATEADD(YEAR, 10, GETDATE()))
	,ud_access = ISNULL(s.ud_access,0 )
	,ud_parking = ISNULL(s.ud_parking, 0)
	,desc_scode = ISNULL(s.desc_scode, '') FROM [ltd-tmdata].[tmdatamart].[dbo].[STOP_FEATURE] f 
	JOIN [ltd-tmdata].[tmdatamart].[dbo].[STOP_FEATURE_XREF] x
			ON x.STOP_FEATURE_ID = f.STOP_FEATURE_ID 
	JOIN [ltd-tmdata].[tmdatamart].dbo.GEO_NODE g
				ON g.GEO_NODE_ID = x.GEO_NODE_ID 
	FULL OUTER JOIN (
	SELECT o.stop_id
		,l.shelter bus_shelter
		,o.ud_shelter_type
		,l.bench
		,l.layby
		,l.info_booth
		,l.accessible
		,l.parking
		,l.parking_size
		,l.parking_fare
		,l.allow_boarding
		,l.allow_debarking
		,o.ud_deactivation
		,o.ud_access
		,o.ud_parking
		,c.desc_scode -- select * 
		FROM [ltd-hastus2].[hastus2021].[dbo].[stop] o
		JOIN [ltd-hastus2].[hastus2021].[dbo].[stop_period] l ON l.stop_no = o.stop_no
		LEFT JOIN  [ltd-hastus2].[hastus2021].[dbo].[stoploc] c ON c.stop_no = o.stop_no
	) s
	ON s.stop_id COLLATE SQL_Latin1_General_CP850_CI_AS = g.geo_node_abbr
	) o

GO
