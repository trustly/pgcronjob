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
\ir FUNCTIONS/dispatch.sql
\ir FUNCTIONS/restart.sql
GRANT USAGE ON SCHEMA cron TO pgcronjob;
GRANT SELECT,UPDATE ON TABLE cron.Jobs TO pgcronjob;
GRANT INSERT ON TABLE cron.Log TO pgcronjob;
GRANT USAGE ON SEQUENCE cron.log_logid_seq TO pgcronjob;
-- INSERT INTO cron.Jobs (JobID,Function) VALUES (0,'cron.Run(integer)');
-- INSERT INTO cron.Processes (ProcessID,JobID) VALUES (0,0);

-- For testing only, remove these lines in production:
\ir FUNCTIONS/function_template_skeleton.sql
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '1 second',  _RunMaxOtherProcessesLimit := 2);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '1 second',  _RunMaxOtherProcessesLimit := 2);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '1 second',  _RunMaxOtherProcessesLimit := 2);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '1 second',  _RunMaxOtherProcessesLimit := 2);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '1 second',  _RunMaxOtherProcessesLimit := 2);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '1 second',  _RunMaxOtherProcessesLimit := 2);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '1 second',  _RunMaxOtherProcessesLimit := 2);
COMMIT;
