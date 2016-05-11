CREATE OR REPLACE FUNCTION cron.Example_Random_Sleep(_ProcessID integer)
RETURNS batchjobstate
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
-- This example function sleeps between 1-2 seconds and then always returns AGAIN
DECLARE
BEGIN
PERFORM pg_sleep(1+random());
RETURN 'AGAIN';
END;
$FUNC$;

ALTER FUNCTION cron.Example_Random_Sleep(_ProcessID integer) OWNER TO pgcronjob;

GRANT EXECUTE ON FUNCTION cron.Example_Random_Sleep(_ProcessID integer) TO pgcronjob;
