CREATE TABLE cron.ErrorLog (
ErrorLogID   serial  NOT NULL,
ProcessID    integer NOT NULL,
PgBackendPID integer NOT NULL,
PgErr        text,
PgErrStr     text,
PgState      text,
Datestamp    timestamptz NOT NULL DEFAULT now(),
PRIMARY KEY (ErrorLogID)
);

ALTER TABLE cron.ErrorLog OWNER TO pgcronjob;
