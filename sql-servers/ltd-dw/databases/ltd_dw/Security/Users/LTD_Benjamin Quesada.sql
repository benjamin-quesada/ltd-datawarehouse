IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'LTD\Benjamin Quesada')
CREATE LOGIN [LTD\Benjamin Quesada] FROM WINDOWS
GO
CREATE USER [LTD\Benjamin Quesada] FOR LOGIN [LTD\Benjamin Quesada]
GO
