CREATE TABLE [fact].[NewFlyer_Parameters_Pivot]
(
[parameterFactId] [bigint] NOT NULL IDENTITY(1, 1),
[license_number] [int] NOT NULL,
[Date And Time] [datetime] NOT NULL,
[calId] [int] NULL,
[cal_spm_param] [bigint] NOT NULL,
[Speed(Kph)] [decimal] (14, 5) NULL,
[Mileage(Km)] [decimal] (14, 5) NULL,
[Mileage(Miles)] [decimal] (14, 5) NULL,
[NF TK_AmbTemp (40 ft)] [decimal] (14, 5) NULL,
[NF TK_HVACMainSwitchStatus] [decimal] (14, 5) NULL,
[VAN_DCDC_IIN_ST (SPN 65495)] [decimal] (14, 5) NULL,
[VAN_DCDC_VIN_ST (SPN 65492)] [decimal] (14, 5) NULL,
[NF XE_DICO_PWR_AX_MOT 1 (Auxiliary Motor Power Draw)] [decimal] (14, 5) NULL,
[NF CM0711 Average Consumption Rate TripkWh-mi] [decimal] (14, 5) NULL,
[NF CM0711_Electric_Heater_Energy_Consumption_kWh] [decimal] (14, 5) NULL,
[NF CM0711_XE_XALT_Charging_Energy_Transfer_kWh] [decimal] (14, 5) NULL,
[NF XPAND BATT_Sys_Energy_System] [decimal] (14, 5) NULL,
[NF XPAND_SYS_SOC (PGN: 65349)] [decimal] (14, 5) NULL,
[NF XE_DICO_BR_RWES_FB (Auxiliary Heater Power Draw)] [decimal] (14, 5) NULL,
[NF CM0711_Trip_Motor_Energy_Consumption_kWh] [decimal] (14, 5) NULL,
[NF CM0711_Trip_Regen_Energy_kWh] [decimal] (14, 5) NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF__NewFlyer___recor__51D6E840] DEFAULT (sysdatetime())
) ON [PRIMARY]
GO
CREATE CLUSTERED COLUMNSTORE INDEX [IX_NewFlyer_Parameters_Pivot_ClusteredColumnStore] ON [fact].[NewFlyer_Parameters_Pivot] ON [PRIMARY]
GO
