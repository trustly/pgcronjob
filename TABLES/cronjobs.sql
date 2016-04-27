CREATE TABLE public.CronJobs (
CronJobID                 serial      NOT NULL,
SchemaName                text        NOT NULL,
FunctionName              text        NOT NULL,
Enabled                   boolean     NOT NULL DEFAULT TRUE,
RunEvenIfOthersAreWaiting boolean     NOT NULL DEFAULT FALSE,
RetryOnError              boolean     NOT NULL DEFAULT FALSE,
RequestedBy               text        NOT NULL DEFAULT session_user,
RequestedAt               timestamptz NOT NULL DEFAULT now(),
RunAfterTimestamp         timestamptz,
RunUntilTimestamp         timestamptz,
RunAfterTime              time,
RunUntilTime              time,
RunInterval               interval, -- time to sleep after StartedAt
SleepInterval             interval, -- time to sleep after FinishedAt
FirstRunStartedAt         timestamptz,
FirstRunFinishedAt        timestamptz,
LastRunStartedAt          timestamptz,
LastRunFinishedAt         timestamptz,
BatchJobState             batchjobstate,
LastSQLSTATE              text,
LastSQLERRM               text,
PRIMARY KEY (CronJobID),
UNIQUE(SchemaName,FunctionName),
CHECK(LastSQLSTATE ~ '^[0-9A-Z]{5}$')
);
