CREATE VIEW cron.Status AS
SELECT
Jobs.JobID,
Jobs.Function,
Processes.ProcessID,
Processes.Running,
Processes.Calls,
Processes.BatchJobState,
Processes.LastSQLSTATE,
Processes.LastSQLERRM,
Processes.PgBackendPID,
pg_stat_activity.procpid,
pg_stat_activity.waiting,
pg_stat_activity.current_query
FROM cron.Processes
INNER JOIN cron.Jobs ON (Jobs.JobID = Processes.JobID)
LEFT JOIN pg_stat_activity ON (pg_stat_activity.current_query = format('SELECT RunInSeconds FROM cron.Run(_ProcessID := %s)',Processes.ProcessID))
ORDER BY Jobs.JobID, Jobs.Function, Processes.ProcessID;

ALTER TABLE cron.Status OWNER TO pgcronjob;

