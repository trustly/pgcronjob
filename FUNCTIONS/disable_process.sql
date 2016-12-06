CREATE OR REPLACE FUNCTION cron.Disable_Process(_ProcessID integer)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK boolean;
BEGIN
UPDATE cron.Processes SET Enabled = FALSE WHERE ProcessID = _ProcessID RETURNING TRUE INTO STRICT _OK;
RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Disable_Process(_ProcessID integer) OWNER TO pgcronjob;
