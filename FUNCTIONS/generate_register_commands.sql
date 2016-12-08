CREATE OR REPLACE FUNCTION cron.Generate_Register_Commands()
RETURNS SETOF text
LANGUAGE plpgsql
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
BEGIN
RETURN QUERY SELECT '
SELECT cron.New_Connection_Pool(
_Name              := ' || quote_literal(Name) || ',
_MaxProcesses      := ' || MaxProcesses || '
);' FROM cron.ConnectionPools ORDER BY ConnectionPoolID;
RETURN QUERY SELECT '
SELECT cron.Register(
_Function          := ' || quote_literal(Function) || ',
_Processes         := ' || (
    SELECT COUNT(*) FROM cron.Processes
    WHERE cron.Processes.JobID = cron.Jobs.JobID
    AND (cron.Jobs.IntervalDONE IS NOT NULL OR cron.Processes.BatchJobState IS DISTINCT FROM 'DONE')
) || ',
_Concurrent        := ' || upper(Concurrent::text) || ',
_Enabled           := ' || upper(Enabled::text) || ',
_RunIfWaiting      := ' || upper(RunIfWaiting::text) || ',
_RetryOnError      := ' || COALESCE(quote_literal(RetryOnError),'NULL') || ',
_RandomInterval    := ' || upper(RandomInterval::text) || ',
_IntervalAGAIN     := ' || quote_literal(IntervalAGAIN) || ',
_IntervalDONE      := ' || COALESCE(quote_literal(IntervalDONE),'NULL') || ',
_RunAfterTimestamp := ' || COALESCE(quote_literal(RunAfterTimestamp),'NULL') || ',
_RunUntilTimestamp := ' || COALESCE(quote_literal(RunUntilTimestamp),'NULL') || ',
_RunAfterTime      := ' || COALESCE(quote_literal(RunAfterTime),'NULL') || ',
_RunUntilTime      := ' || COALESCE(quote_literal(RunUntilTime),'NULL') || ',
_ConnectionPool    := ' || COALESCE((SELECT quote_literal(Name) FROM cron.ConnectionPools WHERE cron.ConnectionPools.ConnectionPoolID = cron.Jobs.ConnectionPoolID),'NULL') || ',
_LogTableAccess    := ' || upper(LogTableAccess::text) || ',
_RequestedBy       := ' || quote_literal(RequestedBy) || ',
_RequestedAt       := ' || quote_literal(RequestedAt) || '
);' FROM cron.Jobs
WHERE cron.Jobs.IntervalDONE IS NOT NULL OR EXISTS (
    SELECT 1 FROM cron.Processes WHERE cron.Processes.JobID = cron.Jobs.JobID AND cron.Processes.BatchJobState IS DISTINCT FROM 'DONE'
)
ORDER BY JobID;
RETURN;
END;
$FUNC$;

ALTER FUNCTION cron.Generate_Register_Commands() OWNER TO pgcronjob;
