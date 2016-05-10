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
\ir VIEWS/status.sql
GRANT USAGE ON SCHEMA cron TO pgcronjob;
GRANT SELECT,UPDATE ON TABLE cron.Jobs TO pgcronjob;
GRANT INSERT ON TABLE cron.Log TO pgcronjob;
GRANT USAGE ON SEQUENCE cron.log_logid_seq TO pgcronjob;

-- For testing only, remove these lines in production:
\ir FUNCTIONS/function_template_skeleton.sql

-- DEFAULT:
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _Processes := 1, _LimitProcesses := NULL, _Concurrent := TRUE, _RetryOnError := FALSE, _IntervalAGAIN := '100 ms', _IntervalDONE := NULL);;

-- Run two processes in parallell:
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _Processes := 2);

-- Only run this cron job if there are no other cron jobs running. If others are running, wait in queue until we have waited the longest time:
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _LimitProcesses := 0);

-- If the cron job function raises an exception, the default is to not run it again. This setting overrides that behaviour:
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _RetryOnError := TRUE);

-- _IntervalAGAIN is how long time to sleep between each time the cron job function returns AGAIN,
-- which means it did some work and wants cron to commit the db txn and call it agian in _IntervalAGAIN seconds.
-- Pass 0 as _IntervalAGAIN to make cron run it again immediately: 
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '0 ms');

-- Or maybe we want to sleep 2 seconds between each run:
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalAGAIN := '2 seconds');

-- When a cron job returns DONE, the default is to never call it again. This can be overriden by passing a NOT NULL _IntervalDONE value.
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _IntervalDONE := '10 seconds');

-- Pass _RunAfterTimestamp to specify a cron job should only be started from a specific timestamp:
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _RunAfterTimestamp := now()+'30 seconds'::interval);

-- Pass _RunUntilTimestamp to specify a cron job should only be run until a specific timestamp:
SELECT cron.Register('cron.Function_Template_Skeleton(integer)', _RunUntilTimestamp := now()+'20 seconds'::interval);

COMMIT;
