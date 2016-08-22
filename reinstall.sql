ROLLBACK;
\set AUTOCOMMIT OFF
BEGIN;
DROP SCHEMA cron CASCADE;
CREATE SCHEMA cron;
\ir TABLES/jobs.sql
\ir TABLES/processes.sql
\ir TABLES/log.sql
\ir TABLES/logwaiting.sql
\ir TABLES/logwaitingpgstatactivity.sql
\ir FUNCTIONS/waiting_pids.sql
\ir FUNCTIONS/is_valid_function.sql
\ir FUNCTIONS/register.sql
\ir FUNCTIONS/disable.sql
\ir FUNCTIONS/enable.sql
\ir FUNCTIONS/run.sql
\ir FUNCTIONS/dispatch.sql
\ir FUNCTIONS/terminate_all_backends.sql
\ir FUNCTIONS/terminate_backend.sql
\ir FUNCTIONS/reset_runattime.sql
\ir FUNCTIONS/log_waiting.sql
\ir VIEWS/vjobs.sql
\ir VIEWS/vprocesses.sql
\ir VIEWS/vlog.sql
GRANT USAGE ON SCHEMA cron TO pgcronjob;
GRANT SELECT,UPDATE ON TABLE cron.Jobs TO pgcronjob;
GRANT INSERT ON TABLE cron.Log TO pgcronjob;
GRANT USAGE ON SEQUENCE cron.log_logid_seq TO pgcronjob;
COMMIT;
