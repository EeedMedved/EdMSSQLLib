-- Получить фрагментацию индекса для таблицы 
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.index_id,
    ps.index_type_desc,
    ps.avg_fragmentation_in_percent,
    ps.page_count
FROM sys.dm_db_index_physical_stats(DB_ID('<put database name here>'), OBJECT_ID('<put table name here>'), NULL, NULL, 'LIMITED') ps
JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
JOIN sys.tables t ON ps.object_id = t.object_id
WHERE ps.database_id = DB_ID()
ORDER BY ps.avg_fragmentation_in_percent DESC;


-- Получить фрагментацию индексов для всей БД
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.index_id,
    ps.index_type_desc,
    ps.avg_fragmentation_in_percent,
    ps.page_count
FROM sys.dm_db_index_physical_stats(DB_ID('<put database name here>'), NULL, NULL, NULL, 'LIMITED') ps
JOIN sys.indexes i ON ps.object_id = i.object_id AND ps.index_id = i.index_id
JOIN sys.tables t ON ps.object_id = t.object_id
WHERE ps.database_id = DB_ID()
ORDER BY ps.avg_fragmentation_in_percent DESC;