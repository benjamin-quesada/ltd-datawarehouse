CREATE TABLE [pds].[Integration_EmpPhone_Stage]
(
[person_id] [int] NULL,
[employee_id] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[area_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[extension] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone_number] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (254) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_unlisted] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_primary] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[emp_phone_status] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
