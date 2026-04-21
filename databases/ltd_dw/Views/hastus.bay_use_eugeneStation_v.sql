SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



 
/********LTD_GLOSSARY********
 
CREATED BY : B Eichberger
CREATED DT : 2024-05-24
PURPOSE : collect data to merge into bay use table
		  used by report Eugene Station Bay Use (SSRS)
 
*/
 
CREATE VIEW [hastus].[bay_use_eugeneStation_v]
AS


WITH setupYr AS (SELECT right(YEAR(GETDATE())-1,2) +'00a' AS bookYr)
,
lyvrs
AS (
SELECT d.booking_id,sched_type_id,
d.depart_time AS depart,
[10LIN_A_lo],
[10LIN_B_lo],
[11D_lo],
[A_lo],
[B_lo],
[C_lo],
[D_lo],
[E_lo],
[F_lo],
[G_lo],
[H_lo],
[I_lo],
[J_lo],
[K_lo],
[L_lo],
[LIN_lo],
[M_lo],
[N_lo],
[O_lo],
[OSD_lo],
[P_lo],
[Q_lo],
[R_lo],
[S_lo],
[T_lo],
[U_lo]
FROM (
SELECT booking_id,sched_type_id
,depart_time 
,ISNULL([es_10lin_a],0) AS [10LIN_A_lo]
,ISNULL([es_10lin_b],0) AS [10LIN_B_lo]
,ISNULL([es_11d],0) AS [11D_lo]
,ISNULL([es_a],0) AS [A_lo]
,ISNULL([es_b],0) AS [B_lo]
,ISNULL([es_c],0) AS [C_lo]
,ISNULL([es_d],0) AS [D_lo]
,ISNULL([es_e],0) AS [E_lo]
,ISNULL([es_f],0) AS [F_lo]
,ISNULL([es_g],0) AS [G_lo]
,ISNULL([es_h],0) AS [H_lo]
,ISNULL([es_i],0) AS [I_lo]
,ISNULL([es_j],0) AS [J_lo]
,ISNULL([es_k],0) AS [K_lo]
,ISNULL([es_l],0) AS [L_lo]
,ISNULL([es_lin],0) AS [LIN_lo]
,ISNULL([es_m],0) AS [M_lo]
,ISNULL([es_n],0) AS [N_lo]
,ISNULL([es_o],0) AS [O_lo]
,ISNULL([es_osd],0) AS [OSD_lo]
,ISNULL([es_p],0) AS [P_lo]
,ISNULL([es_q],0) AS [Q_lo]
,ISNULL([es_r],0) AS [R_lo]
,ISNULL([es_s],0) AS [S_lo]
,ISNULL([es_t],0) AS [T_lo]
,ISNULL([es_u],0) AS [U_lo]
FROM (
SELECT y.booking_id, y.sched_type_id,
	y.place_id
	, y.depart_time, y.layover_minutes, y.route_id_1, y.duty_id_1
FROM
    hastus.layovers y
	JOIN setupYr s ON y.booking_id >= s.bookYr
WHERE
    (y.sched_type_id = 0 OR
    y.sched_type_id = 5 OR
    y.sched_type_id = 6)
	AND y.place_id LIKE 'es%'
	--AND y.booking_id >= '2200a'
) AS src
PIVOT (
SUM(layover_minutes)
FOR place_id IN ([es_10lin_a],[es_10lin_b],[es_11d],[es_a],[es_b],[es_c],[es_d],[es_e],[es_f],[es_g],[es_h],[es_i],[es_j],[es_k],[es_l],[es_lin],[es_m],[es_n],[es_o],[es_osd],[es_p],[es_q],[es_r],[es_s],[es_t],[es_u])
) AS pvt
) d
)

