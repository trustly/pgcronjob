CREATE OR REPLACE FUNCTION public.CronJob_No_Waiting()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
IF (SELECT setting::integer FROM pg_catalog.pg_settings WHERE pg_catalog.pg_settings.name = 'server_version_num') < 90600 THEN
    RETURN NOT EXISTS (SELECT 1 FROM pg_catalog.pg_stat_activity WHERE pg_catalog.pg_stat_activity.waiting);
ELSE
    -- N.B.: this is not exactly the same thing as pg_catalog.pg_stat_activity.waiting, but should be close enough for most use-cases
    RETURN NOT EXISTS (SELECT 1 FROM pg_catalog.pg_stat_activity WHERE pg_catalog.pg_stat_activity.wait_event IS NOT NULL);
END IF;
END;
$FUNC$;
