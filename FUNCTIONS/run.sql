CREATE OR REPLACE FUNCTION cron.Run(OUT RunInSeconds numeric, _ProcessID integer)
RETURNS numeric
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK                  boolean;
_JobID               integer;
_Function            regprocedure;
_RunAtTime           timestamptz;
_BatchJobState       batchjobstate;
_Concurrent          boolean;
_IntervalAGAIN       interval;
_IntervalDONE        interval;
_RandomInterval      boolean;
_RunIfWaiting        boolean;
_RunAfterTimestamp   timestamptz;
_RunUntilTimestamp   timestamptz;
_RunAfterTime        interval;
_RunUntilTime        interval;
_LastRunStartedAt    timestamptz;
_LastRunFinishedAt   timestamptz;
_SQL                 text;
_ConnectionPoolID    integer;
_CycleFirstProcessID integer;
_Enabled             boolean;
_LogTableAccess      boolean;
_Waiting             boolean;
BEGIN

IF _ProcessID IS NULL THEN
    RAISE EXCEPTION 'Input param ProcessID cannot be NULL';
END IF;

SELECT
    J.JobID,
    J.Enabled AND P.Enabled,
    J.Function::regprocedure,
    J.Concurrent,
    J.RunIfWaiting,
    J.RunAfterTimestamp,
    J.RunUntilTimestamp,
    J.RunAfterTime,
    J.RunUntilTime,
    J.IntervalAGAIN,
    J.IntervalDONE,
    J.RandomInterval,
    J.ConnectionPoolID,
    J.LogTableAccess,
    CP.CycleFirstProcessID
INTO STRICT
    _JobID,
    _Enabled,
    _Function,
    _Concurrent,
    _RunIfWaiting,
    _RunAfterTimestamp,
    _RunUntilTimestamp,
    _RunAfterTime,
    _RunUntilTime,
    _IntervalAGAIN,
    _IntervalDONE,
    _RandomInterval,
    _ConnectionPoolID,
    _LogTableAccess,
    _CycleFirstProcessID
FROM cron.Jobs                  AS J
INNER JOIN cron.Processes       AS P  ON (P.JobID             = J.JobID)
LEFT  JOIN cron.ConnectionPools AS CP ON (CP.ConnectionPoolID = J.ConnectionPoolID)
WHERE P.ProcessID = _ProcessID
FOR UPDATE OF P;

IF _Enabled IS NOT TRUE THEN
    RunInSeconds := NULL;
    RETURN;
END IF;

IF _RunAfterTimestamp > now()
OR _RunUntilTimestamp < now()
OR _RunAfterTime      > now()::time
OR _RunUntilTime      < now()::time
THEN
    UPDATE cron.Processes SET
        BatchJobState = 'DONE',
        RunAtTime     = NULL
    WHERE ProcessID = _ProcessID
    RETURNING TRUE INTO STRICT _OK;
    RunInSeconds := NULL;
    RETURN;
END IF;

IF _RandomInterval IS TRUE THEN
    _IntervalAGAIN := _IntervalAGAIN * random();
    _IntervalDONE  := _IntervalDONE  * random();
END IF;

IF NOT _RunIfWaiting THEN
    IF current_setting('server_version_num')::int >= 90600 THEN
        _Waiting := EXISTS (SELECT 1 FROM pg_catalog.pg_stat_activity WHERE wait_event IS NOT NULL);
    ELSE
        _Waiting := EXISTS (SELECT 1 FROM pg_catalog.pg_stat_activity WHERE waiting IS TRUE);
    END IF;
    IF _Waiting THEN
        RAISE DEBUG '% ProcessID % pg_backend_pid % : other processes are waiting, aborting', clock_timestamp()::timestamp(3), _ProcessID, pg_backend_pid();
        _RunAtTime := now() + _IntervalAGAIN;
        UPDATE cron.Processes SET RunAtTime = _RunAtTime WHERE ProcessID = _ProcessID RETURNING TRUE INTO STRICT _OK;
        RunInSeconds := extract(epoch from _RunAtTime-now());
        RETURN;
    END IF;
END IF;

IF _CycleFirstProcessID = _ProcessID THEN
    UPDATE cron.ConnectionPools SET
        LastCycleAt         = ThisCycleAt,
        ThisCycleAt         = clock_timestamp()
    WHERE ConnectionPoolID = _ConnectionPoolID
    RETURNING TRUE INTO STRICT _OK;
END IF;

UPDATE cron.Processes SET
    FirstRunStartedAt = COALESCE(FirstRunStartedAt,clock_timestamp()),
    LastRunStartedAt  = clock_timestamp(),
    Calls             = Calls + 1,
    PgBackendPID      = pg_backend_pid()
WHERE ProcessID = _ProcessID RETURNING LastRunStartedAt INTO STRICT _LastRunStartedAt;

IF NOT _Concurrent THEN
    IF NOT pg_try_advisory_xact_lock(_Function::int, 0) THEN
        RAISE EXCEPTION 'Aborting % because of a concurrent execution', _Function;
    END IF;
END IF;

_SQL := 'SELECT '||format(replace(_Function::text,'(integer)','(%s)'),_ProcessID);
RAISE DEBUG 'Starting cron job % process % %', _JobID, _ProcessID, _SQL;
PERFORM set_config('application_name', _Function::text,TRUE);
EXECUTE _SQL USING _ProcessID INTO STRICT _BatchJobState;
RAISE DEBUG 'Finished cron job % process % % -> %', _JobID, _ProcessID, _SQL, _BatchJobState;

IF _BatchJobState = 'AGAIN' THEN
    _RunAtTime := now() + _IntervalAGAIN;
ELSIF _BatchJobState = 'DONE' THEN
    _RunAtTime := now() + _IntervalDONE;
ELSE
    RAISE EXCEPTION 'Cron function % did not return a valid BatchJobState: %', _Function, _BatchJobState;
END IF;
RunInSeconds := extract(epoch from _RunAtTime-now());

UPDATE cron.Processes SET
    FirstRunFinishedAt = COALESCE(FirstRunFinishedAt,clock_timestamp()),
    LastRunFinishedAt  = clock_timestamp(),
    BatchJobState      = _BatchJobState,
    RunAtTime          = _RunAtTime
WHERE ProcessID = _ProcessID
RETURNING
    LastRunFinishedAt
INTO STRICT
    _LastRunFinishedAt;

IF _LogTableAccess IS TRUE THEN
    PERFORM cron.Log_Table_Access(_ProcessID, _BatchJobState, _LastRunStartedAt, _LastRunFinishedAt);
END IF;

RAISE DEBUG '% ProcessID % pg_backend_pid % : % [JobID % Function % RunInSeconds %]', clock_timestamp()::timestamp(3), _ProcessID, pg_backend_pid(), _BatchJobState, _JobID, _Function, RunInSeconds;
RETURN;
END;
$FUNC$;

ALTER FUNCTION cron.Run(_ProcessID integer) OWNER TO pgcronjob;
