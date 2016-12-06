ROLLBACK;
\set AUTOCOMMIT OFF
BEGIN;
CREATE TYPE public.batchjobstate AS ENUM (
    'AGAIN',
    'DONE'
);
COMMIT;
BEGIN;
DROP SCHEMA cron CASCADE;
COMMIT;
BEGIN;
CREATE SCHEMA cron;
\ir FUNCTIONS/pg_stat_activity_portable.sql
\ir TABLES/connectionpools.sql
\ir TABLES/jobs.sql
\ir TABLES/processes.sql
\ir TABLES/log.sql
\ir TABLES/errorlog.sql
\ir FUNCTIONS/log_error.sql
\ir FUNCTIONS/waiting_pids.sql
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
\ir VIEWS/vjobs.sql
\ir VIEWS/vprocesses.sql
\ir VIEWS/vlog.sql
GRANT USAGE ON SCHEMA cron TO pgcronjob;
GRANT SELECT,UPDATE ON TABLE cron.Jobs TO pgcronjob;
GRANT INSERT ON TABLE cron.Log TO pgcronjob;
GRANT USAGE ON SEQUENCE cron.log_logid_seq TO pgcronjob;

COMMIT;
