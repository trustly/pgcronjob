CREATE OR REPLACE FUNCTION cron.Restart()
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
UPDATE cron.Processes SET Running = FALSE WHERE Running;
PERFORM pg_cancel_backend(procpid) FROM pg_stat_activity WHERE application_name = 'cron.Run(integer)';
RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Restart() OWNER TO pgcronjob;
