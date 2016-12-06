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
_seq_scan            bigint;
_seq_tup_read        bigint;
_idx_scan            bigint;
_idx_tup_fetch       bigint;
_n_tup_ins           bigint;
_n_tup_upd           bigint;
_n_tup_del           bigint;
_n_tup_hot_upd       bigint;
_SQL                 text;
_ConnectionPoolID    integer;
_CycleFirstProcessID integer;
_Enabled             boolean;
_LogTableAccess      boolean;
BEGIN

IF _ProcessID IS NULL THEN
    RAISE EXCEPTION 'Input param ProcessID cannot be NULL';
END IF;

SELECT
    P.RunAtTime,
    J.JobID,
    J.Enabled,
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
    _RunAtTime,
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
FROM cron.Jobs AS J
INNER JOIN cron.Processes AS P ON (P.JobID = J.JobID)
LEFT JOIN cron.ConnectionPools AS CP ON (CP.ConnectionPoolID = J.ConnectionPoolID)
WHERE P.ProcessID = _ProcessID
FOR UPDATE OF P;

IF _RunAtTime IS NULL OR NOT _Enabled THEN
    RETURN;
ELSIF _RunAtTime > now() THEN
    RunInSeconds := extract(epoch from _RunAtTime-now());
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

IF cron.Waiting_PIDs() IS NOT NULL AND NOT _RunIfWaiting THEN
    RAISE DEBUG '% ProcessID % pg_backend_pid % : other processes are waiting, aborting', clock_timestamp()::timestamp(3), _ProcessID, pg_backend_pid();
    _RunAtTime := now() + _IntervalAGAIN * CASE WHEN _RandomInterval THEN random() ELSE 1 END;
    UPDATE cron.Processes SET RunAtTime = _RunAtTime WHERE ProcessID = _ProcessID RETURNING TRUE INTO STRICT _OK;
    RunInSeconds := extract(epoch from _RunAtTime-now());
    RETURN;
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

IF _LogTableAccess IS TRUE THEN
    SELECT
        COALESCE(SUM(seq_scan),0),
        COALESCE(SUM(seq_tup_read),0),
        COALESCE(SUM(idx_scan),0),
        COALESCE(SUM(idx_tup_fetch),0),
        COALESCE(SUM(n_tup_ins),0),
        COALESCE(SUM(n_tup_upd),0),
        COALESCE(SUM(n_tup_del),0),
        COALESCE(SUM(n_tup_hot_upd),0)
    INTO STRICT
        _seq_scan,
        _seq_tup_read,
        _idx_scan,
        _idx_tup_fetch,
        _n_tup_ins,
        _n_tup_upd,
        _n_tup_del,
        _n_tup_hot_upd
    FROM pg_catalog.pg_stat_xact_user_tables;
END IF;

IF NOT _Concurrent THEN
    IF NOT pg_try_advisory_xact_lock(_Function::int, 0) THEN
        RAISE EXCEPTION 'Aborting % because of a concurrent execution', _Function;
    END IF;
END IF;
_SQL := 'SELECT '||format(replace(_Function::text,'(integer)','(%s)'),_ProcessID);
RAISE DEBUG 'Starting cron job % process % %', _JobID, _ProcessID, _SQL;
PERFORM set_config('application_name', regexp_replace(_SQL,'^SELECT ',''),TRUE);
EXECUTE _SQL USING _ProcessID INTO STRICT _BatchJobState;
RAISE DEBUG 'Finished cron job % process % % -> %', _JobID, _ProcessID, _SQL, _BatchJobState;
IF _BatchJobState = 'AGAIN' THEN
    _RunAtTime := now() + _IntervalAGAIN * CASE WHEN _RandomInterval THEN random() ELSE 1 END;
ELSIF _BatchJobState = 'DONE' THEN
    _RunAtTime := now() + _IntervalDONE * CASE WHEN _RandomInterval THEN random() ELSE 1 END;
ELSE
    RAISE EXCEPTION 'Cron function % did not return a valid BatchJobState: %', _Function, _BatchJobState;
END IF;
RunInSeconds := extract(epoch from _RunAtTime-now());

IF _LogTableAccess IS TRUE THEN
    SELECT
        COALESCE(SUM(seq_scan),0)       - _seq_scan,
        COALESCE(SUM(seq_tup_read),0)   - _seq_tup_read,
        COALESCE(SUM(idx_scan),0)       - _idx_scan,
        COALESCE(SUM(idx_tup_fetch),0)  - _idx_tup_fetch,
        COALESCE(SUM(n_tup_ins),0)      - _n_tup_ins,
        COALESCE(SUM(n_tup_upd),0)      - _n_tup_upd,
        COALESCE(SUM(n_tup_del),0)      - _n_tup_del,
        COALESCE(SUM(n_tup_hot_upd),0)  - _n_tup_hot_upd
    INTO STRICT
        _seq_scan,
        _seq_tup_read,
        _idx_scan,
        _idx_tup_fetch,
        _n_tup_ins,
        _n_tup_upd,
        _n_tup_del,
        _n_tup_hot_upd
    FROM pg_catalog.pg_stat_xact_user_tables;
END IF;

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
    INSERT INTO cron.Log ( JobID, BatchJobState,    PgBackendPID,StartTxnAt,        StartedAt,        FinishedAt, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, n_tup_upd, n_tup_del, n_tup_hot_upd)
    VALUES               (_JobID,_BatchJobState,pg_backend_pid(),     now(),_LastRunStartedAt,_LastRunFinishedAt,_seq_scan,_seq_tup_read,_idx_scan,_idx_tup_fetch,_n_tup_ins,_n_tup_upd,_n_tup_del,_n_tup_hot_upd)
    RETURNING TRUE INTO STRICT _OK;
END IF;

RAISE DEBUG '% ProcessID % pg_backend_pid % : % [JobID % Function % RunInSeconds %]', clock_timestamp()::timestamp(3), _ProcessID, pg_backend_pid(), _BatchJobState, _JobID, _Function, RunInSeconds;
RETURN;
END;
$FUNC$;

ALTER FUNCTION cron.Run(_ProcessID integer) OWNER TO pgcronjob;
