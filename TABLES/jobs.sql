CREATE TABLE cron.Jobs (
JobID                     serial       NOT NULL,
Function                  regprocedure NOT NULL,
DedicatedProcesses        integer      NOT NULL DEFAULT 0, -- 0 means only run in main parent loop's db connection, 1 means run in 1 separate db connection, 2 means run in 2 separare db connections, etc. 
Concurrent                boolean      NOT NULL DEFAULT TRUE, -- if set to FALSE, we will protect against concurrent execution using pg_try_advisory_xact_lock()
Enabled                   boolean      NOT NULL DEFAULT TRUE,
RunEvenIfOthersAreWaiting boolean      NOT NULL DEFAULT FALSE,
RetryOnError              boolean      NOT NULL DEFAULT FALSE,
IntervalAGAIN             interval     NOT NULL DEFAULT '100 ms'::interval, -- time to sleep between each db txn commit to spread the load
IntervalDONE              interval,    -- time to sleep after a cron job has completed and has no more work to do for now, NULL means never run again
RunAfterTimestamp         timestamptz,
RunUntilTimestamp         timestamptz,
RunAfterTime              time,
RunUntilTime              time,
RequestedBy               text         NOT NULL DEFAULT session_user,
RequestedAt               timestamptz  NOT NULL DEFAULT now(),
PRIMARY KEY (JobID),
CHECK(DedicatedProcesses >= 0),
CHECK(DedicatedProcesses <= 1 OR Concurrent)
);

ALTER TABLE cron.Jobs OWNER TO pgcronjob;
