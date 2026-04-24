SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE view [tm].[ontime_performance_v_wo_ann_arr_stations]

as


/************LTD_GLOSSARY**************

CREATE DT	: 2051121
CREATE BY	: B. Eichberger
PURPOSE		: Source of data to demonstrate difference when explicity excluding these stations
			  and stops (arr's, ann's, etc.

			  all official on time performance reporting is through reporting database:
				reporting.tm.ontime_performance_detail
				reporting.tm.ontime_performance_monthly
				reporting.tm.ontime_performance_weekly

				Variations of those views exist wherein stations are selected
				to be excluded or ann and arr points/stops are excluded
				examples for detail:
					ontime_performance_detail_wo_ann_arr_stations
					ontime_performance_detail_wo_eug_ss
					ontime_performance_detail_wo_eugTU_ssG
				these also exist for monthly and weekly


*/

select [svc]			 = a.svc
	,[the_date]    = a.the_date
	,[rte]         = a.rte_public
	,a.rte_dir
	,a.emx_block
	,[trip_end]    = a.trip_end
	,[sa_tps]      = a.sa_tp
	,[time_points] = count(*)
	,[ontime]      = sum(a.adjusted_ontime)
	,[early]       = sum(a.adjusted_early)
	,[late]        = sum(a.adjusted_late)
	,[missing]     = sum(a.adjusted_missing)
	,[not_missing] = sum(case when a.adjusted_missing = 0 then 1 else 0 end)  
	from Reporting.[tm].[VIEW_STORE_ADH_v] a
	  where a.trip_end is not null
	  and calendar_id > 120220701
	  and a.stop_name not like 'arr%'
	  and stop_name not like 'ann%'
	  and stop_no not in ('escenter',
'eugsta',
'garage',
'garage',
'ss_arr_5',
'ss_arr_a',
'ss_sta')
	    and a.calendar_id > year(getdate())-3
	 group by a.svc
			 ,a.the_date
			 ,a.trip_end
			 ,a.sa_tp
			 ,a.rte_public
			 ,a.rte_dir
			 ,a.emx_block
GO
