SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [rpt].[it_word_cloud_by_year]
as
SELECT 
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace([ITWord],'"',''),'_','')
            ,'districtapplications','applications'),'loin','login'),'“',''),'”',''),'‘',''),'''',''),'…',''),'-',''),'—',''),'a ',''),char(10),''),char(13),'') 
            ,'hellois','hello'), 'thank','thanks'),'thanks you','thank you') ITWord
      ,sum([occu]) occu
      ,[work_year]
      ,[last_refresh]
  FROM [ltd_dw].[rpt].[it_life_word_cloud]
where itword not like '%]%'
and rtrim(ltrim(replace(replace([ITWord],'"',''),'_',''))) <> ''
and itword not like '%/%'
and itword not like '%\%'
and itword not like '%[%]%'
and itword not like '%}%'
and itword not like '%{%'
and itword not like '%&%'
and itword not like '%|%'
and itword not like '%~%'
and itword not like '%blickfeldt%'
and itword not like '%marieca%'
and itword not like '%beatriz%'
and itword not like '%jessica%'
and itword not like '%markj%'
and itword not like '%mayall%'
and itword not like '%munkus%'
and itword not like '%dodge%'
and itword not like '%mjohnson%'
and itword not like '%kari%'
and itword not like '%jason%'
and itword not like '%john%'
and itword not like '%frank%'
and itword not like '%ahlen%'
and itword not like '%mckenzie%'
and itword not like '%neilbli%'
and itword not like '%oylear%'
and itword not like '%abbe%'
and itword not like '%chris%'
and itword not like '%cheryl%'
and itword not like '%ramsey%'
and itword not like '%hare%'
and itword not like '%josh%'
and itword not like '%becky%'
and itword not like '%aimee%'
group by 
replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace([ITWord],'"',''),'_','')
            ,'districtapplications','applications'),'loin','login'),'“',''),'”',''),'‘',''),'''',''),'…',''),'-',''),'—',''),'a ',''),char(10),''),char(13),'') 
            ,'hellois','hello'), 'thank','thanks'),'thanks you','thank you')
,[work_year]
      ,[last_refresh]
having sum(occu) > 9
GO
