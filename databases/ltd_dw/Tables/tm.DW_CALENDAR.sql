CREATE TABLE [tm].[DW_CALENDAR]
(
[CALENDAR_ID] [numeric] (10, 0) NOT NULL,
[TRANSIT_DIV_ID] [numeric] (5, 0) NULL,
[ACTIVATION_TIME] [datetime] NULL,
[DEACTIVATION_TIME] [datetime] NULL,
[EXCLUDE_DAY] [bit] NULL,
[SECT15_SERVICE_TYPE_ID] [numeric] (3, 0) NULL,
[YYYYMMDD] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CALENDAR_DATE] [date] NULL,
[DayNo] [int] NULL,
[DayOfWeek] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DayOfWeekNbr] [int] NULL,
[DayOfYear] [int] NULL,
[WeekOfYear] [int] NULL,
[WeekofYearKey] [int] NULL,
[WeekOfMonth] [int] NULL,
[WeekOfMonthKey] [int] NULL,
[Month] [int] NULL,
[MonthName] [nvarchar] (33) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[MonthNameText] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FiscalPeriod] [int] NOT NULL,
[Quarter] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[QuarterName] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Fiscal Quarter] [int] NULL,
[Fiscal Quarter Name] [nvarchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Year] [int] NULL,
[FiscalYear] [int] NULL,
[Fiscal Year Name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isHoliday] [int] NOT NULL,
[CalculatedMonthAge] [int] NULL,
[IsCurrentMonth] [bit] NULL,
[Current MTD This Year] [bit] NULL,
[Current MTD Last Year] [bit] NULL,
[Last 30 Days] [bit] NULL,
[Last 60 Days] [bit] NULL,
[Last 90 Days] [bit] NULL,
[Prior 90 Days] [bit] NULL,
[Last 10 Working Days] [bit] NULL,
[Last 30 Working Days] [bit] NULL,
[Last 60 Working Days] [bit] NULL,
[Last 90 Working Days] [bit] NULL,
[YearMonth] [varchar] (34) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Last Full Month] [bit] NULL,
[Last Full 6 Months] [bit] NULL,
[Last Full 12 Months] [bit] NULL,
[Last Full 9 Months] [bit] NULL,
[Last 9 Months To Date] [bit] NULL,
[Previous Date Full 6 Months] [bit] NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED COLUMNSTORE INDEX [ix_ccs_tm_dw_calendar] ON [tm].[DW_CALENDAR] ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [ix_Calendar_CalendarID_CalendarDate] ON [tm].[DW_CALENDAR] ([CALENDAR_ID], [CALENDAR_DATE]) ON [PRIMARY]
GO
GRANT SELECT ON  [tm].[DW_CALENDAR] TO [public]
GO
