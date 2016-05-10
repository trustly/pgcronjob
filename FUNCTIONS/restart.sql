CREATE OR REPLACE FUNCTION cron.Restart()
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
UPDATE cron.Processes SET Running = FALSE WHERE Running;
RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Restart() OWNER TO pgcronjob;
