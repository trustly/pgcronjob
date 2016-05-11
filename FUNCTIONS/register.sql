CREATE OR REPLACE FUNCTION cron.Register(
_Function                   regprocedure,
_Processes                  integer     DEFAULT 1,
_MaxProcesses  integer      DEFAULT NULL,
_Concurrent                 boolean     DEFAULT TRUE,
_RunIfWaiting  boolean      DEFAULT FALSE,
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
_NewJobID integer;
_IdenticalConfiguration boolean;
BEGIN
IF cron.Is_Valid_Function(_Function) IS NOT TRUE THEN
    RAISE EXCEPTION 'Function % is not a valid CronJob function.', _Function
    USING HINT = 'It must return BATCHJOBSTATE and the cronjob user must have been explicitly granted EXECUTE on the function.';
END IF;

INSERT INTO cron.Jobs ( Function, Processes, MaxProcesses, Concurrent, RunIfWaiting, RetryOnError, IntervalAGAIN, IntervalDONE, RunAfterTimestamp, RunUntilTimestamp, RunAfterTime, RunUntilTime)
VALUES                (_Function,_Processes,_MaxProcesses,_Concurrent,_RunIfWaiting,_RetryOnError,_IntervalAGAIN,_IntervalDONE,_RunAfterTimestamp,_RunUntilTimestamp,_RunAfterTime,_RunUntilTime)
RETURNING JobID INTO STRICT _NewJobID;

INSERT INTO cron.Processes (JobID) SELECT _NewJobID FROM generate_series(1,_Processes);

RETURN _JobID;
END;
$FUNC$;

ALTER FUNCTION cron.Register(
_Function                   regprocedure,
_Processes                  integer,
_MaxProcesses  integer,
_Concurrent                 boolean,
_RunIfWaiting  boolean,
_RetryOnError               boolean,
_IntervalAGAIN              interval,
_IntervalDONE               interval,
_RunAfterTimestamp          timestamptz,
_RunUntilTimestamp          timestamptz,
_RunAfterTime               time,
_RunUntilTime               time
) OWNER TO pgcronjob;
