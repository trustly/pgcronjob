CREATE OR REPLACE VIEW cron.vProcesses AS
SELECT
Jobs.JobID,
Jobs.Function,
Processes.ProcessID,
format('%s(%s)',ConnectionPools.Name,Jobs.ConnectionPoolID) AS ConnectionPool,
ConnectionPools.MaxProcesses,
CASE 
    WHEN Processes.RunAtTime <= now() THEN 'RUNNING'
    WHEN Processes.RunAtTime > now()  THEN 'QUEUED'
    WHEN Processes.RunAtTime IS NULL  THEN 'STOPPED'
END
AS Status,
extract(epoch from Processes.RunAtTime - now())::numeric(12,2) AS RunInSeconds,
Processes.Calls,
Processes.BatchJobState,
Processes.LastSQLSTATE,
Processes.LastSQLERRM,
CASE WHEN EXISTS (SELECT 1 FROM pg_stat_activity WHERE procpid = Processes.PgBackendPID) THEN 'OPEN' ELSE 'CLOSED' END AS Connection,
COALESCE(pg_stat_activity.procpid,Processes.PgBackendPID) AS procpid,
CASE pg_stat_activity.waiting WHEN TRUE THEN 'WAITING' END AS waiting,
pg_stat_activity.current_query,
(now()-pg_stat_activity.query_start)::interval(0) AS duration,
(Processes.LastRunFinishedAt-Processes.FirstRunStartedAt)::interval(0) AS TotalDuration
FROM cron.Processes
INNER JOIN cron.Jobs ON (Jobs.JobID = Processes.JobID)
LEFT JOIN cron.ConnectionPools ON (ConnectionPools.ConnectionPoolID = cron.Jobs.ConnectionPoolID)
LEFT JOIN pg_stat_activity ON (pg_stat_activity.current_query = format('SELECT RunInSeconds FROM cron.Run(_ProcessID := %s)',Processes.ProcessID))
ORDER BY Jobs.JobID, Jobs.Function, Processes.ProcessID;

ALTER TABLE cron.vProcesses OWNER TO pgcronjob;

