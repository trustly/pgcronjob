CREATE OR REPLACE FUNCTION cron.Set_Child_PID(_PgCrobJobPID integer, _ForkedJobID integer)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK boolean;
BEGIN
UPDATE cron.Jobs SET PgCrobJobPID = _PgCrobJobPID WHERE JobID = _ForkedJobID AND PgCrobJobPID IS NULL RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Set_Child_PID(_PgCrobJobPID integer, _ForkedJobID integer) OWNER TO pgcronjob;
