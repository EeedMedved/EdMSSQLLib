SELECT 
	total_log_size_in_bytes / 1048576 AS [Total Log File Size, MB],
	used_log_space_in_bytes / 1048576 AS [Used Log File Size, MB],
	(total_log_size_in_bytes - used_log_space_in_bytes) / 1048576 AS [Free Space in Log File, MB],
	used_log_space_in_percent 
FROM sys.dm_db_log_space_usage