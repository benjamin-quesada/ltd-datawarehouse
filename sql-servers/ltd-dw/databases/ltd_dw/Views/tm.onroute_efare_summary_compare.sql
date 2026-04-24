SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [tm].[onroute_efare_summary_compare]
as
/*****************************************
CREATED BY	: B Eichberger
CREATED ON	: 20250814
PURPOSE		: Provide summary comparison of onRoute boarding vs efare Transaction Count

*/

select n.calendar_id,
	  n.rte_public
	, n.dir
    , n.rte_rural
    , n.emx_block
	, n.veh
	, n.artic
	, n.electric
	, n.block
	, n.trip_id
	, n.trip_end
    , n.stop
    , n.stop_name
	, n.block_stop_order
    , n.college
    , board = sum(n.board)
    , alight = sum(n.alight)
	, e.TxnCount
	from (select tsCalId,trip, routeName,stopId,vehicle,count(*) TxnCount -- select * 
			from [efare].[vw_FARE_Extended]
			where tsCalId >= 120200101
			group by tsCalId,trip,routeName,stopId,vehicle) e
			-- left originally, changed to full outer join to include all OnRoute, whether or not there are passengers on efare
	full outer join reporting.tm.VIEW_STORE_PASS_v n
				 on n.trip_id = e.trip 
					and n.calendar_id = e.tsCalId
					and n.rte_public = e.routeName 
					and n.stop = e.stopId
					and n.veh = e.vehicle
	where n.calendar_id >= 120210101
	group by 
	 n.calendar_id,
	  n.rte_public
	, n.dir
    , n.rte_rural
    , n.emx_block
	, n.veh
	, n.artic
	, n.electric
	, n.block
	, n.trip_id
	, n.trip_end
    , n.stop
    , n.stop_name
	, n.block_stop_order
    , n.college
	, e.TxnCount
GO
