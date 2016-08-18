CREATE OR REPLACE FUNCTION cron.Terminate_All_Backends()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
IF (SELECT setting::integer FROM pg_catalog.pg_settings WHERE pg_catalog.pg_settings.name = 'server_version_num') < 90600 THEN
    PERFORM pg_terminate_backend(procpid) FROM pg_stat_activity WHERE usename = 'pgcronjob' AND procpid <> pg_backend_pid();
ELSE
    PERFORM pg_terminate_backend(pid)     FROM pg_stat_activity WHERE usename = 'pgcronjob' AND pid <> pg_backend_pid();
END IF;
IF FOUND THEN
    RETURN FALSE; -- there were still alive PIDs
ELSE
    RETURN TRUE; -- all PIDs had already been terminated
END IF;
END;
$FUNC$;

ALTER FUNCTION cron.Terminate_All_Backends() OWNER TO sudo;

REVOKE ALL ON FUNCTION cron.Terminate_All_Backends() FROM PUBLIC;
GRANT  ALL ON FUNCTION cron.Terminate_All_Backends() TO pgcronjob;
