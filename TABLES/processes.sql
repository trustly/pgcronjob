CREATE TABLE cron.Processes (
ProcessID                 serial       NOT NULL,
JobID                     integer      NOT NULL REFERENCES cron.Jobs(JobID),
FirstRunStartedAt         timestamptz,
FirstRunFinishedAt        timestamptz,
LastRunStartedAt          timestamptz,
LastRunFinishedAt         timestamptz,
BatchJobState             batchjobstate,
LastSQLSTATE              text,
LastSQLERRM               text,
PgCrobJobPID              integer,
PgBackendPID              integer,
PRIMARY KEY (ProcessID),
CHECK(LastSQLSTATE ~ '^[0-9A-Z]{5}$')
);

ALTER TABLE cron.Processes OWNER TO pgcronjob;
