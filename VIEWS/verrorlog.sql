CREATE OR REPLACE VIEW cron.vErrorLog AS
SELECT
cron.ErrorLog.ErrorLogID,
cron.ErrorLog.ProcessID,
cron.Jobs.Function,
cron.ErrorLog.PgBackendPID,
cron.ErrorLog.PgErr,
cron.ErrorLog.PgErrStr,
cron.ErrorLog.PgState,
cron.ErrorLog.PerlCallerInfo,
cron.ErrorLog.RetryInSeconds,
cron.ErrorLog.Datestamp
FROM cron.ErrorLog
INNER JOIN cron.Processes ON cron.Processes.ProcessID = cron.ErrorLog.ProcessID
INNER JOIN cron.Jobs      ON cron.Jobs.JobID          = cron.Processes.JobID
ORDER BY cron.ErrorLog.ErrorLogID DESC;

ALTER TABLE cron.vErrorLog OWNER TO pgcronjob;
