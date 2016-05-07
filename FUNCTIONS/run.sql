CREATE OR REPLACE FUNCTION cron.Run(OUT BatchJobState batchjobstate, OUT KeepAlive boolean, OUT RunAgainInSeconds numeric, OUT NewProcessID integer, _ProcessID integer)
RETURNS RECORD
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK                 boolean;
_JobID              integer;
_Function           regprocedure;
_RunProcessID       integer;
_DedicatedProcesses integer;
_Concurrent         boolean;
_IntervalAGAIN      interval;
_IntervalDONE       interval;
_KeepAliveAGAIN     boolean;
_KeepAliveDONE      boolean;
_LastRunStartedAt   timestamptz;
_LastRunFinishedAt  timestamptz;
_LastSQLSTATE       text;
_LastSQLERRM        text;
_seq_scan           bigint;
_seq_tup_read       bigint;
_idx_scan           bigint;
_idx_tup_fetch      bigint;
_n_tup_ins          bigint;
_n_tup_upd          bigint;
_n_tup_del          bigint;
_n_tup_hot_upd      bigint;
_SQL                text;
BEGIN

IF _ProcessID IS NULL THEN
    RAISE EXCEPTION 'Input param ProcessID cannot be NULL';
END IF;

IF _ProcessID = 0 THEN
    IF NOT pg_try_advisory_xact_lock('cron.Run(integer)'::regprocedure::int, 0) THEN
        RAISE EXCEPTION 'Aborting cron.Run() because of a concurrent execution';
    END IF;
END IF;

SELECT
    J.JobID,
    J.Function,
    P.ProcessID,
    J.DedicatedProcesses,
    J.Concurrent,
    J.IntervalAGAIN,
    J.IntervalDONE,
    J.KeepAliveAGAIN,
    J.KeepAliveDONE
INTO
    _JobID,
    _Function,
    _RunProcessID,
    _DedicatedProcesses,
    _Concurrent,
    _IntervalAGAIN,
    _IntervalDONE,
    _KeepAliveAGAIN,
    _KeepAliveDONE
FROM cron.Jobs AS J
INNER JOIN cron.Processes AS P ON (P.JobID = J.JobID)
WHERE cron.Is_Valid_Function(J.Function)
AND (cron.No_Waiting()                 OR J.RunEvenIfOthersAreWaiting = TRUE)
AND (P.LastSQLERRM        IS NULL      OR J.RetryOnError              = TRUE)
AND (J.RunAfterTimestamp  IS NULL      OR now()                       > J.RunAfterTimestamp)
AND (J.RunUntilTimestamp  IS NULL      OR now()                       < J.RunUntilTimestamp)
AND (J.RunAfterTime       IS NULL      OR now()::time                 > J.RunAfterTime)
AND (J.RunUntilTime       IS NULL      OR now()::time                 < J.RunUntilTime)
AND (P.BatchJobState      IS NULL      OR now()                       > P.LastRunFinishedAt+J.IntervalDONE  OR P.BatchJobState = 'AGAIN')
AND (J.IntervalAGAIN      IS NULL      OR now()                       > P.LastRunFinishedAt+J.IntervalAGAIN OR P.FirstRunFinishedAt IS NULL)
AND ((P.Dedicated IS FALSE AND _ProcessID = 0) OR (P.Dedicated IS TRUE AND P.ProcessID = _ProcessID))
AND P.ProcessID <> 0
ORDER BY P.LastRunStartedAt ASC NULLS FIRST;
IF NOT FOUND THEN
    -- No work
    BatchJobState     := 'AGAIN';
    KeepAlive         := _KeepAliveAGAIN;
    NewProcessID      := NULL;
    RunAgainInSeconds := 1;
    RAISE NOTICE '% ProcessID % pg_backend_pid % : no work -> AGAIN [RunAgainInSeconds %]', clock_timestamp()::timestamp(3), _ProcessID, pg_backend_pid(), RunAgainInSeconds;
    RETURN;
END IF;

IF NOT _Concurrent THEN
    IF NOT pg_try_advisory_xact_lock(_Function::int, 0) THEN
        RAISE EXCEPTION 'Aborting % because of a concurrent execution', _Function;
    END IF;
END IF;

