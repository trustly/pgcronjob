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
GRANT USAGE ON SCHEMA cron TO pgcronjob;
GRANT SELECT,UPDATE ON TABLE cron.Jobs TO pgcronjob;
GRANT INSERT ON TABLE cron.Log TO pgcronjob;
GRANT USAGE ON SEQUENCE cron.log_logid_seq TO pgcronjob;
-- For testing only, remove these lines in production:
\ir FUNCTIONS/function_template_skeleton.sql
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '1 second', _DedicatedProcesses := 0);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '2 second', _DedicatedProcesses := 1);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '3 second', _DedicatedProcesses := 3);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '5 second', _DedicatedProcesses := 5);
COMMIT;
