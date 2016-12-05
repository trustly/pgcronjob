CREATE OR REPLACE FUNCTION cron.Log_Error(_ProcessID integer, _PgBackendPID integer, _PgErr text, _PgErrStr text, _PgState text)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_ErrorLogID integer;
BEGIN

INSERT INTO cron.ErrorLog ( ProcessID,  PgBackendPID,  PgErr,  PgErrStr,  PgState)
VALUES                    (_ProcessID, _PgBackendPID, _PgErr, _PgErrStr, _PgState)
RETURNING ErrorLogID INTO STRICT _ErrorLogID;

RETURN _ErrorLogID;
END;
$FUNC$;

ALTER FUNCTION cron.Log_Error(_ProcessID integer, _PgBackendPID integer, _PgErr text, _PgErrStr text, _PgState text) OWNER TO pgcronjob;
