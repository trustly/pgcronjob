CREATE OR REPLACE FUNCTION cron.Run(OUT CronRunState batchjobstate, OUT ForkJobID integer, _PgCrobJobPID integer, _ForkedJobID integer DEFAULT NULL)
RETURNS RECORD
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK                boolean;
_JobID             integer;
_PgBackendPID      integer;
_Function          regprocedure;
_Fork              boolean;
_BatchJobState     batchjobstate;
_LastRunStartedAt  timestamptz;
_LastRunFinishedAt timestamptz;
_LastSQLSTATE      text;
_LastSQLERRM       text;
_seq_scan          bigint;
_seq_tup_read      bigint;
_idx_scan          bigint;
_idx_tup_fetch     bigint;
_n_tup_ins         bigint;
_n_tup_upd         bigint;
_n_tup_del         bigint;
_n_tup_hot_upd     bigint;
BEGIN

IF _ForkedJobID IS NULL THEN
    IF NOT pg_try_advisory_xact_lock('cron.Run(integer,integer)'::regprocedure::int, 0) THEN
        RAISE NOTICE 'Aborting cron.Run() because of a concurrent execution';
        CronRunState := NULL;
        ForkJobID    := NULL;
        RETURN;
    END IF;
END IF;

SELECT JobID,  Function,  Fork
INTO  _JobID, _Function, _Fork
FROM cron.Jobs
WHERE cron.Is_Valid_Function(Function)
AND (cron.No_Waiting()            OR RunEvenIfOthersAreWaiting = TRUE)
AND (LastSQLERRM       IS NULL    OR RetryOnError              = TRUE)
AND (RunAfterTimestamp IS NULL    OR now()                     > RunAfterTimestamp)
AND (RunUntilTimestamp IS NULL    OR now()                     < RunUntilTimestamp)
AND (RunAfterTime      IS NULL    OR now()::time               > RunAfterTime)
AND (RunUntilTime      IS NULL    OR now()::time               < RunUntilTime)
AND (BatchJobState     IS NULL    OR now()                     > LastRunFinishedAt+IntervalDONE  OR BatchJobState = 'AGAIN')
AND (IntervalAGAIN     IS NULL    OR now()                     > LastRunFinishedAt+IntervalAGAIN OR FirstRunFinishedAt IS NULL)
AND PgCrobJobPID       IS NULL    OR PgCrobJobPID              = _PgCrobJobPID
AND JobID = COALESCE(_ForkedJobID,JobID)
ORDER BY LastRunStartedAt ASC NULLS FIRST;
IF NOT FOUND THEN
    -- Tell our while-loop-caller-script we're done, no more work
    -- It will keep calling us again after having slept for a second.
    CronRunState := 'DONE';
    ForkJobID    := NULL;
    RETURN;
END IF;

IF _Fork AND _ForkedJobID IS NULL THEN
    CronRunState := 'AGAIN';
    ForkJobID    := _JobID;
    RETURN;
END IF;

_PgBackendPID := pg_backend_pid();

UPDATE cron.Jobs SET
    FirstRunStartedAt = COALESCE(FirstRunStartedAt,clock_timestamp()),
    LastRunStartedAt  = clock_timestamp(),
    PgCrobJobPID      = _PgCrobJobPID,
    PgBackendPID      = _PgBackendPID
WHERE JobID = _JobID RETURNING LastRunStartedAt INTO STRICT _LastRunStartedAt;

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
    RAISE NOTICE 'Starting cron job % %', _JobID, _Function;
    EXECUTE format('SELECT %s', _Function) INTO STRICT _BatchJobState;
    RAISE NOTICE 'Finished cron job % % -> %', _JobID, _Function, _BatchJobState;
    IF (_BatchJobState IN ('DONE','AGAIN')) IS NOT TRUE THEN
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

UPDATE cron.Jobs SET
    FirstRunFinishedAt = COALESCE(FirstRunFinishedAt,clock_timestamp()),
    LastRunFinishedAt  = clock_timestamp(),
    LastSQLSTATE       = _LastSQLSTATE,
    LastSQLERRM        = _LastSQLERRM,
    BatchJobState      = _BatchJobState
WHERE JobID = _JobID
RETURNING
    LastRunFinishedAt,
    LastSQLSTATE,
    LastSQLERRM
INTO STRICT
    _LastRunFinishedAt,
    _LastSQLSTATE,
    _LastSQLERRM;

INSERT INTO cron.Log ( JobID, PgCrobJobPID, PgBackendPID,StartTxnAt,        StartedAt,        FinishedAt, LastSQLSTATE, LastSQLERRM, seq_scan, seq_tup_read, idx_scan, idx_tup_fetch, n_tup_ins, n_tup_upd, n_tup_del, n_tup_hot_upd)
VALUES               (_JobID,_PgCrobJobPID,_PgBackendPID,     now(),_LastRunStartedAt,_LastRunFinishedAt,_LastSQLSTATE,_LastSQLERRM,_seq_scan,_seq_tup_read,_idx_scan,_idx_tup_fetch,_n_tup_ins,_n_tup_upd,_n_tup_del,_n_tup_hot_upd)
RETURNING TRUE INTO STRICT _OK;

-- Tell our while-loop-caller-script to continue calling us until there is no more PgJobs to execute:
CronRunState := 'AGAIN';
ForkJobID    := NULL;
RETURN;
END;
$FUNC$;

ALTER FUNCTION cron.Run(_PgCrobJobPID integer, _ForkedJobID integer) OWNER TO pgcronjob;
