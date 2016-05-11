CREATE OR REPLACE FUNCTION cron.Example_Random_Error(_ProcessID integer)
RETURNS batchjobstate
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
-- This example function is useful to test the cron.Jobs.RetryOnError setting.
-- It returns AGAIN which tells the caller to run again until random() is
-- less than 0.1 and it throws an error exception to the caller.
DECLARE
BEGIN
IF random() < 0.1 THEN
    RAISE EXCEPTION 'Simulate error in cron function';
END IF;
RETURN 'AGAIN';
END;
$FUNC$;

ALTER FUNCTION cron.Example_Random_Error(_ProcessID integer) OWNER TO pgcronjob;

GRANT EXECUTE ON FUNCTION cron.Example_Random_Error(_ProcessID integer) TO pgcronjob;
