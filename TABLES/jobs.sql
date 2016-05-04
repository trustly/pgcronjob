CREATE TABLE cron.Jobs (
JobID                     serial       NOT NULL,
Function                  regprocedure NOT NULL,
Enabled                   boolean      NOT NULL DEFAULT TRUE,
RunEvenIfOthersAreWaiting boolean      NOT NULL DEFAULT FALSE,
RetryOnError              boolean      NOT NULL DEFAULT FALSE,
RequestedBy               text         NOT NULL DEFAULT session_user,
RequestedAt               timestamptz  NOT NULL DEFAULT now(),
RunAfterTimestamp         timestamptz,
RunUntilTimestamp         timestamptz,
RunAfterTime              time,
RunUntilTime              time,
IntervalAGAIN             interval, -- time to sleep between each db txn commit to spread the load
IntervalDONE              interval, -- time to sleep after a cron job has completed and has no more work to do for now
FirstRunStartedAt         timestamptz,
FirstRunFinishedAt        timestamptz,
LastRunStartedAt          timestamptz,
LastRunFinishedAt         timestamptz,
BatchJobState             batchjobstate,
LastSQLSTATE              text,
LastSQLERRM               text,
PRIMARY KEY (JobID),
UNIQUE(Function),
CHECK(LastSQLSTATE ~ '^[0-9A-Z]{5}$')
);

ALTER TABLE cron.Jobs OWNER TO pgcronjob;
