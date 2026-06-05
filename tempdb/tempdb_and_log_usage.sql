-- Список активных транзакций, занимающих tempdb и утилизирующих лог-файл
SELECT 
    st.session_id,      -- ИД сессии
    t.name,             -- Имя транзакции
    t.transaction_begin_time,       -- Время старта транзакции
    l.database_transaction_log_bytes_reserved / 1048576 as log_MB_reserved,     -- Зарезервировано в лог-файле для транзакции
	l.database_transaction_log_bytes_used / 1048576 AS log_MB_used,         -- Используется в лог-файле для транзакции
	   -- Расчет использования в МБ
    CAST((SSU.user_objects_alloc_page_count * 8) / 1024.0 AS DECIMAL(12,2)) AS session_user_objects_mb,     -- Выделено в tempdb для объектов пользователя в сеансе
    CAST((SSU.internal_objects_alloc_page_count * 8) / 1024.0 AS DECIMAL(12,2)) AS session_internal_objects_mb,     -- Выделено в tempdb для внутренних объектов в сеансе
	CAST((SSU.user_objects_dealloc_page_count * 8) / 1024.0 AS DECIMAL(12,2)) AS session_dealloc_user_objects_mb,       -- Деаллоцированно в tempdb для объектов пользователя в сеансе
	CAST(((SSU.user_objects_alloc_page_count + SSU.internal_objects_alloc_page_count) * 8) / 1024.0 AS DECIMAL(12,2)) AS session_total_tempdb_mb,       -- Всего выделено для пользователя в сеансе

	CAST((TSU.user_objects_alloc_page_count * 8) / 1024.0 AS DECIMAL(12,2)) AS task_user_objects_mb,         -- Выделено в tempdb для объектов пользователя в задаче
    CAST((TSU.internal_objects_alloc_page_count * 8) / 1024.0 AS DECIMAL(12,2)) AS task_internal_objects_mb,        -- Выделено в tempdb для внутренних объектов в задаче
	CAST((TSU.user_objects_dealloc_page_count * 8) / 1024.0 AS DECIMAL(12,2)) AS task_dealloc_user_objects_mb,      -- Деаллоцированно в tempdb для объектов пользователя в задаче
	CAST(((TSU.user_objects_alloc_page_count + TSU.internal_objects_alloc_page_count) * 8) / 1024.0 AS DECIMAL(12,2)) AS task_total_tempdb_mb,	         -- Всего выделено для пользователя в задаче
	EST.text,       -- Текст запроса
	EQP.query_plan,     -- План запроса
    s.host_name,        -- Имя хоста, с которого подключена сессия
    s.program_name,     -- Имя программы, запустившей подключение
    s.login_name,       -- Логин подключения
    r.command,      -- Команда запроса
    r.blocking_session_id       -- Блокирующая сессия. 0 - блокировки нет
FROM sys.dm_tran_active_transactions t
INNER JOIN sys.dm_tran_session_transactions st ON st.transaction_id = t.transaction_id
INNER JOIN sys.dm_tran_database_transactions l 
    ON t.transaction_id = l.transaction_id
INNER JOIN sys.dm_exec_sessions s 

    ON st.session_id = s.session_id
INNER JOIN sys.dm_db_session_space_usage SSU
	ON st.session_id = SSU.session_id
INNER JOIN sys.dm_db_task_space_usage TSU
	ON st.session_id = TSU.session_id
LEFT JOIN sys.dm_exec_requests r 
    ON st.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS EST
OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS EQP
WHERE l.database_id = 2  -- TempDB database_id
ORDER BY l.database_transaction_log_bytes_used DESC;



