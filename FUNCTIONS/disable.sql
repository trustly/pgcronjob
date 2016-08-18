CREATE OR REPLACE FUNCTION cron.Disable(_Function regprocedure)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK boolean;
_JobID integer;
_Enabled boolean;
BEGIN
IF cron.Is_Valid_Function(_Function) IS NOT TRUE THEN
    RAISE EXCEPTION 'Function % is not a valid cron function.', _Function
    USING HINT = 'It must return BATCHJOBSTATE and the cronjob user must have been explicitly granted EXECUTE on the function.';
END IF;

IF (SELECT COUNT(*) FROM cron.Jobs WHERE Function = _Function::text) > 1 THEN
    RAISE EXCEPTION 'Function % has multiple JobIDs registered, you will have to disable it manually by setting cron.Jobs.Enabled=FALSE for some or all rows', _Function;
END IF;

SELECT
    JobID,
    Enabled
INTO
    _JobID,
    _Enabled
FROM cron.Jobs
WHERE Function = _Function::text;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Function % is a valid cron function but has not yet been registered as JobID', _Function;
ELSE
    IF _Enabled IS TRUE THEN
        UPDATE Jobs SET Enabled = FALSE WHERE JobID = _JobID AND Enabled IS TRUE RETURNING TRUE INTO STRICT _OK;
    ELSIF _Enabled IS FALSE THEN
        RAISE NOTICE 'Function % with JobID % has already been disabled', _Function, _JobID;
    ELSE
        RAISE EXCEPTION 'How did we end up here?! Function %, JobID %, Enabled %', _Function, _JobID, _Enabled;
    END IF;
END IF;

RETURN _JobID;
END;
$FUNC$;

ALTER FUNCTION cron.Disable(_Function regprocedure) OWNER TO pgcronjob;