,dpt_max
AS (
SELECT o.booking_id
,o.sched_type_id
,o.depart_time
,o.place_id
,SUM(CASE WHEN place_id = 'es_10lin_a' THEN ISNULL(o.dpt_count, 0) END) AS [10LIN_A_dpt]
,SUM(CASE WHEN place_id = 'es_10lin_b' THEN ISNULL(o.dpt_count, 0) END) AS [10LIN_B_dpt]
,SUM(CASE WHEN place_id = 'es_11d' THEN ISNULL(o.dpt_count, 0) END) AS [11D_dpt]
,SUM(CASE WHEN place_id = 'es_a' THEN ISNULL(o.dpt_count, 0) END) AS [A_dpt]
,SUM(CASE WHEN place_id = 'es_b' THEN ISNULL(o.dpt_count, 0) END) AS [B_dpt]
,SUM(CASE WHEN place_id = 'es_c' THEN ISNULL(o.dpt_count, 0) END) AS [C_dpt]
,SUM(CASE WHEN place_id = 'es_d' THEN ISNULL(o.dpt_count, 0) END) AS [D_dpt]
,SUM(CASE WHEN place_id = 'es_e' THEN ISNULL(o.dpt_count, 0) END) AS [E_dpt]
,SUM(CASE WHEN place_id = 'es_f' THEN ISNULL(o.dpt_count, 0) END) AS [F_dpt]
,SUM(CASE WHEN place_id = 'es_g' THEN ISNULL(o.dpt_count, 0) END) AS [G_dpt]
,SUM(CASE WHEN place_id = 'es_h' THEN ISNULL(o.dpt_count, 0) END) AS [H_dpt]
,SUM(CASE WHEN place_id = 'es_i' THEN ISNULL(o.dpt_count, 0) END) AS [I_dpt]
,SUM(CASE WHEN place_id = 'es_j' THEN ISNULL(o.dpt_count, 0) END) AS [J_dpt]
,SUM(CASE WHEN place_id = 'es_k' THEN ISNULL(o.dpt_count, 0) END) AS [K_dpt]
,SUM(CASE WHEN place_id = 'es_l' THEN ISNULL(o.dpt_count, 0) END) AS [L_dpt]
,SUM(CASE WHEN place_id = 'es_lin' THEN ISNULL(o.dpt_count, 0) END) AS [LIN_dpt]
,SUM(CASE WHEN place_id = 'es_m' THEN ISNULL(o.dpt_count, 0) END) AS [M_dpt]
,SUM(CASE WHEN place_id = 'es_n' THEN ISNULL(o.dpt_count, 0) END) AS [N_dpt]
,SUM(CASE WHEN place_id = 'es_o' THEN ISNULL(o.dpt_count, 0) END) AS [O_dpt]
,SUM(CASE WHEN place_id = 'es_osd' THEN ISNULL(o.dpt_count, 0) END) AS [OSD_dpt]
,SUM(CASE WHEN place_id = 'es_p' THEN ISNULL(o.dpt_count, 0) END) AS [P_dpt]
,SUM(CASE WHEN place_id = 'es_q' THEN ISNULL(o.dpt_count, 0) END) AS [Q_dpt]
,SUM(CASE WHEN place_id = 'es_r' THEN ISNULL(o.dpt_count, 0) END) AS [R_dpt]
,SUM(CASE WHEN place_id = 'es_s' THEN ISNULL(o.dpt_count, 0) END) AS [S_dpt]
,SUM(CASE WHEN place_id = 'es_t' THEN ISNULL(o.dpt_count, 0) END) AS [T_dpt]
,SUM(CASE WHEN place_id = 'es_u' THEN ISNULL(o.dpt_count, 0) END) AS [U_dpt]
FROM (
SELECT y.booking_id, y.sched_type_id, y.place_id, y.depart_time, y.Layover, y.route_id_1, y.duty_id_1
  ,COUNT(*) dpt_count
FROM hastus.layovers y
	JOIN setupYr s ON y.booking_id >= s.bookYr
WHERE
    (y.sched_type_id = 0 OR
    y.sched_type_id = 5 OR
    y.sched_type_id = 6)
	AND y.place_id LIKE 'es%'
GROUP BY  y.booking_id, y.sched_type_id, y.place_id, y.depart_time, y.Layover, y.route_id_1, y.duty_id_1
) o 
GROUP BY 
o.booking_id
   ,o.sched_type_id
   ,o.depart_time
   ,o.place_id
)
 
 
SELECT booking_id,depart,CAST(LEFT(depart,2) AS INT) hr_grp,sched_type_id,
MAX([10LIN_A]) AS [10LIN_A],
MAX([10LIN_B]) AS [10LIN_B],
MAX([11D]) AS [11D],
MAX([A]) AS [A],
MAX([B]) AS [B],
MAX([C]) AS [C],
MAX([D]) AS [D],
MAX([E]) AS [E],
MAX([F]) AS [F],
MAX([G]) AS [G],
MAX([H]) AS [H],
MAX([I]) AS [I],
MAX([J]) AS [J],
MAX([K]) AS [K],
MAX([L]) AS [L],
MAX([LIN]) AS [LIN],
MAX([M]) AS [M],
MAX([N]) AS [N],
MAX([O]) AS [O],
MAX([OSD]) AS [OSD],
MAX([P]) AS [P],
MAX([Q]) AS [Q],
MAX([R]) AS [R],
MAX([S]) AS [S],
MAX([T]) AS [T],
MAX([U]) AS [U],
MAX([10LIN_A_lo]) AS [10LIN_A_lo],
MAX([10LIN_B_lo]) AS [10LIN_B_lo],
MAX([11D_lo]) AS [11D_lo],
MAX([A_lo]) AS [A_lo],
MAX([B_lo]) AS [B_lo],
MAX([C_lo]) AS [C_lo],
MAX([D_lo]) AS [D_lo],
MAX([E_lo]) AS [E_lo],
MAX([F_lo]) AS [F_lo],
MAX([G_lo]) AS [G_lo],
MAX([H_lo]) AS [H_lo],
MAX([I_lo]) AS [I_lo],
MAX([J_lo]) AS [J_lo],
MAX([K_lo]) AS [K_lo],
MAX([L_lo]) AS [L_lo],
MAX([LIN_lo]) AS [LIN_lo],
MAX([M_lo]) AS [M_lo],
MAX([N_lo]) AS [N_lo],
MAX([O_lo]) AS [O_lo],
MAX([OSD_lo]) AS [OSD_lo],
MAX([P_lo]) AS [P_lo],
MAX([Q_lo]) AS [Q_lo],
MAX([R_lo]) AS [R_lo],
MAX([S_lo]) AS [S_lo],
MAX([T_lo]) AS [T_lo],
MAX([U_lo]) AS [U_lo],
CASE WHEN MAX([10LIN_A_dpt]) > 1 THEN 'Red'
WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=1 AND MAX([10LIN_A_lo]) <=5.9 THEN 'White'
WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=6 AND MAX([10LIN_A_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=11 AND MAX([10LIN_A_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=16 AND MAX([10LIN_A_lo]) <=20.9 THEN 'Green'
WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=21 AND MAX([10LIN_A_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=26 AND MAX([10LIN_A_lo]) <=30.9 THEN 'Blue'
WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [10lin_a_back],
CASE WHEN MAX([10LIN_B_dpt]) > 1 THEN 'Red'
WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=1 AND MAX([10LIN_B_lo]) <=5.9 THEN 'White'
WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=6 AND MAX([10LIN_B_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=11 AND MAX([10LIN_B_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=16 AND MAX([10LIN_B_lo]) <=20.9 THEN 'Green'
WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=21 AND MAX([10LIN_B_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=26 AND MAX([10LIN_B_lo]) <=30.9 THEN 'Blue'
WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [10lin_b_back],
CASE WHEN MAX([11D_dpt]) > 1 THEN 'Red'
WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=1 AND MAX([11D_lo]) <=5.9 THEN 'White'
WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=6 AND MAX([11D_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=11 AND MAX([11D_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=16 AND MAX([11D_lo]) <=20.9 THEN 'Green'
WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=21 AND MAX([11D_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=26 AND MAX([11D_lo]) <=30.9 THEN 'Blue'
WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [11d_back],
CASE WHEN MAX([A_dpt]) > 1 THEN 'Red'
WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=1 AND MAX([A_lo]) <=5.9 THEN 'White'
WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=6 AND MAX([A_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=11 AND MAX([A_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=16 AND MAX([A_lo]) <=20.9 THEN 'Green'
WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=21 AND MAX([A_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=26 AND MAX([A_lo]) <=30.9 THEN 'Blue'
WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [a_back],
CASE WHEN MAX([B_dpt]) > 1 THEN 'Red'
WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=1 AND MAX([B_lo]) <=5.9 THEN 'White'
WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=6 AND MAX([B_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=11 AND MAX([B_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=16 AND MAX([B_lo]) <=20.9 THEN 'Green'
WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=21 AND MAX([B_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=26 AND MAX([B_lo]) <=30.9 THEN 'Blue'
WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [b_back],
CASE WHEN MAX([C_dpt]) > 1 THEN 'Red'
WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=1 AND MAX([C_lo]) <=5.9 THEN 'White'
WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=6 AND MAX([C_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=11 AND MAX([C_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=16 AND MAX([C_lo]) <=20.9 THEN 'Green'
WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=21 AND MAX([C_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=26 AND MAX([C_lo]) <=30.9 THEN 'Blue'
WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [c_back],
CASE WHEN MAX([D_dpt]) > 1 THEN 'Red'
WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=1 AND MAX([D_lo]) <=5.9 THEN 'White'
WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=6 AND MAX([D_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=11 AND MAX([D_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=16 AND MAX([D_lo]) <=20.9 THEN 'Green'
WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=21 AND MAX([D_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=26 AND MAX([D_lo]) <=30.9 THEN 'Blue'
WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [d_back],
CASE WHEN MAX([E_dpt]) > 1 THEN 'Red'
WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=1 AND MAX([E_lo]) <=5.9 THEN 'White'
WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=6 AND MAX([E_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=11 AND MAX([E_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=16 AND MAX([E_lo]) <=20.9 THEN 'Green'
WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=21 AND MAX([E_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=26 AND MAX([E_lo]) <=30.9 THEN 'Blue'
WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [e_back],
CASE WHEN MAX([F_dpt]) > 1 THEN 'Red'
WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=1 AND MAX([F_lo]) <=5.9 THEN 'White'
WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=6 AND MAX([F_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=11 AND MAX([F_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=16 AND MAX([F_lo]) <=20.9 THEN 'Green'
WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=21 AND MAX([F_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=26 AND MAX([F_lo]) <=30.9 THEN 'Blue'
WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [f_back],
CASE WHEN MAX([G_dpt]) > 1 THEN 'Red'
WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=1 AND MAX([G_lo]) <=5.9 THEN 'White'
WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=6 AND MAX([G_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=11 AND MAX([G_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=16 AND MAX([G_lo]) <=20.9 THEN 'Green'
WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=21 AND MAX([G_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=26 AND MAX([G_lo]) <=30.9 THEN 'Blue'
WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [g_back],
CASE WHEN MAX([H_dpt]) > 1 THEN 'Red'
WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=1 AND MAX([H_lo]) <=5.9 THEN 'White'
WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=6 AND MAX([H_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=11 AND MAX([H_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=16 AND MAX([H_lo]) <=20.9 THEN 'Green'
WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=21 AND MAX([H_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=26 AND MAX([H_lo]) <=30.9 THEN 'Blue'
WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [h_back],
CASE WHEN MAX([I_dpt]) > 1 THEN 'Red'
WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=1 AND MAX([I_lo]) <=5.9 THEN 'White'
WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=6 AND MAX([I_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=11 AND MAX([I_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=16 AND MAX([I_lo]) <=20.9 THEN 'Green'
WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=21 AND MAX([I_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=26 AND MAX([I_lo]) <=30.9 THEN 'Blue'
WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [i_back],
CASE WHEN MAX([J_dpt]) > 1 THEN 'Red'
WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=1 AND MAX([J_lo]) <=5.9 THEN 'White'
WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=6 AND MAX([J_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=11 AND MAX([J_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=16 AND MAX([J_lo]) <=20.9 THEN 'Green'
WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=21 AND MAX([J_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=26 AND MAX([J_lo]) <=30.9 THEN 'Blue'
WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [j_back],
CASE WHEN MAX([K_dpt]) > 1 THEN 'Red'
WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=1 AND MAX([K_lo]) <=5.9 THEN 'White'
WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=6 AND MAX([K_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=11 AND MAX([K_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=16 AND MAX([K_lo]) <=20.9 THEN 'Green'
WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=21 AND MAX([K_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=26 AND MAX([K_lo]) <=30.9 THEN 'Blue'
WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [k_back],
CASE WHEN MAX([L_dpt]) > 1 THEN 'Red'
WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=1 AND MAX([L_lo]) <=5.9 THEN 'White'
WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=6 AND MAX([L_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=11 AND MAX([L_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=16 AND MAX([L_lo]) <=20.9 THEN 'Green'
WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=21 AND MAX([L_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=26 AND MAX([L_lo]) <=30.9 THEN 'Blue'
WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [l_back],
CASE WHEN MAX([LIN_dpt]) > 1 THEN 'Red'
WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=1 AND MAX([LIN_lo]) <=5.9 THEN 'White'
WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=6 AND MAX([LIN_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=11 AND MAX([LIN_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=16 AND MAX([LIN_lo]) <=20.9 THEN 'Green'
WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=21 AND MAX([LIN_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=26 AND MAX([LIN_lo]) <=30.9 THEN 'Blue'
WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [lin_back],
CASE WHEN MAX([M_dpt]) > 1 THEN 'Red'
WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=1 AND MAX([M_lo]) <=5.9 THEN 'White'
WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=6 AND MAX([M_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=11 AND MAX([M_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=16 AND MAX([M_lo]) <=20.9 THEN 'Green'
WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=21 AND MAX([M_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=26 AND MAX([M_lo]) <=30.9 THEN 'Blue'
WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [m_back],
CASE WHEN MAX([N_dpt]) > 1 THEN 'Red'
WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=1 AND MAX([N_lo]) <=5.9 THEN 'White'
WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=6 AND MAX([N_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=11 AND MAX([N_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=16 AND MAX([N_lo]) <=20.9 THEN 'Green'
WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=21 AND MAX([N_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=26 AND MAX([N_lo]) <=30.9 THEN 'Blue'
WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [n_back],
CASE WHEN MAX([O_dpt]) > 1 THEN 'Red'
WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=1 AND MAX([O_lo]) <=5.9 THEN 'White'
WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=6 AND MAX([O_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=11 AND MAX([O_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=16 AND MAX([O_lo]) <=20.9 THEN 'Green'
WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=21 AND MAX([O_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=26 AND MAX([O_lo]) <=30.9 THEN 'Blue'
WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [o_back],
CASE WHEN MAX([OSD_dpt]) > 1 THEN 'Red'
WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=1 AND MAX([OSD_lo]) <=5.9 THEN 'White'
WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=6 AND MAX([OSD_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=11 AND MAX([OSD_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=16 AND MAX([OSD_lo]) <=20.9 THEN 'Green'
WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=21 AND MAX([OSD_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=26 AND MAX([OSD_lo]) <=30.9 THEN 'Blue'
WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [osd_back],
CASE WHEN MAX([P_dpt]) > 1 THEN 'Red'
WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=1 AND MAX([P_lo]) <=5.9 THEN 'White'
WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=6 AND MAX([P_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=11 AND MAX([P_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=16 AND MAX([P_lo]) <=20.9 THEN 'Green'
WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=21 AND MAX([P_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=26 AND MAX([P_lo]) <=30.9 THEN 'Blue'
WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [p_back],
CASE WHEN MAX([Q_dpt]) > 1 THEN 'Red'
WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=1 AND MAX([Q_lo]) <=5.9 THEN 'White'
WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=6 AND MAX([Q_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=11 AND MAX([Q_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=16 AND MAX([Q_lo]) <=20.9 THEN 'Green'
WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=21 AND MAX([Q_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=26 AND MAX([Q_lo]) <=30.9 THEN 'Blue'
WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [q_back],
CASE WHEN MAX([R_dpt]) > 1 THEN 'Red'
WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=1 AND MAX([R_lo]) <=5.9 THEN 'White'
WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=6 AND MAX([R_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=11 AND MAX([R_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=16 AND MAX([R_lo]) <=20.9 THEN 'Green'
WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=21 AND MAX([R_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=26 AND MAX([R_lo]) <=30.9 THEN 'Blue'
WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [r_back],
CASE WHEN MAX([S_dpt]) > 1 THEN 'Red'
WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=1 AND MAX([S_lo]) <=5.9 THEN 'White'
WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=6 AND MAX([S_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=11 AND MAX([S_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=16 AND MAX([S_lo]) <=20.9 THEN 'Green'
WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=21 AND MAX([S_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=26 AND MAX([S_lo]) <=30.9 THEN 'Blue'
WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [s_back],
CASE WHEN MAX([T_dpt]) > 1 THEN 'Red'
WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=1 AND MAX([T_lo]) <=5.9 THEN 'White'
WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=6 AND MAX([T_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=11 AND MAX([T_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=16 AND MAX([T_lo]) <=20.9 THEN 'Green'
WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=21 AND MAX([T_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=26 AND MAX([T_lo]) <=30.9 THEN 'Blue'
WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [t_back],
CASE WHEN MAX([U_dpt]) > 1 THEN 'Red'
WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=1 AND MAX([U_lo]) <=5.9 THEN 'White'
WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=6 AND MAX([U_lo]) <=10.9 THEN 'Yellow'
WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=11 AND MAX([U_lo]) <=15.9 THEN 'Maroon'
WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=16 AND MAX([U_lo]) <=20.9 THEN 'Green'
WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=21 AND MAX([U_lo]) <=25.9 THEN 'PaleTurquoise'
WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=26 AND MAX([U_lo]) <=30.9 THEN 'Blue'
WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=31 THEN 'Black'
ELSE 'White' END AS [u_back],
CASE WHEN MAX([10LIN_A_dpt]) > 1 THEN 'Red'     WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=1 AND MAX([10LIN_A_lo]) <=5.9 THEN 'Black'     WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=6 AND MAX([10LIN_A_lo]) <=10.9 THEN 'Black'     WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=11 AND MAX([10LIN_A_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=16 AND MAX([10LIN_A_lo]) <=20.9 THEN 'White'     WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=21 AND MAX([10LIN_A_lo]) <=25.9 THEN 'Blue'     WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=26 AND MAX([10LIN_A_lo]) <=30.9 THEN 'White'     WHEN MAX([10LIN_A_dpt])<=1 AND LEN(TRIM(MAX([10LIN_A]))) >1 AND MAX([10LIN_A_lo]) >=31 THEN 'White'     ELSE 'White' END AS [10lin_a_font],
CASE WHEN MAX([10LIN_B_dpt]) > 1 THEN 'Red'     WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=1 AND MAX([10LIN_B_lo]) <=5.9 THEN 'Black'     WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=6 AND MAX([10LIN_B_lo]) <=10.9 THEN 'Black'     WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=11 AND MAX([10LIN_B_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=16 AND MAX([10LIN_B_lo]) <=20.9 THEN 'White'     WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=21 AND MAX([10LIN_B_lo]) <=25.9 THEN 'Blue'     WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=26 AND MAX([10LIN_B_lo]) <=30.9 THEN 'White'     WHEN MAX([10LIN_B_dpt])<=1 AND LEN(TRIM(MAX([10LIN_B]))) >1 AND MAX([10LIN_B_lo]) >=31 THEN 'White'     ELSE 'White' END AS [10lin_b_font],
CASE WHEN MAX([11D_dpt]) > 1 THEN 'Red'     WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=1 AND MAX([11D_lo]) <=5.9 THEN 'Black'     WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=6 AND MAX([11D_lo]) <=10.9 THEN 'Black'     WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=11 AND MAX([11D_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=16 AND MAX([11D_lo]) <=20.9 THEN 'White'     WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=21 AND MAX([11D_lo]) <=25.9 THEN 'Blue'     WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=26 AND MAX([11D_lo]) <=30.9 THEN 'White'     WHEN MAX([11D_dpt])<=1 AND LEN(TRIM(MAX([11D]))) >1 AND MAX([11D_lo]) >=31 THEN 'White'     ELSE 'White' END AS [11d_font],
CASE WHEN MAX([A_dpt]) > 1 THEN 'Red'     WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=1 AND MAX([A_lo]) <=5.9 THEN 'Black'     WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=6 AND MAX([A_lo]) <=10.9 THEN 'Black'     WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=11 AND MAX([A_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=16 AND MAX([A_lo]) <=20.9 THEN 'White'     WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=21 AND MAX([A_lo]) <=25.9 THEN 'Blue'     WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=26 AND MAX([A_lo]) <=30.9 THEN 'White'     WHEN MAX([A_dpt])<=1 AND LEN(TRIM(MAX([A]))) >1 AND MAX([A_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [a_font],
CASE WHEN MAX([B_dpt]) > 1 THEN 'Red'     WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=1 AND MAX([B_lo]) <=5.9 THEN 'Black'     WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=6 AND MAX([B_lo]) <=10.9 THEN 'Black'     WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=11 AND MAX([B_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=16 AND MAX([B_lo]) <=20.9 THEN 'White'     WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=21 AND MAX([B_lo]) <=25.9 THEN 'Blue'     WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=26 AND MAX([B_lo]) <=30.9 THEN 'White'     WHEN MAX([B_dpt])<=1 AND LEN(TRIM(MAX([B]))) >1 AND MAX([B_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [b_font],
CASE WHEN MAX([C_dpt]) > 1 THEN 'Red'     WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=1 AND MAX([C_lo]) <=5.9 THEN 'Black'     WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=6 AND MAX([C_lo]) <=10.9 THEN 'Black'     WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=11 AND MAX([C_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=16 AND MAX([C_lo]) <=20.9 THEN 'White'     WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=21 AND MAX([C_lo]) <=25.9 THEN 'Blue'     WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=26 AND MAX([C_lo]) <=30.9 THEN 'White'     WHEN MAX([C_dpt])<=1 AND LEN(TRIM(MAX([C]))) >1 AND MAX([C_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [c_font],
CASE WHEN MAX([D_dpt]) > 1 THEN 'Red'     WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=1 AND MAX([D_lo]) <=5.9 THEN 'Black'     WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=6 AND MAX([D_lo]) <=10.9 THEN 'Black'     WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=11 AND MAX([D_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=16 AND MAX([D_lo]) <=20.9 THEN 'White'     WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=21 AND MAX([D_lo]) <=25.9 THEN 'Blue'     WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=26 AND MAX([D_lo]) <=30.9 THEN 'White'     WHEN MAX([D_dpt])<=1 AND LEN(TRIM(MAX([D]))) >1 AND MAX([D_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [d_font],
CASE WHEN MAX([E_dpt]) > 1 THEN 'Red'     WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=1 AND MAX([E_lo]) <=5.9 THEN 'Black'     WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=6 AND MAX([E_lo]) <=10.9 THEN 'Black'     WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=11 AND MAX([E_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=16 AND MAX([E_lo]) <=20.9 THEN 'White'     WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=21 AND MAX([E_lo]) <=25.9 THEN 'Blue'     WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=26 AND MAX([E_lo]) <=30.9 THEN 'White'     WHEN MAX([E_dpt])<=1 AND LEN(TRIM(MAX([E]))) >1 AND MAX([E_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [e_font],
CASE WHEN MAX([F_dpt]) > 1 THEN 'Red'     WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=1 AND MAX([F_lo]) <=5.9 THEN 'Black'     WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=6 AND MAX([F_lo]) <=10.9 THEN 'Black'     WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=11 AND MAX([F_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=16 AND MAX([F_lo]) <=20.9 THEN 'White'     WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=21 AND MAX([F_lo]) <=25.9 THEN 'Blue'     WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=26 AND MAX([F_lo]) <=30.9 THEN 'White'     WHEN MAX([F_dpt])<=1 AND LEN(TRIM(MAX([F]))) >1 AND MAX([F_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [f_font],
CASE WHEN MAX([G_dpt]) > 1 THEN 'Red'     WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=1 AND MAX([G_lo]) <=5.9 THEN 'Black'     WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=6 AND MAX([G_lo]) <=10.9 THEN 'Black'     WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=11 AND MAX([G_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=16 AND MAX([G_lo]) <=20.9 THEN 'White'     WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=21 AND MAX([G_lo]) <=25.9 THEN 'Blue'     WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=26 AND MAX([G_lo]) <=30.9 THEN 'White'     WHEN MAX([G_dpt])<=1 AND LEN(TRIM(MAX([G]))) >1 AND MAX([G_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [g_font],
CASE WHEN MAX([H_dpt]) > 1 THEN 'Red'     WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=1 AND MAX([H_lo]) <=5.9 THEN 'Black'     WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=6 AND MAX([H_lo]) <=10.9 THEN 'Black'     WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=11 AND MAX([H_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=16 AND MAX([H_lo]) <=20.9 THEN 'White'     WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=21 AND MAX([H_lo]) <=25.9 THEN 'Blue'     WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=26 AND MAX([H_lo]) <=30.9 THEN 'White'     WHEN MAX([H_dpt])<=1 AND LEN(TRIM(MAX([H]))) >1 AND MAX([H_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [h_font],
CASE WHEN MAX([I_dpt]) > 1 THEN 'Red'     WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=1 AND MAX([I_lo]) <=5.9 THEN 'Black'     WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=6 AND MAX([I_lo]) <=10.9 THEN 'Black'     WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=11 AND MAX([I_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=16 AND MAX([I_lo]) <=20.9 THEN 'White'     WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=21 AND MAX([I_lo]) <=25.9 THEN 'Blue'     WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=26 AND MAX([I_lo]) <=30.9 THEN 'White'     WHEN MAX([I_dpt])<=1 AND LEN(TRIM(MAX([I]))) >1 AND MAX([I_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [i_font],
CASE WHEN MAX([J_dpt]) > 1 THEN 'Red'     WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=1 AND MAX([J_lo]) <=5.9 THEN 'Black'     WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=6 AND MAX([J_lo]) <=10.9 THEN 'Black'     WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=11 AND MAX([J_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=16 AND MAX([J_lo]) <=20.9 THEN 'White'     WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=21 AND MAX([J_lo]) <=25.9 THEN 'Blue'     WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=26 AND MAX([J_lo]) <=30.9 THEN 'White'     WHEN MAX([J_dpt])<=1 AND LEN(TRIM(MAX([J]))) >1 AND MAX([J_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [j_font],
CASE WHEN MAX([K_dpt]) > 1 THEN 'Red'     WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=1 AND MAX([K_lo]) <=5.9 THEN 'Black'     WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=6 AND MAX([K_lo]) <=10.9 THEN 'Black'     WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=11 AND MAX([K_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=16 AND MAX([K_lo]) <=20.9 THEN 'White'     WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=21 AND MAX([K_lo]) <=25.9 THEN 'Blue'     WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=26 AND MAX([K_lo]) <=30.9 THEN 'White'     WHEN MAX([K_dpt])<=1 AND LEN(TRIM(MAX([K]))) >1 AND MAX([K_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [k_font],
CASE WHEN MAX([L_dpt]) > 1 THEN 'Red'     WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=1 AND MAX([L_lo]) <=5.9 THEN 'Black'     WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=6 AND MAX([L_lo]) <=10.9 THEN 'Black'     WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=11 AND MAX([L_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=16 AND MAX([L_lo]) <=20.9 THEN 'White'     WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=21 AND MAX([L_lo]) <=25.9 THEN 'Blue'     WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=26 AND MAX([L_lo]) <=30.9 THEN 'White'     WHEN MAX([L_dpt])<=1 AND LEN(TRIM(MAX([L]))) >1 AND MAX([L_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [l_font],
CASE WHEN MAX([LIN_dpt]) > 1 THEN 'Red'     WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=1 AND MAX([LIN_lo]) <=5.9 THEN 'Black'     WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=6 AND MAX([LIN_lo]) <=10.9 THEN 'Black'     WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=11 AND MAX([LIN_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=16 AND MAX([LIN_lo]) <=20.9 THEN 'White'     WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=21 AND MAX([LIN_lo]) <=25.9 THEN 'Blue'     WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=26 AND MAX([LIN_lo]) <=30.9 THEN 'White'     WHEN MAX([LIN_dpt])<=1 AND LEN(TRIM(MAX([LIN]))) >1 AND MAX([LIN_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [lin_font],
CASE WHEN MAX([M_dpt]) > 1 THEN 'Red'     WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=1 AND MAX([M_lo]) <=5.9 THEN 'Black'     WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=6 AND MAX([M_lo]) <=10.9 THEN 'Black'     WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=11 AND MAX([M_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=16 AND MAX([M_lo]) <=20.9 THEN 'White'     WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=21 AND MAX([M_lo]) <=25.9 THEN 'Blue'     WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=26 AND MAX([M_lo]) <=30.9 THEN 'White'     WHEN MAX([M_dpt])<=1 AND LEN(TRIM(MAX([M]))) >1 AND MAX([M_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [m_font],
CASE WHEN MAX([N_dpt]) > 1 THEN 'Red'     WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=1 AND MAX([N_lo]) <=5.9 THEN 'Black'     WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=6 AND MAX([N_lo]) <=10.9 THEN 'Black'     WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=11 AND MAX([N_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=16 AND MAX([N_lo]) <=20.9 THEN 'White'     WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=21 AND MAX([N_lo]) <=25.9 THEN 'Blue'     WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=26 AND MAX([N_lo]) <=30.9 THEN 'White'     WHEN MAX([N_dpt])<=1 AND LEN(TRIM(MAX([N]))) >1 AND MAX([N_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [n_font],
CASE WHEN MAX([O_dpt]) > 1 THEN 'Red'     WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=1 AND MAX([O_lo]) <=5.9 THEN 'Black'     WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=6 AND MAX([O_lo]) <=10.9 THEN 'Black'     WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=11 AND MAX([O_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=16 AND MAX([O_lo]) <=20.9 THEN 'White'     WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=21 AND MAX([O_lo]) <=25.9 THEN 'Blue'     WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=26 AND MAX([O_lo]) <=30.9 THEN 'White'     WHEN MAX([O_dpt])<=1 AND LEN(TRIM(MAX([O]))) >1 AND MAX([O_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [o_font],
CASE WHEN MAX([OSD_dpt]) > 1 THEN 'Red'     WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=1 AND MAX([OSD_lo]) <=5.9 THEN 'Black'     WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=6 AND MAX([OSD_lo]) <=10.9 THEN 'Black'     WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=11 AND MAX([OSD_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=16 AND MAX([OSD_lo]) <=20.9 THEN 'White'     WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=21 AND MAX([OSD_lo]) <=25.9 THEN 'Blue'     WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=26 AND MAX([OSD_lo]) <=30.9 THEN 'White'     WHEN MAX([OSD_dpt])<=1 AND LEN(TRIM(MAX([OSD]))) >1 AND MAX([OSD_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [osd_font],
CASE WHEN MAX([P_dpt]) > 1 THEN 'Red'     WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=1 AND MAX([P_lo]) <=5.9 THEN 'Black'     WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=6 AND MAX([P_lo]) <=10.9 THEN 'Black'     WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=11 AND MAX([P_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=16 AND MAX([P_lo]) <=20.9 THEN 'White'     WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=21 AND MAX([P_lo]) <=25.9 THEN 'Blue'     WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=26 AND MAX([P_lo]) <=30.9 THEN 'White'     WHEN MAX([P_dpt])<=1 AND LEN(TRIM(MAX([P]))) >1 AND MAX([P_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [p_font],
CASE WHEN MAX([Q_dpt]) > 1 THEN 'Red'     WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=1 AND MAX([Q_lo]) <=5.9 THEN 'Black'     WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=6 AND MAX([Q_lo]) <=10.9 THEN 'Black'     WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=11 AND MAX([Q_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=16 AND MAX([Q_lo]) <=20.9 THEN 'White'     WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=21 AND MAX([Q_lo]) <=25.9 THEN 'Blue'     WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=26 AND MAX([Q_lo]) <=30.9 THEN 'White'     WHEN MAX([Q_dpt])<=1 AND LEN(TRIM(MAX([Q]))) >1 AND MAX([Q_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [q_font],
CASE WHEN MAX([R_dpt]) > 1 THEN 'Red'     WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=1 AND MAX([R_lo]) <=5.9 THEN 'Black'     WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=6 AND MAX([R_lo]) <=10.9 THEN 'Black'     WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=11 AND MAX([R_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=16 AND MAX([R_lo]) <=20.9 THEN 'White'     WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=21 AND MAX([R_lo]) <=25.9 THEN 'Blue'     WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=26 AND MAX([R_lo]) <=30.9 THEN 'White'     WHEN MAX([R_dpt])<=1 AND LEN(TRIM(MAX([R]))) >1 AND MAX([R_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [r_font],
CASE WHEN MAX([S_dpt]) > 1 THEN 'Red'     WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=1 AND MAX([S_lo]) <=5.9 THEN 'Black'     WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=6 AND MAX([S_lo]) <=10.9 THEN 'Black'     WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=11 AND MAX([S_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=16 AND MAX([S_lo]) <=20.9 THEN 'White'     WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=21 AND MAX([S_lo]) <=25.9 THEN 'Blue'     WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=26 AND MAX([S_lo]) <=30.9 THEN 'White'     WHEN MAX([S_dpt])<=1 AND LEN(TRIM(MAX([S]))) >1 AND MAX([S_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [s_font],
CASE WHEN MAX([T_dpt]) > 1 THEN 'Red'     WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=1 AND MAX([T_lo]) <=5.9 THEN 'Black'     WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=6 AND MAX([T_lo]) <=10.9 THEN 'Black'     WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=11 AND MAX([T_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=16 AND MAX([T_lo]) <=20.9 THEN 'White'     WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=21 AND MAX([T_lo]) <=25.9 THEN 'Blue'     WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=26 AND MAX([T_lo]) <=30.9 THEN 'White'     WHEN MAX([T_dpt])<=1 AND LEN(TRIM(MAX([T]))) >1 AND MAX([T_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [t_font],
CASE WHEN MAX([U_dpt]) > 1 THEN 'Red'     WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=1 AND MAX([U_lo]) <=5.9 THEN 'Black'     WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=6 AND MAX([U_lo]) <=10.9 THEN 'Black'     WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=11 AND MAX([U_lo]) <=15.9 THEN 'Yellow'     WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=16 AND MAX([U_lo]) <=20.9 THEN 'White'     WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=21 AND MAX([U_lo]) <=25.9 THEN 'Blue'     WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=26 AND MAX([U_lo]) <=30.9 THEN 'White'     WHEN MAX([U_dpt])<=1 AND LEN(TRIM(MAX([U]))) >1 AND MAX([U_lo]) >=31 THEN 'White'     ELSE 'Black' END AS [u_font]
FROM (
SELECT q.booking_id,q.sched_type_id
   ,q.depart_time AS depart
,CASE WHEN q.[10LIN_A] >= 1 AND ISNULL(m.[10LIN_A_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [10LIN_A]
,CASE WHEN q.[10LIN_B] >= 1 AND ISNULL(m.[10LIN_B_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [10LIN_B]
,CASE WHEN q.[11D] >= 1 AND ISNULL(m.[11D_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [11D]
,CASE WHEN q.[A] >= 1 AND ISNULL(m.[A_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [A]
,CASE WHEN q.[B] >= 1 AND ISNULL(m.[B_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [B]
,CASE WHEN q.[C] >= 1 AND ISNULL(m.[C_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [C]
,CASE WHEN q.[D] >= 1 AND ISNULL(m.[D_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [D]
,CASE WHEN q.[E] >= 1 AND ISNULL(m.[E_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [E]
,CASE WHEN q.[F] >= 1 AND ISNULL(m.[F_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [F]
,CASE WHEN q.[G] >= 1 AND ISNULL(m.[G_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [G]
,CASE WHEN q.[H] >= 1 AND ISNULL(m.[H_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [H]
,CASE WHEN q.[I] >= 1 AND ISNULL(m.[I_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [I]
,CASE WHEN q.[J] >= 1 AND ISNULL(m.[J_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [J]
,CASE WHEN q.[K] >= 1 AND ISNULL(m.[K_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [K]
,CASE WHEN q.[L] >= 1 AND ISNULL(m.[L_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [L]
,CASE WHEN q.[LIN] >= 1 AND ISNULL(m.[LIN_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [LIN]
,CASE WHEN q.[M] >= 1 AND ISNULL(m.[M_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [M]
,CASE WHEN q.[N] >= 1 AND ISNULL(m.[N_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [N]
,CASE WHEN q.[O] >= 1 AND ISNULL(m.[O_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [O]
,CASE WHEN q.[OSD] >= 1 AND ISNULL(m.[OSD_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [OSD]
,CASE WHEN q.[P] >= 1 AND ISNULL(m.[P_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [P]
,CASE WHEN q.[Q] >= 1 AND ISNULL(m.[Q_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [Q]
,CASE WHEN q.[R] >= 1 AND ISNULL(m.[R_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [R]
,CASE WHEN q.[S] >= 1 AND ISNULL(m.[S_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [S]
,CASE WHEN q.[T] >= 1 AND ISNULL(m.[T_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [T]
,CASE WHEN q.[U] >= 1 AND ISNULL(m.[U_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END AS [U]
,ISNULL(MAX(v.[10LIN_A_lo]),0) AS [10LIN_A_lo]
,ISNULL(MAX(v.[10LIN_B_lo]),0) AS [10LIN_B_lo]
,ISNULL(MAX(v.[11D_lo]),0) AS [11D_lo]
,ISNULL(MAX(v.[A_lo]),0) AS [A_lo]
,ISNULL(MAX(v.[B_lo]),0) AS [B_lo]
,ISNULL(MAX(v.[C_lo]),0) AS [C_lo]
,ISNULL(MAX(v.[D_lo]),0) AS [D_lo]
,ISNULL(MAX(v.[E_lo]),0) AS [E_lo]
,ISNULL(MAX(v.[F_lo]),0) AS [F_lo]
,ISNULL(MAX(v.[G_lo]),0) AS [G_lo]
,ISNULL(MAX(v.[H_lo]),0) AS [H_lo]
,ISNULL(MAX(v.[I_lo]),0) AS [I_lo]
,ISNULL(MAX(v.[J_lo]),0) AS [J_lo]
,ISNULL(MAX(v.[K_lo]),0) AS [K_lo]
,ISNULL(MAX(v.[L_lo]),0) AS [L_lo]
,ISNULL(MAX(v.[LIN_lo]),0) AS [LIN_lo]
,ISNULL(MAX(v.[M_lo]),0) AS [M_lo]
,ISNULL(MAX(v.[N_lo]),0) AS [N_lo]
,ISNULL(MAX(v.[O_lo]),0) AS [O_lo]
,ISNULL(MAX(v.[OSD_lo]),0) AS [OSD_lo]
,ISNULL(MAX(v.[P_lo]),0) AS [P_lo]
,ISNULL(MAX(v.[Q_lo]),0) AS [Q_lo]
,ISNULL(MAX(v.[R_lo]),0) AS [R_lo]
,ISNULL(MAX(v.[S_lo]),0) AS [S_lo]
,ISNULL(MAX(v.[T_lo]),0) AS [T_lo]
,ISNULL(MAX(v.[U_lo]),0) AS [U_lo]
,ISNULL(MAX(m.[10LIN_A_dpt]),0) AS [10LIN_A_dpt]
,ISNULL(MAX(m.[10LIN_B_dpt]),0) AS [10LIN_B_dpt]
,ISNULL(MAX(m.[11D_dpt]),0) AS [11D_dpt]
,ISNULL(MAX(m.[A_dpt]),0) AS [A_dpt]
,ISNULL(MAX(m.[B_dpt]),0) AS [B_dpt]
,ISNULL(MAX(m.[C_dpt]),0) AS [C_dpt]
,ISNULL(MAX(m.[D_dpt]),0) AS [D_dpt]
,ISNULL(MAX(m.[E_dpt]),0) AS [E_dpt]
,ISNULL(MAX(m.[F_dpt]),0) AS [F_dpt]
,ISNULL(MAX(m.[G_dpt]),0) AS [G_dpt]
,ISNULL(MAX(m.[H_dpt]),0) AS [H_dpt]
,ISNULL(MAX(m.[I_dpt]),0) AS [I_dpt]
,ISNULL(MAX(m.[J_dpt]),0) AS [J_dpt]
,ISNULL(MAX(m.[K_dpt]),0) AS [K_dpt]
,ISNULL(MAX(m.[L_dpt]),0) AS [L_dpt]
,ISNULL(MAX(m.[LIN_dpt]),0) AS [LIN_dpt]
,ISNULL(MAX(m.[M_dpt]),0) AS [M_dpt]
,ISNULL(MAX(m.[N_dpt]),0) AS [N_dpt]
,ISNULL(MAX(m.[O_dpt]),0) AS [O_dpt]
,ISNULL(MAX(m.[OSD_dpt]),0) AS [OSD_dpt]
,ISNULL(MAX(m.[P_dpt]),0) AS [P_dpt]
,ISNULL(MAX(m.[Q_dpt]),0) AS [Q_dpt]
,ISNULL(MAX(m.[R_dpt]),0) AS [R_dpt]
,ISNULL(MAX(m.[S_dpt]),0) AS [S_dpt]
,ISNULL(MAX(m.[T_dpt]),0) AS [T_dpt]
,ISNULL(MAX(m.[U_dpt]),0) AS [U_dpt]
FROM (
SELECT booking_id
,sched_type_id
,depart_time
,duty_id_1
,route_id_1
,ISNULL([es_10lin_a],0) AS [10LIN_A]
,ISNULL([es_10lin_b],0) AS [10LIN_B]
,ISNULL([es_11d],0) AS [11D]
,ISNULL([es_a],0) AS [A]
,ISNULL([es_b],0) AS [B]
,ISNULL([es_c],0) AS [C]
,ISNULL([es_d],0) AS [D]
,ISNULL([es_e],0) AS [E]
,ISNULL([es_f],0) AS [F]
,ISNULL([es_g],0) AS [G]
,ISNULL([es_h],0) AS [H]
,ISNULL([es_i],0) AS [I]
,ISNULL([es_j],0) AS [J]
,ISNULL([es_k],0) AS [K]
,ISNULL([es_l],0) AS [L]
,ISNULL([es_lin],0) AS [LIN]
,ISNULL([es_m],0) AS [M]
,ISNULL([es_n],0) AS [N]
,ISNULL([es_o],0) AS [O]
,ISNULL([es_osd],0) AS [OSD]
,ISNULL([es_p],0) AS [P]
,ISNULL([es_q],0) AS [Q]
,ISNULL([es_r],0) AS [R]
,ISNULL([es_s],0) AS [S]
,ISNULL([es_t],0) AS [T]
,ISNULL([es_u],0) AS [U]
FROM (
SELECT
    y.booking_id, y.sched_type_id , y.sched_type_id sched_id, y.place_id, y.depart_time, y.Layover, y.route_id_1, y.duty_id_1
FROM
    hastus.layovers y 
	JOIN setupYr s ON y.booking_id >= s.bookYr
WHERE
    (y.sched_type_id = 0 OR
    y.sched_type_id = 5 OR
    y.sched_type_id = 6)
	AND y.place_id LIKE 'es%'
GROUP BY  y.booking_id, y.sched_type_id, y.place_id, y.depart_time, y.Layover, y.route_id_1, y.duty_id_1

) AS src
PIVOT (
COUNT(sched_id)
FOR place_id IN ([es_10lin_a],[es_10lin_b],[es_11d],[es_a],[es_b],[es_c],[es_d],[es_e],[es_f],[es_g],[es_h],[es_i],[es_j],[es_k],[es_l],[es_lin],[es_m],[es_n],[es_o],[es_osd],[es_p],[es_q],[es_r],[es_s],[es_t],[es_u])
) AS pvt
) q
LEFT JOIN lyvrs v ON v.booking_id = q.booking_id
	 AND v.depart = q.depart_time 
	 AND v.sched_type_id = q.sched_type_id 
LEFT JOIN dpt_max m ON m.booking_id = q.booking_id
	AND m.depart_time = q.depart_time
	AND m.sched_type_id = q.sched_type_id
GROUP BY q.booking_id,q.sched_type_id,q.depart_time 
,CASE WHEN q.[10LIN_A] >= 1 AND ISNULL(m.[10LIN_A_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[10LIN_B] >= 1 AND ISNULL(m.[10LIN_B_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[11D] >= 1 AND ISNULL(m.[11D_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[A] >= 1 AND ISNULL(m.[A_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[B] >= 1 AND ISNULL(m.[B_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[C] >= 1 AND ISNULL(m.[C_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[D] >= 1 AND ISNULL(m.[D_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[E] >= 1 AND ISNULL(m.[E_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[F] >= 1 AND ISNULL(m.[F_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[G] >= 1 AND ISNULL(m.[G_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[H] >= 1 AND ISNULL(m.[H_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[I] >= 1 AND ISNULL(m.[I_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[J] >= 1 AND ISNULL(m.[J_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[K] >= 1 AND ISNULL(m.[K_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[L] >= 1 AND ISNULL(m.[L_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[LIN] >= 1 AND ISNULL(m.[LIN_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[M] >= 1 AND ISNULL(m.[M_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[N] >= 1 AND ISNULL(m.[N_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[O] >= 1 AND ISNULL(m.[O_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[OSD] >= 1 AND ISNULL(m.[OSD_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[P] >= 1 AND ISNULL(m.[P_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[Q] >= 1 AND ISNULL(m.[Q_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[R] >= 1 AND ISNULL(m.[R_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[S] >= 1 AND ISNULL(m.[S_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[T] >= 1 AND ISNULL(m.[T_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
,CASE WHEN q.[U] >= 1 AND ISNULL(m.[U_dpt],0) <= 1 THEN q.route_id_1 + '(' + q.duty_id_1 + ')' ELSE '' END 
) t
GROUP BY 
booking_id,depart,sched_type_id

GO
