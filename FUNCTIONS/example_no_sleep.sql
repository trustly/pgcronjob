CREATE OR REPLACE FUNCTION cron.Example_No_Sleep(_ProcessID integer)
RETURNS batchjobstate
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
-- This example function returns AGAIN immediately until random() < 0.0001, i.e. it runs on average 10000 times
DECLARE
BEGIN
IF random() < 0.0001 THEN
    RETURN 'DONE';
ELSE
    RETURN 'AGAIN';
END IF;
END;
$FUNC$;

ALTER FUNCTION cron.Example_No_Sleep(_ProcessID integer) OWNER TO pgcronjob;

GRANT EXECUTE ON FUNCTION cron.Example_No_Sleep(_ProcessID integer) TO pgcronjob;
