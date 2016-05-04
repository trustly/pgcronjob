ROLLBACK;
\set AUTOCOMMIT OFF
BEGIN;
CREATE TYPE public.batchjobstate AS ENUM (
    'AGAIN',
    'DONE'
);
CREATE SCHEMA cron;
\ir TABLES/jobs.sql
\ir TABLES/processes.sql
\ir TABLES/log.sql
\ir FUNCTIONS/no_waiting.sql
\ir FUNCTIONS/is_valid_function.sql
\ir FUNCTIONS/register.sql
\ir FUNCTIONS/disable.sql
\ir FUNCTIONS/enable.sql
\ir FUNCTIONS/run.sql
\ir FUNCTIONS/set_child_pid.sql
GRANT USAGE ON SCHEMA cron TO pgcronjob;
GRANT SELECT,UPDATE ON TABLE cron.Jobs TO pgcronjob;
GRANT INSERT ON TABLE cron.Log TO pgcronjob;
GRANT USAGE ON SEQUENCE cron.log_logid_seq TO pgcronjob;
-- For testing only, remove these lines in production:
\ir FUNCTIONS/function_template_skeleton.sql
SELECT cron.Register('cron.Function_Template_Skeleton()', _IntervalAGAIN := '1 second', _IntervalDONE := '3 seconds', _RetryOnError := TRUE,  _Fork := TRUE, _Processes := 2);
COMMIT;
