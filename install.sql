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
INSERT INTO cron.Jobs (JobID,Function) VALUES (0,'cron.Run(integer)');
INSERT INTO cron.Processes (ProcessID,JobID) VALUES (0,0);

-- For testing only, remove these lines in production:
\ir FUNCTIONS/function_template_skeleton.sql
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '0.1 second', _IntervalDONE := '10 seconds', _DedicatedProcesses := 0, _KeepAliveAGAIN := FALSE, _KeepAliveDONE := FALSE);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '0.3 second', _IntervalDONE := '30 seconds', _DedicatedProcesses := 1, _KeepAliveAGAIN := FALSE, _KeepAliveDONE := FALSE);
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '0.5 second', _IntervalDONE := '50 seconds', _DedicatedProcesses := 2, _KeepAliveAGAIN := FALSE, _KeepAliveDONE := FALSE);
COMMIT;
