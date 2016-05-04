CREATE OR REPLACE FUNCTION cron.Register(
_Function                   regprocedure,
_Fork                       boolean     DEFAULT FALSE,
_RunEvenIfOthersAreWaiting  boolean     DEFAULT FALSE,
_RetryOnError               boolean     DEFAULT FALSE,
_RunAfterTimestamp          timestamptz DEFAULT NULL,
_RunUntilTimestamp          timestamptz DEFAULT NULL,
_RunAfterTime               time        DEFAULT NULL,
_RunUntilTime               time        DEFAULT NULL,
_IntervalAGAIN              interval    DEFAULT NULL,
_IntervalDONE               interval    DEFAULT NULL
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
    ROW( Fork, RunEvenIfOthersAreWaiting, RetryOnError, RunAfterTimestamp, RunUntilTimestamp, RunAfterTime, RunUntilTime, IntervalAGAIN, IntervalDONE) IS NOT DISTINCT FROM
    ROW(_Fork,_RunEvenIfOthersAreWaiting,_RetryOnError,_RunAfterTimestamp,_RunUntilTimestamp,_RunAfterTime,_RunUntilTime,_IntervalAGAIN,_IntervalDONE)
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

INSERT INTO cron.Jobs ( Function, Fork, RunEvenIfOthersAreWaiting, RetryOnError, RunAfterTimestamp, RunUntilTimestamp, RunAfterTime, RunUntilTime, IntervalAGAIN, IntervalDONE)
VALUES                (_Function,_Fork,_RunEvenIfOthersAreWaiting,_RetryOnError,_RunAfterTimestamp,_RunUntilTimestamp,_RunAfterTime,_RunUntilTime,_IntervalAGAIN,_IntervalDONE)
RETURNING JobID INTO STRICT _JobID;

RETURN _JobID;
END;
$FUNC$;

ALTER FUNCTION cron.Register(
_Function                   regprocedure,
_Fork                       boolean,
_RunEvenIfOthersAreWaiting  boolean,
_RetryOnError               boolean,
_RunAfterTimestamp          timestamptz,
_RunUntilTimestamp          timestamptz,
_RunAfterTime               time,
_RunUntilTime               time,
_IntervalAGAIN              interval,
_IntervalDONE               interval
) OWNER TO pgcronjob;
