CREATE TABLE cron.ErrorLog (
ErrorLogID     bigserial NOT NULL,
ProcessID      integer   NOT NULL REFERENCES cron.Processes(ProcessID),
PgBackendPID   integer   NOT NULL,
PgErr          text,
PgErrStr       text,
PgState        text,
PerlCallerInfo text,
RetryInSeconds numeric,
Datestamp      timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY (ErrorLogID)
);

CREATE INDEX ON cron.ErrorLog(ProcessID);

ALTER TABLE cron.ErrorLog OWNER TO pgcronjob;
