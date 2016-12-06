CREATE TABLE cron.Processes (
ProcessID                 serial       NOT NULL,
JobID                     integer      NOT NULL REFERENCES cron.Jobs(JobID),
Calls                     bigint       NOT NULL DEFAULT 0,
Enabled                   boolean      NOT NULL DEFAULT TRUE,
RunAtTime                 timestamptz,
FirstRunStartedAt         timestamptz,
FirstRunFinishedAt        timestamptz,
LastRunStartedAt          timestamptz,
LastRunFinishedAt         timestamptz,
BatchJobState             batchjobstate,
PgBackendPID              integer,
PRIMARY KEY (ProcessID)
);

ALTER TABLE cron.Processes OWNER TO pgcronjob;
