CREATE TABLE [ops].[operator_actual_rdo]
(
[operator_actual_rdo_key] [int] NOT NULL IDENTITY(1, 1),
[emp_sid] [int] NOT NULL,
[opdate] [date] NOT NULL,
[record_created_date] [datetime2] NOT NULL CONSTRAINT [DF_operator_actual_rdo_record_created_date] DEFAULT (sysdatetime()),
[record_updated_date] [datetime2] NOT NULL
) ON [PRIMARY]
GO
