use tempdb;

DECLARE @TempDBLogFilled REAL;

select @TempDBLogFilled = used_log_space_in_percent 
from sys.dm_db_log_space_usage;

if (@TempDBLogFilled > 70)

BEGIN
	DECLARE
	  @query nvarchar(MAX), --A query to turn into HTML format. It should not include an ORDER BY clause.
	  @orderBy nvarchar(MAX), --An optional ORDER BY clause. It should contain the words 'ORDER BY'.
	  @html nvarchar(MAX),  --The HTML output of the procedure.
	  @emailTO nvarchar(MAX),
	  @copy_recipients nvarchar(MAX),
	  @subject nvarchar(MAX)

	set @subject = 'Лог-файл TempDB занят более 70% ' + FORMAT (GETDATE(),'dd.MM.yyyy')
	set @emailTO = 'sennator@srextend.lab' 

	 set @query = N'SELECT 
		st.session_id AS [SPID], 
		t.transaction_begin_time AS [Время начала транзакции],
		l.database_transaction_log_bytes_used / 1048576 AS [Занято в лог-файле, МБ],
		CAST((TSU.user_objects_alloc_page_count + TSU.internal_objects_alloc_page_count) / 128 AS DECIMAL(15,2)) AS [Занято в TempDB, MB],
		s.host_name AS [Имя хоста],
		s.program_name AS [Программа],
		s.login_name AS [Логин],
		r.command,
		EST.text AS [Текст запроса],
		r.blocking_session_id AS [ИД блокирующей сессии]
	FROM sys.dm_tran_active_transactions t
	INNER JOIN sys.dm_tran_session_transactions st ON st.transaction_id = t.transaction_id
	INNER JOIN sys.dm_tran_database_transactions l 
		ON t.transaction_id = l.transaction_id
	INNER JOIN sys.dm_exec_sessions s 
		ON st.session_id = s.session_id
	INNER JOIN sys.dm_db_task_space_usage TSU
		ON st.session_id = TSU.session_id
	LEFT JOIN sys.dm_exec_requests r 
		ON st.session_id = r.session_id
	OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS EST
	WHERE l.database_id = 2
	AND l.database_transaction_log_bytes_used > 0';


	   DECLARE @realQuery nvarchar(MAX) = '
		DECLARE @headerRow nvarchar(MAX);
		DECLARE @cols nvarchar(MAX);    

		SELECT * INTO #dynSql FROM (' + @query + ') sub;

		SELECT @cols = COALESCE(@cols + '', '''''''', '', '''') + ''['' + name + ''] AS ''''td''''''
		FROM tempdb.sys.columns 
		WHERE object_id = object_id(''tempdb..#dynSql'')
		ORDER BY column_id;

		SET @cols = ''SET @html = CAST(( SELECT '' + @cols + '' FROM #dynSql FOR XML PATH(''''tr''''), ELEMENTS XSINIL) AS nvarchar(max))''    

		EXEC sys.sp_executesql @cols, N''@html nvarchar(MAX) OUTPUT'', @html=@html OUTPUT

		SELECT @headerRow = COALESCE(@headerRow + '''', '''') + ''<th>'' + name + ''</th>'' 
		FROM tempdb.sys.columns 
		WHERE object_id = object_id(''tempdb..#dynSql'')
		ORDER BY column_id;

		SET @headerRow = ''<tr>'' + @headerRow + ''</tr>'';

		SET @html = ''<h2>Потребители TempDB</h2><br /><table border="1">'' + @headerRow + @html + ''</table>'';    
		';

	  EXEC sys.sp_executesql @realQuery, N'@html nvarchar(MAX) OUTPUT', @html=@html OUTPUT

	  exec msdb.dbo.sp_send_dbmail @profile_name = 'mssql', @recipients = @emailTO, @subject = @subject, @body = @html , @body_format = 'HTML';
END