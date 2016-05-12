CREATE OR REPLACE FUNCTION cron.Restart()
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
UPDATE cron.Processes SET RunAtTime = NULL WHERE RunAtTime IS NOT NULL;
PERFORM pg_cancel_backend(procpid) FROM pg_stat_activity WHERE application_name = 'cron.Run(integer)';
RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Restart() OWNER TO pgcronjob;
