SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [efare].[SalesbyResellerv2_old]
AS


SELECT y.shortName
     , s.resellerShortName
     , CASE
           WHEN y.shortName LIKE '%|%' THEN
               RIGHT(y.Name, 4)
           WHEN y.shortName NOT LIKE '%|%'
                AND s.resellerShortName LIKE '%|%' THEN
               RIGHT(s.resellerShortName, 4)
	   ELSE NULL
       END AS EdenCode
	   ,Ts AS saleTs
	   ,DATEADD("hh",-7,s.Ts) AS saleLocalTs
     , LEFT(CONVERT(VARCHAR(32), DATEADD("hh",-7,s.Ts) , 112), 6) SaleYYYYMM
     , s.casePass AS FareType
     , SUM(s.Cost) cost
     , COUNT(*) qty
FROM
(
    SELECT r.resellLoadKey
         , r.Name
         , CASE
               WHEN r.Name LIKE '%|%' THEN
                   LEFT(r.Name, CHARINDEX('|', r.Name) - 1)
               ELSE
                   r.Name
           END shortName
 , CASE
                   WHEN r.Name LIKE '%|%' THEN
                       RIGHT(r.Name,4)
                   ELSE
                       r.Name
               END custCode
         , r.Id 
	FROM [ltd_dw].[efare].[RESELL] r 
    WHERE r.Name LIKE 'NP %'
          OR r.Name LIKE 'PS %'
          OR r.Name LIKE 'AP %'
)     y
   INNER JOIN (
        SELECT saleLoadKey
			  ,TxId
			  ,Ts
			  ,Type
			  ,FareType
			  ,AccountId
			  ,passUsed
			  ,SalesUser
			  ,SalesUsername
			  ,SalesChannel
			  ,resellerShortName
			  ,FundingSourceType
			  ,LocationDescription
			  ,Cost
			  ,fileloaded
			 , CASE WHEN passUsed IS NULL AND [Type] = 'SV_Added' THEN 'Stored Value' 
					ELSE passUsed END AS casePass
             , CASE
                   WHEN resellerShortName LIKE '%|%' THEN
                       LEFT(resellerShortName, CHARINDEX('|', resellerShortName) - 1)
                   ELSE
                       resellerShortName
               END shortName
			 , CASE
                   WHEN resellerShortName LIKE '%|%' THEN
                       RIGHT(resellerShortName,4)
                   ELSE
                       resellerShortName
               END custCode
        FROM efare.SALE_Extendedv2
		
    ) s
        ON s.custCode = y.custCode
WHERE s.resellerShortName IS NOT NULL
GROUP BY y.Name,s.Ts,DATEADD("hh",-7,s.Ts) 
       , LEFT(CONVERT(VARCHAR(32), s.Ts, 112), 6)
       , s.shortName
       , s.casePass
       , s.resellerShortName
       , y.shortName;


GO
