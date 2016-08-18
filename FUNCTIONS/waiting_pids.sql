CREATE OR REPLACE FUNCTION cron.Waiting_PIDs()
RETURNS integer[]
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_PIDs integer[];
BEGIN
IF (SELECT setting::integer FROM pg_catalog.pg_settings WHERE pg_catalog.pg_settings.name = 'server_version_num') < 90600 THEN
    SELECT array_agg(procpid) INTO _PIDs FROM pg_catalog.pg_stat_activity WHERE pg_catalog.pg_stat_activity.waiting;
ELSE
    -- N.B.: this is not exactly the same thing as pg_catalog.pg_stat_activity.waiting, but should be close enough for most use-cases
    SELECT array_agg(pid) INTO _PIDs FROM pg_catalog.pg_stat_activity WHERE pg_catalog.pg_stat_activity.wait_event IS NOT NULL;
END IF;
RETURN _PIDs;
END;
$FUNC$;

ALTER FUNCTION cron.Waiting_PIDs() OWNER TO sudo;
