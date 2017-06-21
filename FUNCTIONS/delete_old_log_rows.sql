CREATE OR REPLACE FUNCTION cron.Delete_Old_Log_Rows(_ProcessID integer) RETURNS BatchJobState
LANGUAGE plpgsql SECURITY DEFINER
SET search_path TO public, pg_temp
AS $_$
DECLARE
_LogProcessID             integer;
_DeleteThreshold CONSTANT integer := 11000;
_RowsToKeep      CONSTANT integer := 10000;
_OldestFinishedAtToKeep   timestamptz;
BEGIN
IF (_DeleteThreshold > _RowsToKeep) IS NOT TRUE THEN
    RAISE EXCEPTION 'ERROR_WTF Bad config, _DeleteThreshold % must be greater than _RowsToKeep %', _DeleteThreshold, _RowsToKeep;
END IF;
-- The function will start to delete rows where there are at least _DeleteThreshold cron.Log rows for the ProcessID
-- and will then delete all but the last _RowsToKeep rows.
-- _DeleteThreshold should be greater than _RowsToKeep to avoid the function from running AGAIN, AGAIN, ... AGAIN,
-- the difference between them is how many log rows that needs to be generated before the function deletes again for the ProcessID.
FOR _LogProcessID IN
SELECT ProcessID FROM cron.Processes ORDER BY ProcessID
LOOP
    IF EXISTS (
        SELECT 1 FROM cron.Log
        WHERE ProcessID = _LogProcessID
        ORDER BY FinishedAt DESC
        LIMIT 1
        OFFSET _DeleteThreshold
    ) THEN
        SELECT FinishedAt
        INTO STRICT _OldestFinishedAtToKeep
        FROM cron.Log
        WHERE ProcessID = _LogProcessID
        ORDER BY FinishedAt DESC
        LIMIT 1
        OFFSET _RowsToKeep;
        RAISE NOTICE 'Deleting cron.Log rows for ProcessID % where FinishedAt < _OldestFinishedAtToKeep %', _LogProcessID, _OldestFinishedAtToKeep;
        DELETE FROM cron.Log WHERE ProcessID = _LogProcessID AND FinishedAt < _OldestFinishedAtToKeep;
        RETURN 'AGAIN';
    END IF;
END LOOP;

RETURN 'DONE';
END;
$_$;

ALTER FUNCTION cron.Delete_Old_Log_Rows(_ProcessID integer) OWNER TO gluepay;

REVOKE ALL ON FUNCTION cron.Delete_Old_Log_Rows(_ProcessID integer) FROM PUBLIC;
GRANT  ALL ON FUNCTION cron.Delete_Old_Log_Rows(_ProcessID integer) TO gluepay;
GRANT  ALL ON FUNCTION cron.Delete_Old_Log_Rows(_ProcessID integer) TO pgcronjob;

/*
SELECT cron.Register('cron.Delete_Old_Log_Rows(integer)',
    _Concurrent     := FALSE,
    _RetryOnError   := '1 day'::interval,
    _IntervalAGAIN  := '1 second'::interval,
    _IntervalDONE   := '1 day'::interval,
    _ConnectionPool := 'Non-Time-Critical Jobs'
);
*/
