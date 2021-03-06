CREATE SCHEMA cron;

ALTER SCHEMA cron OWNER TO pgcronjob;
REVOKE ALL ON SCHEMA cron FROM PUBLIC;
GRANT ALL ON SCHEMA cron TO pgcronjob;

\ir TABLES/connectionpools.sql
\ir TABLES/jobs.sql
\ir TABLES/processes.sql
\ir TABLES/log.sql
\ir TABLES/errorlog.sql
\ir FUNCTIONS/log_error.sql
\ir FUNCTIONS/log_table_access.sql
\ir FUNCTIONS/is_valid_function.sql
\ir FUNCTIONS/register.sql
\ir FUNCTIONS/disable.sql
\ir FUNCTIONS/disable_process.sql
\ir FUNCTIONS/enable.sql
\ir FUNCTIONS/enable_process.sql
\ir FUNCTIONS/run.sql
\ir FUNCTIONS/dispatch.sql
\ir FUNCTIONS/terminate_all_backends.sql
\ir FUNCTIONS/new_connection_pool.sql
\ir FUNCTIONS/reset_runattime.sql
\ir FUNCTIONS/schedule.sql
\ir FUNCTIONS/generate_register_commands.sql
\ir FUNCTIONS/delete_old_log_rows.sql
\ir VIEWS/vjobs.sql
\ir VIEWS/vprocesses.sql
\ir VIEWS/vlog.sql
