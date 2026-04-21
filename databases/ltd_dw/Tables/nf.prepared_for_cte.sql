CREATE TABLE [nf].[prepared_for_cte]
(
[calId] [int] NULL,
[license_number] [int] NULL,
[vehicle_id] [int] NULL,
[group_id] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_name] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Date And Time] [datetime] NULL,
[GPS LAT] [numeric] (18, 7) NULL,
[GPS LON] [numeric] (18, 7) NULL,
[Speed(Kph)] [numeric] (18, 7) NULL,
[Mileage(Km)] [numeric] (18, 7) NULL,
[NF TK_AmbTemp (40 ft)] [numeric] (18, 7) NULL,
[NF XPAND BATT_Sys_Energy_System] [numeric] (18, 7) NULL,
[VAN_DCDC_IIN_ST (SPN 65495)] [numeric] (18, 7) NULL,
[VAN_DCDC_VIN_ST (SPN 65492)] [numeric] (18, 7) NULL,
[NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)] [numeric] (18, 7) NULL,
[NF XPAND_SYS_SOC (PGN: 65349)] [numeric] (18, 7) NULL,
[NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)] [numeric] (18, 7) NULL,
[NF CM0711_Electric_Heater_Energy_Consumption_kWh] [numeric] (18, 7) NULL,
[NF CM0711_Trip_Motor_Energy_Consumption_kWh] [numeric] (18, 7) NULL,
[NF CM0711_Trip_Regen_Energy_kWh] [numeric] (18, 7) NULL
) ON [PRIMARY]
GO
