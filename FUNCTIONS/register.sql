CREATE OR REPLACE FUNCTION cron.Register(
_Function                   regprocedure,
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
_JobID integer;
_IdenticalConfiguration boolean;
BEGIN
IF cron.Is_Valid_Function(_Function) IS NOT TRUE THEN
    RAISE EXCEPTION 'Function % is not a valid CronJob function.', _Function
    USING HINT = 'It must return BATCHJOBSTATE and the cronjob user must have been explicitly granted EXECUTE on the function.';
END IF;

SELECT
    JobID,
    ROW( RunEvenIfOthersAreWaiting, RetryOnError, RunAfterTimestamp, RunUntilTimestamp, RunAfterTime, RunUntilTime, RunInterval, SleepInterval) IS NOT DISTINCT FROM
    ROW(_RunEvenIfOthersAreWaiting,_RetryOnError,_RunAfterTimestamp,_RunUntilTimestamp,_RunAfterTime,_RunUntilTime,_RunInterval,_SleepInterval)
INTO
    _JobID,
    _IdenticalConfiguration
FROM cron.Jobs
WHERE Function = _Function;
IF FOUND THEN
    IF _IdenticalConfiguration THEN
        RAISE NOTICE 'Function % is already registered as JobID % with identical configuration', _Function, _JobID;
        RETURN _JobID;
    ELSE
        RAISE EXCEPTION 'Function % is already registered as JobID % but with different configuration', _Function, _JobID;
    END IF;
END IF;

INSERT INTO cron.Jobs ( Function,  RunEvenIfOthersAreWaiting,  RetryOnError, RunAfterTimestamp, RunUntilTimestamp, RunAfterTime, RunUntilTime, RunInterval, SleepInterval)
VALUES                (_Function, _RunEvenIfOthersAreWaiting, _RetryOnError,_RunAfterTimestamp,_RunUntilTimestamp,_RunAfterTime,_RunUntilTime,_RunInterval,_SleepInterval)
RETURNING JobID INTO STRICT _JobID;

RETURN _JobID;
END;
$FUNC$;

ALTER FUNCTION cron.Register(
_Function                   regprocedure,
_RunEvenIfOthersAreWaiting  boolean,
_RetryOnError               boolean,
_RunAfterTimestamp          timestamptz,
_RunUntilTimestamp          timestamptz,
_RunAfterTime               time,
_RunUntilTime               time,
_RunInterval                interval,
_SleepInterval              interval
) OWNER TO pgcronjob;