IF _DedicatedProcesses > 0 AND _ProcessID = 0 THEN
    -- Tell main process to start new process by returning a NOT NULL NewProcessID
    UPDATE cron.Processes SET Dedicated = TRUE WHERE ProcessID = _RunProcessID AND Dedicated IS FALSE RETURNING TRUE INTO STRICT _OK;
    BatchJobState     := 'AGAIN';
    KeepAlive         := _KeepAliveAGAIN;
    NewProcessID      := _RunProcessID;
    RunAgainInSeconds := 0;
    RAISE NOTICE '% ProcessID % pg_backend_pid % : spawn new process -> AGAIN [JobID % Function % DedicatedProcesses % RunProcessID % RunAgainInSeconds %]', clock_timestamp()::timestamp(3), _ProcessID, pg_backend_pid(), _JobID, _Function, _DedicatedProcesses, _RunProcessID, RunAgainInSeconds;
    RETURN;
END IF;

UPDATE cron.Processes SET
    FirstRunStartedAt = COALESCE(FirstRunStartedAt,clock_timestamp()),
    LastRunStartedAt  = clock_timestamp()
WHERE ProcessID = _RunProcessID RETURNING LastRunStartedAt INTO STRICT _LastRunStartedAt;

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

BEGIN
    _SQL := 'SELECT '||format(replace(_Function::text,'(integer)','(%s)'),_RunProcessID);
    RAISE DEBUG 'Starting cron job % process % %', _JobID, _RunProcessID, _SQL;
    EXECUTE _SQL USING _RunProcessID INTO STRICT BatchJobState;
    RAISE DEBUG 'Finished cron job % process % % -> %', _JobID, _RunProcessID, _SQL, BatchJobState;
    IF BatchJobState = 'AGAIN' THEN
        KeepAlive         := _KeepAliveAGAIN;
        RunAgainInSeconds := extract(epoch from _IntervalAGAIN);
    ELSIF BatchJobState = 'DONE' THEN
        KeepAlive         := _KeepAliveDONE;
        RunAgainInSeconds := extract(epoch from _IntervalDONE);
    ELSE
        RAISE EXCEPTION 'Cron function % did not return a valid BatchJobState: %', _Function, BatchJobState;
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'Error when executing cron job %: SQLSTATE % SQLERRM %', _Function, SQLSTATE, SQLERRM;
    _LastSQLSTATE := SQLSTATE;
    _LastSQLERRM  := SQLERRM;
END;

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

UPDATE cron.Processes SET
    FirstRunFinishedAt = COALESCE(FirstRunFinishedAt,clock_timestamp()),
    LastRunFinishedAt  = clock_timestamp(),
    LastSQLSTATE       = _LastSQLSTATE,
    LastSQLERRM        = _LastSQLERRM,
    BatchJobState      = Run.BatchJobState
WHERE ProcessID = _RunProcessID
RETURNING
    LastRunFinishedAt,
    LastSQLSTATE,
    LastSQLERRM
INTO STRICT
    _LastRunFinishedAt,
    _LastSQLSTATE,
    _LastSQLERRM;

INSERT INTO cron.Log ( JobID,BatchJobState,    PgBackendPID,StartTxnAt,        StartedAt,        FinishedAt, LastSQLSTATE, LastSQLERRM, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, n_tup_upd, n_tup_del, n_tup_hot_upd)
VALUES               (_JobID,BatchJobState,pg_backend_pid(),     now(),_LastRunStartedAt,_LastRunFinishedAt,_LastSQLSTATE,_LastSQLERRM,_seq_scan,_seq_tup_read,_idx_scan,_idx_tup_fetch,_n_tup_ins,_n_tup_upd,_n_tup_del,_n_tup_hot_upd)
RETURNING TRUE INTO STRICT _OK;

IF RunAgainInSeconds IS NULL THEN
    KeepAlive := FALSE;
END IF;

NewProcessID  := NULL;
RAISE NOTICE '% ProcessID % pg_backend_pid % : more work -> % [JobID % Function % DedicatedProcesses % RunProcessID % RunAgainInSeconds %]', clock_timestamp()::timestamp(3), _ProcessID, pg_backend_pid(), BatchJobState, _JobID, _Function, _DedicatedProcesses, _RunProcessID, RunAgainInSeconds;
RETURN;
END;
$FUNC$;

ALTER FUNCTION cron.Run(_ProcessID integer) OWNER TO pgcronjob;
