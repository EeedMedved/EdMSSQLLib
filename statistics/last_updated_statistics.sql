
SELECT  OBJECT_NAME(s.object_id) AS TableName,
        s.name AS StatisticsName,
        STATS_DATE(s.object_id, s.stats_id) as LastUpdated,
        sp.rows,
        sp.rows_sampled,
		sp.modification_counter
FROM sys.STATS AS s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
WHERE OBJECT_NAME(s.object_id) = 'MBONUSCHARGETRANSITEM'        -- Имя таблицы
ORDER BY LastUpdated DESC;