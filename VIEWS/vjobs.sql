CREATE OR REPLACE VIEW cron.vJobs AS
SELECT
JobID,
Function,
Processes,
CASE Concurrent          WHEN TRUE THEN 'CONCURRENT'      ELSE 'RUN_ALONE'        END AS Concurrent,
CASE Enabled             WHEN TRUE THEN 'ENABLED'         ELSE 'DISABLED'         END AS Enabled,
CASE RunIfWaiting        WHEN TRUE THEN 'RUN_IF_WAITING'  ELSE 'ABORT_IF_WAITING' END AS RunIfWaiting,
CASE WHEN RetryOnError IS NOT NULL THEN 'RETRY_ON_ERROR'  ELSE 'STOP_ON_ERROR'    END AS RetryOnError,
CASE RandomInterval      WHEN TRUE THEN 'RANDOM_INTERVAL' ELSE 'EXACT_INTERVAL'   END AS RandomInterval,
IntervalAGAIN,
IntervalDONE,
RunAfterTimestamp::timestamp(0),
RunUntilTimestamp::timestamp(0),
RunAfterTime::time(0),
RunUntilTime::time(0),
RequestedBy,
RequestedAt::timestamptz(0)
FROM cron.Jobs
ORDER BY JobID;

ALTER TABLE cron.vJobs OWNER TO pgcronjob;
