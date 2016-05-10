CREATE TABLE cron.Jobs (
JobID                     serial       NOT NULL,
Function                  regprocedure NOT NULL,
RunMaxOtherProcessesLimit integer,
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
PRIMARY KEY (JobID)
);

ALTER TABLE cron.Jobs OWNER TO pgcronjob;
