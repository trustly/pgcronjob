CREATE OR REPLACE FUNCTION cron.Register(
_Function                   regprocedure,
_DedicatedProcesses         integer     DEFAULT 0,
_Concurrent                 boolean     DEFAULT TRUE,
_RunEvenIfOthersAreWaiting  boolean     DEFAULT FALSE,
_RetryOnError               boolean     DEFAULT FALSE,
_IntervalAGAIN              interval    DEFAULT '100 ms'::interval,
_IntervalDONE               interval    DEFAULT NULL,
_RunAfterTimestamp          timestamptz DEFAULT NULL,
_RunUntilTimestamp          timestamptz DEFAULT NULL,
_RunAfterTime               time        DEFAULT NULL,
_RunUntilTime               time        DEFAULT NULL
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
    ROW( DedicatedProcesses, RunEvenIfOthersAreWaiting, RetryOnError, IntervalAGAIN, IntervalDONE) IS NOT DISTINCT FROM
    ROW(_DedicatedProcesses,_RunEvenIfOthersAreWaiting,_RetryOnError,_IntervalAGAIN,_IntervalDONE)
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
        RAISE NOTICE 'Function % is already registered as JobID % but with different configuration', _Function, _JobID;
    END IF;
END IF;

INSERT INTO cron.Jobs ( Function, DedicatedProcesses, Concurrent, RunEvenIfOthersAreWaiting, RetryOnError, IntervalAGAIN, IntervalDONE, RunAfterTimestamp, RunUntilTimestamp, RunAfterTime, RunUntilTime)
VALUES                (_Function,_DedicatedProcesses,_Concurrent,_RunEvenIfOthersAreWaiting,_RetryOnError,_IntervalAGAIN,_IntervalDONE,_RunAfterTimestamp,_RunUntilTimestamp,_RunAfterTime,_RunUntilTime)
RETURNING JobID INTO STRICT _JobID;

-- GREATEST(_DedicatedProcesses,1): Even if _DedicatedProcesses=0 we still want to insert one row in Processes
INSERT INTO cron.Processes (JobID) SELECT _JobID FROM generate_series(1,GREATEST(_DedicatedProcesses,1));

RETURN _JobID;
END;
$FUNC$;

ALTER FUNCTION cron.Register(
_Function                   regprocedure,
_DedicatedProcesses         integer,
_Concurrent                 boolean,
_RunEvenIfOthersAreWaiting  boolean,
_RetryOnError               boolean,
_IntervalAGAIN              interval,
_IntervalDONE               interval,
_RunAfterTimestamp          timestamptz,
_RunUntilTimestamp          timestamptz,
_RunAfterTime               time,
_RunUntilTime               time
) OWNER TO pgcronjob;
