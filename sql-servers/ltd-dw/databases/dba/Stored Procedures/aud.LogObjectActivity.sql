SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [aud].[LogObjectActivity]
    @ObjectID     INT,
    @ObjectType     VARCHAR(20),
    @DatabaseName   sysname
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @FullObjectName SYSNAME;
    DECLARE @DatabaseID INT;
    DECLARE @SchemaName SYSNAME;
    DECLARE @ObjectName SYSNAME;

    --PRINT '--- DEBUG START ---';

    --PRINT 'Current Database Context: ' + DB_NAME();

    --PRINT 'Input Parameters';
    --PRINT '  @ObjectID: ' + CAST(@ObjectID AS VARCHAR(20));
    --PRINT '  @ObjectType: ' + ISNULL(@ObjectType,'NULL');
    --PRINT '  @DatabaseName: ' + ISNULL(@DatabaseName,'NULL');


    SET @DatabaseID = DB_ID(@DatabaseName);

    --PRINT 'Derived Values';
    --PRINT '  @DatabaseID: ' + ISNULL(CAST(@DatabaseID AS VARCHAR(10)),'NULL');

    SELECT
        @SchemaName = OBJECT_SCHEMA_NAME(@ObjectID, @DatabaseID),
        @ObjectName       = OBJECT_NAME(@ObjectID, @DatabaseID);

    --PRINT 'Resolved Names';
    --PRINT '  Schema Name: ' + ISNULL(@SchemaName,'NULL');
    --PRINT '  Object Name: ' + ISNULL(@ObjectName,'NULL');


    SELECT @FullObjectName =
        @SchemaName + '.' + @ObjectName;

    --PRINT 'Final ObjectName: ' + ISNULL(@FullObjectName,'NULL');

    --PRINT 'Session Info';
    --PRINT '  @@SPID: ' + CAST(@@SPID AS VARCHAR(10));
    --PRINT '  HOST_NAME(): ' + HOST_NAME();
    --PRINT '  SYSTEM_USER: ' + SYSTEM_USER;

    --PRINT '--- DEBUG END ---';


    INSERT INTO dba.aud.Object_Activity
    (
        server_name,
        database_name,
        host_name,
        [System_User],
        object_name,
        client_net_address,
        local_net_address,
        auth_Scheme,
        last_read,
        last_write,
        most_recent_sql_handle,
        [Timestamp],
        object_type
    )
    SELECT
        @@SERVERNAME,
        @DatabaseName,
        HOST_NAME(),
        SYSTEM_USER,
        @FullObjectName,
        c.client_net_address,
        c.local_net_address,
        c.auth_scheme,
        c.last_read,
        c.last_write,
        c.most_recent_sql_handle,
        SYSDATETIME(),
        @ObjectType
    FROM sys.dm_exec_connections AS c
    WHERE c.session_id = @@SPID;

    DECLARE @procedure_activity_id INT
    SET @procedure_activity_id = SCOPE_IDENTITY()

    RETURN @procedure_activity_id
END;
GO
