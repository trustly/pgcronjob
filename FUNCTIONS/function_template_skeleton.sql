CREATE OR REPLACE FUNCTION cron.Function_Template_Skeleton()
RETURNS batchjobstate
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
RAISE NOTICE 'Hello world!';
PERFORM pg_sleep(random());
RAISE NOTICE 'Slept for a while.';
IF random() < 0.5 THEN
    -- Tell cron.Run() we have more work to do and we want it to run us again in due time
    RAISE NOTICE 'See you again!';
    RETURN 'AGAIN';
ELSIF random() < 0.5 THEN
    -- Throw error to cron.Run() to test errors
    RAISE EXCEPTION 'Simulate error in cron function';
ELSE
    -- Tell cron.Run() we're done and we don't want it to run us ever again
    RAISE NOTICE 'Bye world!';
    RETURN 'DONE';
END IF;
END;
$FUNC$;

GRANT EXECUTE ON FUNCTION cron.Function_Template_Skeleton() TO pgcronjob;
