CREATE OR REPLACE FUNCTION cron.Log_Waiting(_NumPIDs integer, _MaxSeconds integer)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, pg_temp
AS $FUNC$
DECLARE
_LogWaitingID integer;
_SeenBefore boolean;
_DumpPgStatActivity boolean;
BEGIN

_SeenBefore := EXISTS (SELECT 1 FROM cron.LogWaiting WHERE NumPIDs = _NumPIDs AND MaxSeconds = _MaxSeconds);
INSERT INTO cron.LogWaiting (NumPIDs, MaxSeconds) VALUES (_NumPIDs, _MaxSeconds) RETURNING LogWaitingID INTO STRICT _LogWaitingID;

EXECUTE format($SQL$
INSERT INTO cron.LogWaitingPgStatActivity (
    LogWaitingID,
    datid,
    datname,
    procpid,
    usesysid,
    usename,
    application_name,
    client_addr,
    client_hostname,
    client_port,
    backend_start,
    xact_start,
    query_start,
    waiting,
    current_query
)
SELECT
    %s,
    datid,
    datname,
    %I,
    usesysid,
    usename,
    application_name,
    client_addr,
    client_hostname,
    client_port,
    backend_start,
    xact_start,
    query_start,
    waiting,
    current_query
FROM pg_stat_activity
%s
$SQL$,
    _LogWaitingID,
    CASE WHEN (SELECT setting::integer FROM pg_catalog.pg_settings WHERE pg_catalog.pg_settings.name = 'server_version_num') < 90600 THEN 'procpid' ELSE 'pid' END,
    CASE WHEN _SeenBefore THEN 'ORDER BY xact_start LIMIT 1' END
);

RETURN TRUE;
END;
$FUNC$;

ALTER FUNCTION cron.Log_Waiting(_NumPIDs integer, _MaxSeconds integer) OWNER TO sudo;

REVOKE ALL ON FUNCTION cron.Log_Waiting(_NumPIDs integer, _MaxSeconds integer) FROM PUBLIC;
GRANT  ALL ON FUNCTION cron.Log_Waiting(_NumPIDs integer, _MaxSeconds integer) TO pgcronjob;
