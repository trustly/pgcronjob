CREATE OR REPLACE FUNCTION cron.Restart(_Force boolean DEFAULT FALSE)
RETURNS boolean
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
UPDATE cron.Processes SET RunAtTime = NULL WHERE RunAtTime IS NOT NULL;
IF _Force THEN
    PERFORM pg_terminate_backend(procpid) FROM pg_stat_activity WHERE application_name = 'cron.Run(integer)';
ELSE
    PERFORM pg_cancel_backend(procpid) FROM pg_stat_activity WHERE application_name = 'cron.Run(integer)';
END IF;
IF FOUND THEN
    RETURN FALSE;
END IF;
RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Restart(_Force boolean) OWNER TO pgcronjob;
