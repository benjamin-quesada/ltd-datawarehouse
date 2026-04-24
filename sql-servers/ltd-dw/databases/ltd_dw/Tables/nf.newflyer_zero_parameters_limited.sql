CREATE TABLE [nf].[newflyer_zero_parameters_limited]
(
[license_number] [int] NOT NULL,
[calid] [int] NOT NULL,
[fileloaddt] [date] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [nf].[newflyer_zero_parameters_limited] ADD CONSTRAINT [PK_newflyer_zero_parameters_limited] PRIMARY KEY CLUSTERED ([license_number], [calid]) ON [PRIMARY]
GO
