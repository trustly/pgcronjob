CREATE OR REPLACE FUNCTION cron.Dispatch(OUT RunProcessID integer, OUT RunInSeconds numeric, OUT RunMaxOtherProcessesLimit integer)
RETURNS RECORD
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK       boolean;
_JobID    integer;
_Function regprocedure;
BEGIN

IF NOT pg_try_advisory_xact_lock('cron.Dispatch()'::regprocedure::int, 0) THEN
    RAISE EXCEPTION 'Aborting cron.Dispatch() because of a concurrent execution';
END IF;

SELECT
    P.ProcessID,
    extract(epoch from CASE
        WHEN P.LastRunFinishedAt IS NULL       THEN now()
        WHEN J.RunAfterTimestamp > now()       THEN J.RunAfterTimestamp
        WHEN J.RunUntilTimestamp > now()       THEN NULL
        WHEN J.RunAfterTime      > now()::time THEN now()::date + J.RunAfterTime
        WHEN J.RunUntilTime      > now()::time THEN now()::date + 1
        ELSE P.LastRunFinishedAt + CASE WHEN P.BatchJobState = 'DONE' THEN J.IntervalDONE ELSE J.IntervalAGAIN END
    END - now()),
    J.RunMaxOtherProcessesLimit
INTO
    RunProcessID,
    RunInSeconds,
    RunMaxOtherProcessesLimit
FROM cron.Jobs AS J
INNER JOIN cron.Processes AS P ON (P.JobID = J.JobID)
WHERE NOT P.Running
AND (cron.No_Waiting()                       OR J.RunEvenIfOthersAreWaiting = TRUE)
AND (P.LastSQLERRM IS NULL                   OR J.RetryOnError              = TRUE)
AND (P.BatchJobState IS DISTINCT FROM 'DONE' OR J.IntervalDONE IS NOT NULL)
ORDER BY 2 NULLS LAST
LIMIT 1;
IF NOT FOUND THEN
    RETURN;
END IF;

UPDATE cron.Processes SET Running = TRUE WHERE ProcessID = RunProcessID AND NOT Running RETURNING TRUE INTO STRICT _OK;
RAISE NOTICE '% pg_backend_pid % : spawn new process -> [JobID % Function % RunProcessID % RunInSeconds % RunMaxOtherProcessesLimit %]', clock_timestamp()::timestamp(3), pg_backend_pid(), _JobID, _Function, RunProcessID, RunInSeconds, RunMaxOtherProcessesLimit;
RETURN;

END;
$FUNC$;

ALTER FUNCTION cron.Dispatch() OWNER TO pgcronjob;
