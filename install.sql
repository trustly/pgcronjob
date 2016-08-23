ROLLBACK;
\set AUTOCOMMIT OFF
BEGIN;
CREATE TYPE public.batchjobstate AS ENUM (
    'AGAIN',
    'DONE'
);
CREATE SCHEMA cron;
\ir FUNCTIONS/pg_stat_activity_portable.sql
\ir TABLES/connectionpools.sql
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
\ir FUNCTIONS/new_connection_pool.sql
\ir FUNCTIONS/reset_runattime.sql
\ir FUNCTIONS/log_waiting.sql
\ir FUNCTIONS/schedule.sql
\ir VIEWS/vjobs.sql
\ir VIEWS/vprocesses.sql
\ir VIEWS/vlog.sql
\ir VIEWS/vwaiting.sql
GRANT USAGE ON SCHEMA cron TO pgcronjob;
GRANT SELECT,UPDATE ON TABLE cron.Jobs TO pgcronjob;
GRANT INSERT ON TABLE cron.Log TO pgcronjob;
GRANT USAGE ON SEQUENCE cron.log_logid_seq TO pgcronjob;

-- For testing only, remove these lines in production:
\ir FUNCTIONS/example_random_error.sql
\ir FUNCTIONS/example_random_sleep.sql
\ir FUNCTIONS/example_no_sleep.sql
\ir FUNCTIONS/example_update_same_row.sql

-- cron.Jobs.RetryOnError boolean NOT NULL DEFAULT FALSE:
-- Run until an error is encountered (DEFAULT):
SELECT cron.Register('cron.Example_Random_Error(integer)', _RetryOnError := FALSE);
-- Keep running even if an error is encountered:
SELECT cron.Register('cron.Example_Random_Error(integer)', _RetryOnError := TRUE);

-- cron.Jobs.Concurrent boolean NOT NULL DEFAULT TRUE:
-- Detect and prevent concurrent execution of the function.
-- Simulate by starting two cron jobs, that will eventually run concurrently and then the second job of them will be aborted.
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _Concurrent := FALSE);
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _Concurrent := FALSE);

-- cron.Jobs.IntervalAGAIN interval NOT NULL DEFAULT '100 ms'::interval
-- By default we sleep 100 ms between each cron job function execution that returns AGAIN,
-- asking us to run it again. Let's simulate not sleeping at all between executions.
-- This is also guaranteed to cause pgcrobjob to keep the database connection open and reuse the database handle,
-- since if it does so or not is determined by if _IntervalAGAIN < $ConnectTime, and 0 is of course always < $ConnectTime.
-- Please keep an eye on the "procpid" column in the cron.Status foreground view. Its value will remain the same, i.e. the connection is kept alive.
SELECT cron.Register('cron.Example_No_Sleep(integer)', _IntervalAGAIN := '0'::interval);

-- cron.Jobs.RandomInterval boolean NOT NULL DEFAULT FALSE
-- If set to TRUE, pgcronjob will wait between 0 up to IntervalAGAIN/IntervalDONE before running again, implemented by multiplying the original value with random().
SELECT cron.Register('cron.Example_No_Sleep(integer)', _RunIfWaiting := TRUE, _IntervalAGAIN := '10 ms'::interval, _IntervalDONE := '30 seconds'::interval, _RandomInterval := TRUE);

-- cron.Jobs.Processes integer NOT NULL DEFAULT 1
-- By default, we just start one process per cron job, which means it will only use at most one database connection handle.
-- Some work loads are possible to spread among multiple CPUs, such as if processing rows that don't depend on each other and can be processed in parallel.
-- Simulate starting 2 processes. We'll reuse the Example_No_Sleep() function.
SELECT cron.Register('cron.Example_No_Sleep(integer)', _IntervalAGAIN := '10 ms'::interval, _Processes := 2);

