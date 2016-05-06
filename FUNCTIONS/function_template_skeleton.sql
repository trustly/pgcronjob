CREATE OR REPLACE FUNCTION cron.Function_Template_Skeleton(_ProcessID integer)
RETURNS batchjobstate
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
-- 1. Do some work
-- 2.1. If we have more work to do and want cron.Run() to run us again after Jobs.IntervalAGAIN time has passed or immediately if Jobs.IntervalAGAIN IS NULL, then return 'AGAIN'
RETURN 'AGAIN';
-- 2.2. If we don't have any more work to do and want cron.Run() to run us first after Jobs.IntervalDONE time has passed, or never again if Jobs.IntervalDONE IS NULL, then return 'DONE'
-- RETURN 'DONE';
-- 2.3. If an error occurrs, the cron job function can safely raise an exception since cron.Run() will run us in a sub txn and catch any exceptions. If Jobs.RetryOnError IS TRUE, cron.Run() will run us again automatically.
-- RAISE EXCEPTION 'Simulate error in cron function';
END;
$FUNC$;

ALTER FUNCTION cron.Function_Template_Skeleton(_ProcessID integer) OWNER TO pgcronjob;

GRANT EXECUTE ON FUNCTION cron.Function_Template_Skeleton(_ProcessID integer) TO pgcronjob;
