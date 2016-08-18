CREATE OR REPLACE FUNCTION cron.Dispatch(OUT RunProcessID integer, OUT RunInSeconds numeric, OUT MaxProcesses integer, OUT ConnectionPoolID integer, OUT KillIfWaiting boolean)
RETURNS RECORD
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK        boolean;
_JobID     integer;
_Function  regprocedure;
_RunAtTime timestamptz;
BEGIN

IF NOT pg_try_advisory_xact_lock('cron.Dispatch()'::regprocedure::int, 0) THEN
    RAISE EXCEPTION 'Aborting cron.Dispatch() because of a concurrent execution';
END IF;

SELECT
    P.ProcessID,
    CASE
        WHEN J.RunAfterTimestamp > now()       THEN J.RunAfterTimestamp
        WHEN J.RunAfterTime      > now()::time THEN now()::date + J.RunAfterTime
        WHEN P.LastRunFinishedAt IS NULL       THEN now()
        ELSE P.LastRunFinishedAt + CASE WHEN P.BatchJobState = 'DONE' THEN J.IntervalDONE ELSE J.IntervalAGAIN END
    END,
    CP.MaxProcesses,
    J.ConnectionPoolID,
    J.KillIfWaiting
INTO
    RunProcessID,
    _RunAtTime,
    MaxProcesses,
    ConnectionPoolID,
    KillIfWaiting
FROM cron.Jobs AS J
INNER JOIN cron.Processes AS P ON (P.JobID = J.JobID)
LEFT JOIN cron.ConnectionPools AS CP ON (CP.ConnectionPoolID = J.ConnectionPoolID)
WHERE P.RunAtTime IS NULL
AND J.Enabled
AND (P.BatchJobState IS DISTINCT FROM 'DONE' OR J.IntervalDONE IS NOT NULL)
AND (J.RunUntilTimestamp > now() OR J.RunUntilTime > now()::time) IS NOT TRUE
ORDER BY 2 NULLS LAST, 1
LIMIT 1
FOR UPDATE OF P;
IF NOT FOUND THEN
    RETURN;
END IF;

RunInSeconds := extract(epoch from _RunAtTime - now());

UPDATE cron.Processes SET RunAtTime = _RunAtTime WHERE ProcessID = RunProcessID AND RunAtTime IS NULL RETURNING TRUE INTO STRICT _OK;
RAISE DEBUG '% pg_backend_pid % : spawn new process -> [JobID % Function % RunAtTime % RunProcessID % RunInSeconds % MaxProcesses % ConnectionPoolID %]', clock_timestamp()::timestamp(3), pg_backend_pid(), _JobID, _Function, _RunAtTime, RunProcessID, RunInSeconds, MaxProcesses, ConnectionPoolID;
RETURN;

END;
$FUNC$;

ALTER FUNCTION cron.Dispatch() OWNER TO pgcronjob;