-- cron.Jobs.ConnectionPoolID integer DEFAULT NULL:
-- Only run cron job if there is at most [MaxProcesses] other cron job processes running with the same ConnectionPoolID.
-- NULL means allow it to run regardless of how many other cron jobs are running.
-- Let's register 9 cron jobs to share the same connection pool of max 3 processes.
SELECT cron.New_Connection_Pool(_Name := 'Small test pool', _MaxProcesses := 3);
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _IntervalAGAIN := '100 ms'::interval, _RandomInterval := TRUE, _ConnectionPool := 'Small test pool');
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _IntervalAGAIN := '100 ms'::interval, _RandomInterval := TRUE, _ConnectionPool := 'Small test pool');
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _IntervalAGAIN := '100 ms'::interval, _RandomInterval := TRUE, _ConnectionPool := 'Small test pool');
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _IntervalAGAIN := '100 ms'::interval, _RandomInterval := TRUE, _ConnectionPool := 'Small test pool');
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _IntervalAGAIN := '100 ms'::interval, _RandomInterval := TRUE, _ConnectionPool := 'Small test pool');
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _IntervalAGAIN := '100 ms'::interval, _RandomInterval := TRUE, _ConnectionPool := 'Small test pool');
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _IntervalAGAIN := '100 ms'::interval, _RandomInterval := TRUE, _ConnectionPool := 'Small test pool');
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _IntervalAGAIN := '100 ms'::interval, _RandomInterval := TRUE, _ConnectionPool := 'Small test pool');
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _IntervalAGAIN := '100 ms'::interval, _RandomInterval := TRUE, _ConnectionPool := 'Small test pool');

-- Setting _MaxProcesses to some reasonably high value is probably always a good idea, to prevent process starvation.
-- In the example below, _MaxProcesses := 100 has no effect, since we will never run that many processes anyway:
SELECT cron.New_Connection_Pool(_Name := 'Big test pool', _MaxProcesses := 100);
SELECT cron.Register('cron.Example_No_Sleep(integer)', _IntervalAGAIN := '10 ms'::interval, _Processes := 2, _ConnectionPool := 'Big test pool');

-- cron.Jobs.IntervalDONE interval DEFAULT NULL
-- By default, the cron job is run again and again as long as it keeps returning AGAIN, until it returns DONE (if that ever happens, since maybe it should run forever).
-- Setting _IntervalDONE causes the execution of the cron job to start over after that amount of time has passed.
SELECT cron.Register('cron.Example_No_Sleep(integer)', _IntervalAGAIN := '0'::interval, _IntervalDONE := '10 seconds'::interval, _RunIfWaiting := TRUE);

-- cron.Jobs.RunIfWaiting boolean NOT NULL DEFAULT FALSE:
-- The default is to not run if there is any PostgreSQL backend waiting for anything, not only cron job processes, but any backend.
-- This might not be a good idea if something is always waiting as then no cron jobs will ever be executed.
-- Setting _RunIfWaiting to TRUE will run the cron job anyway.
-- Let's simulate this by calling a function that updates the same row and call that function in two separate processes,
-- which will cause the last one to have to wait for the other one.
-- We will observe the "waiting" column will say "WAITING" for the job that's waiting.
SELECT cron.Register('cron.Example_Update_Same_Row(integer)', _RunIfWaiting := TRUE, _Processes := 2, _IntervalAGAIN := '1 second'::interval);

-- If we do the same thing but leave RunIfWaiting FALSE (by either explicitly specifying FALSE or ommitting the input param as that's the DEFAULT value),
-- then cron.Run() will detect others are waiting and won't proceed executing the cron job function, so we won't see it in WAITING, at least not as often.
-- Then of course, it can still happen it has to wait, since some amount of time passes between the check if others are waiting and the execution of the cron job function.
SELECT cron.Register('cron.Example_Update_Same_Row(integer)', _RunIfWaiting := FALSE, _Processes := 2, _IntervalAGAIN := '1 second'::interval);

-- The columns below are useful if it's interesting to run a cron job after/until/between particular date/times or time of day.
-- cron.Jobs.RunAfterTimestamp timestamptz
-- cron.Jobs.RunUntilTimestamp timestamptz
-- cron.Jobs.RunAfterTime      time
-- cron.Jobs.RunUntilTime      time

-- Run at specific timestamp and then forever:
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunAfterTimestamp := now()+'10 seconds'::interval);
-- Run immediately from now until a specific timestamp in the future:
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunUntilTimestamp := now()+'15 seconds'::interval);
-- Run between two specific timestamps:
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunAfterTimestamp := now()+'20 seconds'::interval, _RunUntilTimestamp := now()+'25 seconds'::interval);
-- Run after a specific time of day and then forever:
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunAfterTime := now()::time+'30 seconds'::interval);
-- Run immediately from now until a specific time of day:
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunUntilTime := now()::time+'35 seconds'::interval);
-- Run between two specific time of day values:
SELECT cron.Register('cron.Example_Random_Sleep(integer)', _RunIfWaiting := TRUE, _RunAfterTime := now()::time+'40 seconds'::interval, _RunUntilTime := now()::time+'45 seconds'::interval);

COMMIT;
