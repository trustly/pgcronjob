CREATE OR REPLACE FUNCTION cron.Run(OUT RunInSeconds numeric, _ProcessID integer)
RETURNS numeric
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK                 boolean;
_JobID              integer;
_Function           regprocedure;
_BatchJobState      batchjobstate;
_Concurrent         boolean;
_IntervalAGAIN      interval;
_IntervalDONE       interval;
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

RAISE NOTICE '% ProcessID % pg_backend_pid %', clock_timestamp()::timestamp(3), _ProcessID, pg_backend_pid();

SELECT
    J.JobID,
    J.Function,
    J.Concurrent,
    J.IntervalAGAIN,
    J.IntervalDONE
INTO STRICT
    _JobID,
    _Function,
    _Concurrent,
    _IntervalAGAIN,
    _IntervalDONE
FROM cron.Jobs AS J
INNER JOIN cron.Processes AS P ON (P.JobID = J.JobID)
WHERE P.Running IS TRUE
AND P.ProcessID = _ProcessID;
IF NOT FOUND THEN
    RAISE NOTICE '% ProcessID % pg_backend_pid % : no work', clock_timestamp()::timestamp(3), _ProcessID, pg_backend_pid();
    RETURN;
END IF;

IF NOT _Concurrent THEN
    IF NOT pg_try_advisory_xact_lock(_Function::int, 0) THEN
        RAISE NOTICE 'Aborting % because of a concurrent execution', _Function;
        RunInSeconds := _IntervalAGAIN;
        RETURN;
    END IF;
END IF;

UPDATE cron.Processes SET
    FirstRunStartedAt = COALESCE(FirstRunStartedAt,clock_timestamp()),
    LastRunStartedAt  = clock_timestamp()
WHERE ProcessID = _ProcessID RETURNING LastRunStartedAt INTO STRICT _LastRunStartedAt;

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
    _SQL := 'SELECT '||format(replace(_Function::text,'(integer)','(%s)'),_ProcessID);
    RAISE NOTICE 'Starting cron job % process % %', _JobID, _ProcessID, _SQL;
    EXECUTE _SQL USING _ProcessID INTO STRICT _BatchJobState;
    RAISE NOTICE 'Finished cron job % process % % -> %', _JobID, _ProcessID, _SQL, _BatchJobState;
    IF _BatchJobState = 'AGAIN' THEN
        RunInSeconds := extract(epoch from _IntervalAGAIN);
    ELSIF _BatchJobState = 'DONE' THEN
        RunInSeconds := extract(epoch from _IntervalDONE);
    ELSE
        RAISE EXCEPTION 'Cron function % did not return a valid BatchJobState: %', _Function, _BatchJobState;
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
    BatchJobState      = _BatchJobState,
    Running            = RunInSeconds IS NOT NULL
WHERE ProcessID = _ProcessID
RETURNING
    LastRunFinishedAt,
    LastSQLSTATE,
    LastSQLERRM
INTO STRICT
    _LastRunFinishedAt,
    _LastSQLSTATE,
    _LastSQLERRM;

INSERT INTO cron.Log ( JobID, BatchJobState,    PgBackendPID,StartTxnAt,        StartedAt,        FinishedAt, LastSQLSTATE, LastSQLERRM, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, n_tup_upd, n_tup_del, n_tup_hot_upd)
VALUES               (_JobID,_BatchJobState,pg_backend_pid(),     now(),_LastRunStartedAt,_LastRunFinishedAt,_LastSQLSTATE,_LastSQLERRM,_seq_scan,_seq_tup_read,_idx_scan,_idx_tup_fetch,_n_tup_ins,_n_tup_upd,_n_tup_del,_n_tup_hot_upd)
RETURNING TRUE INTO STRICT _OK;

RAISE NOTICE '% ProcessID % pg_backend_pid % : % [JobID % Function % RunInSeconds %]', clock_timestamp()::timestamp(3), _ProcessID, pg_backend_pid(), _BatchJobState, _JobID, _Function, RunInSeconds;
RETURN;
END;
$FUNC$;

ALTER FUNCTION cron.Run(_ProcessID integer) OWNER TO pgcronjob;
