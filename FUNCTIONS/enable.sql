CREATE OR REPLACE FUNCTION cron.Enable(_Function regprocedure)
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

SELECT
    JobID,
    Enabled
INTO
    _JobID,
    _Enabled
FROM cron.Jobs
WHERE Function = _Function;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Function % is a valid cron function but has not yet been registered as JobID', _Function;
ELSE
    IF _Enabled IS FALSE THEN
        UPDATE cron.Jobs SET Enabled = TRUE WHERE JobID = _JobID AND Enabled IS FALSE RETURNING TRUE INTO STRICT _OK;
    ELSIF _Enabled IS TRUE THEN
        RAISE NOTICE 'Function % with JobID % has already been enabled', _Function, _JobID;
    ELSE
        RAISE EXCEPTION 'How did we end up here?! Function %, JobID %, Enabled %', _Function, _JobID, _Enabled;
    END IF;
END IF;

RETURN _JobID;
END;
$FUNC$;
