CREATE OR REPLACE FUNCTION cron.Terminate_Backend(_PID integer)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
IF (SELECT setting::integer FROM pg_catalog.pg_settings WHERE pg_catalog.pg_settings.name = 'server_version_num') < 90600 THEN
    PERFORM pg_terminate_backend(procpid) FROM pg_stat_activity WHERE usename = 'pgcronjob' AND procpid = _PID;
ELSE
    PERFORM pg_terminate_backend(pid)     FROM pg_stat_activity WHERE usename = 'pgcronjob' AND pid = _PID;
END IF;
RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Terminate_Backend(_PID integer) OWNER TO sudo;
