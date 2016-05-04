CREATE OR REPLACE FUNCTION cron.Set_Child_PID(_PgCronJobPID integer, _ForkedProcessID integer)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK boolean;
BEGIN
UPDATE cron.Processes SET PgCronJobPID = _PgCronJobPID WHERE ProcessID = _ForkedProcessID AND PgCronJobPID IS NULL RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Set_Child_PID(_PgCronJobPID integer, _ForkedProcessID integer) OWNER TO pgcronjob;
