CREATE TABLE cron.Jobs (
JobID             serial       NOT NULL,
Function          text         NOT NULL,
Processes         integer      NOT NULL DEFAULT 1,
Concurrent        boolean      NOT NULL DEFAULT TRUE, -- if set to FALSE, we will protect against concurrent execution using pg_try_advisory_xact_lock()
Enabled           boolean      NOT NULL DEFAULT TRUE,
RunIfWaiting      boolean      NOT NULL DEFAULT FALSE,
RetryOnError      interval     DEFAULT NULL, -- time to sleep after an error has occurred, or NULL to never retry
RandomInterval    boolean      NOT NULL DEFAULT FALSE,
IntervalAGAIN     interval     NOT NULL DEFAULT '100 ms'::interval, -- time to sleep between each db txn commit to spread the load
IntervalDONE      interval     DEFAULT NULL, -- time to sleep after a cron job has completed and has no more work to do for now, NULL means never run again
RunAfterTimestamp timestamptz  DEFAULT NULL,
RunUntilTimestamp timestamptz  DEFAULT NULL,
RunAfterTime      time         DEFAULT NULL,
RunUntilTime      time         DEFAULT NULL,
ConnectionPoolID  integer      DEFAULT NULL REFERENCES cron.ConnectionPools(ConnectionPoolID),
LogTableAccess    boolean      NOT NULL DEFAULT TRUE,
RequestedBy       text         NOT NULL DEFAULT session_user,
RequestedAt       timestamptz  NOT NULL DEFAULT now(),
PRIMARY KEY (JobID)
);

ALTER TABLE cron.Jobs OWNER TO pgcronjob;
