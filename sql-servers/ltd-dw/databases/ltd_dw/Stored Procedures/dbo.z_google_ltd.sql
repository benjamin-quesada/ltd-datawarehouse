SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[z_google_ltd] (@for VARCHAR(max) = '')
-- exec z_google_ltd 'employeeId'
AS
BEGIN
	SET @for = replace(@for, '_', '[_]');
	SET @for = replace(@for, '%', '[%]');
	SET @for = replace(@for, '[', '[[]');
	SET NOCOUNT ON;

	IF object_id('tempdb..#resultsltd') IS NOT NULL
		DROP TABLE #resultsltd;

	CREATE TABLE #resultsltd (
		columnname VARCHAR(max)
		,columnvalue VARCHAR(max)
		,count INT
		)

	DECLARE @rrows INT = 0;
	DECLARE @tablename VARCHAR(max)
		,@columnname VARCHAR(max)
		,@for2 VARCHAR(max)

	SET @tablename = '';
	SET @for2 = quotename('%' + @for + '%', '''');

	DECLARE @tt VARCHAR(max);

	WHILE (@tablename IS NOT NULL)
	BEGIN
		SET @columnname = '';
		SET @tablename = (
				SELECT min(quotename(table_schema) + '.' + quotename(table_name))
				FROM information_schema.tables
				WHERE table_type = 'base table'
				and table_name not like '%HST'
					AND quotename(table_schema) + '.' + quotename(table_name) > @tablename
					AND objectproperty(object_id(quotename(table_schema) + '.' + quotename(table_name)), 'ismsshipped') = 0
				);
		SET @tt = @tablename + CHAR(13);

		WHILE (
				(@tablename IS NOT NULL)
				AND (@columnname IS NOT NULL)
				)
		BEGIN
			SET @columnname = (
					SELECT min(quotename(column_name))
					FROM information_schema.columns
					WHERE table_schema = parsename(@tablename, 2)
						AND table_name = parsename(@tablename, 1)
						AND data_type IN (
							'char'
							,'char'
							,'varchar'
							,'nchar'
							,'varchar'
							,'text'
							,'uniqueidentifier'
							,'date'
							,'time'
							,'datetime2'
							,'datetimeoffset'
							,'tinyint'
							,'smallint'
							,'int'
							,'smalldatetime'
							,'real'
							,'money'
							,'datetime'
							,'float'
							,'sql_variant'
							,'bit'
							,'decimal'
							,'numeric'
							,'smallmoney'
							,'bigint'
							,'timestamp'
							,'xml'
							,'sysname'
							)
						AND quotename(column_name) > @columnname
					)

			IF @columnname IS NOT NULL
			BEGIN
				DECLARE @sql VARCHAR(max) = 'select db,' + @columnname + ',count(' + @columnname + ')from(select ''' + @tablename + '.' + @columnname + '''db,convert(varchar(max),' + @columnname + ')' + @columnname + 'from ' + @tablename + ' with (nolock) where convert(varchar(max),' + @columnname + ')like' + @for2 + ')q group by db,' + @columnname;/*print(@sql);*/

				INSERT INTO #resultsltd
				EXEC (@sql);

				SET @tt = @tt + '-' + @columnname + CHAR(13);
			END
		END

		SET @tt = @tt + 'Found:' + (
				SELECT cast(count(columnname) - @rrows AS VARCHAR)
				FROM #resultsltd
				) + CHAR(13);

		RAISERROR (
				@tt
				,0
				,1
				)
		WITH NOWAIT;

		SET @rrows = (
				SELECT count(columnname)
				FROM #resultsltd
				)
	END

	SELECT columnname
		,(
			SELECT TOP 1 columnvalue
			FROM #resultsltd r2
			WHERE r2.columnname = r1.columnname
			) sample
		,sum(count) count
	FROM #resultsltd r1
	GROUP BY columnname;
END;
GO
