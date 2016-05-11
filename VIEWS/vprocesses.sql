CREATE OR REPLACE VIEW cron.vProcesses AS
SELECT
Jobs.JobID,
Jobs.Function,
Processes.ProcessID,
CASE Processes.Running WHEN TRUE THEN 'RUNNING' ELSE 'STOPPED' END AS Status,
Processes.Calls,
Processes.BatchJobState,
Processes.LastSQLSTATE,
Processes.LastSQLERRM,
Processes.PgBackendPID,
pg_stat_activity.procpid,
CASE pg_stat_activity.waiting WHEN TRUE THEN 'WAITING' END AS waiting,
pg_stat_activity.current_query,
(now()-pg_stat_activity.query_start)::interval(0) AS duration,
(Processes.LastRunFinishedAt-Processes.FirstRunStartedAt)::interval(0) AS TotalDuration
FROM cron.Processes
INNER JOIN cron.Jobs ON (Jobs.JobID = Processes.JobID)
LEFT JOIN pg_stat_activity ON (pg_stat_activity.current_query = format('SELECT RunInSeconds FROM cron.Run(_ProcessID := %s)',Processes.ProcessID))
ORDER BY Jobs.JobID, Jobs.Function, Processes.ProcessID;

ALTER TABLE cron.vProcesses OWNER TO pgcronjob;

