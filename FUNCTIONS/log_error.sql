CREATE OR REPLACE FUNCTION cron.Log_Error(_ProcessID integer, _PgBackendPID integer, _PgErr text, _PgErrStr text, _PgState text, _PerlCallerInfo text, _RetryInSeconds numeric)
RETURNS bigint
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_ErrorLogID bigint;
BEGIN

INSERT INTO cron.ErrorLog ( ProcessID,  PgBackendPID,  PgErr,  PgErrStr,  PgState,  PerlCallerInfo,  RetryInSeconds)
VALUES                    (_ProcessID, _PgBackendPID, _PgErr, _PgErrStr, _PgState, _PerlCallerInfo, _RetryInSeconds)
RETURNING ErrorLogID INTO STRICT _ErrorLogID;

RETURN _ErrorLogID;
END;
$FUNC$;

ALTER FUNCTION cron.Log_Error(_ProcessID integer, _PgBackendPID integer, _PgErr text, _PgErrStr text, _PgState text, _PerlCallerInfo text, _RetryInSeconds numeric) OWNER TO pgcronjob;
