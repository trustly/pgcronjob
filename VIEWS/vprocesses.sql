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
Processes.PgBackendPID AS procpid,
(Processes.LastRunFinishedAt-Processes.FirstRunStartedAt)::interval(0) AS TotalDuration,
(now()-cron.Processes.LastRunFinishedAt)::interval(0) AS LastRun,
cron.Processes.StateData
FROM cron.Processes
INNER JOIN cron.Jobs ON (Jobs.JobID = Processes.JobID)
LEFT JOIN cron.ConnectionPools ON (ConnectionPools.ConnectionPoolID = cron.Jobs.ConnectionPoolID)
ORDER BY Jobs.JobID, Jobs.Function, Processes.ProcessID;

ALTER TABLE cron.vProcesses OWNER TO pgcronjob;
