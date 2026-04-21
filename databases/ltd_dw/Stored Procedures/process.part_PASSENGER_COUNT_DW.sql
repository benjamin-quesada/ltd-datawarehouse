SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




--exec [process].[part_PASSENGER_COUNT_V_OP_DOORS]


CREATE   PROCEDURE [process].[part_PASSENGER_COUNT_DW]
AS

/* 
PURPOSE: used to manage updates to passenger count table partitions, to aid query speeds

   AUTHOR: Jil Shah
     DATE: 20201110
CHANGEDON: 
 CHANGEBY: 
   CHANGE: 

   exec [process].[Part_PASSENGER_COUNT_DW]
*/

/*------------------LTD_GLOSSARY---------------
UPDATED BY:	Sopheap Suy
UPDATED DT:  10/31/2024
purpose	 :  Add object activities on who, what, when call this object
			write this data to aud.object_activity table everytime it's called */

SET NOCOUNT ON

DECLARE @SPROC VARCHAR(100)
SET @SPROC = OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID)

INSERT INTO DBA.[aud].[Object_Activity]
	([server_name], [database_name] ,[host_name], [System_User], [object_name]
	,[client_net_address], [local_net_address], [auth_Scheme], [last_read], [last_write]
	,[most_recent_sql_handle], [Timestamp], object_type)
SELECT DISTINCT @@SERVERNAME, DB_NAME(),HOST_NAME(),SYSTEM_USER, @SPROC,
	client_net_address, local_net_address , auth_Scheme, last_read, last_write 
	,most_recent_sql_handle, CURRENT_TIMESTAMP AS [Timestamp], 'PROC'
FROM sys.dm_exec_connections 
WHERE session_id = @@SPID ;


DECLARE @currentpartition INT
 , @chunk INT
 , @partvalue SMALLDATETIME
 , @maintainbucket INT
 , @availablepartition INT
 , @partitiontocreate INT
 , @lastavailablepartid INT
 , @lastavailablepartval INT
 , @sql NVARCHAR(4000)
 ,@sqlmaxdate NVARCHAR(4000)
 ,@maxdate INT
 , @pscheme VARCHAR(400) ;

SET @pscheme = 'schPASSENGER_COUNT_DW' ;

SET @chunk = 1 ; --1 Year - Preset Partition Size/Chunk 
SET @maintainbucket = 3 ; --Number of Partitions to maintain any given time

--Prep: Create and Populate Temp Table #Partitions
WITH cte_part
 AS
 (
 SELECT i.index_id
 , prv_left.value AS LowerBoundaryValue
 , prv_right.value AS UpperBoundaryValue

, CASE pf.boundary_value_on_right
 WHEN 1
 THEN 'RIGHT'
 ELSE 'LEFT'
 END AS PartitionFunctionRange
 , p.partition_number AS PartitionNumber
 , p.rows AS Rows
 --In case the table has multiple indexes
 , ROW_NUMBER() OVER (PARTITION BY prv_left.value, prv_right.value, p.rows
 ORDER BY i.index_id,prv_left.value , prv_right.value 
 ) AS row_num
 FROM sys.partitions AS p
 INNER JOIN sys.indexes AS i
 ON i.object_id = p.object_id
 AND i.index_id = p.index_id
 INNER JOIN sys.data_spaces AS ds
 ON ds.data_space_id = i.data_space_id
 INNER JOIN sys.partition_schemes AS ps
 ON ps.data_space_id = ds.data_space_id
 INNER JOIN sys.partition_functions AS pf
 ON pf.function_id = ps.function_id
 LEFT OUTER JOIN sys.partition_range_values AS prv_left
 ON ps.function_id = prv_left.function_id
 AND prv_left.boundary_id = p.partition_number - 1
 LEFT OUTER JOIN sys.partition_range_values AS prv_right
 ON ps.function_id = prv_right.function_id
 AND prv_right.boundary_id = p.partition_number
 WHERE ds.name = @pscheme --Partition Scheme Name
 )
SELECT cte_part.index_id
 , cte_part.LowerBoundaryValue
 , cte_part.UpperBoundaryValue
 , cte_part.PartitionFunctionRange
 , cte_part.PartitionNumber
 , cte_part.Rows
INTO #Partitions
 FROM cte_part
 WHERE cte_part.row_num = 1
 ORDER BY cte_part.LowerBoundaryValue
 , cte_part.UpperBoundaryValue 
 , cte_part.PartitionFunctionRange


SET @sqlmaxdate = 'SELECT @maxdate = MAX([Calendar_id]) FROM [tm].[PASSENGER_COUNT_DW]' ; 

EXEC sp_executesql @sqlmaxdate
 , N'@maxdate NUMERIC(10,0) OUTPUT'
 , @maxdate = @maxdate OUTPUT ;

SELECT @currentpartition = $PARTITION.[pfPASSENGER_COUNT_DW](@maxdate) ;

--Count the number of available Partitions
SET @availablepartition = ((SELECT MAX( PartitionNumber ) FROM #Partitions) - @currentpartition) - 1 /* Minus 1 excluding unpartitioned in the count*/ ;
SET @partitiontocreate = @maintainbucket - @availablepartition ;
SET @lastavailablepartid = ((SELECT MAX( PartitionNumber ) FROM #Partitions) - 1) ; /* Minus 1 excluding unpartitioned in the count*/
SET @lastavailablepartval = (SELECT CONVERT(VARCHAR(9),UpperBoundaryValue,112)FROM #Partitions WHERE PartitionNumber = @lastavailablepartid) ;

BEGIN
IF @maintainbucket = @availablepartition OR @maintainbucket < @availablepartition
 BEGIN
 PRINT 'No Action Needed. Available Partition is: ' + CONVERT( VARCHAR(MAX), @availablepartition ) + ' and Number of Partition to Maintain is: ' + CONVERT( VARCHAR(MAX), @maintainbucket ) ;
 END ;
ELSE 
 BEGIN
 SET @partvalue = CAST(CAST(@lastavailablepartval as VARCHAR(9)) AS DATETIME);

 WHILE @partitiontocreate > 0
 BEGIN
 SET @partvalue = DATEADD(MONTH, @chunk, @partvalue) ; -- Plus @chunk = 1 Month
 SET @sql = 'ALTER PARTITION SCHEME schPASSENGER_COUNT_DW
 NEXT USED [PRIMARY] 
 
 ALTER PARTITION FUNCTION pfPASSENGER_COUNT_DW() SPLIT RANGE (''' + CONVERT( VARCHAR(10), @partvalue, 112 ) + ''')' ;  --Range Partition Value


 EXEC sp_executesql @statement = @sql ;

SET @partitiontocreate = @partitiontocreate - 1 ;
 END ; 
 END 
END

--Cleanup
DROP TABLE #Partitions ;
GO
