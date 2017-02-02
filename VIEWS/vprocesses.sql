CREATE OR REPLACE VIEW cron.vProcesses AS
SELECT
Jobs.JobID,
Jobs.Function,
Processes.ProcessID,
ConnectionPools.Name || '(' || Jobs.ConnectionPoolID || ')' AS ConnectionPool,
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
CASE WHEN EXISTS (SELECT 1 FROM public.pg_stat_activity_portable() WHERE pid = Processes.PgBackendPID) THEN 'OPEN' ELSE 'CLOSED' END AS Connection,
COALESCE(pg_stat_activity.pid,Processes.PgBackendPID) AS procpid,
CASE pg_stat_activity.waiting WHEN TRUE THEN 'WAITING' END AS waiting,
pg_stat_activity.query,
(now()-pg_stat_activity.query_start)::interval(0) AS duration,
(Processes.LastRunFinishedAt-Processes.FirstRunStartedAt)::interval(0) AS TotalDuration,
(now()-cron.Processes.LastRunFinishedAt)::interval(0) AS LastRun,
cron.Processes.StateData
FROM cron.Processes
INNER JOIN cron.Jobs ON (Jobs.JobID = Processes.JobID)
LEFT JOIN cron.ConnectionPools ON (ConnectionPools.ConnectionPoolID = cron.Jobs.ConnectionPoolID)
LEFT JOIN public.pg_stat_activity_portable() AS pg_stat_activity ON (pg_stat_activity.query = format('SELECT RunInSeconds FROM cron.Run(_ProcessID := %s)',Processes.ProcessID))
ORDER BY Jobs.JobID, Jobs.Function, Processes.ProcessID;

ALTER TABLE cron.vProcesses OWNER TO pgcronjob;
