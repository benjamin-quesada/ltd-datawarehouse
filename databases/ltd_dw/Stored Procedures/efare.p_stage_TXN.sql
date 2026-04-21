SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   PROCEDURE [efare].[p_stage_TXN]
@activefile varchar(255) -- = 'DRKTrx637043308162564208.txt'
as
-- exec [efare].[p_stage_TXN] 'E:\filedrop\efare\DRKTrx637043308162564208.txt'
if len(@activefile) > 7
BEGIN

--declare @activefile varchar(255) = 'E:\filedrop\efare\DRKTrx637043308162564208.txt'
declare @sqlcmd nvarchar(max)
select @sqlcmd = ''
select @sqlcmd = @sqlcmd + '
SELECT
       p.name,
       p.description,
	   p.fareTx
FROM OPENROWSET (BULK '''+@activefile+ ''', SINGLE_CLOB) as j
CROSS APPLY OPENJSON(BulkColumn)
WITH (
       name varchar(90),
       description varchar(500),
	   fareTx varchar(500) 
) AS p
'
exec sp_executesql @sqlcmd

WITH RESULT SETS
(
       (
       Name varchar(90),
       Description varchar(500),
	   [FareTx] varchar(500)
       ) 
)

END
GO
