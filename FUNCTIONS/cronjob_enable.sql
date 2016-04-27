CREATE OR REPLACE FUNCTION public.CronJob_Enable(
_SchemaName   text,
_FunctionName text
)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_OK boolean;
_CronJobID integer;
_Enabled boolean;
BEGIN
IF CronJob_Function_Is_Valid(_SchemaName, _FunctionName) IS NOT TRUE THEN
    RAISE EXCEPTION 'Function %.% is not a valid CronJob function.', _SchemaName, _FunctionName
    USING HINT = 'It must return BATCHJOBSTATE and the cronjob user must have been explicitly granted EXECUTE on the function.';
END IF;

SELECT
    CronJobID,
    Enabled
INTO
    _CronJobID,
    _Enabled
FROM CronJobs
WHERE SchemaName = _SchemaName AND FunctionName = _FunctionName;
IF NOT FOUND THEN
    RAISE EXCEPTION 'Function %.% is a valid CronJob function but has not yet been registered as CronJobID', _SchemaName, _FunctionName;
ELSE
    IF _Enabled IS FALSE THEN
        UPDATE CronJobs SET Enabled = TRUE WHERE CronJobID = _CronJobID AND Enabled IS FALSE RETURNING TRUE INTO STRICT _OK;
    ELSIF _Enabled IS TRUE THEN
        RAISE NOTICE 'Function %.% with CronJobID % has already been enabled', _CronJobID, _SchemaName, _FunctionName;
    ELSE
        RAISE EXCEPTION 'How did we end up here?! SchemaName %, FunctionName %, CronJobID %, Enabled %', _SchemaName, _FunctionName, _CronJobID, _Enabled;
    END IF;
END IF;

RETURN _CronJobID;
END;
$FUNC$;
