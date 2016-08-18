CREATE OR REPLACE FUNCTION cron.Reset_RunAtTime()
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
UPDATE cron.Processes SET RunAtTime = NULL WHERE RunAtTime IS NOT NULL;
RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Reset_RunAtTime() OWNER TO pgcronjob;
