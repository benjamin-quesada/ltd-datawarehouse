IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'LTD\SQL Developer')
CREATE LOGIN [LTD\SQL Developer] FROM WINDOWS
GO
CREATE USER [LTD\SQL Developer] FOR LOGIN [LTD\SQL Developer]
GO
