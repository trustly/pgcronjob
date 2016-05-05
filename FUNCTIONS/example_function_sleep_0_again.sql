CREATE OR REPLACE FUNCTION cron.Example_Function_Sleep_0_AGAIN(_ProcessID integer)
RETURNS batchjobstate
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
RETURN 'AGAIN';
END;
$FUNC$;

ALTER FUNCTION cron.Example_Function_Sleep_0_AGAIN(_ProcessID integer) OWNER TO pgcronjob;

GRANT EXECUTE ON FUNCTION cron.Example_Function_Sleep_0_AGAIN(_ProcessID integer) TO pgcronjob;
