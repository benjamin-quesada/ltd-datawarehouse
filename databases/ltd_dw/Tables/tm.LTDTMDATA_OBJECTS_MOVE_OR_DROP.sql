CREATE TABLE [tm].[LTDTMDATA_OBJECTS_MOVE_OR_DROP]
(
[home_db] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[referencing_entity_name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[referencing_desciption] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[referencing_minor_id] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[referencing_class_desc] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[referenced_server_name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[referenced_database_name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[referenced_schema_name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[referenced_entity_name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[referenced_column_name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_caller_dependent] [bit] NOT NULL,
[is_ambiguous] [bit] NOT NULL
) ON [PRIMARY]
GO
