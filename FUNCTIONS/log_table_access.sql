CREATE OR REPLACE FUNCTION cron.Log_Table_Access(_ProcessID integer, _BatchJobState batchjobstate, _LastRunStartedAt timestamptz, _LastRunFinishedAt timestamptz)
RETURNS bigint
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_LogID bigint;
BEGIN

INSERT INTO cron.Log (
    ProcessID,
    BatchJobState,
    PgBackendPID,
    StartTxnAt,
    StartedAt,
    FinishedAt,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    n_tup_ins,
    n_tup_upd,
    n_tup_del,
    n_tup_hot_upd
)
SELECT
    _ProcessID,
    _BatchJobState,
    pg_backend_pid(),
    now(),
    _LastRunStartedAt,
    _LastRunFinishedAt,
    COALESCE(SUM(seq_scan),0),
    COALESCE(SUM(seq_tup_read),0),
    COALESCE(SUM(idx_scan),0),
    COALESCE(SUM(idx_tup_fetch),0),
    COALESCE(SUM(n_tup_ins),0),
    COALESCE(SUM(n_tup_upd),0),
    COALESCE(SUM(n_tup_del),0),
    COALESCE(SUM(n_tup_hot_upd),0)
FROM pg_catalog.pg_stat_xact_user_tables
RETURNING LogID INTO STRICT _LogID;

RETURN _LogID;
END;
$FUNC$;

ALTER FUNCTION cron.Log_Table_Access(_ProcessID integer, _BatchJobState batchjobstate, _LastRunStartedAt timestamptz, _LastRunFinishedAt timestamptz) OWNER TO pgcronjob;
