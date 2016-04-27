CREATE OR REPLACE FUNCTION public.CronJob_Register(
_SchemaName                 text,
_FunctionName               text,
_RunEvenIfOthersAreWaiting  boolean     DEFAULT FALSE,
_RetryOnError               boolean     DEFAULT FALSE,
_RunAfterTimestamp          timestamptz DEFAULT NULL,
_RunUntilTimestamp          timestamptz DEFAULT NULL,
_RunAfterTime               time        DEFAULT NULL,
_RunUntilTime               time        DEFAULT NULL,
_RunInterval                interval    DEFAULT NULL,
_SleepInterval              interval    DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_CronJobID integer;
_IdenticalConfiguration boolean;
BEGIN
IF CronJob_Function_Is_Valid(_SchemaName, _FunctionName) IS NOT TRUE THEN
    RAISE EXCEPTION 'Function %.% is not a valid CronJob function.', _SchemaName, _FunctionName
    USING HINT = 'It must return BATCHJOBSTATE and the cronjob user must have been explicitly granted EXECUTE on the function.';
END IF;

SELECT
    CronJobID,
    ROW( RunEvenIfOthersAreWaiting, RetryOnError, RunAfterTimestamp, RunUntilTimestamp, RunAfterTime, RunUntilTime, RunInterval, SleepInterval) IS NOT DISTINCT FROM
    ROW(_RunEvenIfOthersAreWaiting,_RetryOnError,_RunAfterTimestamp,_RunUntilTimestamp,_RunAfterTime,_RunUntilTime,_RunInterval,_SleepInterval)
INTO
    _CronJobID,
    _IdenticalConfiguration
FROM CronJobs
WHERE SchemaName = _SchemaName AND FunctionName = _FunctionName;
IF FOUND THEN
    IF _IdenticalConfiguration THEN
        RAISE NOTICE 'Function %.% is already registered as CronJobID % with identical configuration', _SchemaName, _FunctionName, _CronJobID;
        RETURN _CronJobID;
    ELSE
        RAISE EXCEPTION 'Function %.% is already registered as CronJobID % but with different configuration', _SchemaName, _FunctionName, _CronJobID;
    END IF;
END IF;

INSERT INTO CronJobs ( SchemaName,  FunctionName, RunEvenIfOthersAreWaiting,  RetryOnError, RunAfterTimestamp, RunUntilTimestamp, RunAfterTime, RunUntilTime, RunInterval, SleepInterval)
VALUES               (_SchemaName, _FunctionName,_RunEvenIfOthersAreWaiting, _RetryOnError,_RunAfterTimestamp,_RunUntilTimestamp,_RunAfterTime,_RunUntilTime,_RunInterval,_SleepInterval)
RETURNING CronJobID INTO STRICT _CronJobID;

RETURN _CronJobID;
END;
$FUNC$;
