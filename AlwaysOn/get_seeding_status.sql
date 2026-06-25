-- Показывает статус сидирирования БД на реплику
select local_database_name, 
	transfer_rate_bytes_per_second / 1048576 as [Transfer Rate, MB] , -- скорость передачи МБ/с
	transferred_size_bytes / 1048576  as [Transferred, MB],	-- Отправлено МБ на вторичную реплику
	database_size_bytes / 1048576 AS [DB Size, MB],	-- Общий размер БД
	(CAST (transferred_size_bytes AS float) / CAST (database_size_bytes as float)) * 100 AS [Completed, %],	-- Процент отправленного
	start_time_utc,	-- Время начала сидирования
	estimate_time_complete_utc	-- Ожидаемое время завершения
from sys.dm_hadr_physical_seeding_stats

