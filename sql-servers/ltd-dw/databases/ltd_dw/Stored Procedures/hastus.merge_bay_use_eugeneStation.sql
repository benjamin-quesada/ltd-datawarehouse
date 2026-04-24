SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [hastus].[merge_bay_use_eugeneStation]
AS
/*-----------LTD_GLOSSARY---------------
 created by	:  b. eichberger
 created dt	:  20240524
 purpose	:  speed data for report by merging ltd_dw.[hastus].[bay_use_eugeneStation] 
			   from ltd_dw.[hastus].[bay_use_eugeneStation_v]
 use		:  exec hastus.merge_bay_use_eugeneStation

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

BEGIN TRY

	DECLARE @sdt DATETIME2 = SYSDATETIME();
	DECLARE @outputTbl TABLE
	(actionNm VARCHAR(32));


	MERGE ltd_dw.[hastus].[bay_use_eugeneStation] AS t
	USING ltd_dw.[hastus].bay_use_eugeneStation_v AS s
	ON (t.booking_id = s.booking_id COLLATE	SQL_Latin1_General_CP850_CI_AS
	AND t.depart = s.depart COLLATE	SQL_Latin1_General_CP850_CI_AS
	AND t.hr_grp = s.hr_grp 
	AND t.sched_type_id = s.sched_type_id 
	)
	WHEN MATCHED AND (
		ISNULL(t.[10LIN_A], '') <> ISNULL(s.[10LIN_A], '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.[10LIN_B], '') <> ISNULL(s.[10LIN_B], '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.[11D], '') <> ISNULL(s.[11D], '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.A, '') <> ISNULL(s.A, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.B, '') <> ISNULL(s.B, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.C, '') <> ISNULL(s.C, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.D, '') <> ISNULL(s.D, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.E, '') <> ISNULL(s.E, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.F, '') <> ISNULL(s.F, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.G, '') <> ISNULL(s.G, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.H, '') <> ISNULL(s.H, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.I, '') <> ISNULL(s.I, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.J, '') <> ISNULL(s.J, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.K, '') <> ISNULL(s.K, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.L, '') <> ISNULL(s.L, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.LIN, '') <> ISNULL(s.LIN, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.M, '') <> ISNULL(s.M, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.N, '') <> ISNULL(s.N, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.O, '') <> ISNULL(s.O, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.OSD, '') <> ISNULL(s.OSD, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.P, '') <> ISNULL(s.P, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.Q, '') <> ISNULL(s.Q, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.R, '') <> ISNULL(s.R, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.S, '') <> ISNULL(s.S, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.T, '') <> ISNULL(s.T, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.U, '') <> ISNULL(s.U, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.[10LIN_A_lo], 0) <> ISNULL(s.[10LIN_A_lo], 0) 	
		OR ISNULL(t.[10LIN_B_lo], 0) <> ISNULL(s.[10LIN_B_lo], 0) 	
		OR ISNULL(t.[11D_lo], '') <> ISNULL(s.[11D_lo], '') 	
		OR ISNULL(t.A_lo, 0) <> ISNULL(s.A_lo, 0) 	
		OR ISNULL(t.B_lo, 0) <> ISNULL(s.B_lo, 0) 	
		OR ISNULL(t.C_lo, 0) <> ISNULL(s.C_lo, 0) 	
		OR ISNULL(t.D_lo, 0) <> ISNULL(s.D_lo, 0) 	
		OR ISNULL(t.E_lo, 0) <> ISNULL(s.E_lo, 0) 	
		OR ISNULL(t.F_lo, 0) <> ISNULL(s.F_lo, 0) 	
		OR ISNULL(t.G_lo, 0) <> ISNULL(s.G_lo, 0) 	
		OR ISNULL(t.H_lo, 0) <> ISNULL(s.H_lo, 0) 	
		OR ISNULL(t.I_lo, 0) <> ISNULL(s.I_lo, 0) 	
		OR ISNULL(t.J_lo, 0) <> ISNULL(s.J_lo, 0) 	
		OR ISNULL(t.K_lo, 0) <> ISNULL(s.K_lo, 0) 	
		OR ISNULL(t.L_lo, 0) <> ISNULL(s.L_lo, 0) 	
		OR ISNULL(t.LIN_lo, 0) <> ISNULL(s.LIN_lo, 0) 	
		OR ISNULL(t.M_lo, 0) <> ISNULL(s.M_lo, 0) 	
		OR ISNULL(t.N_lo, 0) <> ISNULL(s.N_lo, 0) 	
		OR ISNULL(t.O_lo, 0) <> ISNULL(s.O_lo, 0) 	
		OR ISNULL(t.OSD_lo, 0) <> ISNULL(s.OSD_lo, 0) 	
		OR ISNULL(t.P_lo, 0) <> ISNULL(s.P_lo, 0) 	
		OR ISNULL(t.Q_lo, 0) <> ISNULL(s.Q_lo, 0) 	
		OR ISNULL(t.R_lo, 0) <> ISNULL(s.R_lo, 0) 	
		OR ISNULL(t.S_lo, 0) <> ISNULL(s.S_lo, 0) 	
		OR ISNULL(t.T_lo, 0) <> ISNULL(s.T_lo, 0) 	
		OR ISNULL(t.U_lo, 0) <> ISNULL(s.U_lo, 0) 	
		OR ISNULL(t.[10lin_a_back], '') <> ISNULL(s.[10lin_a_back], '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.[10lin_b_back], '') <> ISNULL(s.[10lin_b_back], '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.[11d_back], '') <> ISNULL(s.[11d_back], '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.a_back, '') <> ISNULL(s.a_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.b_back, '') <> ISNULL(s.b_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.c_back, '') <> ISNULL(s.c_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.d_back, '') <> ISNULL(s.d_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.e_back, '') <> ISNULL(s.e_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.f_back, '') <> ISNULL(s.f_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.g_back, '') <> ISNULL(s.g_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.h_back, '') <> ISNULL(s.h_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.i_back, '') <> ISNULL(s.i_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.j_back, '') <> ISNULL(s.j_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.k_back, '') <> ISNULL(s.k_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.l_back, '') <> ISNULL(s.l_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.lin_back, '') <> ISNULL(s.lin_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.m_back, '') <> ISNULL(s.m_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.n_back, '') <> ISNULL(s.n_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.o_back, '') <> ISNULL(s.o_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.osd_back, '') <> ISNULL(s.osd_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.p_back, '') <> ISNULL(s.p_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.q_back, '') <> ISNULL(s.q_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.r_back, '') <> ISNULL(s.r_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.s_back, '') <> ISNULL(s.s_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.t_back, '') <> ISNULL(s.t_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.u_back, '') <> ISNULL(s.u_back, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.[10lin_a_font], '') <> ISNULL(s.[10lin_a_font], '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.[10lin_b_font], '') <> ISNULL(s.[10lin_b_font], '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.[11d_font], '') <> ISNULL(s.[11d_font], '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.a_font, '') <> ISNULL(s.a_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.b_font, '') <> ISNULL(s.b_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.c_font, '') <> ISNULL(s.c_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.d_font, '') <> ISNULL(s.d_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.e_font, '') <> ISNULL(s.e_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.f_font, '') <> ISNULL(s.f_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.g_font, '') <> ISNULL(s.g_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.h_font, '') <> ISNULL(s.h_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.i_font, '') <> ISNULL(s.i_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.j_font, '') <> ISNULL(s.j_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.k_font, '') <> ISNULL(s.k_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.l_font, '') <> ISNULL(s.l_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.m_font, '') <> ISNULL(s.m_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.n_font, '') <> ISNULL(s.n_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.o_font, '') <> ISNULL(s.o_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.p_font, '') <> ISNULL(s.p_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.q_font, '') <> ISNULL(s.q_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.r_font, '') <> ISNULL(s.r_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.s_font, '') <> ISNULL(s.s_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.t_font, '') <> ISNULL(s.t_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
		OR ISNULL(t.u_font, '') <> ISNULL(s.u_font, '') COLLATE	SQL_Latin1_General_CP850_CI_AS
	) THEN 
	UPDATE SET 
	t.[10LIN_A] = s.[10LIN_A]
		,t.[10LIN_B] = s.[10LIN_B]
		,t.[11D] = s.[11D]
		,t.A = s.A
		,t.B = s.B
		,t.C = s.C
		,t.D = s.D
		,t.E = s.E
		,t.F = s.F
		,t.G = s.G
		,t.H = s.H
		,t.I = s.I
		,t.J = s.J
		,t.K = s.K
		,t.L = s.L
		,t.LIN = s.LIN
		,t.M = s.M
		,t.N = s.N
		,t.O = s.O
		,t.OSD = s.OSD
		,t.P = s.P
		,t.Q = s.Q
		,t.R = s.R
		,t.S = s.S
		,t.T = s.T
		,t.U = s.U
		,t.[10LIN_A_lo] = s.[10LIN_A_lo]
		,t.[10LIN_B_lo] = s.[10LIN_B_lo]
		,t.[11D_lo] = s.[11D_lo]
		,t.A_lo = s.A_lo
		,t.B_lo = s.B_lo
		,t.C_lo = s.C_lo
		,t.D_lo = s.D_lo
		,t.E_lo = s.E_lo
		,t.F_lo = s.F_lo
		,t.G_lo = s.G_lo
		,t.H_lo = s.H_lo
		,t.I_lo = s.I_lo
		,t.J_lo = s.J_lo
		,t.K_lo = s.K_lo
		,t.L_lo = s.L_lo
		,t.LIN_lo = s.LIN_lo
		,t.M_lo = s.M_lo
		,t.N_lo = s.N_lo
		,t.O_lo = s.O_lo
		,t.OSD_lo = s.OSD_lo
		,t.P_lo = s.P_lo
		,t.Q_lo = s.Q_lo
		,t.R_lo = s.R_lo
		,t.S_lo = s.S_lo
		,t.T_lo = s.T_lo
		,t.U_lo = s.U_lo
		,t.[10lin_a_back] = s.[10lin_a_back]
		,t.[10lin_b_back] = s.[10lin_b_back]
		,t.[11d_back] = s.[11d_back]
		,t.a_back = s.a_back
		,t.b_back = s.b_back
		,t.c_back = s.c_back
		,t.d_back = s.d_back
		,t.e_back = s.e_back
		,t.f_back = s.f_back
		,t.g_back = s.g_back
		,t.h_back = s.h_back
		,t.i_back = s.i_back
		,t.j_back = s.j_back
		,t.k_back = s.k_back
		,t.l_back = s.l_back
		,t.lin_back = s.lin_back
		,t.m_back = s.m_back
		,t.n_back = s.n_back
		,t.o_back = s.o_back
		,t.osd_back = s.osd_back
		,t.p_back = s.p_back
		,t.q_back = s.q_back
		,t.r_back = s.r_back
		,t.s_back = s.s_back
		,t.t_back = s.t_back
		,t.u_back = s.u_back
		,t.[10lin_a_font] = s.[10lin_a_font]
		,t.[10lin_b_font] = s.[10lin_b_font]
		,t.[11d_font] = s.[11d_font]
		,t.a_font = s.a_font
		,t.b_font = s.b_font
		,t.c_font = s.c_font
		,t.d_font = s.d_font
		,t.e_font = s.e_font
		,t.f_font = s.f_font
		,t.g_font = s.g_font
		,t.h_font = s.h_font
		,t.i_font = s.i_font
		,t.j_font = s.j_font
		,t.k_font = s.k_font
		,t.l_font = s.l_font
		,t.lin_font = s.lin_font
		,t.m_font = s.m_font
		,t.n_font = s.n_font
		,t.o_font = s.o_font
		,t.osd_font = s.osd_font
		,t.p_font = s.p_font
		,t.q_font = s.q_font
		,t.r_font = s.r_font
		,t.s_font = s.s_font
		,t.t_font = s.t_font
		,t.u_font = s.u_font
		,t.record_updated_date = SYSDATETIME()
	WHEN NOT MATCHED BY TARGET THEN INSERT (
	booking_id
	,depart
	,hr_grp
	,sched_type_id
	,[10LIN_A]
	,[10LIN_B]
	,[11D]
	,A
	,B
	,C
	,D
	,E
	,F
	,G
	,H
	,I
	,J
	,K
	,L
	,LIN
	,M
	,N
	,O
	,OSD
	,P
	,Q
	,R
	,S
	,T
	,U
	,[10LIN_A_lo]
	,[10LIN_B_lo]
	,[11D_lo]
	,A_lo
	,B_lo
	,C_lo
	,D_lo
	,E_lo
	,F_lo
	,G_lo
	,H_lo
	,I_lo
	,J_lo
	,K_lo
	,L_lo
	,LIN_lo
	,M_lo
	,N_lo
	,O_lo
	,OSD_lo
	,P_lo
	,Q_lo
	,R_lo
	,S_lo
	,T_lo
	,U_lo
	,[10lin_a_back]
	,[10lin_b_back]
	,[11d_back]
	,a_back
	,b_back
	,c_back
	,d_back
	,e_back
	,f_back
	,g_back
	,h_back
	,i_back
	,j_back
	,k_back
	,l_back
	,lin_back
	,m_back
	,n_back
	,o_back
	,osd_back
	,p_back
	,q_back
	,r_back
	,s_back
	,t_back
	,u_back
	,[10lin_a_font]
	,[10lin_b_font]
	,[11d_font]
	,a_font
	,b_font
	,c_font
	,d_font
	,e_font
	,f_font
	,g_font
	,h_font
	,i_font
	,j_font
	,k_font
	,l_font
	,lin_font
	,m_font
	,n_font
	,o_font
	,osd_font
	,p_font
	,q_font
	,r_font
	,s_font
	,t_font
	,u_font
)
VALUES
(s.booking_id,s.depart,s.hr_grp,s.sched_type_id,s.[10LIN_A],s.[10LIN_B],s.[11D],s.A,s.B,s.C,s.D,s.E,s.F,s.G,s.H,s.I,s.J,s.K,s.L,s.LIN,s.M,s.N,s.O,s.OSD,s.P,s.Q,s.R,s.S,s.T,s.U,s.[10LIN_A_lo],s.[10LIN_B_lo],s.[11D_lo],s.A_lo,s.B_lo,s.C_lo,s.D_lo,s.E_lo,s.F_lo,s.G_lo,s.H_lo,s.I_lo,s.J_lo,s.K_lo,s.L_lo,s.LIN_lo,s.M_lo,s.N_lo,s.O_lo,s.OSD_lo,s.P_lo,s.Q_lo,s.R_lo,s.S_lo,s.T_lo,s.U_lo,s.[10lin_a_back],s.[10lin_b_back],s.[11d_back],s.a_back,s.b_back,s.c_back,s.d_back,s.e_back,s.f_back,s.g_back,s.h_back,s.i_back,s.j_back,s.k_back,s.l_back,s.lin_back,s.m_back,s.n_back,s.o_back,s.osd_back,s.p_back,s.q_back,s.r_back,s.s_back,s.t_back,s.u_back,s.[10lin_a_font],s.[10lin_b_font],s.[11d_font],s.a_font,s.b_font,s.c_font,s.d_font,s.e_font,s.f_font,s.g_font,s.h_font,s.i_font,s.j_font,s.k_font,s.l_font,s.lin_font,s.m_font,s.n_font,s.o_font,s.osd_font,s.p_font,s.q_font,s.r_font,s.s_font,s.t_font,s.u_font)
	WHEN NOT MATCHED BY SOURCE THEN DELETE
	OUTPUT $action
	INTO @outputTbl;


	DECLARE @ins INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'INSERT');
	DECLARE @upd INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'UPDATE');
	DECLARE @del INT = (SELECT COUNT(*)FROM @outputTbl WHERE actionNm = 'DELETE');
	DECLARE @prg VARCHAR(90) = @@SERVERNAME + '.ltd_dw.hastus.merge_bay_use_eugeneStation';

	INSERT process.MergeLogs
	(
		[MergeCode]
	   ,[ObjectDestination]
	   ,[ObjectSource]
	   ,[ObjectProgram]
	   ,[recInsert]
	   ,[recUpdate]
	   ,[recDelete]
	   ,[MergeBeginDatetime]
	   ,[MergeEndDatetime]
	)
	SELECT 'HSTBU'
   ,'ltd_dw.[hastus].[bay_use_eugeneStation]'
   ,'HASTUS'
   ,@prg
   ,ISNULL(@ins, 0)
   ,ISNULL(@upd, 0)
   ,ISNULL(@del, 0)
   ,@sdt
   ,SYSDATETIME();



END TRY
BEGIN CATCH

	DECLARE @profile VARCHAR(255) = (
				SELECT [name] FROM msdb.dbo.sysmail_profile
			);
	DECLARE @errormsg VARCHAR(MAX)
   ,@error INT
   ,@message VARCHAR(MAX)
   ,@xstate INT
   ,@errsev INT
   ,@sub VARCHAR(255);

	SELECT @error = ERROR_NUMBER()
   ,@errsev = ERROR_SEVERITY()
   ,@message = ERROR_MESSAGE()
   ,@xstate = XACT_STATE();

	SELECT @errormsg = 'Error in ' + ISNULL(@SPROC, '') + ': ' + CAST(ISNULL(@error, '') AS NVARCHAR(32)) + '|' + COALESCE(@message, '') + '|' + CAST(ISNULL(@xstate, '') AS NVARCHAR(32)) + '|' + CAST(ISNULL(@errsev, '') AS NVARCHAR(32));

	SELECT @sub = 'ERROR: ' + @SPROC;

	EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile
   ,@recipients = 'barb.eichberger@ltd.org'
   ,@subject = @sub
   ,@body = @errormsg;

	RAISERROR(@errormsg, @errsev, 1);
END CATCH;
GO
